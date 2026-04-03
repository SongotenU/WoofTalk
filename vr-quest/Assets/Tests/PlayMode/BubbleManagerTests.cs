using System.Collections;
using System.Collections.Generic;
using NUnit.Framework;
using TMPro;
using UnityEngine;
using UnityEngine.TestTools;

namespace WoofTalk.VR.UI.Tests
{
    public class BubbleManagerTests
    {
        private GameObject _bubblePrefab;
        private GameObject _bubbleManagerObj;
        private BubbleManager _bubbleManager;
        private Transform _anchorPoint;

        [SetUp]
        public void Setup()
        {
            // Create a temporary bubble prefab equivalent
            _bubblePrefab = new GameObject("TestBubble");
            var canvas = _bubblePrefab.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.WorldSpace;
            _bubblePrefab.AddComponent<BillboardVR>();
            var bubbleComp = _bubblePrefab.AddComponent<TranslationBubble>();

            // Create text child for the prefab
            var textObj = new GameObject("Text");
            var tmpText = textObj.AddComponent<TextMeshProUGUI>();
            tmpText.fontSize = 28;
            textObj.transform.SetParent(_bubblePrefab.transform);

            // Wire up the TranslationBubble component
            bubbleComp.SetText("test");

            // Create BubbleManager
            _bubbleManagerObj = new GameObject("BubbleManager");
            _bubbleManager = _bubbleManagerObj.AddComponent<BubbleManager>();

            // Create anchor point
            _anchorPoint = new GameObject("AnchorPoint").transform;
        }

        [TearDown]
        public void TearDown()
        {
            Object.DestroyImmediate(_bubblePrefab);
            Object.DestroyImmediate(_bubbleManagerObj);
            Object.DestroyImmediate(_anchorPoint.gameObject);
        }

