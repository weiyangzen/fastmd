#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="${FASTMD_ANDROID_AUDIT_ROOT:-"${script_dir}/.."}"
cd "$repo_root"

failure=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failure=1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

require_file_contains() {
  local file="$1"
  local pattern="$2"
  local message="$3"

  if [ ! -f "$file" ]; then
    fail "Missing required file: ${file}."
    return
  fi

  if rg -n "$pattern" "$file" >/dev/null; then
    pass "$message"
  else
    fail "$message"
  fi
}

main_code_paths=(
  app/src/main/java
  core/src/main/java
  feature/reader/src/main/java
  feature/library/src/main/java
  feature/settings/src/main/java
)

existing_main_code_paths=()
for path in "${main_code_paths[@]}"; do
  if [ -e "$path" ]; then
    existing_main_code_paths+=("$path")
  fi
done

policy_file="core/src/main/java/com/fastmd/mobile/core/render/RichRendererAssetPolicy.kt"
policy_test_file="core/src/test/java/com/fastmd/mobile/core/render/RichRendererAssetPolicyTest.kt"

require_file_contains "$policy_file" "object RichRendererRequestPolicy" \
  "Renderer request policy is a first-class Android core contract."
require_file_contains "$policy_file" "RichRendererRequestKind\\.Iframe" \
  "Renderer request policy has an explicit iframe request class."
require_file_contains "$policy_file" "NetworkRequest" \
  "Renderer request policy has an explicit network-request block reason."
require_file_contains "$policy_file" "ExternalNavigation" \
  "Renderer request policy has an explicit external-navigation block reason."
require_file_contains "$policy_file" "JavascriptUrl" \
  "Renderer request policy has an explicit javascript: URL block reason."
require_file_contains "$policy_file" "DataUrl" \
  "Renderer request policy has an explicit data: URL block reason."
require_file_contains "$policy_file" "ContentUri" \
  "Renderer request policy has an explicit content URI block reason."
require_file_contains "$policy_file" "NonRendererFile" \
  "Renderer request policy has an explicit non-renderer-file block reason."
require_file_contains "$policy_test_file" "requestPolicyAllowsOnlyBundledRendererAssets" \
  "Unit tests cover allowlisting of bundled Android renderer assets."
require_file_contains "$policy_test_file" "renderer-assets\\.lock" \
  "Unit tests cover blocking renderer metadata lock file requests."
require_file_contains "$policy_test_file" "requestPolicyBlocksRemoteAndDangerousRendererRequests" \
  "Unit tests cover remote and dangerous renderer request blocking."
require_file_contains "$policy_test_file" "requestPolicyClassifiesPercentEncodedDangerousRendererRequests" \
  "Unit tests cover percent-encoded dangerous renderer requests."
require_file_contains "$policy_test_file" "requestPolicyBlocksExternalNavigationAndIframes" \
  "Unit tests cover external navigation and iframe blocking."

if [ "${#existing_main_code_paths[@]}" -eq 0 ]; then
  fail 'No Android main source paths were found for renderer request-blocking audit.'
elif rg -n 'WebView|android\.webkit' "${existing_main_code_paths[@]}" >/tmp/fastmd-webview-scan.out 2>&1; then
  cat /tmp/fastmd-webview-scan.out

  if rg -n 'RichRendererRequestPolicy\.decide' "${existing_main_code_paths[@]}" >/dev/null; then
    pass 'WebView renderer code routes requests through RichRendererRequestPolicy.'
  else
    fail 'WebView renderer code must route every request through RichRendererRequestPolicy.decide.'
  fi

  if rg -n 'shouldInterceptRequest' "${existing_main_code_paths[@]}" >/dev/null; then
    pass 'WebView renderer code defines shouldInterceptRequest.'
  else
    fail 'WebView renderer code must define shouldInterceptRequest to block network and non-renderer subresources.'
  fi

  if rg -n 'shouldOverrideUrlLoading' "${existing_main_code_paths[@]}" >/dev/null; then
    pass 'WebView renderer code defines shouldOverrideUrlLoading.'
  else
    fail 'WebView renderer code must define shouldOverrideUrlLoading to block external navigation.'
  fi

  if rg -n 'RichRendererRequestKind\.Iframe' "${existing_main_code_paths[@]}" >/dev/null; then
    pass 'WebView renderer code classifies iframe requests explicitly.'
  else
    fail 'WebView renderer code must classify iframe requests explicitly.'
  fi
else
  pass 'No Android WebView or android.webkit implementation is present; rich Markdown uses native fallback surfaces.'
fi

rm -f /tmp/fastmd-webview-scan.out

if [ "$failure" -ne 0 ]; then
  exit 1
fi
