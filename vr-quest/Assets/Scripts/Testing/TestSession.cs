using UnityEngine;

namespace WoofTalk.VR.Testing
{
    /// <summary>
    /// Tracks VR session metrics for user testing cycles.
    /// Records session duration, bark detections, bubble displays, and
    /// current environment. Attach to a persistent GameObject in the VR scene.
    /// Call LogSummary() at the end of a test session to review all metrics.
    /// </summary>
    public class TestSession : MonoBehaviour
    {
        /// <summary>Duration of the current session in seconds.</summary>
        public float SessionDuration
        {
            get
            {
                if (_sessionStartTime < 0f) return 0f;
                return Time.timeSinceLevelLoad - _sessionStartTime;
            }
        }

        /// <summary>Total number of barks detected during this session.</summary>
        public int TotalBarksDetected { get; private set; }

        /// <summary>Total number of bubbles shown during this session.</summary>
        public int TotalBubblesShown { get; private set; }

        /// <summary>Name of the currently active VR environment.</summary>
        public string CurrentEnvironment { get; private set; }

        private float _sessionStartTime = -1f;
        private float _sessionEndTime = -1f;
        private bool _sessionActive = false;

        void OnEnable()
        {
            StartSession();
        }

        void OnDisable()
        {
            EndSession();
        }

        /// <summary>
        /// Start a new test session. Resets all counters and records start time.
        /// </summary>
        public void StartSession()
        {
            _sessionStartTime = Time.timeSinceLevelLoad;
            _sessionEndTime = -1f;
            _sessionActive = true;
            TotalBarksDetected = 0;
            TotalBubblesShown = 0;
            CurrentEnvironment = "Unknown";

            Debug.Log("[TestSession] Session started");
        }

        /// <summary>
        /// End the current test session and log final summary.
        /// </summary>
        public void EndSession()
        {
            if (!_sessionActive) return;

            _sessionEndTime = Time.timeSinceLevelLoad;
            _sessionActive = false;

            float duration = _sessionEndTime - _sessionStartTime;
            Debug.Log($"[TestSession] Session ended. Duration: {duration:F1}s");
            LogSummary();
        }

        /// <summary>
        /// Record a single bark detection event.
        /// </summary>
        public void RecordBark()
        {
            TotalBarksDetected++;
        }

        /// <summary>
        /// Record a single bubble display event.
        /// </summary>
        public void RecordBubble()
        {
            TotalBubblesShown++;
        }

        /// <summary>
        /// Set the name of the current VR environment.
        /// </summary>
        /// <param name="envName">Environment name (e.g., "Backyard", "Park").</param>
        public void SetEnvironment(string envName)
        {
            CurrentEnvironment = envName;
            Debug.Log($"[TestSession] Environment changed to: {envName}");
        }

        /// <summary>
        /// Log all session metrics to the Unity console.
        /// </summary>
        public void LogSummary()
        {
            float duration = SessionDuration;
            Debug.Log("[TestSession] === Session Summary ===");
            Debug.Log($"[TestSession] Duration: {duration:F1}s ({duration / 60f:F1} minutes)");
            Debug.Log($"[TestSession] Total Barks Detected: {TotalBarksDetected}");
            Debug.Log($"[TestSession] Total Bubbles Shown: {TotalBubblesShown}");
            Debug.Log($"[TestSession] Current Environment: {CurrentEnvironment}");
            Debug.Log("[TestSession] =======================");
        }
    }
}
