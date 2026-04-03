using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace WoofTalk.VR.UI
{
    /// <summary>
    /// Manages a pool of translation bubbles with spawn, auto-dismiss, and FIFO eviction.
    /// Object pooling prevents GC spikes at 90 FPS by reusing GameObjects.
    /// </summary>
    public class BubbleManager : MonoBehaviour
    {
        [SerializeField] private GameObject bubblePrefab;
        [SerializeField] private int poolSize = 5;
        [SerializeField] private float autoDismissSeconds = 5f;

        private Queue<GameObject> _pool;
        private List<GameObject> _activeBubbles;
        private Transform _cameraTarget;

        public int PoolSize => poolSize;
        public int ActiveCount => _activeBubbles.Count;

        void Awake()
        {
            _pool = new Queue<GameObject>(poolSize);
            _activeBubbles = new List<GameObject>(poolSize);

            for (int i = 0; i < poolSize; i++)
            {
                GameObject bubble = Instantiate(bubblePrefab, transform);
                bubble.SetActive(false);
                _pool.Enqueue(bubble);
            }

            // Find the camera target from OVRCameraRig for billboard assignment
            var rig = FindAnyObjectByType<OVRCameraRig>();
            if (rig != null)
            {
                _cameraTarget = rig.centerEyeAnchor;
            }
        }

        public void ShowBubble(string text, Transform anchorPoint)
        {
            if (anchorPoint == null) return;

            Vector3 spawnPos = anchorPoint.position + new Vector3(0, 0.5f, 0);

            GameObject bubble = null;

            // If pool is empty, evict oldest active bubble (FIFO)
            if (_pool.Count == 0 && _activeBubbles.Count > 0)
            {
                GameObject oldest = _activeBubbles[0];
                EvictBubble(oldest);
            }

            if (_pool.Count > 0)
            {
                bubble = _pool.Dequeue();
            }

            if (bubble == null) return;

            bubble.transform.position = spawnPos;
            bubble.SetActive(true);

            // Set text content
            TranslationBubble bubbleComp = bubble.GetComponent<TranslationBubble>();
            if (bubbleComp != null)
            {
                bubbleComp.SetText(text);
                bubbleComp.poolReturn += () => ReturnToPool(bubble);
            }

            // Assign billboard camera target
            BillboardVR billboard = bubble.GetComponent<BillboardVR>();
            if (billboard != null && _cameraTarget != null)
            {
                billboard.SetCameraTarget(_cameraTarget);
            }

            // Start auto-dismiss coroutine
            StartCoroutine(DismissAfter(bubble, autoDismissSeconds));

            _activeBubbles.Add(bubble);
        }

        private IEnumerator DismissAfter(GameObject bubble, float seconds)
        {
            yield return new WaitForSeconds(seconds);
            ReturnToPool(bubble);
        }

        private void ReturnToPool(GameObject bubble)
        {
            if (!_activeBubbles.Contains(bubble)) return;

            bubble.SetActive(false);
            _activeBubbles.Remove(bubble);

            // Remove poolReturn listener for this instance
            TranslationBubble bubbleComp = bubble.GetComponent<TranslationBubble>();
            if (bubbleComp != null)
            {
                bubbleComp.poolReturn = null;
            }

            _pool.Enqueue(bubble);
        }

        private void EvictBubble(GameObject bubble)
        {
            if (bubble == null) return;

            bubble.SetActive(false);
            _activeBubbles.Remove(bubble);
            _pool.Enqueue(bubble);
        }
    }
}
