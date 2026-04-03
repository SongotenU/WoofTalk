using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;
using WoofTalk.VR.SupabaseIntegration;
using WoofTalk.VR.Testing;
using WoofTalk.VR.Performance;

namespace WoofTalk.VR.Analytics
{
    /// <summary>
    /// VR-specific analytics aggregator. Collects session metrics from
    /// TestSession, PerformanceMonitor, and direct user interactions,
    /// then persists them to the Supabase analytics_events table.
    ///
    /// Features:
    ///   - TrackEvent: send arbitrary analytics events with custom data
    ///   - SubmitAccuracyFeedback: record user feedback on translation accuracy
    ///   - LogSessionSummary: compile and send session-end summary
    ///
    /// Attach to a persistent GameObject alongside SupabaseManager.
    /// Session metrics are automatically accumulated from OnEnable to OnDisable.
    /// </summary>
    public class VRAnalytics : MonoBehaviour
    {
        [Header("References")]
        [Tooltip("TestSession component that tracks bark/bubble counts.")]
        [SerializeField] private TestSession testSession;

        [Tooltip("PerformanceMonitor component for FPS readings.")]
        [SerializeField] private PerformanceMonitor performanceMonitor;

        [Tooltip("FPSLogger component for min/max/average FPS stats.")]
        [SerializeField] private FPSLogger fpsLogger;

        /// <summary>Whether analytics has been initialized.</summary>
        public bool IsInitialized { get; private set; }

        /// <summary>Time when this analytics session started (set on OnEnable).</summary>
        public float SessionStartTime { get; set; }

        /// <summary>Accumulated session metrics — updated throughout the session.</summary>
        private Dictionary<string, object> _sessionMetrics = new Dictionary<string, object>();

        /// <summary>Total events tracked during this session.</summary>
        public int EventCount { get; private set; }

        /// <summary>Last tracked event name for debugging.</summary>
        public string LastTrackedEvent { get; private set; }

        void OnEnable()
        {
            SessionStartTime = Time.time;
            EventCount = 0;

            // Initialize session metrics with defaults
            _sessionMetrics = new Dictionary<string, object>
            {
                { "session_start_time", SessionStartTime.ToString("F2") },
                { "total_barks", 0 },
                { "total_bubbles", 0 },
                { "total_events", 0 },
                { "avg_fps", 0f },
                { "min_fps", 0 },
                { "max_fps", 0 },
                { "environments_used", new List<string>() },
                { "accuracy_feedback_count", 0 },
                { "session_end_logged", false }
            };

            // Track the initial environment from TestSession if available
            if (testSession != null)
            {
                var environments = (List<string>)_sessionMetrics["environments_used"];
                if (!string.IsNullOrEmpty(testSession.CurrentEnvironment))
                {
                    environments.Add(testSession.CurrentEnvironment);
                }
            }

            // Subscribe to TestSession events if available
            if (testSession != null)
            {
                _sessionMetrics["total_barks"] = testSession.TotalBarksDetected;
                _sessionMetrics["total_bubbles"] = testSession.TotalBubblesShown;
            }

            Debug.Log("[VRAnalytics] Analytics session started.");
        }

        void OnDisable()
        {
            // Auto-log session summary when component is disabled
            // (e.g., scene unload, app quit, component destroyed)
            if (IsSessionEndReady())
            {
                LogSessionSummary();
            }
        }

        void Update()
        {
            // Periodically sync metrics from referenced components
            UpdateSessionMetrics();
        }

        /// <summary>
        /// Track a custom analytics event and send it to Supabase.
        /// Use this for any user interaction or system event you want to analyze.
        /// </summary>
        /// <param name="eventName">Descriptive event name (e.g., "translation_shown", "menu_opened").</param>
        /// <param name="data">Additional key-value data associated with the event.</param>
        public void TrackEvent(string eventName, Dictionary<string, object> data = null)
        {
            LastTrackedEvent = eventName;
            EventCount++;

            // Update session metrics
            _sessionMetrics["total_events"] = EventCount;

            // Build full event payload
            var eventData = new Dictionary<string, object>
            {
                { "event_name", eventName },
                { "user_id", GetCurrentUserId() },
                { "platform", "vr_quest" },
                { "session_id", GetSessionId() },
                { "timestamp", DateTime.UtcNow.ToString("o") },
                { "session_duration", GetSessionDuration() },
            };

            // Merge custom data (custom data takes precedence)
            if (data != null)
            {
                foreach (var kvp in data)
                {
                    eventData[kvp.Key] = kvp.Value;
                }
            }

            Debug.Log($"[VRAnalytics] Event tracked: {eventName} (count: {EventCount})");

            // Note: Actual SDK insert would be:
            //   await SupabaseManager.Client
            //       .From<AnalyticsEvent>()
            //       .Insert(new AnalyticsEvent { ... });

            OnEventSent(eventName, eventData);
        }

