# Pitfalls Research

**Domain:** M007 AR/VR — Mixed Reality Translation Features
**Researched:** 2026-04-03
**Confidence:** HIGH

## Critical Pitfalls (6)

### Pitfall 1: Dog Body Tracking Is Extremely Hard

**What goes wrong:**
AR/VR translation requires detecting where the dog is in 3D space to attach translation bubbles. But dog body tracking (pose estimation, skeletal tracking) is not solved by existing AR platforms. Vision Pro can detect human bodies via ARKit, but NOT dogs. Attempting to build custom dog detection/tracking with computer vision will be a multi-year research project.

**Why it happens:**
- ARKit/ARKit 支持人类身体追踪，但不支持动物
- 计算机视觉模型用于动物姿态估计 (如 Animal Pose) 需要大量标注数据集 (mscoco-animals 只有有限数量)
- 实时 3D 边界框检测 + sphere fitting 对于摇头摆尾的狗狗非常不稳定
- 训练自己的模型会变成 AI 研究项目，而非产品特性

**Prevention:**
1. **V1 anchoring strategy:** Anchor translation to **user's gaze direction** or **manual placement** (user points at dog)
2. **Simple proximity detection:** Use distance from user + audio direction (dog bark localization) to guess dog position
3. **Defer true dog tracking to M007.2 or later** - label as "advanced" feature
4. **VR approach:** In VR, dog can be represented as **avatar** with known position (simplified)

**Phase to address:** Phase 38 (AR Foundation) - define anchoring constraints clearly

---

### Pitfall 2: Vision Pro Market Share ~0.1% - Is It Worth It?

**What goes wrong:**
Building for Apple Vision Pro means targeting a device with tiny user base (<1M active users worldwide). The development cost (buying $3500 hardware, learning new platform, App Store optimization) may exceed expected ROI.

**Why it happens:**
- Vision Pro launched in 2024, still in early adopter phase
- Enterprise AR use cases are still emerging
- Most WoofTalk users are on iOS/Android phones, not headsets

**Prevention:**
1. **Pilot strategy:** Build AR as a premium showcase, not primary user flow
2. **Cross-platform AR fallback:** Use ARKit on iPhone/iPad (ARKit on devices without Vision Pro's spatial display)
3. **Marketing angle:** "Experience WoofTalk in mixed reality" - PR value may justify cost
4. **Future-proofing:** AR skill in house for when Apple releases cheaper glasses

**Phase to address:** Phase 38 - set clear scope: Vision Pro first, iPhone ARKit as stretch

---

### Pitfall 3: Dog Bark Detection Accuracy

**What goes wrong:**
Translating dog communication requires first detecting that a dog is barking/whining, then classifying emotion/intent. Off-the-shelf bark detectors have ~80-90% accuracy in quiet environments. Background noise (TV, other dogs, wind) reduces accuracy dramatically. False positives (cat meows, human coughs) will frustrate users.

**Why it happens:**
- Dog vocalizations are highly variable by breed, size, context
- Environmental noise is unpredictable
- On-device ML models need to be small (<10MB) → less accurate than cloud models

**Prevention:**
1. **User-controlled activation:** Manual "listen" button to reduce false positives
2. **Confidence threshold:** Only show translation when model confidence >85%
3. **User feedback loop:** "Was this accurate?" button to collect training data
4. **Fallback:** Allow manual text entry if voice detection fails
5. **Gradual rollout:** Beta test with WoofTalk power users first

**Phase to address:** Phase 39 (Audio Processing) - iterate on model training

---

### Pitfall 4: VR Hardware Fragmentation & Performance

**What goes wrong:**
Meta Quest 2, Quest 3, Quest Pro have different performance characteristics and capabilities. Hand tracking is available on newer models but not Quest 2. Building for "lowest common denominator" yields poor experience on Quest Pro; targeting high-end excludes Quest 2 users.

**Why it happens:**
- Quest 2: 72 Hz, no hand tracking (controllers only), 3GB RAM for app
- Quest 3: 90 Hz, hand tracking, color passthrough, more GPU
- Quest Pro: higher resolution, face/eye tracking
- Unity project settings need per-device configuration

**Prevention:**
1. **Target Quest 3 as baseline**, gracefully degrade on Quest 2 (lower texture quality, disable hand tracking)
2. **Runtime device detection:** Adjust settings based on detected model
3. **Performance budget:** Keep draw calls <200, polycount <100k for 90 FPS
4. **User-configurable graphics:** Settings menu for quality presets

**Phase to address:** Phase 40 (VR Implementation) - test on all target devices

---

### Pitfall 5: 3D UI Design Is Harder Than 2D

**What goes wrong:**
Designing readable text in 3D space is non-trivial. Text placed in world space can be too small, too far, occluded by objects, or rotated awkwardly. Users experience "spatial UI fatigue" if forced to constantly turn head to read.

**Why it happens:**
- Readable text requires: sufficient size (>1 degree visual angle), perpendicular orientation, good contrast against background
- In AR, text clipping (entering/exiting walls) is jarring
- In VR, text at infinity (billboarded) can cause eye strain

**Prevention:**
1. **Billboarding:** Text always faces user (but readable from any angle)
2. **Distance clamping:** Translation bubbles never closer than 1m or farther than 10m
3. **Occlusion culling:** Don't draw text if dog is behind wall (Raycast check)
4. **Opt-in explicit reading mode:** "Pin translation to HUD" for users who want always-visible overlay
5. **Test with users early:** Spatial UX needs empirical validation

**Phase to address:** Phase 38 (AR UI) and Phase 40 (VR UI) - iterative user testing

---

### Pitfall 6: Motion Sickness in VR

**What goes wrong:**
If user's vestibular sense (inner ear) detects motion but eyes see no motion (or vice versa), motion sickness occurs. This is especially problematic when:
- User is stationary but dog moves around them (can cause sensory conflict)
- Translating world during head movement (should be head-locked only)
- Low or unstable framerate

**Why it happens:**
- WoofTalk VR involves dogs moving around user in a room
- If translation bubbles are world-locked and user turns head quickly, visual motion without self-motion triggers nausea
- Frame drops break immersion → discomfort

**Prevention:**
1. **Head-locked UI:** Translation HUD attached to user's head orientation, not world space
2. **Smooth 90 FPS minimum:** Profile performance, reduce effects before dropping below 90
3. **Avoid artificial locomotion:** Let users physically move; don't use thumbstick movement
4. **Comfort mode toggle:** Simplify visuals, reduce animations for sensitive users
5. **Session length warnings:** "Take a break" after 20 minutes

**Phase to address:** Phase 40 (VR Implementation) - motion sickness testing mandatory

---

## Additional Risks (Lower Priority)

- **Battery drain:** AR/VR + audio processing drains Vision Pro/Quest battery quickly → limit session duration
- **Privacy concerns:** Camera passthough records environment → need clear privacy policy
- **App Store review:** Apple may reject AR apps that record without obvious consent
- **Seasickness with moving dogs:** If dog runs behind user, following with gaze may cause dizziness
- **3D model licensing:** If using pre-made dog avatars, ensure commercial license
