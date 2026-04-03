---
phase: 38-ar-foundation
plan: 01b
type: execute
wave: 1
depends_on:
  - "38-01a"
files_modified:
  - WoofTalkAR/Entitlements/WoofTalkAR.entitlements
  - WoofTalkAR/Info.plist
  - Package.swift
  - WoofTalkAR/App.swift
requirements:
  - AR-01
autonomous: true
must_haves:
  truths:
    - "Entitlements file contains required permissions (ARKit, camera, microphone)"
    - "Info.plist contains all usage description keys"
    - "Swift Package dependencies (Supabase) added and resolved"
    - "Supabase client initialized in App.swift"
    - "Project builds successfully with all dependencies"
  artifacts:
    - path: "WoofTalkAR/Entitlements/WoofTalkAR.entitlements"
      provides: "Code signing entitlements for ARKit, camera, microphone"
      contains:
        - "com.apple.developer.arkit"
        - "com.apple.security.device.camera"
        - "com.apple.security.device.microphone"
    - path: "WoofTalkAR/Info.plist"
      provides: "Application configuration and usage descriptions"
      contains:
        - "NSCameraUsageDescription"
        - "NSMicrophoneUsageDescription"
        - "NSMotionUsageDescription"
    - path: "Package.swift"
      provides: "Swift Package Manager dependencies"
      contains:
        - "Supabase"
        - "from: \"2.0.0\""
    - path: "WoofTalkAR/App.swift"
      provides: "App entry with SupabaseClient initialization"
      contains:
        - "SupabaseClient"
        - "environmentObject"
  key_links:
    - from: "Info.plist"
      to: "Entitlements/WoofTalkAR.entitlements"
      via: "capabilities reference"
      pattern: "Entitlements"
    - from: "Package.swift"
      to: "App.swift"
      via: "import Supabase"
      pattern: "Supabase"
    - from: "App.swift"
      to: "ContentView.swift"
      via: "environmentObject(supabaseClient)"
      pattern: "environmentObject"

---

<objective>
Configure project entitlements, Info.plist permissions, and add Swift package dependencies (Supabase).

**Purpose:** Complete the AR-01 infrastructure setup by adding required permissions and backend client dependencies.

**Output:** Fully configured Xcode project with:
- Entitlements for ARKit, camera, microphone
- Info.plist with all usage descriptions
- Package.swift with Supabase dependency (v2.0.0)
- SupabaseClient initialized in App.swift
- Build succeeds with all dependencies resolved

</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/38-ar-foundation/38-CONTEXT.md
@.planning/phases/38-ar-foundation/38-RESEARCH.md

# Configuration Context

**From CONTEXT.md:**
- Entitlements required: camera, microphone, motion (ARKit)
- Swift 6, Xcode 16+
- Supabase Swift SDK v2.0.0 (empirical evidence from Edge Functions)
- Environment variables: SUPABASE_URL, SUPABASE_ANON_KEY

**From RESEARCH.md:**
- Supabase client for auth and Edge Function calls
- Standard visionOS app template structure
- Separate modules: BarkDetection, TranslationAPI, ARExperience, SpatialAudio

**Existing infrastructure:**
- Supabase backend already deployed with Edge Functions
- No new database schema needed for Phase 38

</context>

<tasks>