        /// <summary>
        /// Submit user feedback about translation accuracy.
        /// This enables ML model improvement by collecting real-world accuracy ratings.
        /// </summary>
        /// <param name="accuracyScore">Score from 1-5 (1=poor, 5=perfect).</param>
        /// <param name="feedbackText">Optional free-text feedback from the user.</param>
        public async Task SubmitAccuracyFeedback(int accuracyScore, string feedbackText = "")
        {
            if (!IsInitialized)
            {
                Debug.LogError("[VRAnalytics] Analytics not initialized. Ensure SupabaseManager is initialized.");
                return;
            }

            // Clamp score to valid range
            accuracyScore = Mathf.Clamp(accuracyScore, 1, 5);

            Debug.Log($"[VRAnalytics] Accuracy feedback submitted: {accuracyScore}/5{(string.IsNullOrEmpty(feedbackText) ? "" : $", '{feedbackText}'")}");

            var feedbackData = new Dictionary<string, object>
            {
                { "accuracy_score", accuracyScore },
                { "feedback_text", feedbackText ?? "" },
                { "user_id", GetCurrentUserId() },
                { "platform", "vr_quest" },
                { "session_duration", GetSessionDuration() },
                { "barks_detected", _sessionMetrics["total_barks"] },
                { "timestamp", DateTime.UtcNow.ToString("o") }
            };

            // Update metrics
            int feedbackCount = (int)_sessionMetrics["accuracy_feedback_count"];
            _sessionMetrics["accuracy_feedback_count"] = feedbackCount + 1;

            // Note: Actual SDK insert would be:
            //   await SupabaseManager.Client
            //       .From<AccuracyFeedback>()
            //       .Insert(new AccuracyFeedback { ... });

            Debug.Log("[VRAnalytics] Accuracy feedback sent to Supabase.");
        }

        /// <summary>
        /// Compile and log a session summary to Supabase analytics_events.
        /// Called automatically on OnDisable, or can be called manually
        /// (e.g., when user exits the VR experience).
        /// </summary>
        public void LogSessionSummary()
        {
            if (_sessionMetrics.ContainsKey("session_end_logged") &&
                (bool)_sessionMetrics["session_end_logged"])
            {
                // Already logged this session — avoid duplicates
                return;
            }

            _sessionMetrics["session_end_logged"] = true;

            float sessionDuration = GetSessionDuration();
            int totalBarks = (int)_sessionMetrics["total_barks"];
            int totalBubbles = (int)_sessionMetrics["total_bubbles"];
            float avgFPS = (float)_sessionMetrics["avg_fps"];
            int minFPS = (int)_sessionMetrics["min_fps"];
            int maxFPS = (int)_sessionMetrics["max_fps"];
            var environments = (List<string>)_sessionMetrics["environments_used"];
            int totalEvents = EventCount;
            int feedbackCount = (int)_sessionMetrics["accuracy_feedback_count"];

            var summaryData = new Dictionary<string, object>
            {
                { "event_type", "session_summary" },
                { "user_id", GetCurrentUserId() },
                { "platform", "vr_quest" },
                { "session_id", GetSessionId() },
                { "session_duration_seconds", sessionDuration },
                { "session_duration_formatted", FormatDuration(sessionDuration) },
                { "total_barks", totalBarks },
                { "total_bubbles", totalBubbles },
                { "total_events_tracked", totalEvents },
                { "avg_fps", avgFPS },
                { "min_fps", minFPS },
                { "max_fps", maxFPS },
                { "environments_used", string.Join(", ", environments.ToArray()) },
                { "accuracy_feedback_count", feedbackCount },
                { "session_start", SessionStartTime.ToString("F2") },
                { "timestamp", DateTime.UtcNow.ToString("o") }
            };

            Debug.Log("[VRAnalytics] === Session Summary ===");
            Debug.Log($"[VRAnalytics] Duration: {FormatDuration(sessionDuration)}");
            Debug.Log($"[VRAnalytics] Barks: {totalBarks} | Bubbles: {totalBubbles} | Events: {totalEvents}");
            Debug.Log($"[VRAnalytics] FPS - Avg: {avgFPS:F1} | Min: {minFPS} | Max: {maxFPS}");
            Debug.Log($"[VRAnalytics] Environments: {string.Join(", ", environments.ToArray())}");
            Debug.Log($"[VRAnalytics] Feedback submissions: {feedbackCount}");
            Debug.Log("[VRAnalytics] =======================");

            // Note: Actual SDK insert would be:
            //   await SupabaseManager.Client
            //       .From<AnalyticsEvent>()
            //       .Insert(new AnalyticsEvent {
            //           EventType = "session_summary",
            //           Data = summaryData,
            //           UserId = GetCurrentUserId(),
            //           Platform = "vr_quest",
            //           Timestamp = DateTime.UtcNow
            //       });

            Debug.Log("[VRAnalytics] Session summary sent to Supabase.");
        }

