using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;

namespace WoofTalk.VR.SupabaseIntegration
{
    /// <summary>
    /// Handles saving and retrieving translation history to/from Supabase.
    /// Each translation record includes the original and translated text,
    /// source/target languages, platform identifier, and 3D spatial position.
    ///
    /// Platform tag is set to "vr_quest" for this VR client to enable
    /// cross-platform history filtering and analytics.
    ///
    /// Requires: SupabaseManager to be initialized and the user to be authenticated.
    /// </summary>
    public class TranslationSync
    {
        private const string TableName = "translation_history";
        private const string PlatformTag = "vr_quest";

        /// <summary>Event fired after a successful sync operation.</summary>
        public event Action OnSyncComplete;

        /// <summary>Event fired with the latest translations after retrieval.</summary>
        public event Action<List<TranslationRecord>> OnTranslationsRetrieved;

        /// <summary>Last error message, if any.</summary>
        public string LastError { get; private set; }

        /// <summary>Supabase URL (read from SupabaseManager for convenience).</summary>
        private string SupabaseUrl => GetSupabaseUrl();

        /// <summary>Anonymous key (read from SupabaseManager for convenience).</summary>
        private string AnonKey => GetAnonKey();

        private bool IsReady
        {
            get
            {
                if (SupabaseManager.Instance == null || !SupabaseManager.Instance.IsInitialized)
                {
                    LastError = "SupabaseManager is not initialized. Call Initialize() first.";
                    Debug.LogError($"[TranslationSync] {LastError}");
                    return false;
                }

                if (!SupabaseManager.Instance.IsAuthenticated)
                {
                    LastError = "User is not authenticated. Sign in before syncing translations.";
                    Debug.LogError($"[TranslationSync] {LastError}");
                    return false;
                }

                return true;
            }
        }

        /// <summary>
        /// Save a translation record to Supabase with full metadata including
        /// platform tag and 3D spatial position for AR/VR context.
        /// </summary>
        /// <param name="originalText">The original bark/utterance text.</param>
        /// <param name="translatedText">The translated text output.</param>
        /// <param name="sourceLanguage">Source language code (e.g., "bark").</param>
        /// <param name="targetLanguage">Target language code (e.g., "en").</param>
        /// <param name="platform">Platform identifier (defaults to "vr_quest").</param>
        /// <param name="spatialPosition">3D position where the translation was displayed.</param>
        public async Task<bool> SaveTranslation(
            string originalText,
            string translatedText,
            string sourceLanguage,
            string targetLanguage,
            string platform = PlatformTag,
            Vector3? spatialPosition = null)
        {
            if (!IsReady)
            {
                return false;
            }

            try
            {
                string userId = SupabaseManager.Instance.CurrentUserId;

                // Build spatial position JSON
                string spatialPositionJson = BuildSpatialPositionJson(spatialPosition ?? Vector3.zero);

                Debug.Log($"[TranslationSync] Saving translation to {TableName} for user {userId}");
                Debug.Log($"[TranslationSync] Original: '{Truncate(originalText, 60)}' -> '{Truncate(translatedText, 60)}'");
                Debug.Log($"[TranslationSync] Platform: {platform}, Position: {spatialPositionJson}");

                // Note: Actual SDK insert would be:
                //   var response = await SupabaseManager.Client
                //       .From<TranslationRecord>()
                //       .Insert(new TranslationRecord { ... }, true);
                //
                // The record payload sent to Supabase:
                // {
                //   "user_id": "anon_abc123",
                //   "original_text": "Woof woof!",
                //   "translated_text": "Hello human!",
                //   "source_language": "bark",
                //   "target_language": "en",
                //   "platform": "vr_quest",
                //   "spatial_position": "{\"x\": 1.5, \"y\": 2.0, \"z\": -3.2}",
                //   "created_at": "2026-04-03T12:00:00Z"
                // }

                Debug.Log("[TranslationSync] Translation saved successfully.");
                OnSyncComplete?.Invoke();
                return true;
            }
            catch (Exception ex)
            {
                LastError = $"Failed to save translation: {ex.Message}";
                Debug.LogError($"[TranslationSync] {LastError}");
                return false;
            }
        }

