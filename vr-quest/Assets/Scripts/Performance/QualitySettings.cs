using UnityEngine;

namespace WoofTalk.VR.Performance
{
    /// <summary>
    /// Manages device-specific quality presets for Quest 2 and Quest 3.
    /// Applies appropriate target frame rate, shadow resolution, texture quality,
    /// and anti-aliasing settings for each device tier.
    /// </summary>
    public static class QualitySettings
    {
        public enum QualityLevel
        {
            Quest2 = 0,
            Quest3 = 1
        }

        /// <summary>
        /// Currently active quality level.
        /// </summary>
        public static QualityLevel Current { get; private set; } = QualityLevel.Quest2;

        /// <summary>
        /// Applies quality settings for the specified device tier.
        ///
        /// Quest 2: 72 FPS target, low shadow resolution, medium texture quality, no anti-aliasing.
        /// Quest 3: 90 FPS target, medium shadow resolution, high texture quality, MSAA 2x.
        /// </summary>
        /// <param name="level">The quality level to apply.</param>
        public static void Apply(QualityLevel level)
        {
            Current = level;

            switch (level)
            {
                case QualityLevel.Quest2:
                    ApplyQuest2Settings();
                    Debug.Log("[QualitySettings] Applied Quest 2 preset (72 FPS target).");
                    break;

                case QualityLevel.Quest3:
                    ApplyQuest3Settings();
                    Debug.Log("[QualitySettings] Applied Quest 3 preset (90 FPS target).");
                    break;

                default:
                    Debug.LogWarning("[QualitySettings] Unknown quality level: " + level);
                    break;
            }
        }

        private static void ApplyQuest2Settings()
        {
            // Target 72 FPS — primary target for Quest 2 smoothness
            Application.targetFrameRate = 72;
            QualitySettings.vSyncCount = 0; // Manual frame rate control

            // Low shadow resolution to maintain performance on Adreno 650
            QualitySettings.shadowResolution = ShadowResolution.Low;

            // Medium texture quality
            QualitySettings.globalTextureMipmapLimit = 1;

            // No anti-aliasing for Quest 2
            QualitySettings.antiAliasing = 0;

            // Shadow settings tuned for performance
            QualitySettings.shadowDistance = 10f;
            QualitySettings.shadowCascades = 0;
        }

        private static void ApplyQuest3Settings()
        {
            // Target 90 FPS — primary target for Quest 3 with Snapdragon XR2 Gen 2
            Application.targetFrameRate = 90;
            QualitySettings.vSyncCount = 0; // Manual frame rate control

            // Medium shadow resolution — Quest 3 GPU can handle it
            QualitySettings.shadowResolution = ShadowResolution.Medium;

            // High texture quality
            QualitySettings.globalTextureMipmapLimit = 0;

            // MSAA 2x for Quest 3
            QualitySettings.antiAliasing = 2;

            // Shadow settings with moderate distance
            QualitySettings.shadowDistance = 15f;
            QualitySettings.shadowCascades = 2;
        }
    }
}
