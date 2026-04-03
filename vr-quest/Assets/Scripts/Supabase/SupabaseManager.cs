using System;
using System.Threading.Tasks;
using UnityEngine;
using WoofTalk.VR.Analytics;

namespace WoofTalk.VR.SupabaseIntegration
{
    /// <summary>
    /// Singleton MonoBehaviour that manages the Supabase client lifecycle,
    /// authentication, and session caching for cross-platform integration.
    ///
    /// Provides anonymous auth by default with optional email/password sign-in.
    /// Session tokens are cached in PlayerPrefs to persist across VR sessions.
    ///
    /// Usage:
    ///   1. Add to a persistent GameObject in the scene.
    ///   2. Set supabaseUrl and anonKey in the inspector (or via config).
    ///   3. Call Initialize() on awake, then SignInAnonymously() if needed.
    /// </summary>
    public class SupabaseManager : MonoBehaviour
    {
        private static SupabaseManager _instance;

        /// <summary>Shared instance accessible from anywhere.</summary>
        public static SupabaseManager Instance
        {
            get
            {
                if (_instance == null)
                {
                    Debug.LogError("[SupabaseManager] No instance found. Add SupabaseManager to a GameObject in the scene.");
                }
                return _instance;
            }
        }

        [Header("Connection")]
        [SerializeField] private string supabaseUrl = "https://YOUR_PROJECT.supabase.co";

        // TODO: Use secure storage for production (Keychain / Keystore / encrypted PlayerPrefs)
        [SerializeField] private string anonKey = "YOUR_ANON_KEY";

        /// <summary>Whether the Supabase client has been initialized and is ready.</summary>
        public bool IsInitialized { get; private set; }

        /// <summary>Whether the current session is authenticated.</summary>
        public bool IsAuthenticated { get; private set; }

        /// <summary>Current authenticated user ID (null if not signed in).</summary>
        public string CurrentUserId { get; private set; }

        /// <summary>Event fired when authentication state changes.</summary>
        public event Action<SupabaseSession> AuthStateChanged;

        /// <summary>Last known Supabase session (public for analytics to read).</summary>
        public SupabaseSession CurrentSession { get; private set; }

        private const string SessionCacheKey = "Supabase_SessionToken";
        private const string UserIdCacheKey = "Supabase_UserId";

#if UNITY_EDITOR
        private const string PrefsPrefix = "WoofTalk_";
#else
        private const string PrefsPrefix = "WoofTalk_";
#endif

        void Awake()
        {
            if (_instance != null && _instance != this)
            {
                Debug.LogWarning("[SupabaseManager] Duplicate instance detected, destroying.");
                Destroy(gameObject);
                return;
            }

            _instance = this;
            DontDestroyOnLoad(gameObject);
        }

        /// <summary>
        /// Initialize the Supabase client. Loads cached session from PlayerPrefs
        /// and attempts to restore it. Call this before any Supabase operations.
        /// </summary>
        public async Task Initialize()
        {
            if (IsInitialized)
            {
                Debug.Log("[SupabaseManager] Already initialized, skipping.");
                return;
            }

            try
            {
                Debug.Log($"[SupabaseManager] Initializing Supabase client at {supabaseUrl}");

                // Note: In a real Unity + Supabase integration, use the official
                // supabase-unity SDK (com.supabase.unity) or the C# supabase client.
                // This implementation provides the interface contract that the SDK
                // would fulfill. The actual SDK initialization is deferred until
                // the package is integrated.

                IsInitialized = true;
                Debug.Log("[SupabaseManager] Supabase client initialized successfully.");

                // Attempt to restore cached session
                await TryRestoreSession();
            }
            catch (Exception ex)
            {
                Debug.LogError($"[SupabaseManager] Failed to initialize: {ex.Message}");
                IsInitialized = false;
            }
        }

        /// <summary>
        /// Create an anonymous session with Supabase. Useful for unregistered
        /// VR users who need to sync translations without a full account.
        /// Caches the session to PlayerPrefs for future restoration.
        /// </summary>
        public async Task SignInAnonymously()
        {
            if (!IsInitialized)
            {
                Debug.LogError("[SupabaseManager] Call Initialize() before SignInAnonymously()");
                return;
            }

            if (IsAuthenticated && CurrentUserId != null)
            {
                Debug.Log("[SupabaseManager] Already authenticated, skipping anonymous sign-in.");
                return;
            }

            try
            {
                Debug.Log("[SupabaseManager] Signing in anonymously...");

                // Note: Actual SDK call would be:
                //   var response = await Supabase.Gotrue.Client.SignInAnonymously();
                //   CurrentSession = new SupabaseSession(response.Session);

                // Simulated anonymous session for interface contract:
                // Generate a device-based anonymous ID
                string deviceId = GetOrCreateDeviceId();
                CurrentUserId = $"anon_{deviceId}";
                IsAuthenticated = true;

                CacheSession("anonymous_token", CurrentUserId);

                Debug.Log($"[SupabaseManager] Anonymous sign-in complete. User ID: {CurrentUserId}");
                AuthStateChanged?.Invoke(CurrentSession);
            }
            catch (Exception ex)
            {
                Debug.LogError($"[SupabaseManager] Anonymous sign-in failed: {ex.Message}");
                IsAuthenticated = false;
            }
        }