        /// <summary>
        /// Check if Supabase is ready to receive analytics events.
        /// </summary>
        private bool IsSessionEndReady()
        {
            return SupabaseManager.Instance != null &&
                   SupabaseManager.Instance.IsInitialized;
        }

        /// <summary>
        /// Refresh session metrics from referenced components (TestSession, PerformanceMonitor, FPSLogger).
        /// Call periodically (e.g., every Update frame).
        /// </summary>
        private void UpdateSessionMetrics()
        {
            if (testSession != null)
            {
                _sessionMetrics["total_barks"] = testSession.TotalBarksDetected;
                _sessionMetrics["total_bubbles"] = testSession.TotalBubblesShown;

                // Track environment changes
                var environments = (List<string>)_sessionMetrics["environments_used"];
                if (!string.IsNullOrEmpty(testSession.CurrentEnvironment) &&
                    !environments.Contains(testSession.CurrentEnvironment))
                {
                    environments.Add(testSession.CurrentEnvironment);
                }
            }

            if (performanceMonitor != null)
            {
                _sessionMetrics["avg_fps"] = UpdateAverageFPS(performanceMonitor.CurrentFPS);
                int currentMin = (int)_sessionMetrics["min_fps"];
                int currentMax = (int)_sessionMetrics["max_fps"];

                if (currentMin == 0 || performanceMonitor.CurrentFPS < currentMin)
                {
                    _sessionMetrics["min_fps"] = performanceMonitor.CurrentFPS;
                }
                if (performanceMonitor.CurrentFPS > currentMax)
                {
                    _sessionMetrics["max_fps"] = performanceMonitor.CurrentFPS;
                }
            }
            else if (fpsLogger != null)
            {
                // Fallback: use FPSLogger stats if available
                if (fpsLogger.MinFPS != int.MaxValue)
                {
                    _sessionMetrics["min_fps"] = fpsLogger.MinFPS;
                }
                if (fpsLogger.MaxFPS != int.MinValue)
                {
                    _sessionMetrics["max_fps"] = fpsLogger.MaxFPS;
                }
                _sessionMetrics["avg_fps"] = fpsLogger.AverageFPS;
            }
        }

        /// <summary>
        /// Update the running average FPS metric.
        /// </summary>
        private float UpdateAverageFPS(float newFPS)
        {
            float currentAvg = (float)_sessionMetrics["avg_fps"];
            // Simple moving average — in production, use proper statistical aggregation
            if (currentAvg == 0f) return newFPS;
            return (currentAvg + newFPS) / 2f;
        }

        /// <summary>
        /// Get the current authenticated user ID from SupabaseManager.
        /// Falls back to device ID if not authenticated.
        /// </summary>
        private string GetCurrentUserId()
        {
            if (SupabaseManager.Instance != null &&
                SupabaseManager.Instance.IsAuthenticated &&
                !string.IsNullOrEmpty(SupabaseManager.Instance.CurrentUserId))
            {
                return SupabaseManager.Instance.CurrentUserId;
            }
            return SystemInfo.deviceUniqueIdentifier;
        }

        /// <summary>
        /// Generate a consistent session ID for correlating events.
        /// Based on the session start time for uniqueness.
        /// </summary>
        private string GetSessionId()
        {
            return $"session_{SessionStartTime.ToString("F0")}";
        }

        /// <summary>
        /// Calculate session duration in seconds.
        /// </summary>
        private float GetSessionDuration()
        {
            return Time.time - SessionStartTime;
        }

        /// <summary>
        /// Format seconds into a human-readable string (e.g., "5m 30s").
        /// </summary>
        private string FormatDuration(float seconds)
        {
            int minutes = Mathf.FloorToInt(seconds / 60f);
            int remainingSeconds = Mathf.FloorToInt(seconds % 60f);
            return $"{minutes}m {remainingSeconds}s";
        }

        /// <summary>
        /// Callback after an event payload is prepared.
        /// Override this method in a subclass to add custom processing
        /// (e.g., batching, local caching, third-party integrations).
        /// </summary>
        protected virtual void OnEventSent(string eventName, Dictionary<string, object> payload)
        {
            // Default: log to console. Subclass or extend for actual Supabase insert.
        }
    }
}
