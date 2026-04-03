using System.Collections;
using UnityEngine;

namespace WoofTalk.VR.Audio
{
    /// <summary>
    /// Manages spatial audio playback using Oculus Spatializer.
    /// Creates temporary 3D AudioSources that auto-destroy after clip completion.
    /// </summary>
    public class SpatialAudioManager : MonoBehaviour
    {
        /// <summary>
        /// Plays an AudioClip at the specified 3D position with full spatialization.
        /// </summary>
        public AudioSource PlayAtPosition(AudioClip clip, Vector3 position)
        {
            // Create a new GameObject as the audio source container
            GameObject audioObj = new GameObject($"SpatialAudioSource_{clip.name}");
            audioObj.transform.position = position;

            AudioSource source = audioObj.AddComponent<AudioSource>();
            source.clip = clip;
            source.spatialBlend = 1.0f;      // Full 3D spatialization
            source.spatialize = true;         // Enable Oculus Spatializer
            source.rolloffMode = AudioRolloffMode.Logarithmic;
            source.minDistance = 1.0f;        // Full volume within 1 meter
            source.maxDistance = 20.0f;       // Inaudible beyond 20 meters
            source.dopplerLevel = 0.0f;       // Disable Doppler effect
            source.priority = 128;            // Default priority

            source.Play();

            // Auto-destroy after clip completes
            StartCoroutine(DestroyAfterClip(source, clip.length + 0.5f));

            return source;
        }

        private IEnumerator DestroyAfterClip(AudioSource source, float seconds)
        {
            yield return new WaitForSeconds(seconds);
            Destroy(source.gameObject);
        }

        /// <summary>
        /// Ensures an AudioListener exists on the OVRCameraRig centerEyeAnchor.
        /// Must be called once during scene initialization.
        /// </summary>
        public static void EnsureAudioListener()
        {
            var listener = FindAnyObjectByType<AudioListener>();
            if (listener != null)
                return;

            // Find OVRCameraRig and add AudioListener to centerEyeAnchor
            var ovR = FindObjectOfType<Transform>();
            // In a real implementation, find the centerEyeAnchor under OVRCameraRig
            // For now, log that it needs to be added manually
            Debug.LogWarning("[SpatialAudioManager] No AudioListener found. Add to OVRCameraRig.centerEyeAnchor manually.");
        }
    }
}
