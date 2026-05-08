# Phase 60: Build Signed Release AAB

## Prerequisites

### Option 1: Use Android Studio (Recommended)
1. Open Android Studio
2. Open project: `/Users/vandopha/Downloads/PersonalSideProjects/WoofTalk/android/WoofTalk`
3. Let Gradle sync complete
4. Menu: **Build → Generate Signed Bundle / APK**
5. Select **Android App Bundle**
6. Key store path: `/Users/vandopha/Downloads/PersonalSideProjects/WoofTalk/android/WoofTalk/wooftalk-release.keystore`
   - Key store password: `wooftalk123`
   - Key alias: `wooftalk-key`
   - Key password: `wooftalk123`
7. Build type: **release**
8. Output: `android/WoofTalk/app/build/outputs/bundle/release/app-release.aab`

### Option 2: Command Line with Java 11

```bash
# Install Java 11
brew install openjdk@11

# Set JAVA_HOME
export JAVA_HOME=/opt/homebrew/opt/openjdk@11

# Build
cd /Users/vandopha/Downloads/PersonalSideProjects/WoofTalk/android/WoofTalk
./gradlew bundleRelease --no-daemon
```

### Option 3: Use SDKMAN

```bash
# Install SDKMAN
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Install Java 11
sdk install java 11.0.21-tem
sdk use java 11.0.21-tem

# Build
cd /Users/vandopha/Downloads/PersonalSideProjects/WoofTalk/android/WoofTalk
./gradlew bundleRelease --no-daemon
```

### Option 4: Use Eclipae Temurin JDK 11

Download from: https://adoptium.net/temurin/releases/?version=11
Select: macOS, x64, .tar.gz

```bash
cd /tmp
# Extract downloded file
tar xzf OpenJDK11U-jdk_x64_mac_hotspot_*.tar.gz

# Build with Java 11
cd /Users/vandopha/Downloads/PersonalSideProjects/WoofTalk/android/WoofTalk
JAVA_HOME=/tmp/jdk-11.0.21+9/Contents/Home ./gradlew bundleRelease --no-daemon
```

## After Build

1. Verify AAB exists: `ls -lh app/build/outputs/bundle/release/app-release.aab`
2. Upload to Play Console: https://play.google.com/console
3. Follow steps in `play-store/PLAY_CONSOLE_GUIDE.md`

## Known Issue

AGP 8.x has a bug accessing private method `computeAndroidFolder()` via reflection on Java 17+.
- Issue: https://issuetracker.google.com/issues/305063590
- Workaround: Use Java 11 or Android Studio's bundled JDK

## Current Setup

- Signing config: `app/build.gradle.kts` (lines 11-30)
- Keystore: `wooftalk-release.keystore`
- Keystore properties: `keystore.properties`
- AGP version: 8.7.3 (in `settings.gradle.kts`)
- Gradle version: 8.9 (in `gradle-wrapper.properties`)
