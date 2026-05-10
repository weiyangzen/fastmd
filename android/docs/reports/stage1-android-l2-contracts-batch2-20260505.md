# Stage 1 Android L2 Contracts Batch 2 Report - 2026-05-05

## Scope

Implemented the next bounded Android-owned L2 core contract batch under `android/core/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, or `Docs/todos_20260505.md`.

## Blueprint Items Advanced

- L2: Define link policy model with allowed, confirm, and blocked decisions.
- L2: Define platform performance profile model for Android and iOS.
  - Android-side implementation is complete for Watch Compact, Legacy Efficient, Modern Standard, and Large Screen profile selection.
  - The supervisor should only mark the full cross-platform checklist item complete if iOS-side reconciliation is already covered elsewhere.
- L2: Define local/offline rich renderer asset policy for any JS/CSS/font dependencies.

## Changed Files

- `android/core/src/main/java/com/fastmd/mobile/core/link/LinkPolicy.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/performance/AndroidPerformanceProfile.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt`
- `android/docs/reports/stage1-android-l2-contracts-batch2-20260505.md`

## Implementation Notes

- Added `LinkTarget`, `LinkPolicy`, and `LinkPolicyDecision` to model internal allowed links, confirm-before-open external links, and blocked dangerous schemes.
- Default link decisions block `javascript:`, `data:`, `file:`, `content:`, `intent:`, `android-app:`, and `vbscript:` schemes.
- Added Android profile inputs and selector contracts for Stage 1 device classes:
  - `WatchCompact`
  - `LegacyEfficient`
  - `ModernStandard`
  - `LargeScreen`
- Profile contracts encode Stage 1 behaviors such as compact spacing, animation reduction, file-size soft limits, remote-media disabled by default, and fallback preference for heavy rich blocks.
- Added local rich renderer asset contracts for Mermaid/math-only rich surfaces.
- Renderer asset policy requires platform-local relative asset paths under `fastmd-renderers/`, optional SHA-256 hashes, and blocked network requests, external navigation, `javascript:` URLs, `data:` URLs, iframes, and remote subresources.
- No WebView implementation or renderer dependency was introduced in this batch.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :core:testDebugUnitTest` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `git diff --check -- android` | PASS | No whitespace errors were reported for tracked Android diffs. |
| `find android -path 'android/.gradle' -prune -o -path 'android/build' -prune -o -type f -print0 \| xargs -0 perl -ne 'if(/[ \t]$/){print "$ARGV:$.: trailing whitespace\n"; $bad=1} END{exit($bad ? 1 : 0)}'` | PASS | No trailing whitespace found in Android files outside local Gradle/build output. |
| `rg -n "INTERNET\|MANAGE_EXTERNAL_STORAGE\|READ_EXTERNAL_STORAGE\|READ_MEDIA_\|POST_NOTIFICATIONS\|WebView\|http://\|https://" android/app/src/main android/core/src/main android/feature -S` | PASS | Matches were only Android XML namespace declarations in launcher drawables/manifests; no broad storage, notification, network permission, or WebView usage was found. |

## Current Blockers

- Android SDK is still not configured through `ANDROID_HOME` or `android/local.properties`, so Android compile/unit-test tasks cannot run.
- No checked-in Android Gradle wrapper exists under `android/`, so required wrapper-based validation remains blocked.
- The shell `java -version` still cannot locate a Java runtime, while global Gradle can run through its own configured runtime.

## Supervisor Reconciliation Notes

The supervisor can mark the link policy and local/offline renderer asset policy L2 items complete for the Android lane based on the implementation files and unit-test coverage added in this batch.

For the platform performance profile L2 item, Android-side implementation evidence is complete in `android/core/src/main/java/com/fastmd/mobile/core/performance/AndroidPerformanceProfile.kt` and `android/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt`. If the authoritative checklist treats this item as requiring both platforms in one checkbox, leave it open until the iOS lane records matching evidence.
