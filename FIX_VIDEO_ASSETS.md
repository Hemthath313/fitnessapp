# Fix Video Assets Issue

## Problem
Flutter hot restart doesn't fully rebuild asset bundles, so it's still trying to find old filenames with spaces.

## Solution: Full Rebuild Required

**DO NOT use hot restart (R)** - it won't work for asset changes.

### Steps to Fix:

1. **Stop the app completely**
   - Press `q` in the terminal to quit
   - Or close the app on your device/emulator

2. **Do a full rebuild:**
   ```bash
   flutter run
   ```

   Or if you want to build and install:
   ```bash
   flutter build apk --debug  # for Android
   flutter install             # to install
   ```

3. **Alternative: Full clean rebuild**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Why This Happens

- Hot restart (R) only reloads Dart code, not assets
- Hot reload (r) only reloads changed widgets
- Asset changes require a **full rebuild** to update the asset bundle

## Current Video Files (All Correct ✅)

- `barbell_bench_press.mp4` ✅
- `barbell_curl.mp4` ✅
- `barbell_decline_bench_press.mp4` ✅
- `cable_one_arm_curl.mp4` ✅
- `stretching_seated_twist_straight_arm.mp4` ✅

All code mappings are correct. Just need a full rebuild!


