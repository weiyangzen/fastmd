# Stage 1 Android Core Contracts Report - 2026-05-05

## Scope

Implemented the first Android-owned L2 core contract batch under `android/core/**` only.

## Blueprint Items Advanced

- L2: Define shared mobile document handle model for platform document references.
- L2: Define Markdown load result model with file metadata, write capability, and source origin.
- L2: Define render model with stable block ids and source ranges.
- L2: Define four font tier model: Compact, Default, Large, Reader.
- L2: Define reader UI state model covering Empty, Loading, Rendering, Ready, Searching, EditingSource, EditingBlock, Saving, ReadOnly, PermissionLost, and Error.
- L2: Define structured error codes for open, read, parse, render, search, edit, save, link, permission, and security failures.

## Changed Files

- `android/core/src/main/java/com/fastmd/mobile/core/document/DocumentHandle.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/document/MarkdownLoadResult.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/error/FastMdErrorCode.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/reader/FontTier.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/reader/ReaderUiState.kt`
- `android/core/src/main/java/com/fastmd/mobile/core/render/MarkdownRenderModel.kt`
- `android/core/src/test/java/com/fastmd/mobile/core/contracts/CoreContractsTest.kt`
- `android/docs/reports/stage1-android-core-contracts-20260505.md`

## Implementation Notes

- Added an Android-side document handle contract with platform, reference kind, sanitized raw reference, permission grant, display metadata, size, and modified-time metadata.
- Added Markdown load success/failure contracts that carry source metadata, encoding, line ending, write capability, source origin, and structured failure codes.
- Added render contracts for stable block ids, one-based source line ranges, offsets, block kinds, contiguous ordinals, and source revisions.
- Added the Stage 1 four-tier font model with fixed base `sp` tiers and line-height multipliers from the blueprint.
- Added sealed reader UI states for the full Stage 1 reader lifecycle surface.
- Added structured error categories and codes spanning open, read, parse, render, search, edit, save, link, permission, and security failures.
- Added unit tests for the contract invariants and required model coverage.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :core:testDebugUnitTest` | BLOCKED | Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `./gradlew projects` | BLOCKED | No Gradle wrapper exists under `android/`: `gradlew missing`. |
| `git diff --check -- android` | PASS | No whitespace errors were reported for tracked Android diffs. |
| `kotlinc -version` | BLOCKED | `kotlinc` is not installed in the shell path. |

## Current Blockers

- Android SDK is still not configured through `ANDROID_HOME` or `android/local.properties`, so Android compile/unit-test tasks cannot run.
- No checked-in Android Gradle wrapper exists under `android/`, so required wrapper-based validation remains blocked.
- The shell `java -version` still cannot locate a Java runtime, while global Gradle can run through its own configured runtime.

## Supervisor Reconciliation Notes

The six L2 items listed above have implementation files and unit-test coverage added under `android/core/**`. The central checklist should only mark them complete if the supervising session accepts `gradle projects` plus the blocked SDK/JDK evidence as sufficient for this batch, or after rerunning `:core:testDebugUnitTest` in an environment with Android SDK/JDK 17 configured.
