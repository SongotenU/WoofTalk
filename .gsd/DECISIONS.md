# Decisions Register

<!-- Append-only. Never edit or remove existing rows.
     To reverse a decision, add a new row that supersedes it.
     Read this file at the start of any planning or research phase. -->

| # | When | Scope | Decision | Choice | Rationale | Revisable? |
|---|------|-------|----------|--------|-----------|------------|
| D001 | M001/S01 | platform | Development platform | Native iOS with Swift | User confirmed preference for native performance | No |
| D002 | M001/S01 | architecture | Translation approach | Real-time speech-to-speech | Core value proposition requires real-time capability | No |
| D003 | M001/S01 | data | Data source strategy | Hybrid API + user contributions | User confirmed need for both API integration and community input | No |
| D004 | M001/S01 | business | Monetization model | Monthly/annual subscription | User confirmed preference for recurring revenue | No |
| D005 | M001/S01 | scope | Launch strategy | Feature-complete launch | User confirmed desire to launch with all planned features | No |
| D006 | M001/S02 | architecture | Offline capability | Core vocabulary works offline | Requirement R003 mandates offline functionality | No |
| D007 | M001/S03 | ui | UI framework | UIKit (likely) | Native iOS performance requirements | Yes — if SwiftUI proves viable |
| D008 | M001/S04 | storage | Offline storage | SQLite for caching | Efficient storage of translation models and phrases | Yes — if file-based proves better |
| D010 | M001/S01 | audio | Audio processing framework | AVFoundation + Speech Framework | Native iOS performance and low-latency requirements | No |
| D011 | M001/S01 | audio | Buffer size for latency | 5ms buffer size | Targets <100ms capture-to-processing latency | No |
| D012 | M001/S01 | audio | Speech recognition approach | iOS Speech Framework for human voice | Native integration and reliability | No |
| D013 | M001/S01 | audio | Audio format standard | 44.1 kHz, 16-bit PCM | Industry standard for audio processing | No |
| D014 | M001/S01 | audio | Error handling strategy | Comprehensive error handling with graceful degradation | Critical for user experience and reliability | No |
| D015 | M001/S01 | audio | Audio synthesis capabilities | Full synthesis with tones, speech, effects | Valuable for testing and user feedback | No |
| D009 | M001/S05 | deployment | App Store compliance | Full compliance with guidelines | Essential for App Store approval | No |