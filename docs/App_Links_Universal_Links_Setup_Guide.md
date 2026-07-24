# Invite Links — App Links / Universal Links Setup Guide

This covers the backend/hosting side needed so `https://app.tbh.com/i/{token}`
opens the TBH app directly instead of a browser. The Flutter app side
(`DeepLinkService`, the Android manifest `intent-filter`, and the iOS
`Runner.entitlements`) is already done — this guide is only about the two
files your web server needs to serve.

Two identifiers from the app are used below:

| Platform | Identifier                     | Value               |
| -------- | ------------------------------ | ------------------- |
| Android  | Package name (`applicationId`) | `com.jargon.tbh`    |
| iOS      | Bundle ID                      | `com.jargon.tbhApp` |

---

## 1. Android — `assetlinks.json`

### 1.1 What it does

Tells Android "the app with this package name and signing certificate is
authorized to handle links on this domain." Without it, tapping an invite
link opens a browser (or a chooser) instead of the app.

### 1.2 Get your app's SHA-256 signing certificate fingerprint

You need the fingerprint of the **release** keystore you sign the Play
Store build with (a debug-keystore fingerprint only works for links opened
on devices running debug builds).

```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
```

You'll be prompted for the keystore password. Look for a line like:

```
SHA256: 14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A3:D4:43:7A:42:C6:04:52:65:8F:...
```

Copy that value (keep the colons — they belong in the JSON, but see note
below on format).

> If you use **Play App Signing** (recommended — this is the default for
> new apps), Google re-signs your app before distribution, so the
> fingerprint that matters is the one shown in **Play Console → your app →
> Setup → App integrity → App signing key certificate**, not your local
> upload keystore. Use that one instead.

If you have more than one signing key in play (e.g. separate debug and
release), you can list multiple fingerprints in the same file — see 1.4.

### 1.3 Create `assetlinks.json`

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.jargon.tbh",
      "sha256_cert_fingerprints": [
        "14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A3:D4:43:7A:42:C6:04:52:65:8F:XX:XX:XX:XX:XX:XX"
      ]
    }
  }
]
```

Replace the fingerprint with your real one from step 1.2.

### 1.4 (Optional) Support multiple builds/keys

If QA/staging builds are signed with a different key than production, add
more entries to the array, or more fingerprints to the same entry:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.jargon.tbh",
      "sha256_cert_fingerprints": [
        "AA:BB:...  <- Play App Signing key (production)",
        "CC:DD:...  <- your local debug/upload key, if needed"
      ]
    }
  }
]
```

### 1.5 Host it

Upload the file so it's reachable at exactly:

```
https://app.tbh.com/.well-known/assetlinks.json
```

Requirements:

- Must be served over **HTTPS** (no redirects — a 301/302 to another URL
  will fail verification).
- Must respond with `Content-Type: application/json`.
- Must return **HTTP 200** directly at that path (not behind a login wall,
  not requiring cookies).
- No robots.txt rule should block `/.well-known/`.

### 1.6 Verify

```bash
curl -i https://app.tbh.com/.well-known/assetlinks.json
```

Confirm status `200`, `Content-Type: application/json`, and valid JSON
body. You can also use Google's own validator:

```
https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://app.tbh.com&relation=delegate_permission/common.handle_all_urls
```

Paste that URL in a browser — it should return your `target` block back.

### 1.7 Confirm the app manifest side is already correct

Already done in the app, for reference — this is what makes Android look
for the file above:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data
        android:scheme="https"
        android:host="app.tbh.com"
        android:pathPrefix="/i"/>
</intent-filter>
```

### 1.8 Test end-to-end

1. Install a fresh build (App Links verification is checked at install
   time, and can be cached — see the ADB command below to force it).
2. Force Android to re-verify:
   ```bash
   adb shell pm verify-app-links --re-verify com.jargon.tbh
   ```
3. Check the result:
   ```bash
   adb shell pm get-app-links com.jargon.tbh
   ```
   You want to see `app.tbh.com` listed under `verified`, not `legacy_failure`
   or `none`.
4. Send yourself a real link (e.g. via a messaging app — typing it into
   Chrome's address bar does **not** trigger App Links) and confirm it
   opens the app directly, for:
   - Cold start (app not running / recently killed)
   - Warm start (app in background)
   - App already open in foreground

---

## 2. iOS — `apple-app-site-association` (AASA)

### 2.1 What it does

The iOS equivalent of `assetlinks.json` — tells iOS "this domain is
associated with this app," authorizing Universal Links.

### 2.2 Find your Apple Team ID

**Apple Developer account → Membership** (or **Xcode → your project →
Signing & Capabilities → Team**). It's a 10-character alphanumeric string,
e.g. `A1B2C3D4E5`.

### 2.3 Create the AASA file

File name is exactly `apple-app-site-association` — **no extension**.

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "A1B2C3D4E5.com.jargon.tbhApp",
        "paths": ["/i/*"]
      }
    ]
  }
}
```

