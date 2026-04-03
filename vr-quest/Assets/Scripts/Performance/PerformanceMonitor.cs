using UnityEngine;
using TMPro;

namespace WoofTalk.VR.Performance
{
    /// <summary>
    /// Real-time FPS monitor that updates every 1 second and logs warnings
    /// when frame rate drops below the configured target.
    /// Attach to a GameObject in the VR scene with an optional world-space
    /// TextMeshPro UI element for on-screen FPS display.
    /// </summary>
    public class PerformanceMonitor : MonoBehaviour
    {
        [Header("Display")]
        [Tooltip("TextMeshProUGUI element to display FPS readout (world-space UI).")]
        [SerializeField] private TextMeshProUGUI fpsDisplay;

        [Header("Monitoring")]
        [Tooltip("How many consecutive seconds below target before logging a warning.")]
        [SerializeField] private int consecutiveDropThreshold = 3;

        /// <summary>
        /// Current measured frames per second (updated every 1 second).
        /// </summary>
        public int CurrentFPS { get; private set; }

        /// <summary>
        /// Target FPS for the current quality setting.
        /// Update this when quality settings change.
        /// </summary>
        public int TargetFPS { get; set; } = 72;

        private float _deltaTime;
        private int _frameCount;
        private int _consecutiveLowFrames;
        private bool _fpsCalculated;

        void Start()
        {
            _consecutiveLowFrames = 0;
            _fpsCalculated = false;
        }

        void Update()
        {
            _deltaTime += Time.deltaTime;
            _frameCount++;

            if (_deltaTime >= 1.0f)
            {
                // Calculate FPS from accumulated frames
                CurrentFPS = Mathf.RoundToInt(_frameCount / _deltaTime);
                _fpsCalculated = true;

                // Update display if assigned
                if (fpsDisplay != null)
                {
                    fpsDisplay.text = $"FPS: {CurrentFPS}";
                }

                // Check if below target for consecutive seconds
                if (CurrentFPS < TargetFPS)
                {
                    _consecutiveLowFrames++;

                    if (_consecutiveLowFrames >= consecutiveDropThreshold)
                    {
                        Debug.LogWarning($"[PerformanceMonitor] FPS below target for {consecutiveDropThreshold}+ seconds: {CurrentFPS} FPS (target: {TargetFPS} FPS)");
                        _consecutiveLowFrames = consecutiveDropThreshold; // Cap to avoid spam
                    }
                }
                else
                {
                    _consecutiveLowFrames = 0;
                }

                // Reset accumulators
                _deltaTime = 0f;
                _frameCount = 0;
            }
        }

        /// <summary>
        /// Update the target FPS (call when QualitySettings.Apply() changes).
        /// </summary>
        /// <param name="targetFps">New target FPS value.</param>
        public void SetTargetFPS(int targetFps)
        {
            TargetFPS = targetFps;
            _consecutiveLowFrames = 0; // Reset consecutive counter on target change
            Debug.Log($"[PerformanceMonitor] Target FPS updated to: {targetFps}");
        }

        /// <summary>
        /// Returns whether the current FPS is above the warning threshold.
        /// </summary>
        public bool IsPerformingAboveThreshold()
        {
            return CurrentFPS >= TargetFPS;
        }
    }
}
