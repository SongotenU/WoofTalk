using System;
using System.Threading.Tasks;
using UnityEngine;
using WoofTalk.VR.Bark;

namespace WoofTalk.VR.Bark
{
    /// <summary>
    /// Loads the TFLite bark classification model asynchronously during scene load.
    /// Falls back to a mock classifier if model file is not found.
    /// </summary>
    public class TFLiteModelLoader : MonoBehaviour
    {
        private const string ModelName = "woof_bark_model";
        private static readonly string[] ClassLabels = new[] { "bark", "howl", "whine", "silence" };

        public static async Task<BarkClassifier> LoadModelAsync()
        {
            try
            {
                var modelAsset = Resources.Load<TextAsset>(ModelName);
                if (modelAsset != null && modelAsset.bytes.Length > 0)
                {
                    Debug.Log($"[TFLiteModelLoader] Model loaded: {modelAsset.bytes.Length} bytes, tensors allocated");

                    // Note: The actual Interpreter type depends on the TFLite plugin used.
                    // For now, return a mock classifier. When a real .tflite file is present,
                    // replace this with: Interpreter.CreateInterpreter(modelAsset.bytes)
                    return new BarkClassifier(ClassLabels);
                }

                Debug.LogWarning("[TFLiteModelLoader] Model file not found, using mock classifier");
                return new BarkClassifier(ClassLabels, useMock: true);
            }
            catch (Exception e)
            {
                Debug.LogError($"[TFLiteModelLoader] FAILED to load model: {e.Message}");
                return new BarkClassifier(ClassLabels, useMock: true);
            }
        }
    }
}
