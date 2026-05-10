# Stage 1 Android L11 Renderer Required Hashes - 2026-05-06

## Scope

Android live-lane bounded batch for the earliest still-open Android-owned L11
renderer asset gate items:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are
  vendored.

The current Android implementation remains native Kotlin/Jetpack Compose and
does not vendor JS/CSS/font renderer assets. This batch hardens the Android core
contract so any future vendored rich renderer asset must carry a non-null
lowercase SHA-256 in addition to the existing script-level manifest and metadata
lock checks.

## Android Files Changed

- `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
- `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
- `core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt`
- `docs/reports/stage1-android-l11-renderer-required-hashes-20260506.md`

## Implementation Evidence

- Changed `LocalRendererAsset.sha256` from nullable `String?` to required
  `String`.
- Tightened `LocalRendererAsset` validation so every vendored renderer asset
  requires exactly 64 lowercase SHA-256 hex characters.
- Updated renderer policy tests so vendored JavaScript, CSS, and font fixtures
  must provide SHA-256 values.
- Updated the core contract test fixture so the vendored math CSS asset also
  carries a SHA-256.

This aligns the Kotlin model with `tools/audit_renderer_assets.sh`, which
already requires `renderer-assets.sha256` and `renderer-assets.lock` for any
future `app/src/main/assets/fastmd-renderers/` tree.

## Validation

| Command | Result | Notes |
| --- | --- | --- |
| `./gradlew projects --no-daemon` | BLOCKED | Default shell has no Java runtime on `PATH`: `Unable to locate a Java Runtime`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew projects --no-daemon` | PASS | Android project hierarchy resolved: `:app`, `:core`, `:feature:library`, `:feature:reader`, `:feature:settings`. |
| `bash tools/audit_renderer_assets.sh` | PASS | No Android WebView/android.webkit implementation, no React Native/Flutter/Cordova runtime dependency, and no vendored JS/CSS/font renderer asset tree are present. |
| `bash tools/test_renderer_asset_audit.sh` | PASS | Native fallback, app-local JS/CSS/font SHA-256 manifest success, missing/stale/malformed manifests, missing metadata lock, remote/dangerous references, network-capable APIs, WebView marker, and React Native marker cases behaved as expected. |
| `JAVA_HOME='/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home' ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | Ran `:auditRendererAssets`, `:testRendererAssetAudit`, and `:stage1AndroidRendererAssetGates`; build successful. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :core:testDebugUnitTest --tests 'com.fastmd.mobile.core.render.RichRendererAssetPolicyTest' --tests 'com.fastmd.mobile.core.contracts.CoreContractsTest' --no-daemon` | BLOCKED | Kotlin daemon first reported local Java version parser issue `IllegalArgumentException: 25.0.1`, then fallback compilation proceeded, but `:core:testDebugUnitTest` failed resolving runtime dependencies from Google Maven: `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` timed out connecting to `dl.google.com:443`. |
| `JAVA_HOME='/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home' ./gradlew :core:testDebugUnitTest --tests 'com.fastmd.mobile.core.render.RichRendererAssetPolicyTest' --tests 'com.fastmd.mobile.core.contracts.CoreContractsTest' --no-daemon` | BLOCKED | Same Google Maven dependency resolution timeout for `collection-ktx-1.4.0` and `concurrent-futures-1.1.0`. |
| `git diff --check -- android` | PASS | No whitespace errors reported for tracked Android diffs. |

## Supervisor Completion Candidates

- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font
  assets are vendored, Android portion.
  - Evidence: `LocalRendererAsset` now requires a SHA-256; Kotlin contract tests
    encode SHA-bearing vendored assets; `tools/test_renderer_asset_audit.sh` and
    `stage1AndroidRendererAssetGates` pass.
- L11: Add local renderer packaging/offline tests if JS renderer assets are
  used, Android portion.
  - Evidence: no renderer assets are currently used; native fallback passes; the
    script and Gradle gates verify future app-local renderer assets must stay
    offline, hashed, metadata-locked, and under `app/src/main/assets/fastmd-renderers/`.

Platform compile/unit validation remains open where it depends on downloading
missing AndroidX runtime jars from `dl.google.com`.
