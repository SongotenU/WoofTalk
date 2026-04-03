using System;
using System.Threading.Tasks;
using UnityEngine;
using WoofTalk.VR.UI;
using WoofTalk.VR.Avatar;
using WoofTalk.VR.Audio;

namespace WoofTalk.VR.Bark
{
    /// <summary>
    /// Low-latency bark detector using OnAudioFilterRead for audio capture.
    /// Streams audio to the TFLite classifier and triggers events on detection.
    /// </summary>
    public class BarkDetector : MonoBehaviour
    {
        public event Action<float, string> BarkDetected;

        [SerializeField] private float confidenceThreshold = 0.7f;
        [SerializeField] private float debounceSeconds = 1.0f;
        [SerializeField] private BubbleManager bubbleManager;
        [SerializeField] private DogAvatarController dogAvatar;
        [SerializeField] private SpatialAudioManager spatialAudioManager;
        [SerializeField] private AudioClip barkDetectionSound;

        private BarkClassifier _classifier;
        private float[] _sampleBuffer = new float[1024];
        private int _sampleIndex = 0;
        private float _lastDetectionTime = 0f;
        private const int SampleRate = 48000;
        private const int InputSize = 1024;
        private AudioSource _audioSource;

        void Awake()
        {
            _audioSource = gameObject.AddComponent<AudioSource>();
            _audioSource.playOnAwake = false;
            _audioSource.loop = false;
        }

        async void Start()
        {
            // Load model asynchronously
            _classifier = await TFLiteModelLoader.LoadModelAsync();
            Debug.Log("[BarkDetector] Model loaded, detection active");
        }

        void OnAudioFilterRead(float[] data, int channels)
        {
            if (_classifier == null) return;

            // Downmix to mono by averaging channels
            int monoIndex = 0;
            for (int i = 0; i < data.Length && monoIndex < InputSize; i += channels)
            {
                float sum = 0f;
                for (int c = 0; c < channels; c++)
                {
                    sum += data[i + c];
                }
                _sampleBuffer[_sampleIndex] = sum / channels;
                _sampleIndex++;
                monoIndex++;
            }

            // When we have enough samples, classify
            if (_sampleIndex >= InputSize)
            {
                // Check debounce
                if (Time.time - _lastDetectionTime >= debounceSeconds)
                {
                    var (className, confidence) = _classifier.Classify(_sampleBuffer);

                    if (confidence >= confidenceThreshold && className != "silence")
                    {
                        _lastDetectionTime = Time.time;
                        StartCoroutine(OnBarkDetected(confidence, className));
                    }
                }

                _sampleIndex = 0;
            }
        }

        private System.Collections.IEnumerator OnBarkDetected(float confidence, string className)
        {
            Debug.Log($"[BarkDetector] Detected: {className} ({confidence:P0})");

            if (dogAvatar != null)
                dogAvatar.PlayBark();

            if (bubbleManager != null && dogAvatar != null)
                bubbleManager.ShowBubble($"Dog: {className} ({confidence:P0})", dogAvatar.transform);

            if (spatialAudioManager != null && barkDetectionSound != null)
            {
                Vector3 bubblePos = dogAvatar.transform.position + Vector3.up * 0.5f;
                spatialAudioManager.PlayAtPosition(barkDetectionSound, bubblePos);
            }

            yield return null;
        }

        void OnDestroy()
        {
            _classifier?.Dispose();
        }
    }
}
