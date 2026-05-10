# Stage 1 Android L11 Renderer Iframe/Srcdoc Gate Batch 41

Date: 2026-05-06

Scope:

- Android-owned files only.
- Hardened the Android local renderer asset regression gate for Stage 1 rich-block security.
- Did not edit `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `ios/**`.

Implementation:

- Updated `android/tools/test_renderer_asset_audit.sh`.
- Added negative renderer asset fixtures proving the audit rejects:
  - packaged HTML renderer assets containing `<iframe ...>`
  - packaged HTML renderer assets containing `srcdoc=...`

Checklist Evidence:

- L11 `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: `bash tools/test_renderer_asset_audit.sh` passed.
  - The suite validates native fallback with no vendored assets, valid app-local JS/CSS/font packaging with SHA-256 manifest and metadata lock, missing manifest/metadata failures, misplaced asset failures, stale hash failures, and unlisted packaged asset failures.
- L11 `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Android evidence: `bash tools/audit_renderer_assets.sh` passed with no Android `WebView` or `android.webkit` implementation present.
  - Regression evidence: `bash tools/test_renderer_asset_audit.sh` includes a failing fixture when Android WebView code appears before a request-blocking gate exists.
  - New hardening evidence: iframe and srcdoc renderer surfaces fail the audit.
- L11 `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: `bash tools/test_renderer_asset_audit.sh` passed.
  - The suite verifies valid SHA-256 manifests, metadata locks, metadata hashes, manifest path hygiene, self-hash rejection, malformed line rejection, and tamper detection.

Validation Commands:

```text
cd android && bash tools/audit_renderer_assets.sh
PASS
PASS: No Android WebView or android.webkit implementation is present.
PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.

cd android && bash tools/test_renderer_asset_audit.sh
PASS
Includes passing regression assertions for native fallback, app-local packaged assets, missing manifests, metadata locks, remote references, dangerous URL schemes, external navigation APIs, meta refresh, form navigation, iframe, srcdoc, network-capable browser APIs, dynamic import, worker APIs, tampered hashes, malformed manifests, WebView presence, and React Native dependency detection.

cd android && ./gradlew projects
BLOCKED
The operation could not be completed. Unable to locate a Java Runtime.

java -version
BLOCKED
The operation could not be completed. Unable to locate a Java Runtime.

/usr/libexec/java_home -V
BLOCKED
The operation could not be completed. Unable to locate a Java Runtime.
```

Platform Validation Status:

- Android script-level renderer asset validation passed.
- Gradle validation remains open because JDK 17, or any Java runtime visible to the shell, is missing in this environment.
- Device-backed validation was not attempted in this batch because Gradle cannot start.

Supervisor Reconciliation Notes:

- The Android side of the three conditional L11 renderer asset checklist items can be marked complete from this report if the supervisor accepts native fallback plus script-backed conditional gates as sufficient.
- L12 Gradle and device validation checklist items must remain open until a Java runtime and Android validation target are available.