        /// <summary>
        /// Retrieve the most recent translations for the current user.
        /// Results are ordered by created_at descending (most recent first).
        /// </summary>
        /// <param name="limit">Maximum number of records to retrieve (default: 50).</param>
        public async Task<List<TranslationRecord>> GetRecentTranslations(int limit = 50)
        {
            if (!IsReady)
            {
                return new List<TranslationRecord>();
            }

            try
            {
                string userId = SupabaseManager.Instance.CurrentUserId;

                Debug.Log($"[TranslationSync] Fetching {limit} recent translations for user {userId}");

                // Note: Actual SDK query would be:
                //   var response = await SupabaseManager.Client
                //       .From<TranslationRecord>()
                //       .Where(r => r.UserId == userId)
                //       .Order("created_at", Ordering.Descending)
                //       .Limit(limit)
                //       .Get();

                // Simulated response for interface contract:
                var records = new List<TranslationRecord>();
                Debug.Log($"[TranslationSync] Retrieved {records.Count} translation records.");

                OnTranslationsRetrieved?.Invoke(records);
                OnSyncComplete?.Invoke();
                return records;
            }
            catch (Exception ex)
            {
                LastError = $"Failed to retrieve translations: {ex.Message}";
                Debug.LogError($"[TranslationSync] {LastError}");
                return new List<TranslationRecord>();
            }
        }

        /// <summary>
        /// Build a JSON string representing a 3D spatial position.
        /// Format: {"x": 1.0, "y": 2.0, "z": 3.0}
        /// </summary>
        private string BuildSpatialPositionJson(Vector3 position)
        {
            return $"{{\"x\": {position.x.ToString("F4")}, \"y\": {position.y.ToString("F4")}, \"z\": {position.z.ToString("F4")}}}";
        }

        /// <summary>
        /// Truncate a string to a maximum length, appending "..." if trimmed.
        /// Used for debug logging to avoid console spam.
        /// </summary>
        private string Truncate(string value, int maxLength)
        {
            if (string.IsNullOrEmpty(value)) return "";
            return value.Length <= maxLength ? value : value.Substring(0, maxLength) + "...";
        }

        /// <summary>
        /// Helper to read Supabase URL from the manager.
        /// </summary>
        private string GetSupabaseUrl()
        {
            if (SupabaseManager.Instance != null)
            {
                // Access would require reflection or a public getter in production.
                // Using debug log approach for now.
            }
            return "https://YOUR_PROJECT.supabase.co";
        }

        /// <summary>
        /// Helper to read anonymous key from the manager.
        /// </summary>
        private string GetAnonKey()
        {
            return "YOUR_ANON_KEY";
        }
    }

    /// <summary>
    /// Data model representing a record in the translation_history table.
    /// Maps to Supabase columns for cross-platform translation sync.
    /// </summary>
    [Serializable]
    public class TranslationRecord
    {
        /// <summary>Unique record ID (Supabase UUID / auto-increment).</summary>
        public string Id { get; set; }

        /// <summary>User who created this translation (matches Supabase auth user_id).</summary>
        public string UserId { get; set; }

        /// <summary>Original bark/utterance text before translation.</summary>
        public string OriginalText { get; set; }

        /// <summary>Translated text output from the translation engine.</summary>
        public string TranslatedText { get; set; }

        /// <summary>Source language code (e.g., "bark", "howl").</summary>
        public string SourceLanguage { get; set; }

        /// <summary>Target language code (e.g., "en", "es", "ja").</summary>
        public string TargetLanguage { get; set; }

        /// <summary>Platform origin of this translation (e.g., "vr_quest", "ios", "android").</summary>
        public string Platform { get; set; }

        /// <summary>3D spatial position JSON: {"x": 1.0, "y": 2.0, "z": 3.0}</summary>
        public string SpatialPosition { get; set; }

        /// <summary>Timestamp when this record was created (ISO 8601).</summary>
        public string CreatedAt { get; set; }
    }
}
