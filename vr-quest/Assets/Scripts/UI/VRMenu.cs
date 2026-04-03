using UnityEngine;

namespace WoofTalk.VR.UI
{
    /// <summary>
    /// World-space VR menu panel with toggle visibility and button callbacks.
    /// Positioned at chest height, 1m in front of the user.
    /// Buttons: Toggle Detection, Toggle Avatar, Settings (stub).
    /// </summary>
    public class VRMenu : MonoBehaviour
    {
        [SerializeField] private GameObject menuPanel;
        [SerializeField] private Camera cameraRef;

        private bool _isVisible;

        /// <summary>Toggle menu visibility</summary>
        public void ToggleVisibility()
        {
            if (_isVisible)
            {
                Hide();
            }
            else
            {
                Show();
            }
        }

        /// <summary>Show the menu panel</summary>
        public void Show()
        {
            if (menuPanel != null)
            {
                menuPanel.SetActive(true);
                _isVisible = true;
            }
        }

        /// <summary>Hide the menu panel</summary>
        public void Hide()
        {
            if (menuPanel != null)
            {
                menuPanel.SetActive(false);
                _isVisible = false;
            }
        }

        void Awake()
        {
            // Start with menu hidden
            if (menuPanel != null)
            {
                menuPanel.SetActive(false);
            }
            _isVisible = false;
        }

        // --- Button callback stubs ---

        /// <summary>Toggle detection on/off (stub - wired to Plan 40-03)</summary>
        public void OnToggleDetection()
        {
            Debug.Log("[VRMenu] Toggle Detection");
        }

        /// <summary>Toggle dog avatar on/off (stub)</summary>
        public void OnToggleAvatar()
        {
            Debug.Log("[VRMenu] Toggle Avatar");
        }

        /// <summary>Open settings panel (stub - deferred to Phase 41/42)</summary>
        public void OnSettings()
        {
            Debug.Log("[VRMenu] Settings (stub)");
        }
    }
}
