using UnityEngine;

namespace WoofTalk.VR.Avatar
{
    /// <summary>
    /// Handles dog avatar customization including breed selection via material swapping
    /// and accessory toggling for collar, hat, and glasses.
    /// </summary>
    public class AvatarCustomization : MonoBehaviour
    {
        public enum BreedType
        {
            Golden = 0,
            Black = 1,
            Brown = 2,
            White = 3
        }

        public enum AccessoryType
        {
            Collar = 0,
            Hat = 1,
            Glasses = 2
        }

        [Header("Breed Materials")]
        [Tooltip("Array of 4 materials: Golden, Black, Brown, White")]
        [SerializeField] private Material[] breedMaterials;

        [Header("Accessories")]
        [Tooltip("Array of 3 accessory GameObjects: Collar, Hat, Glasses")]
        [SerializeField] private GameObject[] accessories;

        private SkinnedMeshRenderer _meshRenderer;
        private Material _defaultMaterial;

        void Awake()
        {
            _meshRenderer = GetComponentInChildren<SkinnedMeshRenderer>();
            if (_meshRenderer == null)
            {
                Debug.LogWarning("[AvatarCustomization] No SkinnedMeshRenderer found on avatar or children.");
            }
            else
            {
                _defaultMaterial = _meshRenderer.material;
            }

            if (breedMaterials == null || breedMaterials.Length < 4)
            {
                Debug.LogWarning("[AvatarCustomization] breedMaterials array should have at least 4 entries (Golden, Black, Brown, White).");
            }

            if (accessories == null || accessories.Length < 3)
            {
                Debug.LogWarning("[AvatarCustomization] accessories array should have at least 3 entries (Collar, Hat, Glasses).");
            }
        }

        /// <summary>
        /// Changes the dog avatar's breed by swapping the SkinnedMeshRenderer material.
        /// </summary>
        /// <param name="breed">The breed to apply.</param>
        public void SetBreed(BreedType breed)
        {
            if (_meshRenderer == null)
            {
                Debug.LogWarning("[AvatarCustomization] Cannot set breed: no SkinnedMeshRenderer available.");
                return;
            }

            int index = (int)breed;
            if (breedMaterials != null && index >= 0 && index < breedMaterials.Length && breedMaterials[index] != null)
            {
                _meshRenderer.material = breedMaterials[index];
                Debug.Log($"[AvatarCustomization] Breed set to: {breed}");
            }
            else
            {
                Debug.LogWarning($"[AvatarCustomization] Invalid breed material at index {index}.");
            }
        }

        /// <summary>
        /// Toggles visibility of a specific accessory by enabling/disabling its GameObject.
        /// </summary>
        /// <param name="accessory">The accessory type to toggle.</param>
        /// <param name="enabled">Whether the accessory should be visible.</param>
        public void SetAccessoryEnabled(AccessoryType accessory, bool enabled)
        {
            int index = (int)accessory;
            if (accessories != null && index >= 0 && index < accessories.Length && accessories[index] != null)
            {
                accessories[index].SetActive(enabled);
                Debug.Log($"[AvatarCustomization] Accessory '{accessory}' set to: {enabled}");
            }
            else
            {
                Debug.LogWarning($"[AvatarCustomization] Invalid accessory at index {index}.");
            }
        }

        /// <summary>
        /// Applies default configuration: Golden breed with all accessories disabled.
        /// </summary>
        public void ApplyDefaults()
        {
            SetBreed(BreedType.Golden);

            if (accessories != null)
            {
                for (int i = 0; i < accessories.Length; i++)
                {
                    if (accessories[i] != null)
                    {
                        accessories[i].SetActive(false);
                    }
                }
            }

            Debug.Log("[AvatarCustomization] Defaults applied: Golden breed, all accessories off.");
        }

        /// <summary>
        /// Get the current breed index (for external systems to query).
        /// </summary>
        public BreedType GetCurrentBreed()
        {
            if (_meshRenderer == null || breedMaterials == null)
                return BreedType.Golden;

            var currentMaterial = _meshRenderer.material;
            for (int i = 0; i < breedMaterials.Length; i++)
            {
                if (breedMaterials[i] == currentMaterial)
                    return (BreedType)i;
            }
            return BreedType.Golden;
        }

        /// <summary>
        /// Check whether a specific accessory is currently enabled.
        /// </summary>
        public bool IsAccessoryEnabled(AccessoryType accessory)
        {
            int index = (int)accessory;
            if (accessories != null && index >= 0 && index < accessories.Length && accessories[index] != null)
                return accessories[index].activeSelf;
            return false;
        }
    }
}
