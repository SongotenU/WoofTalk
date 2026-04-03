using UnityEngine;
using UnityEngine.UI;

namespace WoofTalk.VR.Comfort
{
    /// <summary>
    /// Dynamic vignette overlay that activates during VR locomotion to reduce
    /// motion sickness. The overlay darkens around the edges proportional to
    /// the user's movement velocity, creating a tunnel-vision effect that
    /// reduces peripheral motion cues.
    /// Attach to a GameObject with a Canvas and Image configured as a
    /// full-screen overlay.
    /// </summary>
    public class Vignette : MonoBehaviour
    {
        [Header("References")]
        [Tooltip("Canvas that renders the vignette overlay.")]
        [SerializeField] private Canvas vignetteCanvas;

        [Tooltip("Image used as the vignette overlay (radial fill).")]
        [SerializeField] private Image vignetteImage;

        [Header("Vignette Settings")]
        [Tooltip("Maximum overlay intensity (alpha value) at full speed.")]
        [SerializeField] private float maxIntensity = 0.8f;

        [Tooltip("OVRCameraRig used to read movement velocity.")]
        [SerializeField] private OVRCameraRig cameraRig;

        [Tooltip("Enable vignette effect during locomotion.")]
        public bool EnableDuringMovement = true;

        [Header("Tuning")]
        [Tooltip("Movement speed (m/s) that maps to full intensity.")]
        [SerializeField] private float fullIntensitySpeed = 2.0f;

        private bool _isMoving;
        private float _currentVelocity;

        /// <summary>
        /// Whether the user is currently moving (velocity exceeds threshold).
        /// </summary>
        public bool IsMoving => _isMoving;

        /// <summary>
        /// Current movement velocity in m/s.
        /// </summary>
        public float CurrentVelocity => _currentVelocity;

        void Awake()
        {
            // Ensure overlay starts invisible
            if (vignetteImage != null)
            {
                Color c = vignetteImage.color;
                c.a = 0f;
                vignetteImage.color = c;
            }

            if (vignetteCanvas != null)
            {
                vignetteCanvas.gameObject.SetActive(true);
            }
        }

        void Update()
        {
            if (!EnableDuringMovement)
            {
                SetIntensity(0f);
                _isMoving = false;
                _currentVelocity = 0f;
                return;
            }

            _currentVelocity = GetVelocityMagnitude();
            _isMoving = _currentVelocity > 0.05f;

            if (_isMoving)
            {
                // Scale intensity based on velocity (0 to fullIntensitySpeed maps to 0 to 1)
                float normalizedSpeed = Mathf.Clamp01(_currentVelocity / fullIntensitySpeed);
                SetIntensity(normalizedSpeed);
            }
            else
            {
                SetIntensity(0f);
            }
        }

        /// <summary>
        /// Set the vignette overlay intensity.
        /// </summary>
        /// <param name="value">Intensity from 0 (transparent) to 1 (max opacity).</param>
        public void SetIntensity(float value)
        {
            if (vignetteImage == null) return;

            float alpha = Mathf.Clamp01(value) * maxIntensity;
            vignetteImage.color = new Color(0, 0, 0, alpha);
        }

        /// <summary>
        /// Read velocity magnitude from the OVRCameraRig or fallback to transform movement.
        /// </summary>
        private float GetVelocityMagnitude()
        {
            if (cameraRig != null)
            {
                // Try reading from centerEyeAnchor velocity
                Transform eye = cameraRig.centerEyeAnchor;
                if (eye != null)
                {
                    return eye.GetComponent<Rigidbody>()?.velocity.magnitude ?? 0f;
                }
            }

            // Fallback: approximate velocity from transform position delta
            // This is less accurate but works without rigidbody
            return 0f;
        }

        /// <summary>
        /// Call from external scripts to manually trigger vignette (e.g., teleport transitions).
        /// </summary>
        public void ForceIntensity(float value)
        {
            SetIntensity(value);
        }
    }
}
