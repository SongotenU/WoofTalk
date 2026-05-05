# Phase 58: CI/CD Pipeline — PLAN

**Goal**: Set up automated build, test, and deployment pipeline for all platforms (iOS, Android, Web).

**Depends on**: Phase 57 (Web Production Deployment)

**Requirements**: CI-01, CI-02, CI-03, CI-04, CI-05, CI-06

**Success Criteria** (what must be TRUE):
1. GitHub Actions workflow for iOS builds (archive, test, distribute)
2. GitHub Actions workflow for Android builds (APK/AAB, test, distribute)
3. Automated testing on PR (lint, unit tests, build verification)
4. Staging deployment configured (auto-deploy on merge to `develop`)
5. Release build automation (tag-triggered production builds)
6. All workflows pass without errors

---

## Plans

### 58-01: iOS Build Workflow
**File**: `.github/workflows/ios-build.yml`
**Goal**: Create GitHub Actions workflow for iOS builds
**Verification**: Workflow runs successfully, produces `.ipa` artifact

**Steps**:
1. Create `ios-build.yml` with:
   - Trigger: push to `main`, PRs, manual dispatch
   - Set up macOS runner
   - Install dependencies (Xcode, certificates, provisioning profiles)
   - Build archive (xcodebuild or xcodebuild -archive)
   - Run unit tests (xcodebuild test)
   - Upload artifacts (.ipa, dSYM)
2. Document required secrets (certificates, provisioning profiles, App Store Connect API key)
3. Test workflow with a push to `main`

---

### 58-02: Android Build Workflow
**File**: `.github/workflows/android-build.yml`
**Goal**: Create GitHub Actions workflow for Android builds
**Verification**: Workflow runs successfully, produces `.apk`/`.aab` artifacts

**Steps**:
1. Create `android-build.yml` with:
   - Trigger: push to `main`, PRs, manual dispatch
   - Set up Ubuntu runner with JDK
   - Cache Gradle dependencies
   - Run lint and unit tests
   - Build release APK/AAB
   - Upload artifacts
2. Document required secrets (signing keystore, key alias, passwords)
3. Test workflow with a push to `main`

---

### 58-03: PR Automated Testing Workflow
**File**: `.github/workflows/pr-test.yml`
**Goal**: Run automated tests on every PR
**Verification**: Tests run on PR creation/update, status check appears

**Steps**:
1. Create `pr-test.yml` with:
   - Trigger: pull_request (opened, synchronize)
   - Lint check (web, iOS, Android)
   - Unit tests (web vitest, iOS XCTest, Android JUnit)
   - Build verification (all platforms)
   - Code coverage upload (optional)
2. Configure branch protection rules on `main` to require passing checks
3. Test with a sample PR

---

### 58-04: Staging Deployment Workflow
**File**: `.github/workflows/staging-deploy.yml`
**Goal**: Auto-deploy to staging environments on merge to `develop`
**Verification**: Successful deployment to staging URLs

**Steps**:
1. Create `staging-deploy.yml` with:
   - Trigger: push to `develop` branch
   - Deploy web to Vercel preview environment
   - Deploy iOS to TestFlight (internal testing)
   - Deploy Android to Play Console (internal testing track)
2. Set up `develop` branch if not exists
3. Configure staging environment secrets
4. Test deployment with a merge to `develop`

---

### 58-05: Release Build Automation
**File**: `.github/workflows/release-build.yml`
**Goal**: Trigger production releases via git tags
**Verification**: Tagging a commit triggers production build and release

**Steps**:
1. Create `release-build.yml` with:
   - Trigger: tag matching `v*` (e.g., `v1.0.0`)
   - Build production iOS IPA (App Store distribution)
   - Build production Android AAB (Play Store distribution)
   - Create GitHub Release with artifacts
   - Submit to App Store / Play Store (optional, may need manual)
2. Document release process (tagging, changelog)
3. Test with a test tag (e.g., `v0.1.0-test`)

---

### 58-06: Workflow Integration & Documentation
**File**: `.github/workflows/README.md`, repository documentation
**Goal**: Document all CI/CD workflows and required secrets
**Verification**: README explains setup, all secrets documented

**Steps**:
1. Create `.github/workflows/README.md` with:
   - Overview of all workflows
   - Required secrets table with descriptions
   - Setup instructions for each platform
   - Troubleshooting common issues
2. Update main `README.md` with CI/CD badge
3. Verify all workflows are documented