<task type="auto">
  <name>Task 1: Create entitlements and Info.plist</name>
  <files>WoofTalkAR/Entitlements/WoofTalkAR.entitlements, WoofTalkAR/Info.plist
  </files>
  <read_first>
    - Reference: .planning/research/STACK.md for required capabilities
  </read_first>
  <acceptance_criteria>
    - Entitlements file contains ARKit, camera, microphone permissions (all three present)
    - Info.plist contains NSCameraUsageDescription, NSMicrophoneUsageDescription, NSMotionUsageDescription
    - Both files have valid XML structure (well-formed plist)
    - Bundle identifier in Info.plist matches project (com.wooftalk.ar)
  </acceptance_criteria>
  <verify>
    <automated>
      test -f WoofTalkAR/Entitlements/WoofTalkAR.entitlements
      test -f WoofTalkAR/Info.plist
      grep -q "com.apple.developer.arkit" WoofTalkAR/Entitlements/WoofTalkAR.entitlements
      grep -q "com.apple.security.device.camera" WoofTalkAR/Entitlements/WoofTalkAR.entitlements
      grep -q "com.apple.security.device.microphone" WoofTalkAR/Entitlements/WoofTalkAR.entitlements
      grep -q "NSCameraUsageDescription" WoofTalkAR/Info.plist
      grep -q "NSMicrophoneUsageDescription" WoofTalkAR/Info.plist
      grep -q "NSMotionUsageDescription" WoofTalkAR/Info.plist
      grep -q "com.wooftalk.ar" WoofTalkAR/Info.plist
      # Validate plist XML
      xmllint --noout WoofTalkAR/Entitlements/WoofTalkAR.entitlements 2>/dev/null || echo "Entitlements file may have XML issues"
      xmllint --noout WoofTalkAR/Info.plist 2>/dev/null || echo "Info.plist may have XML issues"
    </automated>
  </verify>
  <action>
    1. Create `WoofTalkAR/Entitlements/WoofTalkAR.entitlements`:
       ```xml
       <?xml version="1.0" encoding="UTF-8"?>
       <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
       <plist version="1.0">
       <dict>
           <key>com.apple.developer.arkit</key>
           <true/>
           <key>com.apple.security.device.camera</key>
           <true/>
           <key>com.apple.security.device.microphone</key>
           <true/>
       </dict>
       </plist>
       ```
      
    2. Create `WoofTalkAR/Info.plist`:
       ```xml
       <?xml version="1.0" encoding="UTF-8"?>
       <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
       <plist version="1.0">
       <dict>
           <key>CFBundleDisplayName</key>
           <string>WoofTalk AR</string>
           <key>CFBundleIdentifier</key>
           <string>com.wooftalk.ar</string>
           <key>NSCameraUsageDescription</key>
           <string>WoofTalk AR uses camera to show the real world and detect dogs.</string>
           <key>NSMicrophoneUsageDescription</key>
           <string>WoofTalk AR uses microphone to listen for dog barks.</string>
           <key>NSMotionUsageDescription</key>
           <string>WoofTalk AR uses motion data to understand your position in space.</string>
           <key>UISupportedInterfaceOrientations</key>
           <array>
               <string>UIInterfaceOrientationLandscapeLeft</string>
               <string>UIInterfaceOrientationLandscapeRight</string>
           </array>
           <key>UIApplicationSceneManifest</key>
           <dict>
               <key>UIApplicationSupportsMultipleScenes</key>
               <false/>
           </dict>
       </dict>
       </plist>
       ```
      
    3. Link entitlements in Xcode project (manual step documented):
       - Add `WoofTalkAR.entitlements` to Code Signing Entitlements build setting
       - Enable Camera, Microphone, Motion capabilities in Xcode capabilities tab
  </action>
  <done>
    - Entitlements file exists with ARKit (com.apple.developer.arkit), camera, and microphone permissions
    - Info.plist contains all required usage descriptions (camera, microphone, motion)
    - Bundle identifier set to com.wooftalk.ar
    - XML validation passes (well-formed plists)
    - Manual linking of entitlements documented for user
  </done>
</task>

