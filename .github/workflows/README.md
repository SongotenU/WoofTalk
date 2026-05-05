# WoofTalk CI/CD Workflows

This directory contains GitHub Actions workflows for automated build, test, and deployment of WoofTalk across all platforms (iOS, Android, Web).

## Workflow Overview

| Workflow | File | Trigger | Purpose |
|----------|------|----------|---------|
| Web Deploy | `web-deploy.yml` | Push to `main` | Deploy Next.js web app to Vercel production |
| iOS Build | `ios-build.yml` | Push to `main`/`develop`, PR | Build iOS app archive and export IPA |
| Android Build | `android-build.yml` | Push to `main`/`develop`, PR | Build Android APK/AAB |
| PR Tests | `pr-test.yml` | PR to `main`/`develop` | Run lint, type check, build verification |
| Staging Deploy | `staging-deploy.yml` | Push to `develop` | Deploy to staging environments |
| Release Build | `release-build.yml` | Git tags (`v*`) | Create GitHub Release with production builds |
| Supabase | `supabase.yml` | Push to `main` | Run Supabase migrations |
| Uptime Monitor | `uptime-monitor.yml` | Schedule (every 5 min) | Monitor production health |

## Required Secrets

### Vercel (Web Deployment)
- `VERCEL_TOKEN` - Vercel API token
- `VERCEL_ORG_ID` - Vercel organization ID
- `VERCEL_PROJECT_ID` - Vercel project ID

### iOS Build
- `APPLE_DEVELOPER_TEAM_ID` - Apple Developer Team ID
- `IOS_CERTIFICATE_BASE64` - Base64-encoded .p12 certificate
- `IOS_CERTIFICATE_PASSWORD` - Certificate password
- `IOS_PROVISIONING_PROFILE_BASE64` - Base64-encoded provisioning profile
- `IOS_PROVISIONING_PROFILE_NAME` - Provisioning profile name
- `APP_STORE_CONNECT_API_KEY_ID` - App Store Connect API Key ID
- `APP_STORE_CONNECT_ISSUER_ID` - App Store Connect Issuer ID
- `APP_STORE_CONNECT_PRIVATE_KEY` - App Store Connect Private Key

### Android Build
- `ANDROID_KEYSTORE_BASE64` - Base64-encoded keystore file
- `ANDROID_KEYSTORE_PASSWORD` - Keystore password
- `ANDROID_KEY_ALIAS` - Key alias
- `ANDROID_KEY_PASSWORD` - Key password
- `PLAY_STORE_SERVICE_ACCOUNT_JSON` - Google Play service account JSON

### Supabase
- `SUPABASE_ACCESS_TOKEN` - Supabase personal access token
- `SUPABASE_PROJECT_ID` - Supabase project ID

### RevenueCat (Web)
- `NEXT_PUBLIC_REVENUECAT_WEB_API_KEY` - RevenueCat web API key

## Setting Up Secrets

1. Go to your GitHub repository
2. Navigate to **Settings → Secrets and variables → Actions**
3. Click **New repository secret**
4. Add each secret listed above with its corresponding value

## Branch Strategy

- `main` - Production branch (triggers production deployments)
- `develop` - Staging branch (triggers staging deployments)
- Feature branches - Create PRs to `develop` for testing

## Workflow Details

### Web Deploy (`web-deploy.yml`)
Deploys the Next.js web app to Vercel production environment when changes are pushed to `main` and affect the `web/` directory.

**Environment Variables**: Requires `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in Vercel project settings.

### iOS Build (`ios-build.yml`)
Builds the iOS app using Xcode on macOS runners. Exports IPA files for distribution.

**Note**: Requires Apple Developer certificates and provisioning profiles to be set up as secrets.

### Android Build (`android-build.yml`)
Builds the Android app using Gradle on Ubuntu runners. Produces both debug APKs (for PRs) and release AABs (for main/develop).

**Note**: Release builds require a valid keystore. Debug builds run on PRs for quick testing.

### PR Tests (`pr-test.yml`)
Runs automated checks on pull requests:
- Web: lint, type check, build verification
- iOS: build check (if iOS files changed)
- Android: build check (if Android files changed)

### Staging Deploy (`staging-deploy.yml`)
Deploys to staging environments when changes are pushed to `develop`:
- Web: Deploys to Vercel staging URL
- iOS: Uploads to TestFlight internal testing (disabled by default)
- Android: Uploads to Play Console internal track (disabled by default)

### Release Build (`release-build.yml`)
Triggered by version tags (e.g., `v1.0.0`). Creates a GitHub Release with:
- Auto-generated changelog from git commits
- iOS IPA attached
- Android AAB attached

## Testing Workflows

To test the workflows:

1. **PR Test**: Create a test PR to `main` or `develop`
   ```bash
   git checkout -b test-pr
   echo "test" >> README.md
   git commit -am "Test PR workflow"
   git push origin test-pr
   # Create PR via GitHub UI
   ```

2. **Staging Deploy**: Push to `develop` branch
   ```bash
   git checkout develop
   git merge main
   git push origin develop
   ```

3. **Release Build**: Create a version tag
   ```bash
   git tag v0.1.0-test
   git push origin v0.1.0-test
   ```

## Troubleshooting

### iOS Build Fails with Certificate Error
- Verify `IOS_CERTIFICATE_BASE64` is correctly encoded
- Check certificate password
- Ensure provisioning profile matches the bundle ID

### Android Build Fails with Keystore Error
- Verify `ANDROID_KEYSTORE_BASE64` is correctly encoded
- Check keystore password and key alias
- Ensure keystore was generated with correct algorithm

### Web Deploy Fails
- Check Vercel token has correct permissions
- Verify project ID and org ID are correct
- Check Vercel project has correct environment variables

## Disabling Workflows

To temporarily disable a workflow, add `if: false` to the job:

```yaml
jobs:
  deploy:
    if: false  # Disabled
    runs-on: ubuntu-latest
    ...
```

Or delete/comment out the workflow file.

## Manual Trigger

All workflows support manual trigger via `workflow_dispatch`. Go to **Actions** tab in GitHub, select a workflow, and click **Run workflow**.
