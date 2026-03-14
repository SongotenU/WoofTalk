#!/bin/bash

# WoofTalk App Store Configuration Verification Script
# Verifies all required files and metadata are present and valid for App Store submission

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🧪 Verifying WoofTalk App Store configuration..."
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Function to print check result
check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
    PASSED=$((PASSED + 1))
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
    FAILED=$((FAILED + 1))
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Change to project root
cd "$PROJECT_ROOT"

echo "== Checking required files =="

# Required files
REQUIRED_FILES=(
    "AppStoreMetadata.json"
    "PrivacyPolicy.md"
    "TermsOfService.md"
    "ExportOptions.plist"
    "Entitlements.plist"
    "ReleaseNotes.md"
    "WoofTalk/Info.plist"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_pass "Found required file: $file"
    else
        check_fail "Missing required file: $file"
    fi
done

echo ""
echo "== Checking App Store Screenshots =="

if [ -d "AppStoreScreenshots" ]; then
    check_pass "Screenshots directory exists"

    # Count PNG and JPG files
    IMG_COUNT=$(find AppStoreScreenshots -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | wc -l)
    if [ "$IMG_COUNT" -ge 9 ]; then
        check_pass "Found $IMG_COUNT screenshot images (minimum 9 required)"
    else
        check_fail "Only $IMG_COUNT screenshot images found (minimum 9 required)"
    fi
else
    check_fail "AppStoreScreenshots directory not found"
fi

echo ""
echo "== Validating metadata JSON =="

if command -v python3 &> /dev/null; then
    if python3 -m json.tool AppStoreMetadata.json > /dev/null 2>&1; then
        check_pass "AppStoreMetadata.json is valid JSON"
    else
        check_fail "AppStoreMetadata.json is invalid JSON"
    fi
elif command -v python &> /dev/null; then
    if python -m json.tool AppStoreMetadata.json > /dev/null 2>&1; then
        check_pass "AppStoreMetadata.json is valid JSON"
    else
        check_fail "AppStoreMetadata.json is invalid JSON"
    fi
else
    check_warn "Python not available - skipping JSON validation (install Python to validate)"
fi

echo ""
echo "== Validating Info.plist required keys =="

REQUIRED_PLIST_KEYS=(
    "CFBundleName"
    "CFBundleIdentifier"
    "CFBundleVersion"
    "CFBundleShortVersionString"
    "NSMicrophoneUsageDescription"
    "NSSpeechRecognitionUsageDescription"
)

if command -v plutil &> /dev/null; then
    for key in "${REQUIRED_PLIST_KEYS[@]}"; do
        if plutil -extract "$key" raw WoofTalk/Info.plist > /dev/null 2>&1; then
            check_pass "Info.plist contains key: $key"
        else
            check_fail "Info.plist missing required key: $key"
        fi
    done
else
    # Fallback: check using grep (basic)
    for key in "${REQUIRED_PLIST_KEYS[@]}"; do
        if grep -q "<key>$key</key>" WoofTalk/Info.plist; then
            check_pass "Info.plist contains key: $key"
        else
            check_fail "Info.plist missing required key: $key"
        fi
    done
fi

echo ""
echo "== Validating configuration consistency =="

# Check that bundle ID in metadata matches Info.plist
BUNDLE_ID_PLIST=$(grep -A1 "<key>CFBundleIdentifier</key>" WoofTalk/Info.plist | grep -oP '(?<=<string>)[^<]+' | head -1)
BUNDLE_ID_META=$(grep -oP '"bundleId"\s*:\s*"\K[^"]+' AppStoreMetadata.json | head -1)

if [ "$BUNDLE_ID_PLIST" = "$BUNDLE_ID_META" ]; then
    check_pass "Bundle ID consistent between Info.plist and AppStoreMetadata.json ($BUNDLE_ID_PLIST)"
else
    check_fail "Bundle ID mismatch: Info.plist='$BUNDLE_ID_PLIST' vs metadata='$BUNDLE_ID_META'"
fi

# Check version consistency
VERSION_PLIST=$(grep -A1 "<key>CFBundleShortVersionString</key>" WoofTalk/Info.plist | grep -oP '(?<=<string>)[^<]+' | head -1)
VERSION_META=$(grep -oP '"version"\s*:\s*"\K[^"]+' AppStoreMetadata.json | head -1)

if [ "$VERSION_PLIST" = "$VERSION_META" ]; then
    check_pass "Version consistent between Info.plist and AppStoreMetadata.json ($VERSION_PLIST)"
else
    check_fail "Version mismatch: Info.plist='$VERSION_PLIST' vs metadata='$VERSION_META'"
fi

echo ""
echo "== Checking script permissions =="

if [ -x "scripts/verify-app-store.sh" ]; then
    check_pass "Verification script is executable"
else
    check_fail "Verification script is not executable (run: chmod +x scripts/verify-app-store.sh)"
fi

echo ""
echo "== Checking documentation =="

# Ensure privacy policy and terms are non-empty
if [ -s "PrivacyPolicy.md" ]; then
    check_pass "PrivacyPolicy.md is non-empty"
else
    check_fail "PrivacyPolicy.md is empty or missing"
fi

if [ -s "TermsOfService.md" ]; then
    check_pass "TermsOfService.md is non-empty"
else
    check_fail "TermsOfService.md is empty or missing"
fi

if [ -s "ReleaseNotes.md" ]; then
    check_pass "ReleaseNotes.md is non-empty"
else
    check_fail "ReleaseNotes.md is empty or missing"
fi

echo ""
echo "========================================"
echo "Verification Summary"
echo "========================================"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All App Store configuration checks passed!${NC}"
    echo "The app is ready for archive and submission."
    echo ""
    echo "Next steps:"
    echo "1. Replace placeholder team IDs in plist files with your Apple Developer Team ID"
    echo "2. Create actual App Store screenshots (replace placeholders in AppStoreScreenshots/)"
    echo "3. Archive the app using Xcode (Product > Archive) with Release configuration"
    echo "4. Validate archive in Organizer"
    echo "5. Submit to App Store Connect"
    exit 0
else
    echo -e "${RED}❌ Verification failed. Please fix the above issues before submission.${NC}"
    exit 1
fi
