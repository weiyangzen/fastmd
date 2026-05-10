#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

failure=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failure=1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

manifest_paths=(
  app/src/main/AndroidManifest.xml
  core/src/main/AndroidManifest.xml
  feature/reader/src/main/AndroidManifest.xml
  feature/library/src/main/AndroidManifest.xml
  feature/settings/src/main/AndroidManifest.xml
)

if rg -n '<uses-permission' "${manifest_paths[@]}"; then
  fail 'Stage 1 Android manifests must not request runtime or install-time permissions.'
else
  pass 'No uses-permission declarations are present.'
fi

if rg -n 'MANAGE_EXTERNAL_STORAGE|READ_EXTERNAL_STORAGE|READ_MEDIA_|POST_NOTIFICATIONS|INTERNET' "${manifest_paths[@]}"; then
  fail 'Broad storage, notification, or default network permissions are present.'
else
  pass 'No broad storage, notification, or default INTERNET permission is present.'
fi

if rg -n 'android:allowBackup="true"' "${manifest_paths[@]}"; then
  fail 'allowBackup=true is not allowed for Stage 1.'
elif rg -q 'android:allowBackup="false"' app/src/main/AndroidManifest.xml; then
  pass 'App manifest documents Stage 1 backup posture with allowBackup=false.'
else
  fail 'App manifest must explicitly set android:allowBackup="false".'
fi

if rg -q 'android:usesCleartextTraffic="false"' app/src/main/AndroidManifest.xml; then
  pass 'App manifest disables cleartext network traffic.'
else
  fail 'App manifest must explicitly set android:usesCleartextTraffic="false".'
fi

exported_matches="$(rg -n 'android:exported="true"' "${manifest_paths[@]}" || true)"
exported_count="$(printf '%s\n' "$exported_matches" | sed '/^$/d' | wc -l | tr -d ' ')"
if [ "$exported_count" = "1" ] && rg -q 'android:name=".MainActivity"' app/src/main/AndroidManifest.xml; then
  pass 'Only the document-entry MainActivity is exported.'
else
  fail "Unexpected exported component count: ${exported_count}."
fi

if rg -n 'WebView|android.webkit' app/src/main/java core/src/main/java feature; then
  fail 'WebView usage requires the separate local renderer request-blocking gate.'
else
  pass 'No Android WebView implementation is present in Stage 1 main code.'
fi

if rg -q 'release \{' app/build.gradle.kts &&
  rg -q 'isDebuggable = false' app/build.gradle.kts &&
  rg -q 'isMinifyEnabled = true' app/build.gradle.kts &&
  rg -q 'isShrinkResources = true' app/build.gradle.kts &&
  rg -q 'proguard-android-optimize.txt' app/build.gradle.kts &&
  rg -q 'proguard-rules.pro' app/build.gradle.kts &&
  test -f app/proguard-rules.pro; then
  pass 'Release build type enables R8 minify, resource shrinking, non-debuggable output, and app ProGuard rules.'
else
  fail 'Release build type must document R8 minify, resource shrinking, non-debuggable output, and app ProGuard rules.'
fi

if [ "$failure" -ne 0 ]; then
  exit 1
fi