Replace `A1B2C3D4E5` with your real Team ID. `appID` is always
`{TeamID}.{BundleID}` — the Bundle ID here (`com.jargon.tbhApp`) matches
`PRODUCT_BUNDLE_IDENTIFIER` in the Xcode project.

`"paths": ["/i/*"]` restricts Universal Links to invite links only —
any other path on `app.tbh.com` opens normally in Safari, which is what
you want.

> Newer format note: Apple's current docs also accept a top-level
> `"appIDs"` array (plural) as a forward-compatible alternative to
> `"appID"` inside `details`. Either is fine for a single app; the format
> above is the one that's been stable the longest and works everywhere.

### 2.4 Host it

Upload so it's reachable at **both** of these (serve the identical file
at both paths — iOS checks the `.well-known` location first, then falls
back to the root):

```
https://app.tbh.com/.well-known/apple-app-site-association
https://app.tbh.com/apple-app-site-association
```

Requirements:

- **HTTPS only**, no redirects.
- Content-Type should be `application/json` (some setups use
  `application/pkcs7-mime` for a signed AASA — plain JSON over HTTPS is
  sufficient and simpler; you don't need to sign it).
- Must return **HTTP 200**, no auth wall.
- File must be under ~128KB (yours is tiny, so not a concern).
- **No file extension** — if your static host insists on adding `.json`,
  configure a rewrite/alias so the URL itself has no extension.

### 2.5 Verify

```bash
curl -i https://app.tbh.com/.well-known/apple-app-site-association
```

Confirm `200` and valid JSON. Apple also provides a validator:

```
https://search.developer.apple.com/appsearch-validation-tool/
```

Enter `https://app.tbh.com` there to check it.

### 2.6 Confirm the app entitlement side is already correct

Already done in the app, for reference — this is what makes iOS look for
the file above:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:app.tbh.com</string>
</array>
```

(In `ios/Runner/Runner.entitlements`, wired into the Xcode build settings
for Debug/Release/Profile.)

### 2.7 Test end-to-end

iOS caches the AASA file aggressively and only re-fetches it in limited
circumstances, so:

1. Install the build via TestFlight or Xcode (Universal Links
   verification largely does not work reliably in the Simulator — test on
   a **physical device**).
2. If you change the AASA file after already installing the app once,
   iOS may not notice until you delete and reinstall the app, or:
   - Settings → General → VPN & Device Management (or reboot the device),
   - or wait — iOS periodically re-fetches AASA files in the background.
3. Send yourself a real link via Messages/Mail/Notes (typing into Safari's
   address bar does **not** trigger Universal Links) and confirm it opens
   the app directly for cold start, warm start, and already-open cases.
4. If it keeps opening Safari instead of the app:
   - Long-press the link → confirm there's an "Open in TBH" option
     (if absent, the AASA association didn't verify).
   - Double check `paths` matches the real invite path (`/i/<token>`,
     not `/invite/<token>` or similar).
   - Double check the Team ID and Bundle ID are exactly right — a typo
     here fails silently (no error, links just never open the app).

---

## 3. Quick checklist

- [ ] Android release/Play-signing SHA-256 fingerprint obtained
- [ ] `assetlinks.json` created and hosted at
      `https://app.tbh.com/.well-known/assetlinks.json` (200, JSON, HTTPS, no redirect)
- [ ] `adb shell pm get-app-links com.jargon.tbh` shows `app.tbh.com` as `verified`
- [ ] Apple Team ID obtained
- [ ] `apple-app-site-association` created and hosted at both
      `https://app.tbh.com/.well-known/apple-app-site-association` and
      `https://app.tbh.com/apple-app-site-association` (200, no extension, HTTPS, no redirect)
- [ ] Real invite link tested on a physical iOS device — opens app, not Safari
- [ ] Real invite link tested on Android — opens app, not chooser/browser
- [ ] Both tested for cold start, warm start, and app-already-open

Until both files are live and verified, invite links will simply open in
the browser instead of the app — everything else (link generation, share
sheet, token storage, and attaching the token at registration) already
works regardless, since that logic lives entirely in the app and backend,
not in the link-verification step.
