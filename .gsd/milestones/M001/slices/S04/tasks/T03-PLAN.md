---
estimated_steps: 6
estimated_files: 4
---

# T03: Integration with Translation Engine

**Slice:** S04 — Offline Mode
**Milestone:** M001

## Description

Wire the offline functionality into the existing translation engine and UI components. This task modifies the translation flow to use cached translations when offline and adds visual indicators for connectivity status.

## Steps

1. Modify translation_engine.ts to use offline_manager for translation lookups
2. Add connectivity status to translation results and error handling
3. Update UI components to show online/offline status
4. Implement graceful degradation for features unavailable offline
5. Add performance monitoring for offline vs online translation times
6. Test integration with real translation data and network conditions

## Must-Haves

- Translation engine uses offline cache when network is unavailable
- No regression in online translation performance
- Users can distinguish between online and offline states
- Features unavailable offline are clearly disabled or hidden
- Error handling is graceful for all offline scenarios

## Verification

- Translation works identically online and offline for cached phrases
- Online performance is not impacted by offline code
- UI correctly shows connectivity status
- Missing phrases in offline mode provide appropriate fallback
- No crashes or errors when switching between online/offline

## Observability Impact

- Signals added: Translation source (online/offline), fallback usage, performance metrics
- How a future agent inspects this: Debug logs, performance monitoring, UI state inspection
- Failure state exposed: Translation failures, connectivity issues, cache problems

## Inputs

- Offline manager implementation from T02
- Translation engine from S02
- UI components from S03
- Performance requirements from S01

## Expected Output

- Modified translation_engine.ts with offline support
- Updated UI components with connectivity indicators
- Integration tests for online/offline scenarios
- Performance benchmarks for offline functionality