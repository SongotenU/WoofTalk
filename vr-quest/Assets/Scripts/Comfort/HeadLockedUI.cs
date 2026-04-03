using UnityEngine;

namespace WoofTalk.VR.Comfort
{
    /// <summary>
    /// Keeps a UI element locked to the camera's view position in world space.
    /// The element follows the centerEyeAnchor at a fixed offset so critical
    /// information (FPS display, crosshair, notifications) is always readable.
    /// Attach to the UI element you want to lock. Assign the cameraTarget to
    /// the OVRCameraRig centerEyeAnchor.
    /// </summary>
    public class HeadLockedUI : MonoBehaviour
    {
        [Header("Camera Reference")]
        [Tooltip("OVRCameraRig centerEyeAnchor to lock UI relative to.")]
        [SerializeField] private Transform cameraTarget;

        [Header("Position Offset")]
        [Tooltip("Camera-relative offset: x=left/right, y=up/down, z=distance forward.")]
        [SerializeField] private Vector3 offset = new Vector3(0f, -0.3f, 0.5f);

        [Header("Smoothing")]
        [Tooltip("Smooth follow speed (0 = instant, higher = smoother). Set to 0 for instant snap.")]
        [SerializeField] private float smoothSpeed = 0f;

        /// <summary>
        /// Whether the head-locking is currently active.
        /// </summary>
        public bool Enabled = true;

        /// <summary>
        /// Lock to specific axes (useful for keeping UI on a flat plane).
        /// </summary>
        public bool LockYAxis = false;

        void LateUpdate()
        {
            if (!Enabled || cameraTarget == null) return;

            Vector3 targetPosition = cameraTarget.position
                + cameraTarget.forward * offset.z
                + cameraTarget.up * offset.y
                + cameraTarget.right * offset.x;

            if (LockYAxis)
            {
                targetPosition.y = cameraTarget.position.y + offset.y;
            }

            if (smoothSpeed > 0f)
            {
                transform.position = Vector3.Lerp(
                    transform.position, targetPosition, smoothSpeed * Time.deltaTime);
            }
            else
            {
                transform.position = targetPosition;
            }

            // Always match camera rotation so UI faces the user
            transform.rotation = cameraTarget.rotation;
        }

        /// <summary>
        /// Enable head-locked positioning.
        /// </summary>
        public void Enable()
        {
            Enabled = true;
        }

        /// <summary>
        /// Disable head-locked positioning (UI stays at current position).
        /// </summary>
        public void Disable()
        {
            Enabled = false;
        }

        /// <summary>
        /// Set the camera target at runtime (e.g., after OVRCameraRig is found).
        /// </summary>
        public void SetCameraTarget(Transform target)
        {
            cameraTarget = target;
        }
    }
}
