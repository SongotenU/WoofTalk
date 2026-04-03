using System;
using System.Linq;
using UnityEngine;

namespace WoofTalk.VR.Bark
{
    /// <summary>
    /// Bark classification wrapper for TFLite model inference.
    /// Returns class name and confidence from audio buffer.
    /// Uses mock fallback when model is not available.
    /// </summary>
    public class BarkClassifier : IDisposable
    {
        private readonly string[] _classLabels;
        private readonly bool _useMock;

        /// <summary>
        /// Creates a classifier instance.
        /// </summary>
        /// <param name="classLabels">Class names for model output mapping</param>
        /// <param name="useMock">If true, returns mock outputs for testing</param>
        public BarkClassifier(string[] classLabels, bool useMock = false)
        {
            _classLabels = classLabels;
            _useMock = useMock;
        }

        /// <summary>
        /// Classifies 1024 audio samples into bark/howl/whine/silence categories.
        /// </summary>
        /// <param name="audioSamples">Audio samples (expected 1024 float values)</param>
        /// <returns>Tuple of (className, confidence)</returns>
        public (string className, float confidence) Classify(float[] audioSamples)
        {
            // Pad or truncate to 1024 samples
            float[] input = new float[1024];
            int copyLen = Mathf.Min(audioSamples.Length, 1024);
            Array.Copy(audioSamples, input, copyLen);

            if (_useMock)
            {
                // Mock classifier: returns silence unless audio has significant amplitude
                float rms = 0f;
                foreach (var s in input)
                    rms += s * s;
                rms = Mathf.Sqrt(rms / 1024f);

                if (rms > 0.01f)
                    return ("bark", Mathf.Min(0.9f, rms * 2f));
                return ("silence", 1f - rms);
            }

            // TODO: When actual TFLite plugin is installed:
            // _interpreter.GetInputTensor().CopyFromData(input);
            // _interpreter.Invoke();
            // float[] output = _interpreter.GetOutputTensor().CopyToFloatArray();

            // For now, use simple energy-based heuristic
            float energy = 0f;
            foreach (var s in input)
                energy += s * s;
            energy = Mathf.Sqrt(energy / 1024f);

            float[] output = new float[_classLabels.Length];
            // Heuristic: more energy = more likely bark/howl

            float silenceConfidence = Mathf.Max(0f, 1f - energy * 5f);
            float barkConfidence = Mathf.Clamp01(energy * 3f);
            float howlConfidence = Mathf.Clamp01(energy * 1.5f);
            float whineConfidence = Mathf.Clamp01(energy * 1f);

            output[0] = barkConfidence;   // bark
            output[1] = howlConfidence;   // howl
            output[2] = whineConfidence;  // whine
            output[3] = silenceConfidence; // silence

            int maxIdx = System.Array.IndexOf(output, output.Max());
            return (_classLabels[maxIdx], output[maxIdx]);
        }

        public void Dispose()
        {
            // Cleanup interpreter if real TFLite is implemented
        }
    }
}
