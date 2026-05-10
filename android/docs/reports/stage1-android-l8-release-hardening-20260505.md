# Stage 1 Android L8 Release Hardening Report - 2026-05-05

## Scope

Implemented one bounded Android-owned L8 release/security hardening batch under `android/**`.

This batch did not edit `ios/**`, `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, or `.cron/**`.

## Blueprint Items Advanced

- L8: Document Android R8/release hardening posture.
- L8: If Android WebView rich rendering is used, load vendored local assets only and block network requests.

## Changed Files

- `android/app/build.gradle.kts`
- `android/app/proguard-rules.pro`
- `android/app/src/main/AndroidManifest.xml`
- `android/tools/audit_stage1_manifest.sh`
- `android/docs/reports/stage1-android-l8-release-hardening-20260505.md`

## Implementation Notes

- Added an explicit Android `release` build type in `app/build.gradle.kts`.
- Release output is explicitly non-debuggable with `isDebuggable = false`.
- Release output enables R8 code shrinking with `isMinifyEnabled = true`.
- Release output enables resource shrinking with `isShrinkResources = true`.
- Release output uses Android's optimized default ProGuard file plus the app-local `app/proguard-rules.pro`.
- Added `app/proguard-rules.pro` with an intentionally narrow Stage 1 posture: no broad keep rules are added until a release validation failure proves they are needed.
- Set `android:usesCleartextTraffic="false"` in the app manifest as defense in depth even though Stage 1 still requests no `INTERNET` permission.
- Strengthened `tools/audit_stage1_manifest.sh` so the repeatable Android audit now verifies:
  - no permissions are declared;
  - no broad storage, notification, or default `INTERNET` permission is present;
  - `allowBackup=false`;
  - cleartext traffic is disabled;
  - only `MainActivity` is exported;
  - no Android WebView implementation is present in Stage 1 main code;
  - release hardening enables non-debuggable output, R8 minify, resource shrinking, Android optimized ProGuard defaults, and app-local ProGuard rules.
- No Android WebView rich renderer is currently used. The audit continues to fail if `WebView` or `android.webkit` appears in Stage 1 main code without a separate renderer request-blocking gate, so the conditional WebView local-assets/network-blocking item is not applicable for the current implementation.
- No React Native, Flutter, Cordova, remote WebView shell, JavaScript renderer, CDN/network renderer, broad storage permission, notification permission, or default Internet permission was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `bash -n tools/audit_stage1_manifest.sh` | PASS | Bash syntax validation completed with no output. |
| `bash tools/audit_stage1_manifest.sh` | PASS | Reported no permissions, no broad storage/notification/default `INTERNET`, `allowBackup=false`, cleartext disabled, only `MainActivity` exported, no WebView implementation, and release R8/resource shrinking/non-debuggable posture present. |
| `gradle projects` | PASS | Build succeeded and listed `:app`, `:core`, `:feature:library`, `:feature:reader`, and `:feature:settings`. |
| `gradle :app:assembleRelease` | BLOCKED | Gradle reached `:app:minifyReleaseWithR8` dependency resolution, then stopped because Android SDK location is not configured: `SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/Users/wangweiyang/GitHub/fastmd/android/local.properties'.` |
| `java -version` | BLOCKED | `/usr/bin/java` reported: `Unable to locate a Java Runtime.` |
| `test -x ./gradlew && ./gradlew projects || printf 'gradlew missing or not executable\n'` | BLOCKED | No checked-in Android Gradle wrapper exists under `android/`: `gradlew missing or not executable`. |
| `git diff --check -- android/app/build.gradle.kts android/app/proguard-rules.pro android/app/src/main/AndroidManifest.xml android/tools/audit_stage1_manifest.sh` | PASS | No whitespace errors were reported. The Android tree is currently untracked in this workspace, so tracked diff output is not available until it is added to Git. |
| `perl -ne 'print "$ARGV:$.: trailing whitespace\n" if /[ \t]$/' app/build.gradle.kts app/proguard-rules.pro app/src/main/AndroidManifest.xml tools/audit_stage1_manifest.sh` | PASS | No trailing whitespace was reported in this batch's touched Gradle, ProGuard, manifest, or script files. |
| `rg -n "<uses-permission\|MANAGE_EXTERNAL_STORAGE\|READ_EXTERNAL_STORAGE\|READ_MEDIA_\|POST_NOTIFICATIONS\|INTERNET\|android:allowBackup=\"true\"\|WebView\|android.webkit\|ReactNative\|Flutter\|Cordova" android/app/src/main android/core/src/main android/feature android/app/build.gradle.kts android/tools/audit_stage1_manifest.sh -S` | PASS | Matches were limited to the audit script's own policy checks; no forbidden implementation or manifest usage was found. |

## Current Blockers

- Android SDK remains unavailable to Gradle because neither `ANDROID_HOME` nor `android/local.properties` with `sdk.dir` is configured.
- The checked-in Android Gradle wrapper is still absent under `android/`.
- `/usr/bin/java` still cannot locate a system Java runtime, although the installed `gradle` command can run `gradle projects` through its own runtime path.
- Release assembly, lint, unit tests, instrumentation tests, and device validation remain blocked by the SDK/JDK/wrapper setup above.

## Supervisor Reconciliation Notes

The supervisor can use this report as Android-lane evidence for the following L8 item, subject to rerunning release/device gates after Android SDK/JDK/wrapper setup is repaired:

- Document Android R8/release hardening posture.

The conditional Android WebView rich-rendering checklist item can be treated as not applicable for the current Stage 1 Android implementation because no Android WebView renderer is used. If a future Android rich renderer adds WebView or `android.webkit`, keep that checklist item open until local asset packaging and request-blocking tests are implemented.

Keep L11 and L12 execution gates open until Android SDK/JDK/wrapper setup allows release assembly, unit test, lint, assemble, and device validation tasks to run.
