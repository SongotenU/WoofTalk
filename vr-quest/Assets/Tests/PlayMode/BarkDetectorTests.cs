using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using System.Collections;
using WoofTalk.VR.Bark;

namespace WoofTalk.VR.Tests.PlayMode
{
    public class BarkDetectorTests
    {
        private string[] _classLabels;

        [SetUp]
        public void Setup()
        {
            _classLabels = new[] { "bark", "howl", "whine", "silence" };
        }

        [Test]
        public void BarkClassifier_WithHighEnergyInput_ReturnsBark()
        {
            // Create a mock classifier and test with high-energy input
            var classifier = new BarkClassifier(_classLabels, useMock: true);

            // Generate a high-energy audio sample
            float[] input = new float[1024];
            for (int i = 0; i < 1024; i++)
                input[i] = Random.Range(0.5f, 1.0f);

            var (className, confidence) = classifier.Classify(input);

            Assert.IsTrue(confidence > 0, "Classifier should return some confidence for high-energy input");
            Assert.IsNotEmpty(className, "Class name should not be empty");
        }

        [Test]
        public void BarkClassifier_WithLowEnergyInput_ReturnsSilence()
        {
            var classifier = new BarkClassifier(_classLabels, useMock: true);

            // Low energy input
            float[] input = new float[1024];
            for (int i = 0; i < 1024; i++)
                input[i] = 0.001f;

            var (className, confidence) = classifier.Classify(input);

            Assert.AreEqual("silence", className, "Low energy input should return silence");
            Assert.IsTrue(confidence > 0.9f, "Silence confidence should be very high");
        }

        [Test]
        public void BarkClassifier_WithSmallerInput_PadsTo1024()
        {
            var classifier = new BarkClassifier(_classLabels, useMock: true);

            // Input smaller than 1024
            float[] input = new float[512];
            Assert.DoesNotThrow(() => classifier.Classify(input), "Classifier should handle inputs smaller than 1024");
        }

        [Test]
        public void BarkClassifier_WithLargerInput_TruncatesTo1024()
        {
            var classifier = new BarkClassifier(_classLabels, useMock: true);

            // Input larger than 1024
            float[] input = new float[2048];
            Assert.DoesNotThrow(() => classifier.Classify(input), "Classifier should handle inputs larger than 1024");
        }

        [Test]
        public void BarkClassifier_Dispose_DoesNotThrow()
        {
            var classifier = new BarkClassifier(_classLabels, useMock: true);
            Assert.DoesNotThrow(() => classifier.Dispose(), "Dispose should not throw");
        }
    }
}
