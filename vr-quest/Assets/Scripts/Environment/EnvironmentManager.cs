using System;
using UnityEngine;

namespace WoofTalk.VR.Environment
{
    /// <summary>
    /// Central environment switching manager for VR scenes.
    /// Loads environments by name with event notification.
    /// Singleton pattern — only one instance should be active.
    /// </summary>
    public class EnvironmentManager : MonoBehaviour
    {
        public static EnvironmentManager Instance { get; private set; }

        public event Action<string> EnvironmentChanged;

        /// <summary>
        /// Names of supported environments.
        /// </summary>
        private static readonly string[] _supportedEnvironments = { "park", "livingroom", "beach" };

        /// <summary>
        /// Currently active environment name.
        /// </summary>
        public string CurrentEnvironment { get; private set; } = "park";

        /// <summary>
        /// Child transforms that represent each environment container.
        /// The child name must match the environment name (case-insensitive).
        /// </summary>
        [Tooltip("Child GameObject that holds all environment variants")]
        public Transform environmentRoot;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }

            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        private void Start()
        {
            // Load default environment on start
            LoadEnvironment(CurrentEnvironment);
        }

        /// <summary>
        /// Load the specified environment by name.
        /// Activates the matching child GameObject and deactivates all others.
        /// </summary>
        /// <param name="environmentName">Name of environment to load. Supported: park, livingroom, beach</param>
        public void LoadEnvironment(string environmentName)
        {
            if (string.IsNullOrEmpty(environmentName))
            {
                Debug.LogWarning("[EnvironmentManager] Empty environment name, using default 'park'");
                environmentName = "park";
            }

            string normalizedName = environmentName.ToLowerInvariant();

            if (Array.IndexOf(_supportedEnvironments, normalizedName) == -1)
            {
                Debug.LogWarning($"[EnvironmentManager] Unsupported environment '{environmentName}', falling back to 'park'");
                normalizedName = "park";
            }

            if (environmentRoot == null)
            {
                Debug.LogError("[EnvironmentManager] EnvironmentRoot is not assigned. Cannot load environment.");
                return;
            }

            // Deactivate all children, activate the matching one
            int childCount = environmentRoot.childCount;
            for (int i = 0; i < childCount; i++)
            {
                Transform child = environmentRoot.GetChild(i);
                bool isActive = child.name.Equals(normalizedName, StringComparison.OrdinalIgnoreCase);
                child.gameObject.SetActive(isActive);
            }

            CurrentEnvironment = normalizedName;
            Debug.Log($"[EnvironmentManager] Loaded {normalizedName}");

            EnvironmentChanged?.Invoke(normalizedName);
        }

        /// <summary>
        /// Returns the list of supported environment names.
        /// </summary>
        public string[] GetSupportedEnvironments()
        {
            return (string[])_supportedEnvironments.Clone();
        }
    }
}
