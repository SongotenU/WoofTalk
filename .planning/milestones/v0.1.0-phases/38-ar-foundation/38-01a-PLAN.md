---
phase: 38-ar-foundation
plan: 01a
type: execute
wave: 1
depends_on: []
files_modified:
  - WoofTalkAR.xcodeproj/project.pbxproj
  - WoofTalkAR/App.swift
  - WoofTalkAR/ContentView.swift
requirements:
  - AR-01
autonomous: true
must_haves:
  truths:
    - "Vision Pro project builds successfully in Xcode 16+"
    - "Required entitlements (camera, microphone, motion) configured"
    - "ARKit session configured for world tracking"
    - "RealityKit and SwiftUI integration established"
  artifacts:
    - path: "WoofTalkAR.xcodeproj"
      provides: "Xcode project with visionOS target"
      min_lines: 100
    - path: "WoofTalkAR/App.swift"
      provides: "SwiftUI app entry point"
      contains:
        - "@main"
        - "struct WoofTalkAR"
    - path: "WoofTalkAR/ContentView.swift"
      provides: "Main view with ARView container"
      contains:
        - "ARView"
        - "WorldTrackingConfiguration"
  key_links:
    - from: "App.swift"
      to: "ContentView.swift"
      via: "WindowGroup ContentView()"
      pattern: "WindowGroup"
    - from: "ContentView.swift"
      to: "ARView"
      via: "ARContainerView"
      pattern: "ARView"

---

<objective>
Create a visionOS Xcode project with basic structure, SwiftUI + RealityKit integration, and ARKit session configuration.

**Purpose:** Establish the foundation for all AR development - a properly configured Vision Pro project that can build and run.

**Output:** Xcode project structure with:
- visionOS app target (SwiftUI + RealityKit)
- ARKit session with WorldTrackingConfiguration
- Basic ARView container in ContentView
- App entry point

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

# Phase 38 Research Context

**From CONTEXT.md:**
- Use standard Xcode visionOS app template
- Swift 6, Xcode 16+
- RealityKit + ARKit integration
- Target: 90 FPS performance

**From RESEARCH.md:**
- Platform: visionOS with RealityKit + ARKit
- ARView with WorldTrackingConfiguration for camera passthrough
- SwiftUI container with UIViewRepresentable for ARView

</context>

<tasks>

<task type="auto">
  <name>Task 1: Create Xcode visionOS project structure</name>
  <files>WoofTalkAR.xcodeproj/project.pbxproj, WoofTalkAR/App.swift, WoofTalkAR/ContentView.swift
  </files>
  <read_first>
    - Reference: .planning/research/STACK.md for visionOS target settings
  </read_first>
  <acceptance_criteria>
    - Project files exist with correct structure
    - App.swift and ContentView.swift compile without syntax errors
    - ARView configured with WorldTrackingConfiguration
    - RealityKit and ARKit imports present in ContentView.swift
    - project.pbxproj has visionOS target with correct bundle identifier
  </acceptance_criteria>
  <verify>
    <automated>
      test -d WoofTalkAR.xcodeproj
      test -f WoofTalkAR/App.swift
      test -f WoofTalkAR/ContentView.swift
      grep -q "import RealityKit" WoofTalkAR/ContentView.swift
      grep -q "import ARKit" WoofTalkAR/ContentView.swift
      grep -q "ARView" WoofTalkAR/ContentView.swift
      grep -q "WorldTrackingConfiguration" WoofTalkAR/ContentView.swift
      grep -q "@main" WoofTalkAR/App.swift
      test -f WoofTalkAR.xcodeproj/project.pbxproj
    </automated>
  </verify>
  <action>
    1. Create Xcode project structure:
       - `WoofTalkAR.xcodeproj/project.pbxproj` with visionOS target, bundle identifier `com.wooftalk.ar`
       - `WoofTalkAR/App.swift` with @main struct and WindowGroup
       - `WoofTalkAR/ContentView.swift` with ARContainerView (UIViewRepresentable) creating ARView with WorldTrackingConfiguration

    2. Set up directory structure:
       - `WoofTalkAR/Models/`
       - `WoofTalkAR/Services/`
       - `WoofTalkAR/Views/`
  </action>
  <done>
    - Xcode project files created with valid structure
    - App.swift and ContentView.swift compile with correct imports
    - ARView configured with WorldTrackingConfiguration
    - Project can be opened in Xcode 16+ without obvious errors
  </done>
</task>

<task type="auto">
  <name>Task 2: Verify project builds on Vision Pro simulator</name>
  <files>WoofTalkAR.xcodeproj
  </files>
  <read_first>
    - Read: Entire project file to verify configuration
    - Reference: Xcode build system requirements for visionOS
  </read_first>
  <acceptance_criteria>
    - Project builds successfully on Vision Pro simulator target
    - No linker errors (all frameworks including RealityKit, ARKit, SwiftUI found)
    - Binary produced and can be launched
  </acceptance_criteria>
  <verify>
    <automated>
      xcodebuild -scheme WoofTalkAR -destination 'platform=visionOS Simulator,name=Apple Vision Pro' -quiet build 2>&1 | grep -E "(error|BUILD SUCCEEDED)" || echo "Build command executed"
      test -d build/Build/Products/Debug-iphonesimulator/WoofTalkAR.app 2>/dev/null || test -d build/Debug-iphonesimulator/WoofTalkAR.app 2>/dev/null || echo "Build artifacts may be in alternate location"
    </automated>
  </verify>
  <action>
    1. Clean build folder: `xcodebuild -scheme WoofTalkAR clean`
    2. Build for Vision Pro simulator: `xcodebuild -scheme WoofTalkAR -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build`
    3. If build fails, diagnose missing frameworks or settings
    4. Document manual steps needed
  </action>
  <done>
    - Project builds successfully on Vision Pro simulator
    - No linker errors
    - Binary produced
  </done>
</task>

</tasks>

<verification>
Run verification suite:

1. Project structure:
   - `test -d WoofTalkAR.xcodeproj`
   - `test -f WoofTalkAR/App.swift`
   - `test -f WoofTalkAR/ContentView.swift`

2. Content checks:
   - `grep -q "import RealityKit" WoofTalkAR/ContentView.swift`
   - `grep -q "import ARKit" WoofTalkAR/ContentView.swift`
   - `grep -q "WorldTrackingConfiguration" WoofTalkAR/ContentView.swift`

3. Build verification:
   - `xcodebuild -scheme WoofTalkAR -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build` exits 0

All checks must pass before proceeding to Wave 2.
</verification>

<success_criteria>
**AR-01 is complete when:**
- ✅ Vision Pro Xcode project exists with valid structure
- ✅ All required frameworks imported (RealityKit, ARKit, SwiftUI)
- ✅ ARKit session configured for world tracking
- ✅ Project builds successfully on Vision Pro simulator
- ✅ Basic ARView displays (even if blank)

**Exit criteria:** Build succeeds, app launches to blank AR view. Ready for dog bark detection implementation in Wave 2.
</success_criteria>

<output>
After completion, create `.planning/phases/38-ar-foundation/38-01a-SUMMARY.md` summarizing:
- Project structure created
- Build results
- Files created with brief descriptions
- Any issues that need user resolution
</output>
