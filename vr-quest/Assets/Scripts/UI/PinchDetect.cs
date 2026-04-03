using System;
using UnityEngine;

namespace WoofTalk.VR.UI
{
    /// <summary>
    /// Detects hand pinch gestures via OVRHand finger confidence values.
    /// Provides edge detection events (OnPinchStarted / OnPinchReleased)
    /// for UI interaction.
    /// </summary>
    public class PinchDetect : MonoBehaviour
    {
        public enum HandSide { Left, Right }

        [SerializeField] private OVRHand _ovrHand;
        [SerializeField] private HandSide selectedHand = HandSide.Right;
        [SerializeField] private float pinchThreshold = 0.8f;

        public event Action OnPinchStarted;
        public event Action OnPinchReleased;

        public bool IsPinching => _wasPinching;

        private bool _wasPinching;

        void Awake()
        {
            if (_ovrHand == null)
            {
                _ovrHand = GetComponent<OVRHand>();
            }
        }

        void Update()
        {
            if (_ovrHand == null) return;

            bool isPinching = _ovrHand.GetFingerIsPinching(OVRHand.FingerIndex.thumb);

            // Edge detection: pinch started
            if (isPinching && !_wasPinching)
            {
                if (OnPinchStarted != null)
                {
                    OnPinchStarted.Invoke();
                }
            }

            // Edge detection: pinch released
            if (!isPinching && _wasPinching)
            {
                if (OnPinchReleased != null)
                {
                    OnPinchReleased.Invoke();
                }
            }

            _wasPinching = isPinching;
        }
    }
}