        /// <summary>
        /// Sign in with email and password for registered users.
        /// Caches session for future sessions.
        /// </summary>
        public async Task SignIn(string email, string password)
        {
            if (!IsInitialized)
            {
                Debug.LogError("[SupabaseManager] Call Initialize() before SignIn()");
                return;
            }

            try
            {
                Debug.Log($"[SupabaseManager] Signing in as {email}...");

                // Note: Actual SDK call would be:
                //   var response = await Supabase.Gotrue.Client.SignInWithEmailAndPassword(email, password);
                //   CurrentSession = new SupabaseSession(response.Session);

                IsAuthenticated = true;
                CacheSession("email_session_token", CurrentUserId ?? email);

                Debug.Log($"[SupabaseManager] Sign-in successful for {email}");
                AuthStateChanged?.Invoke(CurrentSession);
            }
            catch (Exception ex)
            {
                Debug.LogError($"[SupabaseManager] Sign-in failed: {ex.Message}");
                IsAuthenticated = false;
            }
        }

        /// <summary>
        /// Sign out and clear the cached session.
        /// </summary>
        public async Task SignOut()
        {
            Debug.Log("[SupabaseManager] Signing out...");

            IsAuthenticated = false;
            CurrentUserId = null;
            CurrentSession = null;

            ClearCachedSession();

            // Notify listeners (e.g., VRAnalytics should flush session summary)
            AuthStateChanged?.Invoke(null);

            Debug.Log("[SupabaseManager] Signed out successfully.");
        }

        /// <summary>
        /// Attempt to restore a previously cached session from PlayerPrefs.
        /// </summary>
        private async Task TryRestoreSession()
        {
            if (PlayerPrefs.HasKey($"{PrefsPrefix}{SessionCacheKey}"))
            {
                string cachedToken = PlayerPrefs.GetString($"{PrefsPrefix}{SessionCacheKey}");
                string cachedUserId = PlayerPrefs.GetString($"{PrefsPrefix}{UserIdCacheKey}", null);

                if (!string.IsNullOrEmpty(cachedToken))
                {
                    Debug.Log("[SupabaseManager] Restoring cached session from PlayerPrefs.");

                    // Note: Actual SDK would validate the token:
                    //   var session = await Supabase.Gotrue.Client.RefreshSession(cachedToken);

                    IsAuthenticated = true;
                    CurrentUserId = cachedUserId;

                    Debug.Log($"[SupabaseManager] Session restored. User: {CurrentUserId}");
                    AuthStateChanged?.Invoke(CurrentSession);
                    return;
                }
            }

            Debug.Log("[SupabaseManager] No cached session found.");
        }

        /// <summary>
        /// Cache session token and user ID to PlayerPrefs for persistence.
        /// </summary>
        private void CacheSession(string token, string userId)
        {
            PlayerPrefs.SetString($"{PrefsPrefix}{SessionCacheKey}", token);
            PlayerPrefs.SetString($"{PrefsPrefix}{UserIdCacheKey}", userId ?? "");
            PlayerPrefs.Save();

            Debug.Log("[SupabaseManager] Session cached to PlayerPrefs.");
        }

        /// <summary>
        /// Clear cached session from PlayerPrefs.
        /// </summary>
        private void ClearCachedSession()
        {
            PlayerPrefs.DeleteKey($"{PrefsPrefix}{SessionCacheKey}");
            PlayerPrefs.DeleteKey($"{PrefsPrefix}{UserIdCacheKey}");
            PlayerPrefs.Save();

            Debug.Log("[SupabaseManager] Cached session cleared.");
        }

        /// <summary>
        /// Retrieve or create a persistent device identifier for anonymous auth.
        /// Uses Unity's SystemInfo.deviceUniqueIdentifier as a base,
        /// but creates a cached UUID if that's not available.
        /// </summary>
        private string GetOrCreateDeviceId()
        {
            string deviceIdKey = $"{PrefsPrefix}DeviceId";

            if (PlayerPrefs.HasKey(deviceIdKey))
            {
                return PlayerPrefs.GetString(deviceIdKey);
            }

            string deviceId;
            try
            {
                deviceId = SystemInfo.deviceUniqueIdentifier;
                if (string.IsNullOrEmpty(deviceId) || deviceId == SystemInfo.unsupportedIdentifier)
                {
                    deviceId = Guid.NewGuid().ToString("N");
                }
            }
            catch
            {
                deviceId = System.Guid.NewGuid().ToString("N");
            }

            PlayerPrefs.SetString(deviceIdKey, deviceId);
            PlayerPrefs.Save();

            return deviceId;
        }
    }

    /// <summary>
    /// Lightweight representation of a Supabase session for cross-script communication.
    /// Wraps the session data needed by TranslationSync, SettingsSync, and VRAnalytics.
    /// </summary>
    public class SupabaseSession
    {
        public string AccessToken { get; set; }
        public string RefreshToken { get; set; }
        public string UserId { get; set; }
        public DateTime? ExpiresAt { get; set; }

        public bool IsValid
        {
            get
            {
                return !string.IsNullOrEmpty(AccessToken) &&
                       (!ExpiresAt.HasValue || ExpiresAt.Value > DateTime.UtcNow);
            }
        }

        public SupabaseSession() { }

        public SupabaseSession(string accessToken, string refreshToken, string userId, DateTime? expiresAt = null)
        {
            AccessToken = accessToken;
            RefreshToken = refreshToken;
            UserId = userId;
            ExpiresAt = expiresAt;
        }
    }
}
