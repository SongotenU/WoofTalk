using System;
using UnityEngine;

namespace WoofTalk.VR.UI
{
    /// <summary>
    /// VR menu button that triggers when a hand pointer is within activation distance
    /// AND the hand is pinching. Provides visual feedback via scale animation.
    /// </summary>
    public class VRMenuButton : MonoBehaviour
    {
        [SerializeField] private PinchDetect pinchDetect;
        [SerializeField] private Transform handPointer;
        [SerializeField] private float activationDistance = 0.02f;
        [SerializeField] private UnityEngine.UI.Button unityButton;

        public event Action OnPressed;

        private bool _isPressed;
        private Vector3 _originalScale;

        void Awake()
        {
            _originalScale = transform.localScale;

            if (pinchDetect == null)
            {
                pinchDetect = FindFirstObjectByType<PinchDetect>();
            }

            // If handPointer not assigned, try to get index finger tip from OVRHand
            if (handPointer == null)
            {
                var ovrHand = GetComponentInParent<OVRHand>();
                if (ovrHand != null)
                {
                    handPointer = ovrHand.transform;
                }
            }
        }

        void Update()
        {
            if (handPointer == null || pinchDetect == null) return;

            float dist = Vector3.Distance(handPointer.position, transform.position);
            bool shouldBePressed = dist < activationDistance && pinchDetect.IsPinching;

            if (shouldBePressed && !_isPressed)
            {
                OnPressed?.Invoke();
                unityButton?.onClick?.Invoke();
                _isPressed = true;
                // Visual feedback: press down scale
                transform.localScale = _originalScale * 0.95f;
            }

            if (!shouldBePressed && _isPressed)
            {
                _isPressed = false;
                // Visual feedback: release back to normal
                transform.localScale = _originalScale;
            }
        }
    }
}
