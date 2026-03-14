# Requirements Register

## Active

| ID | Title | Class | Status | Description | Why | Source | Primary Owner | Supporting | Validation | Notes |
|----|-------|-------|--------|-------------|-----|--------|---------------|------------|------------|-------|
| R002 | Comprehensive Vocabulary | Core | Active | Extensive dog-human vocabulary with contextual understanding | Enables meaningful communication | user | M002/S01 (to be re-scoped) | M001/S02, M002/S01 | Vocabulary expansion needed | 5000+ phrases minimum; 100+ implemented in M001 |
| R004 | User Contribution System | Growth | Active | Users can submit translations and corrections | Improves model accuracy over time | user | M002/S01 | M002/S02, M003/S01 | Contribution workflow testing | Quality control needed |
| R005 | Community Features | Growth | Active | Sharing translations, following users, leaderboards | Engagement and retention | user | M002/S02 | M002/S01, M002/S03 | Social features testing | Privacy considerations |
| R006 | Advanced AI Models | Core | Active | Enhanced translation accuracy with deep learning | Competitive advantage | user | M003/S01 | M003/S02, M003/S03 | Model accuracy testing | Requires significant compute |
| R007 | Analytics Dashboard | Business | Active | Usage analytics and user behavior insights | Business intelligence | user | M003/S02 | M003/S01, M003/S03 | Data accuracy verification | GDPR compliance |
| R008 | Subscription Management | Business | Active | Monthly/annual subscription with feature gating | Monetization strategy | user | M003/S03 | M003/S01, M003/S02 | Payment processing testing | Apple App Store compliance |

## Validated

| ID | Title | Class | Status | Description | Why | Source | Primary Owner | Supporting | Validation | Notes |
|----|-------|-------|--------|-------------|-----|--------|---------------|------------|------------|-------|
| R001 | Real-time Speech Translation | Core | Validated | Two-way voice translation between human and dog with minimal latency | Core value proposition | user | M001/S01 | M001/S02, M001/S03 | Design review, latency testing | Must support iOS speech frameworks |
| R003 | Offline Capability | Core | Validated | Basic translation works without internet connection | Reliability, user experience | user | M001/S03 | M001/S01, M001/S02 | Offline testing | Fallback to cached model |
| R009 | iOS Native Development | Platform | Validated | Swift-based iOS application | Native performance and UX | research | M001/S01 | All milestones | Platform capability confirmed | Requires iOS 15+ |

## Deferred

| ID | Title | Class | Status | Description | Why | Source | Primary Owner | Supporting | Validation | Notes |
|----|-------|-------|--------|-------------|-----|--------|---------------|------------|------------|-------|
| R010 | Android Support | Platform | Deferred | Cross-platform Android version | Market expansion | user | M004 | M001-M003 | Post-launch | Requires React Native port |

## Out of Scope

| ID | Title | Class | Status | Description | Why | Source | Primary Owner | Supporting | Validation | Notes |
|----|-------|-------|--------|-------------|-----|--------|---------------|------------|------------|-------|
| R011 | Web Interface | Platform | Out of Scope | Browser-based translation tool | Focus on mobile experience | research | None | None | Not aligned with core strategy | Could be future feature |

## Traceability

- **Core Translation** (M001): R001, R002, R003
- **Community Features** (M002): R004, R005
- **Advanced AI** (M003): R006, R007, R008
- **Platform Validation** (M001): R009
- **Future Expansion** (M004): R010
- **Excluded** (None): R011

## Notes
- All Active requirements must be mapped to a roadmap owner
- R001 and R03 validated in M001 (real-time translation and offline capability)
- R002 remains Active because vocabulary coverage (100+ phrases) falls short of 5000+ target
- Community features (R004-R005) are essential for long-term engagement
- Advanced AI features (R006-R008) provide competitive differentiation
- Subscription model must comply with Apple App Store guidelines
