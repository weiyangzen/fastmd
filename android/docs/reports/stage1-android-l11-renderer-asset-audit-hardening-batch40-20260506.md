# Stage 1 Android L11 Renderer Asset Audit Hardening Batch 40

Date: 2026-05-06

## Scope

- Android-owned files only.
- Hardened the local renderer asset audit for the conditional L11 JS/CSS/font renderer gates.
- No vendored renderer asset tree is currently present in `app/src/main/assets/fastmd-renderers`, so Android rich Markdown remains on native Compose fallback paths for Stage 1.

## Implementation Evidence

- `tools/audit_renderer_assets.sh`
  - Extends the renderer asset network-capable API scan to reject dynamic `import(...)`, `Worker(...)`, `SharedWorker(...)`, `ServiceWorker`, and `navigator.serviceWorker` usage inside packaged renderer assets.
- `tools/test_renderer_asset_audit.sh`
  - Adds a regression fixture where `renderer-assets.lock` exists but is omitted from `renderer-assets.sha256`; the audit must fail it.
  - Adds regression fixtures for dynamic import and worker APIs inside packaged renderer JavaScript; the audit must fail them.

## Validation

### `bash tools/audit_renderer_assets.sh`

Result: PASS

Key output:

```text
PASS: No Android WebView or android.webkit implementation is present.
PASS: No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.
PASS: No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.
```

### `bash tools/test_renderer_asset_audit.sh`

Result: PASS

Key new regression output:

```text
PASS: renderer asset metadata lock must be included in hash manifest
PASS: renderer assets with dynamic import APIs fail
PASS: renderer assets with worker APIs fail
```

The full run also revalidated existing pass/fail fixtures for native fallback, app-local JS/CSS/font assets with SHA-256 manifests, missing manifests, missing metadata locks, misplaced assets, non-main source-set assets, remote/content/protocol-relative/encoded/double-encoded dangerous URLs, external navigation APIs, HTML meta refresh/form navigation, stale hashes, malformed manifests, malformed metadata, WebView presence, and React Native dependency presence.

### `java -version`

Result: BLOCKED

Exact blocker:

```text
The operation couldn’t be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

### `./gradlew projects`

Result: BLOCKED

Exact blocker:

```text
The operation couldn’t be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

### `./gradlew stage1AndroidRendererAssetGates`

Result: BLOCKED

Exact blocker:

```text
The operation couldn’t be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

## Supervisor Checklist Candidates

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: `tools/audit_renderer_assets.sh`, `tools/test_renderer_asset_audit.sh`, this report.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Android evidence: `tools/audit_renderer_assets.sh` currently fails any Android `WebView`/`android.webkit` implementation until a request-blocking gate exists; no Android WebView surface is present in Stage 1 main code.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: `tools/audit_renderer_assets.sh`, `tools/test_renderer_asset_audit.sh`, especially the added `renderer-assets.lock` omission regression.
- L13: Record validation reports under `android/docs/reports/`.
  - Evidence: this report.

## Open Validation Blockers

- L12 Gradle-backed Android validation remains open because the host has no discoverable Java runtime.
- Device-backed Android validation remains open; no connected API 27, small-screen/low-memory, or modern Android device run was performed in this batch.
