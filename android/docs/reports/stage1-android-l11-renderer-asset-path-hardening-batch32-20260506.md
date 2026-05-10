# Stage 1 Android L11 Renderer Asset Path Hardening Batch 32 - 2026-05-06

## Scope

This bounded Android live-lane batch advanced the earliest still-open
Android-owned checklist cluster in L11:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

No shared `Docs/**`, `ios/**`, or `.cron/**` files were edited.

## Implementation

Changed Android-local renderer asset audit coverage:

- `android/tools/audit_renderer_assets.sh`
  - Added `validate_renderer_asset_path` and applied it to every renderer hash
    manifest entry.
  - Applied the same validation to every packaged renderer asset found under a
    `fastmd-renderers` asset tree.
  - The audit now rejects blank paths, absolute paths, URI schemes, colons,
    whitespace/control characters, percent escapes, query markers, fragment
    markers, backslashes, blank path segments, `.` segments, and `..` segments.
  - This aligns the source-level packaging/hash audit with
    `LocalRendererAssetPath` in Android core code.
- `android/tools/test_renderer_asset_audit.sh`
  - Added regression cases proving the audit fails renderer asset manifests with
    parent-directory paths, dot segments, percent-escaped paths, and whitespace.
  - Added a regression case proving a packaged renderer asset with whitespace in
    its path fails even when it is not listed in the hash manifest.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `java -version` | BLOCKED | macOS reported `Unable to locate a Java Runtime.` The shell default Java remains unavailable. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android `WebView` or `android.webkit` implementation, no React Native/Flutter/Cordova web runtime dependency, and no vendored JS/CSS/font renderer asset tree is present. Native fallback remains the active Android rich-block path. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Existing renderer asset negative cases passed, plus the new path-hygiene cases for dot segments, percent escapes, whitespace in manifest paths, and whitespace in packaged asset paths. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew projects --no-daemon` | PASS | Gradle listed root project `fastmd-android` and modules `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`; `BUILD SUCCESSFUL in 4s`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Ran `auditRendererAssets`, `testRendererAssetAudit`, and `stage1AndroidRendererAssetGates`; `BUILD SUCCESSFUL in 15s`. |

## Blockers Preserved

- The default shell Java runtime is still unavailable, so wrapper commands require
  an explicit `JAVA_HOME` pointing at the Android Studio bundled JBR in this
  environment.
- This batch did not rerun `lint`, `build`, `:core:testDebugUnitTest`,
  `:feature:reader:testDebugUnitTest`, `:app:assembleDebug`, or device-backed
  validation gates. Prior Android reports preserve their network, Gradle task,
  SDK image, and device/emulator blockers.

## Supervisor Checklist Recommendation

The supervising session can use this report as Android evidence for marking:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L13: Record validation reports under `android/docs/reports/`.

Keep these Android L12 checklist items open from this batch:

- Run Android `./gradlew lint`.
- Run Android `./gradlew build`.
- Run Android `./gradlew :core:testDebugUnitTest`.
- Run Android `./gradlew :feature:reader:testDebugUnitTest`.
- Run Android `./gradlew :app:assembleDebug`.
- Run Android `./gradlew :app:connectedDebugAndroidTest`.
- Run Android API 27 validation.
- Run Android low-memory/small-screen profile validation.
- Run Android modern device validation.

## Files Changed

- `android/tools/audit_renderer_assets.sh`
- `android/tools/test_renderer_asset_audit.sh`
- `android/docs/reports/stage1-android-l11-renderer-asset-path-hardening-batch32-20260506.md`