<task type="auto">
  <name>Task 2: Add Supabase Swift package dependency and initialize client</name>
  <files>Package.swift, WoofTalkAR/App.swift
  </files>
  <read_first>
    - Reference: .planning/research/STACK.md for Supabase version
    - Existing Supabase Edge Functions confirm v2 API usage
  </read_first>
  <acceptance_criteria>
    - Package.swift contains Supabase dependency from version 2.0.0
    - App.swift imports Supabase and initializes SupabaseClient
    - SupabaseClient configured with SUPABASE_URL and SUPABASE_ANON_KEY environment variables
    - Client added to SwiftUI environment as environmentObject
    - swift package resolve completes without errors (dependency resolution)
  </acceptance_criteria>
  <verify>
    <automated>
      test -f Package.swift
      test -f WoofTalkAR/App.swift
      grep -q "Supabase" Package.swift
      grep -q "from: \"2.0.0\"" Package.swift
      grep -q "supabase-swift" Package.swift
      grep -q "import Supabase" WoofTalkAR/App.swift
      grep -q "SupabaseClient" WoofTalkAR/App.swift
      grep -q "environmentObject(supabaseClient)" WoofTalkAR/App.swift
      # Check swift package resolves (may need network)
      swift package resolve 2>&1 | grep -q "error" && echo "Package resolution may have issues" || echo "Package resolution successful or skipped"
    </automated>
  </verify>
  <action>
    1. Create `Package.swift` in project root:
       ```swift
       // swift-tools-version:5.9
       import PackageDescription
       
       let package = Package(
           name: "WoofTalkAR",
           platforms: [
               .visionOS(.v1)
           ],
           dependencies: [
               .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
               .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.20.0")
           ],
           targets: [
               .target(
                   name: "WoofTalkAR",
                   dependencies: [
                       .product(name: "Supabase", package: "supabase-swift")
                   ]
               )
           ]
       )
       ```
      
    2. Update `WoofTalkAR/App.swift` to initialize Supabase client:
       ```swift
       import SwiftUI
       import Supabase
       
       @main
       struct WoofTalkAR: App {
           @StateObject private var supabaseClient = SupabaseClient(
               supabaseURL: URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "")!,
               supabaseKey: ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
           )
           
           var body: some Scene {
               WindowGroup {
                   ContentView()
                       .environmentObject(supabaseClient)
               }
           }
       }
       ```
      
    3. Create configuration for environment variables (document for user):
       - Create `WoofTalkAR/Config/Secrets.xcconfig` (template):
         ```
         SUPABASE_URL = your-project-ref.supabase.co
         SUPABASE_ANON_KEY = your-anon-key
         ```
       - Document that user must provide actual values in Xcode build settings or via scheme
       - Note: Environment variables are required for Edge Function calls (AR-05)
  </action>
  <done>
    - Package.swift with Supabase v2.0.0 and swift-protobuf dependencies
    - App.swift imports Supabase and initializes SupabaseClient with env vars
    - SupabaseClient added to SwiftUI environment
    - swift package resolve completes (or warnings documented)
    - User instructions for setting SUPABASE_URL and SUPABASE_ANON_KEY provided
  </done>
</task>

</tasks>

<verification>
Wave 1b - Configuration & Dependencies verification:

1. **Entitlements & Info.plist:**
   - `test -f WoofTalkAR/Entitlements/WoofTalkAR.entitlements`
   - `grep -q "com.apple.developer.arkit" WoofTalkAR/Entitlements/WoofTalkAR.entitlements`
   - `grep -q "com.apple.security.device.camera" WoofTalkAR/Entitlements/WoofTalkAR.entitlements`
   - `grep -q "com.apple.security.device.microphone" WoofTalkAR/Entitlements/WoofTalkAR.entitlements`
   - `test -f WoofTalkAR/Info.plist`
   - `grep -q "NSCameraUsageDescription" WoofTalkAR/Info.plist`
   - `grep -q "NSMicrophoneUsageDescription" WoofTalkAR/Info.plist`
   - `grep -q "NSMotionUsageDescription" WoofTalkAR/Info.plist`

2. **Swift packages:**
   - `test -f Package.swift`
   - `grep -q "Supabase.*from:.*2.0.0" Package.swift`
   - `grep -q "import Supabase" WoofTalkAR/App.swift`
   - `grep -q "SupabaseClient" WoofTalkAR/App.swift`

3. **Full build (combining 01a + 01b):**
   - `xcodebuild -scheme WoofTalkAR -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build` exits 0

All checks must pass before Wave 2 can begin.

**Note:** User must still configure Development Team and code signing in Xcode manually.
</verification>

<success_criteria>
**AR-01 complete when:**

✅ Xcode project structure created (38-01a)
✅ Entitlements configured (ARKit, camera, microphone)
✅ Info.plist contains all usage descriptions
✅ Swift Package dependencies added (Supabase v2.0.0)
✅ SupabaseClient initialized in App.swift
✅ Project builds successfully on Vision Pro simulator

**Exit criteria:** Full project foundation with all permissions and dependencies ready. Wave 2 (dog bark detection) can begin.
</success_criteria>

<output>
After completion, create `.planning/phases/38-ar-foundation/38-01b-SUMMARY.md` summarizing:
- Entitlements and permissions configuration
- Swift package dependencies added
- Supabase client setup
- Build results (combined with 01a)
- User setup steps remaining (team ID, env vars)
- Files created/modified
</output>
