# Play Store Assets Checklist

## Required Assets for Google Play Console

### 1. App Details
- [ ] App Name: WoofTalk
- [ ] Short Description (80 chars): "Connect with dog lovers, share moments, and discover local dog events"
- [ ] Full Description (up to 4000 chars): See FULL_DESCRIPTION.md
- [ ] App Category: Social
- [ ] Tags: dogs, pets, social, community, events

### 2. Graphics & Media
- [ ] App Icon: 512 x 512 px (PNG, 32-bit)
  - Location: android/WoofTalk/app/src/main/res/mipmap-anydpi-v26/
  - Status: ✓ Already exists (ic_launcher)
- [ ] Feature Graphic: 1024 x 500 px (PNG/JPEG)
  - Create: android/WoofTalk/play-store/feature-graphic.png
  - Status: TODO
- [ ] Screenshots (at least 2, max 8 per type):
  - Phone: 16:9 aspect ratio, min 320px, max 3840px
  - 7-inch tablet: 16:10 aspect ratio
  - 10-inch tablet: 16:10 aspect ratio
  - Status: TODO - Need to capture from running app

### 3. Store Listing
- [ ] Privacy Policy URL: https://wooftalk.app/privacy
  - Create privacy policy document
- [ ] Website URL: https://wooftalk.app
- [ ] Email: support@wooftalk.app
- [ ] Phone: (optional)

### 4. Content Rating
- [ ] Complete questionnaire in Play Console
- [ ] Category: Social
- [ ] Content: No explicit content (rated for everyone)

### 5. Pricing & Distribution
- [ ] Free app (initial release)
- [ ] Supported countries: All (or select target markets)
- [ ] Device categories: Phone, Tablet
- [ ] Wear OS: No (unless adding later)

### 6. App Content
- [ ] App provides functionality for dogs/pets social networking
- [ ] Target audience: 18+ (or 13+ if appropriate)
- [ ] Ads: No (or Yes if using ad network)
- [ ] In-app purchases: Yes (via RevenueCat/Google Play Billing)

### 7. Release Type
- [ ] Internal Testing (recommended first step)
- [ ] Closed Testing (optional)
- [ ] Open Testing (optional)
- [ ] Production (final release)

## Next Steps
1. Generate signed AAB (see task #9)
2. Create Google Play Console account ($25 one-time fee)
3. Create app entry in Play Console
4. Upload AAB to Internal Testing track
5. Complete store listing with assets above
6. Submit for content rating
7. Set up pricing & distribution
8. Roll out to production
