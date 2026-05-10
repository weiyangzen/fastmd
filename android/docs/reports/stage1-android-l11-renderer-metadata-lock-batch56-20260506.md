# Stage 1 Android L11 Renderer Metadata Lock Batch 56

Date: 2026-05-06
Lane: Android live lane
Scope: `android/**`

## Batch Selection

This bounded batch advanced the earliest still-open Android-owned L11 renderer gate
cluster without touching iOS, shared `Docs/**` checklist files, or `.cron/**`.

Target checklist area:

- L11 conditional local renderer packaging/offline tests if JS renderer assets are used.
- L11 conditional renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

The current Android implementation still has no vendored JS/CSS/font renderer asset
tree and no Android `WebView`/`android.webkit` renderer surface. Mermaid and math
remain native readable fallback cards.

## Implementation Evidence

- `core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
  - Added `LocalRendererAssetMetadataEntry`.
  - Added `LocalRendererAssetMetadataLock`.
  - Parses future `renderer-assets.lock` lines in the Android core contract format:
    `path|upstream name|upstream version|license notes|sha256`.
  - Requires clean renderer-relative paths, nonblank metadata fields, lowercase
    SHA-256 hashes, no duplicate metadata paths, no description of
    `renderer-assets.sha256`, and no description of `renderer-assets.lock` itself.
  - Verifies the metadata lock against `LocalRendererAssetManifest`, so every
    manifest-listed renderer asset has metadata, no extra metadata path exists,
    and lock hashes match manifest hashes.
- `core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
  - Added positive coverage for metadata lock parsing and manifest verification.
  - Added negative coverage for malformed lock lines, duplicate paths, path
    traversal, percent-escaped paths, root-prefixed paths, padded paths, blank
    metadata fields, padded metadata fields, extra pipe-delimited fields,
    manifest-file entries, uppercase hashes, missing metadata, unlisted metadata,
    and mismatched metadata hashes.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `bash -n tools/audit_renderer_assets.sh && bash -n tools/audit_renderer_request_blocking.sh && bash -n tools/test_renderer_asset_audit.sh` | PASS | All renderer audit shell scripts parsed successfully. |
| `bash tools/audit_renderer_assets.sh && bash tools/audit_renderer_request_blocking.sh && bash tools/test_renderer_asset_audit.sh` | PASS | Confirmed no Android WebView/android.webkit implementation, no web runtime dependency, no vendored JS/CSS/font renderer asset tree, request-policy coverage, and fail-closed synthetic asset cases for local manifests, metadata locks, remote/dangerous references, network APIs, WebView markers, and React Native markers. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew projects --no-daemon` | PASS | `BUILD SUCCESSFUL in 12s`; module graph included root `fastmd-android`, `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:testDebugUnitTest --no-daemon` | BLOCKED | Main and test Kotlin compilation ran through the changed core/test sources after the known Kotlin daemon fallback from `IllegalArgumentException: 25.0.1`. The task then failed resolving AndroidX runtime jars from Google Maven: `androidx.collection:collection-ktx:1.4.0` and `androidx.concurrent:concurrent-futures:1.1.0` timed out from `https://dl.google.com/dl/android/maven2/...`. This is a dependency download blocker, not a Kotlin source failure. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew stage1AndroidRendererAssetGates --no-daemon` | PASS | `BUILD SUCCESSFUL in 52s`; ran `auditRendererAssets`, `auditRendererRequestBlocking`, `testRendererAssetAudit`, and `stage1AndroidRendererAssetGates`. |
| `JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.17/libexec/openjdk.jdk/Contents/Home ./gradlew :core:compileDebugUnitTestKotlin --no-daemon` | PASS | `BUILD SUCCESSFUL in 16s`; focused Kotlin unit-test compilation for the changed core contract was up to date after the blocked full unit-test attempt compiled sources. |

## Checklist Evidence For Supervisor

The supervisor can use this Android evidence for:

- L11 `Add local renderer packaging/offline tests if JS renderer assets are used.`
  Evidence: `android/tools/test_renderer_asset_audit.sh`,
  `android/tools/audit_renderer_assets.sh`, and Gradle
  `stage1AndroidRendererAssetGates` continue to pass for the native fallback path
  and synthetic app-local JS/CSS/font renderer fixtures.
- L11 `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  Evidence: `LocalRendererAssetManifest`, new `LocalRendererAssetMetadataLock`
  core contract coverage, `RichRendererAssetPolicyTest`, shell renderer asset
  audits, and Gradle `stage1AndroidRendererAssetGates`.
- L12 `Run Android ./gradlew projects.`
  Evidence: the JDK 17 wrapper command above passed and printed the expected module
  graph.

The supervisor should keep this Android L12 item open:

- L12 `Run Android ./gradlew :core:testDebugUnitTest.`
  Blocker: Google Maven timed out resolving `androidx.collection:collection-ktx:1.4.0`
  and `androidx.concurrent:concurrent-futures:1.1.0` from `dl.google.com:443`.

## Files Touched

- `android/core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt`
- `android/docs/reports/stage1-android-l11-renderer-metadata-lock-batch56-20260506.md`
