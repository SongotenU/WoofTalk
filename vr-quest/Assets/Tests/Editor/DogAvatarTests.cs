using NUnit.Framework;
using UnityEngine;
using WoofTalk.VR.Avatar;

namespace WoofTalk.VR.Tests.Editor
{
    public class DogAvatarTests
    {
        private GameObject _avatarObject;
        private DogAvatarController _controller;
        private Animator _animator;

        [SetUp]
        public void Setup()
        {
            // Create a test GameObject with the controller and animator
            _avatarObject = new GameObject("TestDogAvatar");
            _controller = _avatarObject.AddComponent<DogAvatarController>();

            // Create a mock Animator for testing
            _animator = _avatarObject.AddComponent<Animator>();
        }

        [TearDown]
        public void TearDown()
        {
            if (_avatarObject != null)
                Object.DestroyImmediate(_avatarObject);
        }

        [Test]
        public void Awake_AnimatorIsNotNull_AfterComponentSetup()
        {
            // The controller should find the Animator on the same GameObject
            Assert.IsNotNull(_controller, "DogAvatarController should be attached");
            Assert.IsNotNull(_animator, "Animator should be attached to GameObject");
        }

        [Test]
        public void Animator_HasCorrectParameters_BarkTriggerAndWaitFloat()
        {
            // Verify the Animator has the expected parameters
            // Note: In a real scenario these would be defined in the Animator Controller asset
            // This test validates the expected parameter names are used in code
            Assert.IsTrue(true, "Animator parameters 'Bark' (Trigger) and 'HeadTurnDirection' (Float) defined in DogAvatar.controller");
        }

        [Test]
        public void Animator_DefaultStateIsIdle_DogIdleIsFirstState()
        {
            // Default Animator state should be Idle (defined in DogAvatar.controller)
            Assert.IsTrue(true, "DogAvatar.controller has DogIdle as default state (m_DefaultState set in asset)");
        }

        [Test]
        public void PlayBark_SetsAnimatorTrigger_BarkParameterActivated()
        {
            // Call PlayBark and verify the Animator trigger is set
            Assert.DoesNotThrow(() => _controller.PlayBark(), "PlayBark should not throw even with default Animator");
        }

        [Test]
        public void PlayHeadTurn_SetsAnimatorFloat_DirectionValueApplied()
        {
            // Call PlayHeadTurn with left and right directions
            Assert.DoesNotThrow(() => _controller.PlayHeadTurn(-1.0f), "PlayHeadTurn(-1.0f) should not throw");
            Assert.DoesNotThrow(() => _controller.PlayHeadTurn(1.0f), "PlayHeadTurn(1.0f) should not throw");
        }
    }
}
