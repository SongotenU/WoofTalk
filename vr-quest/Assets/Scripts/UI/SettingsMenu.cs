using UnityEngine;
using UnityEngine.UI;
using WoofTalk.VR.UI;

namespace WoofTalk.VR.Settings
{
    /// <summary>
    /// VR settings panel providing volume, bubble opacity, and comfort mode controls.
    /// Settings persist across sessions via PlayerPrefs.
    /// Wire sliders/toggle in the inspector, then call Show()/Hide() to control visibility.
    /// </summary>
    public class SettingsMenu : MonoBehaviour
    {
        [Header("UI References")]
        [SerializeField] private Slider volumeSlider;
        [SerializeField] private Slider bubbleOpacitySlider;
        [SerializeField] private Toggle comfortModeToggle;
        [SerializeField] private Button closeButton;
        [SerializeField] private Button applySettingsButton;

        [Header("External References")]
        [Tooltip("Reference to BubbleManager for real-time opacity updates.")]
        [SerializeField] private BubbleManager bubbleManager;

        [Header("Settings Keys (PlayerPrefs)")]
        [SerializeField] private string volumeKey = "WoofTalk_Volume";
        [SerializeField] private string opacityKey = "WoofTalk_BubbleOpacity";
        [SerializeField] private string comfortKey = "WoofTalk_ComfortMode";

        // Default values
        private const float DefaultVolume = 1.0f;
        private const float DefaultOpacity = 1.0f;
        private const bool DefaultComfortMode = false;

        void Awake()
        {
            LoadSettings();
            WireCallbacks();
        }

        /// <summary>
        /// Show the settings menu panel.
        /// </summary>
        public void Show()
        {
            gameObject.SetActive(true);
            // Refresh UI with current values
            RefreshUIValues();
        }

        /// <summary>
        /// Hide the settings menu panel.
        /// </summary>
        public void Hide()
        {
            ApplySettings();
            gameObject.SetActive(false);
        }

        /// <summary>
        /// Set master audio volume and save to PlayerPrefs.
        /// </summary>
        /// <param name="value">Volume from 0.0 (mute) to 1.0 (full).</param>
        public void SetVolume(float value)
        {
            value = Mathf.Clamp01(value);
            AudioListener.volume = value;
            PlayerPrefs.SetFloat(volumeKey, value);
            PlayerPrefs.Save();
        }

        /// <summary>
        /// Set bubble opacity and save to PlayerPrefs.
        /// </summary>
        /// <param name="value">Opacity from 0.0 (transparent) to 1.0 (opaque).</param>
        public void SetBubbleOpacity(float value)
        {
            value = Mathf.Clamp01(value);
            PlayerPrefs.SetFloat(opacityKey, value);
            PlayerPrefs.Save();

            // Update BubbleManager if referenced
            if (bubbleManager != null)
            {
                // BubbleManager does not expose a direct opacity setter,
                // so we store the value for it to consume
                PlayerPrefs.SetFloat(opacityKey, value);
            }
        }

        /// <summary>
        /// Toggle comfort mode (vignette during movement).
        /// </summary>
        /// <param name="enabled">Whether comfort mode is on.</param>
        public void SetComfortMode(bool enabled)
        {
            PlayerPrefs.SetInt(comfortKey, enabled ? 1 : 0);
            PlayerPrefs.Save();
        }

        /// <summary>
        /// Apply all current UI values to PlayerPrefs and active systems.
        /// </summary>
        public void ApplySettings()
        {
            if (volumeSlider != null)
            {
                SetVolume(volumeSlider.value);
            }
            if (bubbleOpacitySlider != null)
            {
                SetBubbleOpacity(bubbleOpacitySlider.value);
            }
            if (comfortModeToggle != null)
            {
                SetComfortMode(comfortModeToggle.isOn);
            }
            Debug.Log("[SettingsMenu] Settings applied and saved.");
        }

        /// <summary>
        /// Load all settings from PlayerPrefs and apply to UI.
        /// </summary>
        private void LoadSettings()
        {
            // Volume
            float savedVolume = PlayerPrefs.GetFloat(volumeKey, DefaultVolume);
            AudioListener.volume = savedVolume;

            // Bubble Opacity
            float savedOpacity = PlayerPrefs.GetFloat(opacityKey, DefaultOpacity);

            // Comfort Mode
            bool savedComfort = PlayerPrefs.GetInt(comfortKey, DefaultComfortMode ? 1 : 0) == 1;

            // Apply after loading all values
            Invoke(nameof(RefreshUIValues), 0.1f);
        }

        /// <summary>
        /// Push loaded values into UI elements.
        /// </summary>
        private void RefreshUIValues()
        {
            float savedVolume = PlayerPrefs.GetFloat(volumeKey, DefaultVolume);
            float savedOpacity = PlayerPrefs.GetFloat(opacityKey, DefaultOpacity);
            bool savedComfort = PlayerPrefs.GetInt(comfortKey, DefaultComfortMode ? 1 : 0) == 1;

            if (volumeSlider != null) volumeSlider.value = savedVolume;
            if (bubbleOpacitySlider != null) bubbleOpacitySlider.value = savedOpacity;
            if (comfortModeToggle != null) comfortModeToggle.isOn = savedComfort;
        }

        /// <summary>
        /// Wire slider and button callbacks to methods.
        /// </summary>
        private void WireCallbacks()
        {
            if (volumeSlider != null)
            {
                volumeSlider.onValueChanged.AddListener(SetVolume);
            }

            if (bubbleOpacitySlider != null)
            {
                bubbleOpacitySlider.onValueChanged.AddListener(SetBubbleOpacity);
            }

            if (comfortModeToggle != null)
            {
                comfortModeToggle.onValueChanged.AddListener(SetComfortMode);
            }

            if (closeButton != null)
            {
                closeButton.onClick.AddListener(Hide);
            }

            if (applySettingsButton != null)
            {
                applySettingsButton.onClick.AddListener(ApplySettings);
            }
        }

        /// <summary>
        /// Get the current saved bubble opacity value.
        /// </summary>
        public static float GetSavedBubbleOpacity()
        {
            return PlayerPrefs.GetFloat("WoofTalk_BubbleOpacity", 1.0f);
        }

        /// <summary>
        /// Get whether comfort mode is enabled.
        /// </summary>
        public static bool IsComfortModeEnabled()
        {
            return PlayerPrefs.GetInt("WoofTalk_ComfortMode", 0) == 1;
        }

        /// <summary>
        /// Get the current saved volume.
        /// </summary>
        public static float GetSavedVolume()
        {
            return PlayerPrefs.GetFloat("WoofTalk_Volume", 1.0f);
        }
    }
}
