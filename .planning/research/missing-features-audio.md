# Audio Processing Feature Gaps

## Current State

The WoofTalk app has a foundational audio processing pipeline built on AVFoundation:

**Implemented Components:**
- **AudioCapture**: Real-time microphone capture via AVAudioEngine with tap on input node (buffer size 5120 frames)
- **AudioEngine**: Core coordinator linking session management, playback, and speech recognition
- **AudioSessionManager**: Configures AVAudioSession with `.playAndRecord` category, `.allowBluetooth`, `.mixWithOthers` options, and `.measurement` mode
- **AudioPlayback**: AVAudioPlayerNode-based playback with play/stop/pause/resume and volume control
- **AudioEffectsProcessor**: Pitch shift, formant shift, vibrato, gain, compression, distortion, and dog vocalization effects using AVAudioUnit nodes
- **AudioSynthesis**: Tone generation (sine, square, sawtooth, triangle, noise), click tracks, silence, with reverb and EQ support
- **AudioFormats**: Standard format (44.1kHz mono) and speech recognition format (16kHz mono)
- **SpeechRecognition**: SFSpeechRecognizer integration (en_US only), with partial results support
- **AudioTranslationBridge**: Bridges audio capture to translation engine with basic audio-to-text conversion
- **DogVocalizationSynthesizer**: Emotion-based dog sound synthesis using AudioEffectsProcessor
- **BarkDetector** (WoofTalkAR only): CoreML-based bark detection with debouncing, NOT in main iOS app

**Key observation**: The main iOS app has NO advanced audio processing. The BarkDetector exists only in the AR module and is not integrated into the main app.

## Missing Features (Prioritized)

| # | Feature | Priority | Effort | Impact | Notes |
|---|---------|----------|--------|--------|-------|
| 1 | Bark detection (filter non-bark sounds) | **High** | Medium | High | Core to WoofTalk's purpose; BarkDetector exists in AR module but not main app |
| 2 | Noise cancellation for outdoor use | **High** | High | High | Critical for park/street usage; AVAudioEngine has no built-in noise cancellation |
| 3 | Wind noise reduction | **High** | High | Medium | Important for outdoor use with dogs |
| 4 | Automatic gain control for quiet barks | **Medium** | Low | High | Compressor exists in AudioEffectsProcessor but not applied to input |
| 5 | Audio quality indicators | **Medium** | Low | Medium | Simple level metering already possible via AVAudioEngine |
| 6 | Multiple audio input sources (Bluetooth/AirPods) | **Medium** | Medium | Medium | AVAudioSession supports this; needs UI for source selection |
| 7 | Echo cancellation | **Medium** | High | Medium | AVAudioEngine has limited echo cancellation; may need external lib |
| 8 | Audio compression for sharing | **Low** | Low | Medium | Use AVAssetExportSession or AVAudioConverter |
| 9 | Playback speed control | **Low** | Low | Low | AVAudioPlayerNode doesn't support rate; use AVAudioUnitTimePitch |
| 10 | Support for audio file import (MP3, WAV, M4A) | **Low** | Medium | Medium | Use AVAssetReader to extract PCM buffers |
| 11 | Waveform visualization | **Low** | Medium | Medium | Render waveform from PCM buffer data |
| 12 | Audio trimming/editing before translation | **Low** | Medium | Low | Requires waveform view + trim UI |
| 13 | Spectrogram visualization | **Low** | High | Low | Requires FFT analysis of audio buffer |
| 14 | Stereo/mono handling | **Low** | Low | Low | Currently hardcoded to mono in AudioFormats |
| 15 | Audio bookmarks | **Low** | Low | Low | Metadata-only feature, minimal audio code changes |

## Detailed Analysis

### 1. Bark Detection (Priority: High)
- **Status**: Partial - exists in WoofTalkAR/Services/BarkDetector.swift but NOT in main app
- **Implementation**: Uses CoreML model (DogBarkClassifier.mlmodel) with Vision framework
- **Gap**: Need to integrate into main iOS app's audio pipeline
- **Effort**: Medium - port the AR module's BarkDetector to main app

### 2. Noise Cancellation (Priority: High)
- **Status**: Not implemented
- **Options**:
  - AVAudioUnitEQ with aggressive high-pass/low-pass filtering
  - Core Audio `kAudioUnitSubType_VoiceProcessingIO` (built-in echo/noise cancellation)
  - Third-party: RNNoise (open source), WebRTC audio processing
- **Effort**: High - may require C/C++ integration for good results

### 3. Wind Noise Reduction (Priority: High)
- **Status**: Not implemented
- **Approach**: High-pass filter + spectral gating for wind frequencies (100-500Hz)
- **Can use**: AVAudioUnitEQ with custom filter bands

