using UnityEngine;

namespace WoofTalk.VR.UI
{
    /// <summary>
    /// Makes a GameObject always face the camera, constrained to Y-axis rotation
    /// to keep it upright (no head roll/pitch). Uses LateUpdate to avoid one-frame jitter.
    /// </summary>
    public class BillboardVR : MonoBehaviour
    {
        [SerializeField] private Transform cameraTarget;

        public void SetCameraTarget(Transform target)
        {
            cameraTarget = target;
        }

        void LateUpdate()
        {
            if (cameraTarget == null) return;

            Vector3 flatTarget = new Vector3(
                cameraTarget.position.x,
                transform.position.y,
                cameraTarget.position.z
            );
            transform.LookAt(flatTarget);
        }
    }
}
