using UnityEngine;

namespace WoofTalk.VR.Avatar
{
    public class DogAvatarController : MonoBehaviour
    {
        private Animator _animator;

        void Awake()
        {
            _animator = GetComponent<Animator>();
        }

        public void PlayBark()
        {
            if (_animator != null)
                _animator.SetTrigger("Bark");
        }

        public void PlayHeadTurn(float direction)
        {
            if (_animator != null)
                _animator.SetFloat("HeadTurnDirection", direction);
        }
    }
}
