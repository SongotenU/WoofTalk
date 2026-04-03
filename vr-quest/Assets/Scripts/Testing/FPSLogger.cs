using UnityEngine;

namespace WoofTalk.VR.Testing
{
    /// <summary>
    /// Logs FPS statistics every 30 seconds during testing sessions.
    /// Tracks running min, max, and average FPS since the component was enabled.
    /// Optionally references a PerformanceMonitor for current FPS readings,
    /// but falls back to its own frame counting if no monitor is assigned.
    /// Attach to a GameObject in the VR test scene.
    /// </summary>
    public class FPSLogger : MonoBehaviour
    {
        [Header("References")]
        [Tooltip("Optional PerformanceMonitor to read current FPS from.")]
        [SerializeField] private PerformanceMonitor performanceMonitor;

        [Header("Logging")]
        [Tooltip("Interval in seconds between FPS log entries.")]
        [SerializeField] private float logInterval = 30f;

        /// <summary>Minimum FPS recorded since session start.</summary>
        public int MinFPS { get; private set; } = int.MaxValue;

        /// <summary>Maximum FPS recorded since session start.</summary>
        public int MaxFPS { get; private set; } = int.MinValue;

        /// <summary>Average FPS since session start.</summary>
        public float AverageFPS
        {
            get
            {
                return _frameCount > 0 ? _totalFPS / _frameCount : 0f;
            }
        }

        private float _elapsedTime;
        private float _logTimer;
        private int _totalFPS;
        private int _frameCount;
        private float _frameAccumulator;
        private int _sampleCount;

        void OnEnable()
        {
            ResetStats();
            Debug.Log($"[FPSLogger] FPS logging started. Logging every {logInterval}s.");
        }

        void OnDisable()
        {
            LogFinalStats();
        }

        void Update()
        {
            // Accumulate frames for FPS calculation
            _frameAccumulator += Time.deltaTime;
            _sampleCount++;

            _elapsedTime += Time.deltaTime;
            _logTimer += Time.deltaTime;

            // Log at interval
            if (_logTimer >= logInterval)
            {
                LogCurrentStats();
                _logTimer = 0f;
            }
        }

        /// <summary>
        /// Reset all tracked statistics.
        /// </summary>
        private void ResetStats()
        {
            MinFPS = int.MaxValue;
            MaxFPS = int.MinValue;
            _totalFPS = 0;
            _frameCount = 0;
            _logTimer = 0f;
            _elapsedTime = 0f;
            _frameAccumulator = 0f;
            _sampleCount = 0;
        }

        /// <summary>
        /// Calculate current FPS (from internal sampling or PerformanceMonitor).
        /// </summary>
        private int GetCurrentFPS()
        {
            if (performanceMonitor != null)
            {
                return performanceMonitor.CurrentFPS;
            }

            // Fallback: calculate from our own frame sampling
            if (_sampleCount > 0 && _frameAccumulator > 0f)
            {
                return Mathf.RoundToInt(_sampleCount / _frameAccumulator);
            }

            return 0;
        }

        /// <summary>
        /// Log current FPS stats at the configured interval.
        /// </summary>
        private void LogCurrentStats()
        {
            int currentFPS = GetCurrentFPS();
            if (currentFPS <= 0) return;

            UpdateStats(currentFPS);

            _frameAccumulator = 0f;
            _sampleCount = 0;

            Debug.Log($"[FPSLogger] Average FPS: {AverageFPS:F1} over last {logInterval:F0}s | " +
                      $"Current: {currentFPS} | Min: {MinFPS} | Max: {MaxFPS}");
        }

        /// <summary>
        /// Update running min/max/average with a new FPS sample.
        /// </summary>
        private void UpdateStats(int fps)
        {
            if (fps < MinFPS) MinFPS = fps;
            if (fps > MaxFPS) MaxFPS = fps;
            _totalFPS += fps;
            _frameCount++;
        }

        /// <summary>
        /// Log final statistics when the component is disabled.
        /// </summary>
        private void LogFinalStats()
        {
            // Ensure last sample is recorded
            int currentFPS = GetCurrentFPS();
            if (currentFPS > 0)
            {
                UpdateStats(currentFPS);
            }

            Debug.Log($"[FPSLogger] Final Stats - Min: {MinFPS}, Max: {MaxFPS}, Avg: {AverageFPS:F1} " +
                      $"over {_elapsedTime:F0}s total");
        }
    }
}
