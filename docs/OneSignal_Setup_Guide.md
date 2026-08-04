# OneSignal Setup Guide (Android + iOS)

This covers everything needed **outside** the Dart code to get push
notifications working end-to-end. The Flutter/Dart side is already
done (`NotificationPushService`, `Env.oneSignalAppId`, pubspec
dependency) — this guide is the OneSignal dashboard + native project
work required alongside it.

---

## 0. Prerequisites

- A OneSignal account (free tier is fine) → https://onesignal.com
- For Android: a Firebase project (just for FCM credentials — you
  don't need to write any Firebase code in the app)
- For iOS: an active Apple Developer account, and a Mac with Xcode to
  do the native-project steps

---

## 1. Create the OneSignal App

1. Log in to the OneSignal dashboard → **New App/Website**.
2. Name it (e.g. "TBH — Production") and select **Flutter** as the
   SDK when prompted.
3. Copy the **OneSignal App ID** shown at the end of setup.
4. Paste it into the project:

   ```dart
   // lib/core/network/env.dart
   static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
   ```

You'll configure the Android/iOS platform credentials for this same
app in the steps below (**Settings → Push & In-App** in the OneSignal
dashboard).

---

## 2. Android Setup

### 2.1 Firebase credentials (dashboard only — no app code)

1. In the [Firebase console](https://console.firebase.google.com/),
   create a project (or use an existing one) with the same Android
   package name as this app (`applicationId` in
   `android/app/build.gradle`).
2. In Firebase: **Project Settings → Service Accounts → Generate new
   private key** → downloads a JSON file.
3. In OneSignal: **Settings → Push & In-App → Google Android (FCM)** →
   upload that Service Account JSON.

You do **not** need to add `google-services.json` to the Flutter
project or add the Google Services Gradle plugin — OneSignal's native
Android SDK handles FCM registration on its own once the above is
configured in the dashboard. This step is 100% dashboard-side.

### 2.2 Notification icon (the only Android *file* you add)

Android forces small status-bar icons to render as a solid white
silhouette on API 21+, so the icon file itself must be **pure white
pixels on a transparent background** — color is ignored/clipped by the
OS regardless of what you upload.

**Exact filename (must match this precisely):** `ic_stat_onesignal_default.png`

**Exact paths — you need all five density variants:**

```
android/app/src/main/res/drawable-mdpi/ic_stat_onesignal_default.png      24x24 px
android/app/src/main/res/drawable-hdpi/ic_stat_onesignal_default.png      36x36 px
android/app/src/main/res/drawable-xhdpi/ic_stat_onesignal_default.png     48x48 px
android/app/src/main/res/drawable-xxhdpi/ic_stat_onesignal_default.png    72x72 px
android/app/src/main/res/drawable-xxxhdpi/ic_stat_onesignal_default.png   96x96 px
```

Easiest way to generate all five sizes correctly: use [Android Studio's
Image Asset Studio](https://developer.android.com/studio/write/image-asset-studio)
(**File → New → Image Asset → Notification Icons**) with the app's
logo as the source — it exports directly into these five folders with
the right filename.

If this file is missing (or misnamed, or missing a density), every
push falls back to OneSignal's default bell icon — it won't crash or
error, it just won't show your branding.

> This is the *only* file-based change Android needs. No manifest
> edits, no Gradle changes, no other native code — the OneSignal
> Android SDK auto-configures the rest when `onesignal_flutter` is
> added as a dependency and `flutter pub get` is run.

### 2.3 Build & test

```
flutter pub get
flutter run          # physical device or emulator both work for Android
```

---

## 3. iOS Setup

Unlike Android, iOS needs a few real native-project changes made in
Xcode, on a Mac. None of this is Dart code, but it isn't dashboard-only
either.

### 3.1 APNs key (dashboard + Apple Developer account)

1. In your [Apple Developer account](https://developer.apple.com/account/) →
   **Certificates, Identifiers & Profiles → Keys → +**.
2. Name the key, enable **Apple Push Notifications service (APNs)**,
   click **Continue → Register**.
3. Download the generated **.p8** file (you can only download it
   once — store it safely) and note the **Key ID**, and your account's
   **Team ID** (Account → Membership details).
4. In OneSignal: **Settings → Push & In-App → Apple iOS (APNs)** →
   upload the `.p8` file, Key ID, and Team ID.

(A `.p8` auth key is recommended over the older `.p12` certificate —
it doesn't expire yearly.)

### 3.2 Xcode capabilities (native project changes)

Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj`):

1. Select the **Runner** target → **Signing & Capabilities** tab.
2. **+ Capability → Push Notifications**
   — this adds an `aps-environment` entry to `ios/Runner/Runner.entitlements`.
3. **+ Capability → Background Modes** → check **Remote notifications**
   — this adds a `UIBackgroundModes` entry to `ios/Runner/Info.plist`.
4. Confirm the **Bundle Identifier** on this same tab matches what's
   registered with your Apple Developer account / App ID.

### 3.3 CocoaPods install

```
flutter pub get
cd ios
pod install
cd ..
```

Required because the iOS side of `onesignal_flutter` pulls in
OneSignal's native iOS SDK via CocoaPods — this step doesn't happen
automatically the way Android's Gradle merge does.

### 3.4 (Optional, recommended) Notification Service Extension

Needed for rich push features this module's Detail screen supports —
notification **images** and accurate **badge counts**. Without it,
pushes still work, just without the image/attachment.

1. Xcode → **File → New → Target → Notification Service Extension**.
2. Name it e.g. `OneSignalNotificationServiceExtension`.
3. Replace the generated `NotificationService.swift`/`.m` with
   OneSignal's boilerplate implementation — copy it from OneSignal's
   [iOS SDK setup guide](https://documentation.onesignal.com/docs/ios-sdk-setup)
   under the "Notification Service Extension" section (exact file
   contents are versioned there, so always pull the current copy
   rather than a pasted snapshot).
4. In the new extension target's **Signing & Capabilities**, add the
   same **Push Notifications** capability, and set its Bundle
   Identifier to `<your main bundle id>.OneSignalNotificationServiceExtension`.
5. Run `pod install` again from `ios/` after adding the target.

### 3.5 Build & test

```
flutter run --release   # release build recommended, see note below
```

- **iOS Simulators do not support push notifications at all** — you
  must test on a physical iPhone/iPad.
- In debug builds, tapping a push notification while the app is fully
  force-closed can fail to fire `NotificationNavigator`'s click
  handler at all (a known OneSignal SDK/Xcode debug-mode limitation,
  not a bug in this app's code). Use a release build for that specific
  test case.

---

## 4. Quick Reference

| Step | Android | iOS |
|---|---|---|
| Push credentials | Firebase Service Account JSON → OneSignal dashboard | APNs `.p8` key → OneSignal dashboard |
| Native project file changes | None (icon PNGs only) | Entitlements + Info.plist (via Xcode capabilities) |
| Extra install step | None | `pod install` in `ios/` |
| Icon/branding | `ic_stat_onesignal_default.png` in 5 `drawable-*dpi/` folders | Uses your app's existing app icon — no separate push icon |
| Optional rich media | N/A (large images work by default) | Notification Service Extension target |
| Where to test | Physical device or emulator | Physical device only (no simulator support) |

---

## 5. Already done in the Flutter code

For reference — nothing further needed here:

- `pubspec.yaml` — `onesignal_flutter` dependency added
- `lib/core/network/env.dart` — `Env.oneSignalAppId` placeholder
- `lib/core/services/notification_push_service.dart` — SDK init,
  permission request, foreground/click listeners
- `lib/core/session/session_manager.dart` — external user id
  registered on login, removed on logout
- `lib/main.dart` — fire-and-forget init alongside the app's other
  startup services
