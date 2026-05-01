# Social/Community Feature Gaps

## Current State

WoofTalk has a foundational social/community layer with the following implemented features:

### Implemented Features
| Feature | Implementation | Status |
|---------|---------------|--------|
| Follow/Unfollow dog owners | `SocialGraphManager.swift` - CoreData-backed follow graph with follow/unfollow, follower/following counts | **Complete** |
| Community phrase browsing | `CommunityPhraseBrowserView.swift` - Grid/list view, search, filtering by quality, sorting | **Complete** |
| Community phrase contributions | `CommunityPhraseManager.swift`, `ContributionManager.swift` - Users can submit translations for validation | **Complete** |
| Leaderboard | `LeaderboardManager.swift` - Weekly/monthly/all-time leaderboards based on contribution counts | **Partial** (contribution-based only) |
| Social sharing | `SocialSharingManager.swift` - Basic iOS share sheet for translation text | **Partial** (no platform-specific overlays) |
| Activity events | `ActivityEventManager.swift` - New follower, contribution approved/rejected, leaderboard change, phrase featured, milestone reached | **Complete** |
| Push notifications | `NotificationManager.swift` - Local and remote notifications for social events | **Partial** (newFollower, contributionApproved, leaderboardChange, phraseFeatured only) |
| User profiles | `UserProfileManager.swift`, `UserProfileView+Social.swift` - Profile view with social stats (followers, following, contributions) | **Partial** (no dog profile data) |

### Core Data Models
- **User**: `id`, `username`, `email`, `isModerator`, `contributions` (NSSet)
- **CommunityPhrase**: `id`, `humanText`, `dogTranslation`, `qualityScore`, `timestamp`, `submitter`, `direction`, `usageCount`, `lastUsed`
- **Contribution**: `id`, `humanText`, `dogTranslation`, `qualityScore`, `status`, `timestamp`, `validationNotes`, `validationWarnings`, `user`

### Key Observations
- No dog/pet profile entity exists - the User model only stores human user data
- No breed, photo, or pet attribute data in the system
- No reactions, comments, or engagement features on community phrases
- No messaging system between users
- No event/meetup creation or discovery
- No badge/verification system for dogs or owners
- No breed-specific grouping or communities

---

## Missing Features (Prioritized)

| # | Feature | Priority | Effort | Impact | Notes |
|---|---------|----------|--------|--------|-------|
| 1 | **Dog profile / digital dog card** | High | Medium | High | Foundation for most other features - need Dog entity with breed, photo, owner link |
| 2 | **Photo sharing with translation captions** | High | Medium | High | Natural extension of community phrases - add image asset support |
| 3 | **In-app messaging between owners** | Medium | High | Medium | Requires conversation/thread data model, real-time delivery |
| 4 | **Breed-specific communities** | Medium | Medium | Medium | Depends on Dog entity with breed field; filter/browse by breed |
| 5 | **Translation reactions/emojis** | Medium | Low | Medium | Add reaction counts to CommunityPhrase; simple CoreData relationship |
| 6 | **Comment on translations** | Medium | Medium | Medium | Threaded comments on CommunityPhrase; moderation considerations |
| 7 | **Dog meetup event creation and discovery** | Medium | High | Medium | Event entity, location data, RSVP system |
| 8 | **Sharing to Instagram/TikTok with branded overlays** | Medium | Medium | High | Extend SocialSharingManager with platform-specific image/video generation |
| 9 | **"Bark of the day" community challenge** | Low | Medium | Medium | Daily featured phrase, voting mechanism |
| 10 | **Leaderboards for most translated barks / most active dogs** | Low | Low | Medium | Extend LeaderboardManager - needs Dog entity for "most active dogs" |
| 11 | **Verified dog badges** | Low | Medium | Low | Badge entity, verification workflow, display on profiles |
| 12 | **Dog owner social network (nearby discovery)** | Low | High | Medium | Location services, proximity search, privacy considerations |
| 13 | **Dog adoption/breeding announcements** | Low | Medium | Low | Sensitive content - requires moderation, legal considerations |
| 14 | **Lost dog alerts with bark recognition** | Low | Very High | High | Requires audio fingerprinting, push geofencing - very complex |
| 15 | **Enhanced leaderboard (most active dogs)** | Low | Low | Medium | Already have contribution leaderboard; extend for dog-specific metrics |

---

## Recommendations

### Top 3 Recommendations

**1. Implement Dog Profile Entity (Foundation Block)**
- Create a `Dog` CoreData entity with: `id`, `name`, `breed`, `photoData`/`photoURL`, `owner` (relation to User), `bio`, `age`, `createdDate`
- Add relation from User to Dog (one-to-many: one owner can have multiple dogs)
- This unlocks: dog profile sharing, breed-specific communities, dog leaderboards, dog badges, meetup associations
- Estimated effort: Medium (3-5 files: CoreData model, manager, views)

**2. Add Reactions to Community Phrases**
- Add `Reaction` CoreData entity: `id`, `type` (emoji), `user`, `phrase`, `timestamp`
- Add reaction display to `CommunityPhraseDetailView.swift` and cells
- Simple engagement mechanism that increases community interaction
- Estimated effort: Low (2-3 files)

**3. Extend Social Sharing with Platform-Specific Overlays**
- Extend `SocialSharingManager.swift` to generate branded image overlays for Instagram/TikTok
- Include: translation text, quality score, WoofTalk branding, contributor name
- Generate shareable image with `UIGraphicsImageRenderer`
- High visibility feature for organic user acquisition
- Estimated effort: Medium (extend existing manager + add overlay generation)

---

## Feature Gap Summary

| Category | Existing | Missing | Completion |
|----------|----------|---------|------------|
| User Social Graph | Follow/unfollow, follower counts | Messaging, proximity discovery | 30% |
| Community Content | Phrase browsing, contributions, leaderboards | Photo sharing, reactions, comments, daily challenges | 40% |
| Dog Profiles | None | All dog-related features (profiles, breeds, badges, cards) | 0% |
| Events/Meetups | None | Event creation, discovery, RSVP | 0% |
| Platform Sharing | Basic share sheet | Instagram/TikTok overlays, branded content | 20% |
| Notifications | Basic social events | Rich push, event reminders, proximity alerts | 40% |

**Overall Social/Community Completion: ~25%** - Foundational elements exist (follow system, community phrases, basic leaderboard) but most engaging features around dog profiles, rich interactions, and events are missing.
