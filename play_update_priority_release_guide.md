# Google Play In-App Update Priority — Release Management Guide

## Overview

Gym Buddy uses native **Google Play In-App Updates** with **In-App Update Priority** (`updatePriority`) to distinguish between regular, recommended, and critical releases without relying on Firebase Remote Config or any external configuration backend.

---

## 1. Google Play Priority Scale & Gym Buddy Policy

Google Play assigns an integer value from **0 to 5** (`0` being lowest, `5` highest) to each release:

| Priority | Classification | Gym Buddy Behavior | User Experience | Native API Triggered |
| :---: | :---: | :---: | :---: | :---: |
| **0** | Default / Trivial | Silent / No prompt | Background only; no dialog shown | None |
| **1 – 2** | Minor / Optional | Optional Flexible Update | Dialog shown with "UPGRADE NOW" and "LATER" | `startFlexibleUpdate()` |
| **3** | Recommended | Recommended Optional Update | Dialog highlights "Update Recommended" with "LATER" | `startFlexibleUpdate()` |
| **4 – 5** | Critical / Mandatory | Mandatory Immediate Update | Non-dismissible dialog with "UPDATE NOW" only | `performImmediateUpdate()` (or Play Store direct fallback) |

### Central Thresholds in Gym Buddy
Located in [`lib/config/app_update_config.dart`](file:///Users/hemthath/Documents/Learnings/fitnessapp/lib/config/app_update_config.dart):
- `mandatoryPriorityThreshold = 4`: Priority 4 and 5 trigger non-dismissible mandatory dialogs.
- `optionalPromptPriorityThreshold = 1`: Priority 1, 2, and 3 prompt the user. Priority 0 remains silent.
- **Local Safeguard**: Even if Google Play reports priority 0 or fails to respond, any installed version below `minimumRequiredVersion` (or `minimumRequiredBuildNumber`) will **always** trigger a mandatory update.

---

## 2. Why Google Play Console Web UI Does NOT Support Priority

> [!WARNING]
> **The Google Play Console web interface (`https://play.google.com/console`) does NOT have a UI field to enter `updatePriority`.**
> Any release created and published manually through the Google Play Console web form automatically receives an `inAppUpdatePriority` of **`0`**.

To set priority 1–5, the release must be uploaded and committed using the **Google Play Developer Publishing API**, or CI/CD tools that integrate with it (such as Fastlane or Gradle Play Publisher).

---

## 3. How to Publish with Priority

### Method A: Fastlane (`supply` / `upload_to_play_store`)

Fastlane is the simplest way to set `in_app_update_priority` during your build and deploy pipeline.

In your `fastlane/Fastfile`:

```ruby
lane :deploy_critical_update do
  build_app_bundle # builds Gym Buddy AAB

  upload_to_play_store(
    track: 'production',
    aab: 'build/app/outputs/bundle/release/app-release.aab',
    json_key: 'play-store-service-account.json',
    in_app_update_priority: 5, # Mandatory immediate update (4 or 5)
    release_status: 'completed',
    mapping_paths: ['build/app/outputs/mapping/release/mapping.txt']
  )
end

lane :deploy_recommended_update do
  upload_to_play_store(
    track: 'production',
    aab: 'build/app/outputs/bundle/release/app-release.aab',
    json_key: 'play-store-service-account.json',
    in_app_update_priority: 3, # Recommended optional update
    release_status: 'completed'
  )
end

lane :deploy_regular_update do
  upload_to_play_store(
    track: 'production',
    aab: 'build/app/outputs/bundle/release/app-release.aab',
    json_key: 'play-store-service-account.json',
    in_app_update_priority: 2, # Optional flexible update
    release_status: 'completed'
  )
end
```

---

### Method B: Gradle Play Publisher (GPP)

If using the Gradle Play Publisher plugin in `android/app/build.gradle`:

```groovy
play {
    serviceAccountCredentials = file("play-service-account.json")
    track = "production"
    releaseStatus = "completed"
    // Set update priority: 0 to 5
    updatePriority = 5
}
```

Run via Gradle:
```bash
cd android && ./gradlew publishBundle
```

---

### Method C: Google Play Developer Publishing API Directly (Python / REST)

You can script release creation directly with Google's official API client (`google-api-python-client`).

#### 1. Service Account Setup
1. Open **Google Play Console** -> **API access**.
2. Link or create a Google Cloud Project with the **Google Play Android Developer API** enabled.
3. Create a Service Account, generate a JSON Key, and grant it **Admin** or **Releases** permission in Play Console.

#### 2. Release Script (`publish_with_priority.py`)

```python
import os
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build

PACKAGE_NAME = 'com.gymbuddy.fitnessapp'
TRACK = 'production'  # or 'internal', 'alpha', 'beta'
KEY_FILE = 'service_account.json'
AAB_PATH = 'build/app/outputs/bundle/release/app-release.aab'
PRIORITY = 5  # Set priority: 0 to 5

def publish_release(priority: int):
    credentials = service_account.Credentials.from_service_account_file(
        KEY_FILE,
        scopes=['https://www.googleapis.com/auth/androidpublisher']
    )
    service = build('androidpublisher', 'v3', credentials=credentials)

    # 1. Create a new edit
    edit = service.edits().insert(packageName=PACKAGE_NAME, body={}).execute()
    edit_id = edit['id']
    print(f"Created edit: {edit_id}")

    try:
        # 2. Upload the App Bundle
        bundle = service.edits().bundles().upload(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            media_body=AAB_PATH
        ).execute()
        version_code = bundle['versionCode']
        print(f"Uploaded AAB with versionCode: {version_code}")

        # 3. Create release object with inAppUpdatePriority
        release_body = {
            'releases': [{
                'name': f"Release {version_code}",
                'versionCodes': [str(version_code)],
                'status': 'completed',
                'inAppUpdatePriority': priority,  # <--- SETS IN-APP UPDATE PRIORITY (0-5)
                'releaseNotes': [{
                    'language': 'en-US',
                    'text': 'Critical stability improvements and bug fixes.'
                }]
            }]
        }

        service.edits().tracks().update(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            track=TRACK,
            body=release_body
        ).execute()
        print(f"Track {TRACK} updated with priority {priority}.")

        # 4. Commit edit
        service.edits().commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
        print("Release successfully published!")

    except Exception as e:
        print(f"Error publishing: {e}")
        service.edits().delete(packageName=PACKAGE_NAME, editId=edit_id).execute()
        raise

if __name__ == '__main__':
    priority = int(sys.argv[1]) if len(sys.argv) > 1 else 5
    publish_release(priority)
```

---

## 4. Immutability Rules

> [!IMPORTANT]
> **`inAppUpdatePriority` cannot be updated on an active release.**
> - Priority must be specified when the release is created in an edit.
> - Once the edit is committed and the release is active or 100% rolled out, Google does not permit editing the priority value.
> - To change priority from e.g. 2 to 5, you must publish a new release with an incremented `versionCode`.

---

## 5. Testing In-App Update Priority Before Production

Because In-App Updates interact with the device's Google Play Store app:

1. **Internal App Sharing / Internal Test Track**:
   - Upload the build with priority 4 or 5 to the **Internal testing track** using Fastlane or the script above.
2. **License Testing Account**:
   - In Google Play Console -> **Setup** -> **License testing**, add your test Google account.
   - Set **License response** to `LICENSED`.
3. **Test Device Setup**:
   - Install an older version of Gym Buddy (e.g. `versionCode 31`) on the test Android device.
   - Ensure the Play Store on the device is logged in to the test account added to the tester list.
4. **Launch Gym Buddy**:
   - Gym Buddy queries `InAppUpdate.checkForUpdate()`.
   - The response includes `updatePriority: 5`.
   - Gym Buddy immediately triggers the native immediate update modal or falls back to Google Play.
