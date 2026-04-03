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
@.planning/research/SUMMARY.md

**From CONTEXT.md:**
- Entitlements required: camera, microphone, motion (ARKit)
- Swift 6, Xcode 16+
- Supabase Swift SDK v2.0.0 (empirical evidence from Edge Functions)
- Environment variables: SUPABASE_URL, SUPABASE_ANON_KEY

**From RESEARCH.md:**
- Supabase client for auth and Edge Function calls
- Standard visionOS app template structure

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
    - Both files have valid XML structure
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
    </automated>
  </verify>
  <action>
    1. Create `WoofTalkAR/Entitlements/WoofTalkAR.entitlements` with ARKit, camera, microphone permissions
    2. Create `WoofTalkAR/Info.plist` with usage descriptions and bundle identifier
    3. Link entitlements in Xcode project (document manual step)
  </action>
  <done>
    - Entitlements file exists with required permissions
    - Info.plist contains all usage descriptions
    - XML structure valid
  </done>
</task>

<task type="auto">
  <name>Task 2: Add Supabase Swift package dependency and initialize client</name>
  <files>Package.swift, WoofTalkAR/App.swift
  </files>
  <read_first>
    - Reference: .planning/research/STACK.md for Supabase version
    - Existing Supabase Edge Functions confirm v2 API
  </read_first>
  <acceptance_criteria>
    - Package.swift contains Supabase dependency from version 2.0.0
    - App.swift imports Supabase and initializes SupabaseClient
    - SupabaseClient configured with SUPABASE_URL and SUPABASE_ANON_KEY environment variables
    - Client added to SwiftUI environment as environmentObject
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
    </automated>
  </verify>
  <action>
    1. Create `Package.swift` with supabase-swift v2.0.0 and swift-protobuf v1.20.0
    2. Update `WoofTalkAR/App.swift` to import Supabase and initialize SupabaseClient with env vars
    3. Create `WoofTalkAR/Config/Secrets.xcconfig` template for environment variables
    4. Document user steps to provide actual Supabase credentials
  </action>
  <done>
    - Package.swift with dependencies
    - App.swift with SupabaseClient and environmentObject
    - Configuration template created
  </done>
</task>

</tasks>

<verification>
Wave 1b - Configuration & Dependencies verification:

1. File existence
2. Entitlements permissions
3. Info.plist usage descriptions
4. Package.swift dependencies
5. App.swift Supabase configuration
6. XML validation

All checks must pass before proceeding to Wave 2.
</verification>

<success_criteria>
**AR-01 is complete when:**
- ✅ Vision Pro Xcode project exists with valid structure
- ✅ All required entitlements configured (ARKit, camera, microphone, motion)
- ✅ Info.plist contains all usage description keys
- ✅ Swift packages (Supabase) added and resolved
- ✅ Project builds successfully on Vision Pro simulator
- ✅ ARView with WorldTrackingConfiguration displays onscreen

**Exit criteria:** Build succeeds, app launches to blank AR view (black screen acceptable if simulation limitations). Ready for dog bark detection implementation in Wave 2.
</success_criteria>

<output>
After completion, create `.planning/phases/38-ar-foundation/38-01b-SUMMARY.md` summarizing:
- Project structure created
- Entitlements configured
- Dependencies added
- Build results
- Files created/modified with brief descriptions
- Any issues that need user resolution (team ID, signing)
</output>
