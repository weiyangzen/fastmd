# Stage 1 Android L11 Renderer Source-Set Asset Gate

Date: 2026-05-06

## Scope

This bounded Android live-lane batch advanced the Android portion of the L11
conditional renderer asset gates. It did not edit `ios/**`, shared `Docs/**`,
or `.cron/**`.

The current Android app still has no Android `WebView` / `android.webkit`
implementation and no vendored JS/CSS/font renderer asset tree. The batch
hardens the future-asset gate so renderer assets in any Android source set are
discovered, while still allowing only the app-local main source-set root:

```text
app/src/main/assets/fastmd-renderers
```

## Changes

- Updated `tools/audit_renderer_assets.sh` to scan `*/src/*/assets/fastmd-renderers`
  instead of only `*/src/main/assets/fastmd-renderers`.
- Preserved the allowlist that permits only
  `app/src/main/assets/fastmd-renderers`.
- Added a regression fixture in `tools/test_renderer_asset_audit.sh` proving
  that `app/src/debug/assets/fastmd-renderers` fails the gate, even with a
  valid SHA-256 manifest.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android `WebView` / `android.webkit` implementation, no React Native/Flutter/Cordova/equivalent runtime dependency, and no vendored JS/CSS/font renderer asset tree are present. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Regression harness passed native fallback, valid app-main local JS/CSS/font assets, missing manifest, misplaced module assets, new non-main source-set assets, remote/content/protocol-relative/encoded/double-encoded dangerous references, external navigation APIs, network-capable APIs, stale/unlisted/escaping/self-hashing/malformed manifests, WebView marker failure, and React Native dependency failure. |
| `bash -n tools/audit_renderer_assets.sh` | PASS | Bash syntax validation completed with no output. |
| `bash -n tools/test_renderer_asset_audit.sh` | PASS | Bash syntax validation completed with no output. |
| `./gradlew projects` | BLOCKED | The local machine reported: `The operation couldn’t be completed. Unable to locate a Java Runtime.` Gradle-backed validation remains open until a Java runtime/JDK is available. |

## Supervisor Checklist Evidence

These Android-side checklist items have evidence for supervisor reconciliation:

- L11: Add local renderer packaging/offline tests if JS renderer assets are
  used, Android portion.
  - Evidence: `bash tools/test_renderer_asset_audit.sh` passes valid local
    app-main renderer assets and fails remote/offline-unsafe asset references.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer
  surfaces are used, Android portion.
  - Evidence: no Android WebView surface is present; the audit and regression
    harness fail if a WebView marker appears before request-blocking coverage
    exists.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font
  assets are vendored, Android portion.
  - Evidence: SHA-256 manifest success and failure cases pass, including
    missing, stale, unlisted, escaping, self-hashing, malformed, misplaced
    module-root, and non-main source-set renderer asset cases.
- L13: Record validation reports under `android/docs/reports/`.
  - Evidence: this report.

## Open Validation

Gradle validation remains blocked in this local environment by the missing Java
runtime. Do not mark Android Gradle-backed L12 items complete from this batch.