### 4. Automatic Gain Control (Priority: Medium)
- **Status**: Partially implemented
- **Existing**: AudioEffectsProcessor has `applyCompression` using AVAudioUnitCompressor
- **Gap**: Not applied to input/recording path - only used for output effects
- **Fix**: Apply compressor to input node in AudioCapture or AudioEngine

### 5. Audio Quality Indicators (Priority: Medium)
- **Status**: Not implemented
- **Simple approach**: Monitor average/rms power from audio buffers
- **AudioCaptureDelegate** already has `didUpdateAudioLevel` but it's not implemented
- **Can show**: Signal-to-noise ratio, clipping warnings, input level meter

### 6. Multiple Audio Input Sources (Priority: Medium)
- **Status**: Not implemented
- **Existing**: AudioSessionManager sets `.allowBluetooth` but no source selection UI
- **Available**: `AVAudioSession.currentRoute.inputs` for listing, `setPreferredInput` for selection
- **Needs**: UI to show/select between built-in mic, Bluetooth headset, AirPods, etc.

### 7. Echo Cancellation (Priority: Medium)
- **Status**: Not implemented
- **Option**: Use `kAudioUnitSubType_VoiceProcessingIO` instead of default input
- **This provides**: Built-in echo cancellation, noise reduction, automatic gain
- **Trade-off**: May affect audio quality for dog sounds

### 8-15. Lower Priority Features
- **Audio compression**: AVAssetExportSession with .m4a format
- **Playback speed**: AVAudioUnitTimePitch with `.rate` property
- **Audio file import**: AVAsset → AVAudioFile → AVAudioPCMBuffer conversion
- **Waveform**: Draw samples from buffer using CoreGraphics
- **Trimming**: Requires waveform view + AVAudioPCMBuffer slicing
- **Spectrogram**: FFT via Accelerate framework (vDSP)
- **Stereo/mono**: Make AudioFormats configurable
- **Bookmarks**: Save timestamp/position metadata

## Recommendations

### Top 3 Recommendations:

1. **Integrate BarkDetector into main app** (High impact, medium effort)
   - Port `WoofTalkAR/Services/BarkDetector.swift` to main WoofTalk target
   - Integrate into AudioCapture/AudioEngine pipeline
   - Filter non-bark audio before sending to translation
   - This directly improves translation accuracy by ignoring non-dog sounds

2. **Add Automatic Gain Control to input path** (High impact, low effort)
   - Apply AVAudioUnitCompressor to the input node in AudioCapture
   - Reuse existing `applyCompression` logic from AudioEffectsProcessor
   - Helps with quiet barks and inconsistent microphone levels

3. **Enable Voice Processing IO for echo cancellation + noise reduction** (High impact, medium effort)
   - Replace default AVAudioEngine input with `kAudioUnitSubType_VoiceProcessingIO`
   - This provides built-in echo cancellation, noise reduction, and some gain control
   - Test to ensure it doesn't degrade dog bark audio quality
   - Alternative: start with AVAudioUnitEQ high-pass filter for wind noise as a simpler first step

## Files to Modify (for top 3 recommendations)

1. **BarkDetector integration**:
   - Port: `WoofTalkAR/Services/BarkDetector.swift` → `WoofTalk/BarkDetector.swift`
   - Port: `WoofTalkAR/Services/AudioRecorder.swift` → `WoofTalk/AudioRecorder.swift`
   - Modify: `WoofTalk/AudioProcessing/AudioCapture.swift` to integrate detection
   - Add: DogBarkClassifier.mlmodel to main app bundle

2. **Automatic Gain Control**:
   - Modify: `WoofTalk/AudioProcessing/AudioCapture.swift` - attach compressor to input node
   - Or modify: `WoofTalk/AudioProcessing/AudioEngine.swift` to apply compression before translation

3. **Voice Processing / Noise Reduction**:
   - Modify: `WoofTalk/AudioProcessing/AudioSessionManager.swift` - configure Voice Processing IO
   - Or modify: `WoofTalk/AudioProcessing/AudioCapture.swift` - use voice processing input unit
   - Add: AVAudioUnitEQ in AudioEffectsProcessor for wind noise filtering

## Summary

The audio pipeline is functional but minimal. The highest-value additions are:
1. Bark detection (to filter non-dog sounds)
2. Input gain control (for quiet barks)
3. Basic noise/wind filtering (for outdoor use)

Lower priority: visualization features (waveform/spectrogram), file import, playback controls - these enhance user experience but aren't core to the translation functionality.
