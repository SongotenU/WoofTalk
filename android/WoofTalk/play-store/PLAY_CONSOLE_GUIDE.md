# Google Play Console Submission Guide

## Prerequisites

1. **Google Play Console Account**
   - Visit: https://play.google.com/console
   - Sign up (one-time $25 USD fee)
   - Verify identity (government ID may be required)

2. **Developer Account Requirements**
   - Valid Google account
   - Credit/debit card for registration fee
   - Government-issued ID (for verification)

## Step-by-Step Submission Process

### 1. Create App Entry
1. Log into Google Play Console
2. Click "Create App"
3. Fill in:
   - App name: WoofTalk
   - Select "App" (not game)
   - Select "Free" (or Paid if applicable)
   - Select "Android" (not Wear OS)
   - Check "I acknowledge..." boxes
4. Click "Create"

### 2. Complete Dashboard Tasks

#### Task 1: Set up Store Presence
**Store Listing:**
- App name: WoofTalk
- Short description: "Connect with dog lovers, share moments, and discover local dog events"
- Full description: Use content from `FULL_DESCRIPTION.md`
- App icon: 512x512 PNG (from `app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`)
- Feature graphic: 1024x500 PNG (create `play-store/feature-graphic.png`)
- Screenshots: Upload 2-8 phone screenshots (16:9 ratio)
- Privacy policy URL: https://wooftalk.app/privacy
- Website: https://wooftalk.app
- Email: support@wooftalk.app

**Categorization:**
- App category: Social
- Tags: dogs, pets, social, community

#### Task 2: Set up App Content
- Complete "Privacy Policy" section
- Complete "App Access" (if applicable)
- Complete "Ads" (select "No ads" or describe ad implementation)
- Complete "App Content" questionnaire for content rating
- Complete "Target Audience" (select 18+ or 13+)
- Complete "Data Safety" section (describe data collection)

#### Task 3: Set up Store Settings
- Select countries for distribution (or "Select all")
- Select device categories: Phone, Tablet
- Pricing: Free (or set price)
- In-app purchases: Yes (via RevenueCat)

### 3. Upload App Bundle (AAB)

#### Build Signed AAB
```bash
cd /Users/vandopha/Downloads/PersonalSideProjects/WoofTalk/android/WoofTalk
./gradlew bundleRelease
```

Output location: `app/build/outputs/bundle/release/app-release.aab`

#### Upload to Play Console
1. Go to "Testing and Release" → "Internal Testing"
2. Click "Create Track" (or use default internal track)
3. Click "Upload" and select the AAB file
4. Fill in release name: "1.0.0 (1)"
5. Fill in release notes: "Initial release of WoofTalk"
6. Click "Review Release"
7. Click "Start Rollout to Internal Testing"

### 4. Content Rating
1. Go to "Policy and Programs" → "Content Rating"
2. Complete questionnaire:
   - Category: Social Networking
   - Content: No violence, no sexual content, no profanity
   - Target: General audiences
3. Submit for rating

### 5. Target Audience and Content
1. Go to "Policy and Programs" → "Target Audience"
2. Select age groups (13+: Teen, 18+: Adult)
3. Answer questions about ads and data collection
4. Save

### 6. Data Safety
1. Go to "Policy and Programs" → "Data Safety"
2. Add data collection details:
   - Personal info: Name, email (for account)
   - Location: Approximate location (for local events)
   - Financial info: None (RevenueCat handles payments)
   - Health & fitness: None
   - Photos & videos: User-uploaded dog photos
3. Submit

### 7. Release to Production
After internal testing:
1. Go to "Testing and Release" → "Production"
2. Click "Create Track"
3. Select "Release from Internal Testing" or upload new AAB
4. Fill in release details
5. Click "Review Release"
6. Click "Send for Review"

## Timeline
- Internal Testing: Immediate
- Closed Testing: 1-3 days (if required)
- Open Testing: 1-3 days (optional)
- Production Review: 1-7 days (typical)

## Checklist Before Submission
- [ ] Signed AAB built successfully
- [ ] App icon and feature graphic ready
- [ ] Screenshots captured (min 2, max 8)
- [ ] Privacy policy published and accessible
- [ ] Store listing text prepared
- [ ] Content rating questionnaire completed
- [ ] Data safety section completed
- [ ] Target audience defined
- [ ] Distribution countries selected

## Post-Submission
- Monitor "Policy and Programs" → "App Content" for issues
- Check "Testing and Release" → "Production" for status
- Respond to user reviews
- Plan updates via new releases

## Resources
- Play Console: https://play.google.com/console
- Developer Policy: https://play.google.com/about/developer-content-policy/
- Design Guidelines: https://developer.android.com/distribute/best-practices/ct-store-listing