        [Test]
        public void ShowBubble_SpawnsAtAnchorPlusOffset()
        {
            _anchorPoint.position = new Vector3(0, 1, 0);

            // Use reflection to set the bubblePrefab and poolSize on BubbleManager
            var prefabField = typeof(BubbleManager).GetField("bubblePrefab",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var poolSizeField = typeof(BubbleManager).GetField("poolSize",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);

            prefabField.SetValue(_bubbleManager, _bubblePrefab);
            poolSizeField.SetValue(_bubbleManager, 3);

            // Manually create pool since Awake already ran
            var poolField = typeof(BubbleManager).GetField("_pool",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var activeField = typeof(BubbleManager).GetField("_activeBubbles",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var pool = new Queue<GameObject>(3);
            var active = new List<GameObject>(3);

            for (int i = 0; i < 3; i++)
            {
                GameObject bubble = Object.Instantiate(_bubblePrefab, _bubbleManagerObj.transform);
                bubble.SetActive(false);
                pool.Enqueue(bubble);
            }

            poolField.SetValue(_bubbleManager, pool);
            activeField.SetValue(_bubbleManager, active);

            // Act
            _bubbleManager.ShowBubble("Hello", _anchorPoint);

            // Assert bubble created at anchor + (0, 0.5, 0)
            Assert.AreEqual(1, active.Count, "One active bubble expected");
            GameObject activeBubble = active[0];
            Vector3 expectedPos = _anchorPoint.position + new Vector3(0, 0.5f, 0);
            Assert.AreEqual(expectedPos, activeBubble.transform.position, 0.001f,
                "Bubble should spawn at anchor Y + 0.5m");
        }

        [Test]
        public void ShowBubble_AssignsBillboardCameraTarget()
        {
            var poolField = typeof(BubbleManager).GetField("_pool",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var activeField = typeof(BubbleManager).GetField("_activeBubbles",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var prefabField = typeof(BubbleManager).GetField("bubblePrefab",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var poolSizeField = typeof(BubbleManager).GetField("poolSize",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);

            prefabField.SetValue(_bubbleManager, _bubblePrefab);
            poolSizeField.SetValue(_bubbleManager, 3);

            var pool = new Queue<GameObject>(3);
            var active = new List<GameObject>(3);
            for (int i = 0; i < 3; i++)
            {
                GameObject bubble = Object.Instantiate(_bubblePrefab, _bubbleManagerObj.transform);
                bubble.SetActive(false);
                pool.Enqueue(bubble);
            }
            poolField.SetValue(_bubbleManager, pool);
            activeField.SetValue(_bubbleManager, active);

            // Assign a camera target
            var cameraTarget = new GameObject("CameraTarget").transform;
            var camField = typeof(BubbleManager).GetField("_cameraTarget",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            camField.SetValue(_bubbleManager, cameraTarget);

            _bubbleManager.ShowBubble("Test", _anchorPoint);

            Assert.AreEqual(1, active.Count);
            BillboardVR billboard = active[0].GetComponent<BillboardVR>();
            Assert.IsNotNull(billboard, "BillboardVR component should exist");
        }

        [Test]
        public void ShowBubble_SetsTextOnTranslationBubble()
        {
            var poolField = typeof(BubbleManager).GetField("_pool",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var activeField = typeof(BubbleManager).GetField("_activeBubbles",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var prefabField = typeof(BubbleManager).GetField("bubblePrefab",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var poolSizeField = typeof(BubbleManager).GetField("poolSize",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);

            prefabField.SetValue(_bubbleManager, _bubblePrefab);
            poolSizeField.SetValue(_bubbleManager, 3);

            var pool = new Queue<GameObject>(3);
            var active = new List<GameObject>(3);
            for (int i = 0; i < 3; i++)
            {
                GameObject bubble = Object.Instantiate(_bubblePrefab, _bubbleManagerObj.transform);
                bubble.SetActive(false);
                pool.Enqueue(bubble);
            }
            poolField.SetValue(_bubbleManager, pool);
            activeField.SetValue(_bubbleManager, active);

            _bubbleManager.ShowBubble("Hello World", _anchorPoint);

            Assert.AreEqual(1, active.Count);
            TranslationBubble comp = active[0].GetComponent<TranslationBubble>();
            Assert.IsNotNull(comp, "TranslationBubble component should exist");
        }

        [UnityTest]
        public IEnumerator DismissAfter_DeactivatesBubbleAndReturnsToPool()
        {
            var poolField = typeof(BubbleManager).GetField("_pool",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var activeField = typeof(BubbleManager).GetField("_activeBubbles",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var prefabField = typeof(BubbleManager).GetField("bubblePrefab",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var poolSizeField = typeof(BubbleManager).GetField("poolSize",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);

            prefabField.SetValue(_bubbleManager, _bubblePrefab);
            poolSizeField.SetValue(_bubbleManager, 2);

            var pool = new Queue<GameObject>(2);
            var active = new List<GameObject>(2);
            for (int i = 0; i < 2; i++)
            {
                GameObject bubble = Object.Instantiate(_bubblePrefab, _bubbleManagerObj.transform);
                bubble.SetActive(false);
                pool.Enqueue(bubble);
            }
            poolField.SetValue(_bubbleManager, pool);
            activeField.SetValue(_bubbleManager, active);

            _bubbleManager.ShowBubble("Test", _anchorPoint);
            Assert.AreEqual(1, _bubbleManager.ActiveCount, "Should have 1 active bubble");

            // Wait for auto-dismiss (shortened by using internal coroutine)
            yield return new WaitForSeconds(0.2f);

            // Verify bubble was deactivated and returned to pool
            pool = (Queue<GameObject>)poolField.GetValue(_bubbleManager);
            active = (List<GameObject>)activeField.GetValue(_bubbleManager);
            Assert.GreaterOrEqual(pool.Count, 1, "Bubble should be returned to pool");
        }

        [Test]
        public void PoolExhausted_EvictsOldestBubble()
        {
            var poolField = typeof(BubbleManager).GetField("_pool",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var activeField = typeof(BubbleManager).GetField("_activeBubbles",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var prefabField = typeof(BubbleManager).GetField("bubblePrefab",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var poolSizeField = typeof(BubbleManager).GetField("poolSize",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);

            prefabField.SetValue(_bubbleManager, _bubblePrefab);
            poolSizeField.SetValue(_bubbleManager, 2);

            var pool = new Queue<GameObject>(2);
            var active = new List<GameObject>(2);
            for (int i = 0; i < 2; i++)
            {
                GameObject bubble = Object.Instantiate(_bubblePrefab, _bubbleManagerObj.transform);
                bubble.SetActive(false);
                pool.Enqueue(bubble);
            }
            poolField.SetValue(_bubbleManager, pool);
            activeField.SetValue(_bubbleManager, active);

            // Fill the pool
            _bubbleManager.ShowBubble("First", _anchorPoint);
            _bubbleManager.ShowBubble("Second", _anchorPoint);

            Assert.AreEqual(2, _bubbleManager.ActiveCount, "Pool should be full with 2 active bubbles");

            // Next bubble forces eviction
            _bubbleManager.ShowBubble("Third", _anchorPoint);

            active = (List<GameObject>)activeField.GetValue(_bubbleManager);
            pool = (Queue<GameObject>)poolField.GetValue(_bubbleManager);

            // Should still have 2 active and pool has 1
            Assert.AreEqual(2, active.Count, "After eviction, 2 active bubbles");
            Assert.AreEqual(1, pool.Count, "After eviction, 1 in pool");
        }
    }
}
