#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
audit_script="${script_dir}/audit_renderer_assets.sh"

make_project() {
  local root="$1"

  mkdir -p \
    "${root}/app/src/main/java/com/fastmd/mobile" \
    "${root}/app/src/main/assets" \
    "${root}/core/src/main/java" \
    "${root}/feature/reader/src/main/java" \
    "${root}/feature/library/src/main/java" \
    "${root}/feature/settings/src/main/java" \
    "${root}/feature/reader" \
    "${root}/feature/library" \
    "${root}/feature/settings" \
    "${root}/gradle"

  touch \
    "${root}/app/build.gradle.kts" \
    "${root}/core/build.gradle.kts" \
    "${root}/feature/reader/build.gradle.kts" \
    "${root}/feature/library/build.gradle.kts" \
    "${root}/feature/settings/build.gradle.kts" \
    "${root}/settings.gradle.kts" \
    "${root}/gradle/libs.versions.toml"

  printf 'package com.fastmd.mobile\nclass Placeholder\n' > "${root}/app/src/main/java/com/fastmd/mobile/Placeholder.kt"
}

run_audit() {
  local root="$1"
  FASTMD_ANDROID_AUDIT_ROOT="$root" bash "$audit_script"
}

write_renderer_asset_metadata() {
  local renderer_root="$1"
  shift

  : > "${renderer_root}/renderer-assets.lock"
  local asset_path
  local asset_hash
  for asset_path in "$@"; do
    asset_hash="$(shasum -a 256 "${renderer_root}/${asset_path}" | awk '{print $1}')"
    printf '%s|FastMD offline fixture|test-fixture|Test-only local fixture|%s\n' "$asset_path" "$asset_hash" >> "${renderer_root}/renderer-assets.lock"
  done

  (
    cd "$renderer_root"
    shasum -a 256 "$@" renderer-assets.lock > renderer-assets.sha256
  )
}

expect_pass() {
  local label="$1"
  local root="$2"

  if run_audit "$root" >/tmp/fastmd-renderer-audit-test.out 2>&1; then
    printf 'PASS: %s\n' "$label"
  else
    cat /tmp/fastmd-renderer-audit-test.out >&2
    printf 'FAIL: expected pass for %s\n' "$label" >&2
    exit 1
  fi
}

expect_fail() {
  local label="$1"
  local root="$2"

  if run_audit "$root" >/tmp/fastmd-renderer-audit-test.out 2>&1; then
    cat /tmp/fastmd-renderer-audit-test.out >&2
    printf 'FAIL: expected failure for %s\n' "$label" >&2
    exit 1
  else
    printf 'PASS: %s\n' "$label"
  fi
}

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root" /tmp/fastmd-renderer-audit-test.out' EXIT

native_root="${tmp_root}/native-fallback"
make_project "$native_root"
expect_pass 'native fallback has no vendored renderer assets' "$native_root"

local_asset_root="${tmp_root}/local-assets"
make_project "$local_asset_root"
mkdir -p "${local_asset_root}/app/src/main/assets/fastmd-renderers/math/fonts"
printf 'const fastmdMath = "offline";\n' > "${local_asset_root}/app/src/main/assets/fastmd-renderers/math/math.js"
printf '.fastmd-math { font-family: FastMdMath; }\n' > "${local_asset_root}/app/src/main/assets/fastmd-renderers/math/math.css"
printf 'offline-font-placeholder\n' > "${local_asset_root}/app/src/main/assets/fastmd-renderers/math/fonts/math.woff2"
write_renderer_asset_metadata "${local_asset_root}/app/src/main/assets/fastmd-renderers" math/math.js math/math.css math/fonts/math.woff2
expect_pass 'app-local JS/CSS/font renderer assets verify with SHA-256 manifest' "$local_asset_root"

missing_manifest_root="${tmp_root}/missing-manifest"
make_project "$missing_manifest_root"
mkdir -p "${missing_manifest_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${missing_manifest_root}/app/src/main/assets/fastmd-renderers/math/math.js"
expect_fail 'renderer assets require hash manifest' "$missing_manifest_root"

missing_metadata_root="${tmp_root}/missing-metadata-lock"
make_project "$missing_metadata_root"
mkdir -p "${missing_metadata_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${missing_metadata_root}/app/src/main/assets/fastmd-renderers/math/math.js"
(
  cd "${missing_metadata_root}/app/src/main/assets/fastmd-renderers"
  shasum -a 256 math/math.js > renderer-assets.sha256
)
expect_fail 'renderer assets require platform-local metadata lock' "$missing_metadata_root"

metadata_not_hashed_root="${tmp_root}/metadata-not-hashed"
make_project "$metadata_not_hashed_root"
mkdir -p "${metadata_not_hashed_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${metadata_not_hashed_root}/app/src/main/assets/fastmd-renderers/math/math.js"
asset_hash="$(shasum -a 256 "${metadata_not_hashed_root}/app/src/main/assets/fastmd-renderers/math/math.js" | awk '{print $1}')"
printf 'math/math.js|FastMD offline fixture|test-fixture|Test-only local fixture|%s\n' "$asset_hash" \
  > "${metadata_not_hashed_root}/app/src/main/assets/fastmd-renderers/renderer-assets.lock"
(
  cd "${metadata_not_hashed_root}/app/src/main/assets/fastmd-renderers"
  shasum -a 256 math/math.js > renderer-assets.sha256
)
expect_fail 'renderer asset metadata lock must be included in hash manifest' "$metadata_not_hashed_root"

misplaced_root="${tmp_root}/misplaced-assets"
make_project "$misplaced_root"
mkdir -p "${misplaced_root}/core/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${misplaced_root}/core/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${misplaced_root}/core/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets outside app-local asset root fail' "$misplaced_root"

non_main_asset_root="${tmp_root}/non-main-source-set-assets"
make_project "$non_main_asset_root"
mkdir -p "${non_main_asset_root}/app/src/debug/assets/fastmd-renderers/math"
printf 'const fastmdMath = "debug-only";\n' > "${non_main_asset_root}/app/src/debug/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${non_main_asset_root}/app/src/debug/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets outside app main source set fail' "$non_main_asset_root"

remote_ref_root="${tmp_root}/remote-ref"
make_project "$remote_ref_root"
mkdir -p "${remote_ref_root}/app/src/main/assets/fastmd-renderers/math"
printf 'import "https://cdn.example/math.js";\n' > "${remote_ref_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${remote_ref_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with remote subresources fail' "$remote_ref_root"

content_uri_root="${tmp_root}/content-uri-ref"
make_project "$content_uri_root"
mkdir -p "${content_uri_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const bad = "content://com.fastmd.mobile/private.js";\n' > "${content_uri_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${content_uri_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with content URI subresources fail' "$content_uri_root"

protocol_relative_root="${tmp_root}/protocol-relative-ref"
make_project "$protocol_relative_root"
mkdir -p "${protocol_relative_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const remote = "//example.com/renderer.js";\n' > "${protocol_relative_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${protocol_relative_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with protocol-relative remote URLs fail' "$protocol_relative_root"

encoded_remote_root="${tmp_root}/encoded-remote-ref"
make_project "$encoded_remote_root"
mkdir -p "${encoded_remote_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const remote = "https%%3A%%2F%%2Fcdn.example/renderer.js";\n' > "${encoded_remote_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${encoded_remote_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with percent-encoded remote URLs fail' "$encoded_remote_root"

double_encoded_remote_root="${tmp_root}/double-encoded-remote-ref"
make_project "$double_encoded_remote_root"
mkdir -p "${double_encoded_remote_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const remote = "https%%253A%%252F%%252Fcdn.example/renderer.js";\n' > "${double_encoded_remote_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${double_encoded_remote_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with double percent-encoded remote URLs fail' "$double_encoded_remote_root"

uppercase_remote_root="${tmp_root}/uppercase-remote-ref"
make_project "$uppercase_remote_root"
mkdir -p "${uppercase_remote_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const bad = "JAVASCRIPT:alert(1)";\n' > "${uppercase_remote_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${uppercase_remote_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with uppercase dangerous URLs fail' "$uppercase_remote_root"

double_encoded_javascript_root="${tmp_root}/double-encoded-javascript"
make_project "$double_encoded_javascript_root"
mkdir -p "${double_encoded_javascript_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const bad = "javascript%%253Aalert(1)";\n' > "${double_encoded_javascript_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${double_encoded_javascript_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with double percent-encoded javascript URLs fail' "$double_encoded_javascript_root"

html_entity_url_root="${tmp_root}/html-entity-url"
make_project "$html_entity_url_root"
mkdir -p "${html_entity_url_root}/app/src/main/assets/fastmd-renderers/math"
printf '<a href="javascript&#x3a;alert(1)">bad</a>\n<img src="https&#58;//cdn.example/math.png">\n' > "${html_entity_url_root}/app/src/main/assets/fastmd-renderers/math/frame.html"
write_renderer_asset_metadata "${html_entity_url_root}/app/src/main/assets/fastmd-renderers" math/frame.html
expect_fail 'renderer assets with HTML entity-encoded dangerous URLs fail' "$html_entity_url_root"

html_entity_navigation_root="${tmp_root}/html-entity-navigation"
make_project "$html_entity_navigation_root"
mkdir -p "${html_entity_navigation_root}/app/src/main/assets/fastmd-renderers/math"
printf 'window&#46;location = "fastmd://unexpected";\n' > "${html_entity_navigation_root}/app/src/main/assets/fastmd-renderers/math/frame.html"
write_renderer_asset_metadata "${html_entity_navigation_root}/app/src/main/assets/fastmd-renderers" math/frame.html
expect_fail 'renderer assets with HTML entity-encoded navigation markers fail' "$html_entity_navigation_root"

unicode_escaped_remote_root="${tmp_root}/unicode-escaped-remote"
make_project "$unicode_escaped_remote_root"
mkdir -p "${unicode_escaped_remote_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const remote = "\\u0068\\u0074\\u0074\\u0070\\u0073\\u003a\\u002f\\u002fcdn.example/renderer.js";\n' > "${unicode_escaped_remote_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${unicode_escaped_remote_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with JavaScript unicode-escaped remote URLs fail' "$unicode_escaped_remote_root"

braced_unicode_escaped_data_root="${tmp_root}/braced-unicode-escaped-data"
make_project "$braced_unicode_escaped_data_root"
mkdir -p "${braced_unicode_escaped_data_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const payload = "\\u{64}\\u{61}\\u{74}\\u{61}\\u{3a}text/html;base64,PGgxPkJhZDwvaDE+";\n' > "${braced_unicode_escaped_data_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${braced_unicode_escaped_data_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with JavaScript braced unicode-escaped data URLs fail' "$braced_unicode_escaped_data_root"

hex_escaped_network_api_root="${tmp_root}/hex-escaped-network-api"
make_project "$hex_escaped_network_api_root"
mkdir -p "${hex_escaped_network_api_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const load = (path) => \\x66\\x65\\x74\\x63\\x68(path);\n' > "${hex_escaped_network_api_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${hex_escaped_network_api_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with JavaScript hex-escaped network APIs fail' "$hex_escaped_network_api_root"

blob_url_root="${tmp_root}/blob-url"
make_project "$blob_url_root"
mkdir -p "${blob_url_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const bad = "blob:https://cdn.example/renderer-fragment";\n' > "${blob_url_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${blob_url_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with blob URLs fail' "$blob_url_root"

filesystem_url_root="${tmp_root}/filesystem-url"
make_project "$filesystem_url_root"
mkdir -p "${filesystem_url_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const bad = "filesystem:https://cdn.example/temporary/renderer.js";\n' > "${filesystem_url_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${filesystem_url_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with filesystem URLs fail' "$filesystem_url_root"

external_navigation_root="${tmp_root}/external-navigation"
make_project "$external_navigation_root"
mkdir -p "${external_navigation_root}/app/src/main/assets/fastmd-renderers/math"
printf 'window.location = "fastmd://unexpected";\n' > "${external_navigation_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${external_navigation_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with external navigation APIs fail' "$external_navigation_root"

meta_refresh_root="${tmp_root}/meta-refresh-navigation"
make_project "$meta_refresh_root"
mkdir -p "${meta_refresh_root}/app/src/main/assets/fastmd-renderers/math"
printf '<meta http-equiv="refresh" content="0; url=fastmd://unexpected">\n' > "${meta_refresh_root}/app/src/main/assets/fastmd-renderers/math/frame.html"
write_renderer_asset_metadata "${meta_refresh_root}/app/src/main/assets/fastmd-renderers" math/frame.html
expect_fail 'renderer assets with HTML meta refresh navigation fail' "$meta_refresh_root"

form_navigation_root="${tmp_root}/form-navigation"
make_project "$form_navigation_root"
mkdir -p "${form_navigation_root}/app/src/main/assets/fastmd-renderers/math"
printf '<form action="fastmd://unexpected"><button>open</button></form>\n' > "${form_navigation_root}/app/src/main/assets/fastmd-renderers/math/frame.html"
write_renderer_asset_metadata "${form_navigation_root}/app/src/main/assets/fastmd-renderers" math/frame.html
expect_fail 'renderer assets with HTML form navigation fail' "$form_navigation_root"

iframe_root="${tmp_root}/iframe-navigation"
make_project "$iframe_root"
mkdir -p "${iframe_root}/app/src/main/assets/fastmd-renderers/math"
printf '<iframe src="fastmd://unexpected"></iframe>\n' > "${iframe_root}/app/src/main/assets/fastmd-renderers/math/frame.html"
write_renderer_asset_metadata "${iframe_root}/app/src/main/assets/fastmd-renderers" math/frame.html
expect_fail 'renderer assets with iframe surfaces fail' "$iframe_root"

srcdoc_root="${tmp_root}/srcdoc-navigation"
make_project "$srcdoc_root"
mkdir -p "${srcdoc_root}/app/src/main/assets/fastmd-renderers/math"
printf '<div srcdoc="<script>window.location = '\''fastmd://unexpected'\''</script>"></div>\n' > "${srcdoc_root}/app/src/main/assets/fastmd-renderers/math/frame.html"
write_renderer_asset_metadata "${srcdoc_root}/app/src/main/assets/fastmd-renderers" math/frame.html
expect_fail 'renderer assets with srcdoc surfaces fail' "$srcdoc_root"

svg_active_content_root="${tmp_root}/svg-active-content"
make_project "$svg_active_content_root"
mkdir -p "${svg_active_content_root}/app/src/main/assets/fastmd-renderers/mermaid"
printf '<svg><script>alert(1)</script></svg>\n' > "${svg_active_content_root}/app/src/main/assets/fastmd-renderers/mermaid/diagram.svg"
write_renderer_asset_metadata "${svg_active_content_root}/app/src/main/assets/fastmd-renderers" mermaid/diagram.svg
expect_fail 'renderer SVG assets with active script content fail' "$svg_active_content_root"

svg_remote_reference_root="${tmp_root}/svg-remote-reference"
make_project "$svg_remote_reference_root"
mkdir -p "${svg_remote_reference_root}/app/src/main/assets/fastmd-renderers/mermaid"
printf '<svg><image href="https://cdn.example/diagram.png"/></svg>\n' > "${svg_remote_reference_root}/app/src/main/assets/fastmd-renderers/mermaid/diagram.svg"
write_renderer_asset_metadata "${svg_remote_reference_root}/app/src/main/assets/fastmd-renderers" mermaid/diagram.svg
expect_fail 'renderer SVG assets with remote references fail' "$svg_remote_reference_root"

svg_event_handler_root="${tmp_root}/svg-event-handler"
make_project "$svg_event_handler_root"
mkdir -p "${svg_event_handler_root}/app/src/main/assets/fastmd-renderers/mermaid"
printf '<svg onload="window.open('\''fastmd://unexpected'\'')"></svg>\n' > "${svg_event_handler_root}/app/src/main/assets/fastmd-renderers/mermaid/diagram.svg"
write_renderer_asset_metadata "${svg_event_handler_root}/app/src/main/assets/fastmd-renderers" mermaid/diagram.svg
expect_fail 'renderer SVG assets with event handlers fail' "$svg_event_handler_root"

network_api_root="${tmp_root}/network-api"
make_project "$network_api_root"
mkdir -p "${network_api_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const load = (path) => fetch(path);\n' > "${network_api_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${network_api_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with network-capable browser APIs fail' "$network_api_root"

mjs_network_api_root="${tmp_root}/mjs-network-api"
make_project "$mjs_network_api_root"
mkdir -p "${mjs_network_api_root}/app/src/main/assets/fastmd-renderers/math"
printf 'export const load = (path) => fetch(path);\n' > "${mjs_network_api_root}/app/src/main/assets/fastmd-renderers/math/math.mjs"
write_renderer_asset_metadata "${mjs_network_api_root}/app/src/main/assets/fastmd-renderers" math/math.mjs
expect_fail 'renderer module assets with network-capable browser APIs fail' "$mjs_network_api_root"

xhr_api_root="${tmp_root}/xhr-api"
make_project "$xhr_api_root"
mkdir -p "${xhr_api_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const request = new XMLHttpRequest();\n' > "${xhr_api_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${xhr_api_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with XMLHttpRequest APIs fail' "$xhr_api_root"

websocket_api_root="${tmp_root}/websocket-api"
make_project "$websocket_api_root"
mkdir -p "${websocket_api_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const socket = new WebSocket("wss://example.invalid/renderer");\n' > "${websocket_api_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${websocket_api_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with WebSocket APIs fail' "$websocket_api_root"

eventsource_api_root="${tmp_root}/eventsource-api"
make_project "$eventsource_api_root"
mkdir -p "${eventsource_api_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const stream = new EventSource("/events");\n' > "${eventsource_api_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${eventsource_api_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with EventSource APIs fail' "$eventsource_api_root"

beacon_api_root="${tmp_root}/beacon-api"
make_project "$beacon_api_root"
mkdir -p "${beacon_api_root}/app/src/main/assets/fastmd-renderers/math"
printf 'navigator.sendBeacon("/collect", "offline");\n' > "${beacon_api_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${beacon_api_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with sendBeacon APIs fail' "$beacon_api_root"

dynamic_import_root="${tmp_root}/dynamic-import-api"
make_project "$dynamic_import_root"
mkdir -p "${dynamic_import_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const load = (path) => import(path);\n' > "${dynamic_import_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${dynamic_import_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with dynamic import APIs fail' "$dynamic_import_root"

eval_api_root="${tmp_root}/eval-api"
make_project "$eval_api_root"
mkdir -p "${eval_api_root}/app/src/main/assets/fastmd-renderers/math"
printf 'eval("renderMathOffline()");\n' > "${eval_api_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${eval_api_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with eval dynamic code execution fail' "$eval_api_root"

function_constructor_root="${tmp_root}/function-constructor-api"
make_project "$function_constructor_root"
mkdir -p "${function_constructor_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const run = Function("return renderMathOffline()");\n' > "${function_constructor_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${function_constructor_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with Function constructor dynamic code execution fail' "$function_constructor_root"

string_timeout_root="${tmp_root}/string-timeout-api"
make_project "$string_timeout_root"
mkdir -p "${string_timeout_root}/app/src/main/assets/fastmd-renderers/math"
printf 'setTimeout("renderMathOffline()", 0);\n' > "${string_timeout_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${string_timeout_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with string-based timers fail' "$string_timeout_root"

escaped_eval_root="${tmp_root}/escaped-eval-api"
make_project "$escaped_eval_root"
mkdir -p "${escaped_eval_root}/app/src/main/assets/fastmd-renderers/math"
printf '\\u0065\\u0076\\u0061\\u006c("renderMathOffline()");\n' > "${escaped_eval_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${escaped_eval_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with JavaScript-escaped eval fail' "$escaped_eval_root"

worker_api_root="${tmp_root}/worker-api"
make_project "$worker_api_root"
mkdir -p "${worker_api_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const worker = new Worker("worker.js");\n' > "${worker_api_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${worker_api_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with worker APIs fail' "$worker_api_root"

shared_worker_api_root="${tmp_root}/shared-worker-api"
make_project "$shared_worker_api_root"
mkdir -p "${shared_worker_api_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const worker = new SharedWorker("worker.js");\n' > "${shared_worker_api_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${shared_worker_api_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with shared worker APIs fail' "$shared_worker_api_root"

import_scripts_api_root="${tmp_root}/import-scripts-api"
make_project "$import_scripts_api_root"
mkdir -p "${import_scripts_api_root}/app/src/main/assets/fastmd-renderers/math"
printf 'importScripts("renderer-helper.js");\n' > "${import_scripts_api_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${import_scripts_api_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with importScripts APIs fail' "$import_scripts_api_root"

service_worker_api_root="${tmp_root}/service-worker-api"
make_project "$service_worker_api_root"
mkdir -p "${service_worker_api_root}/app/src/main/assets/fastmd-renderers/math"
printf 'navigator.serviceWorker.register("worker.js");\n' > "${service_worker_api_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${service_worker_api_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'renderer assets with service worker APIs fail' "$service_worker_api_root"

tampered_hash_root="${tmp_root}/tampered-hash"
make_project "$tampered_hash_root"
mkdir -p "${tampered_hash_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${tampered_hash_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${tampered_hash_root}/app/src/main/assets/fastmd-renderers" math/math.js
printf 'const fastmdMath = "changed";\n' > "${tampered_hash_root}/app/src/main/assets/fastmd-renderers/math/math.js"
expect_fail 'renderer assets with stale SHA-256 manifest fail' "$tampered_hash_root"

tampered_metadata_root="${tmp_root}/tampered-metadata-hash"
make_project "$tampered_metadata_root"
mkdir -p "${tampered_metadata_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${tampered_metadata_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${tampered_metadata_root}/app/src/main/assets/fastmd-renderers" math/math.js
printf 'math/math.js|FastMD offline fixture|test-fixture|Test-only local fixture|0000000000000000000000000000000000000000000000000000000000000000\n' > "${tampered_metadata_root}/app/src/main/assets/fastmd-renderers/renderer-assets.lock"
(
  cd "${tampered_metadata_root}/app/src/main/assets/fastmd-renderers"
  shasum -a 256 math/math.js renderer-assets.lock > renderer-assets.sha256
)
expect_fail 'renderer metadata lock with stale asset hash fails' "$tampered_metadata_root"

unlisted_asset_root="${tmp_root}/unlisted-asset"
make_project "$unlisted_asset_root"
mkdir -p "${unlisted_asset_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${unlisted_asset_root}/app/src/main/assets/fastmd-renderers/math/math.js"
printf 'const extra = "not hashed";\n' > "${unlisted_asset_root}/app/src/main/assets/fastmd-renderers/math/extra.js"
write_renderer_asset_metadata "${unlisted_asset_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'packaged renderer assets missing from manifest fail' "$unlisted_asset_root"

escaping_manifest_root="${tmp_root}/escaping-manifest"
make_project "$escaping_manifest_root"
mkdir -p "${escaping_manifest_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${escaping_manifest_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${escaping_manifest_root}/app/src/main/assets/fastmd-renderers" math/math.js
(
  cd "${escaping_manifest_root}/app/src/main/assets/fastmd-renderers"
  hash="$(shasum -a 256 math/math.js | awk '{print $1}')"
  lock_hash="$(shasum -a 256 renderer-assets.lock | awk '{print $1}')"
  printf '%s  ../math/math.js\n%s  renderer-assets.lock\n' "$hash" "$lock_hash" > renderer-assets.sha256
)
expect_fail 'renderer asset manifest paths cannot escape asset root' "$escaping_manifest_root"

dot_segment_manifest_root="${tmp_root}/dot-segment-manifest"
make_project "$dot_segment_manifest_root"
mkdir -p "${dot_segment_manifest_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${dot_segment_manifest_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${dot_segment_manifest_root}/app/src/main/assets/fastmd-renderers" math/math.js
(
  cd "${dot_segment_manifest_root}/app/src/main/assets/fastmd-renderers"
  hash="$(shasum -a 256 math/math.js | awk '{print $1}')"
  lock_hash="$(shasum -a 256 renderer-assets.lock | awk '{print $1}')"
  printf '%s  math/./math.js\n%s  renderer-assets.lock\n' "$hash" "$lock_hash" > renderer-assets.sha256
)
expect_fail 'renderer asset manifest paths cannot contain dot segments' "$dot_segment_manifest_root"

escaped_path_manifest_root="${tmp_root}/escaped-path-manifest"
make_project "$escaped_path_manifest_root"
mkdir -p "${escaped_path_manifest_root}/app/src/main/assets/fastmd-renderers/math/%2e%2e"
printf 'const fastmdMath = "offline";\n' > "${escaped_path_manifest_root}/app/src/main/assets/fastmd-renderers/math/%2e%2e/math.js"
(
  cd "${escaped_path_manifest_root}/app/src/main/assets/fastmd-renderers"
  hash="$(shasum -a 256 'math/%2e%2e/math.js' | awk '{print $1}')"
  printf 'math/%%2e%%2e/math.js|FastMD offline fixture|test-fixture|Test-only local fixture|%s\n' "$hash" > renderer-assets.lock
  shasum -a 256 'math/%2e%2e/math.js' renderer-assets.lock > renderer-assets.sha256
)
expect_fail 'renderer asset manifest paths cannot contain percent escapes' "$escaped_path_manifest_root"

whitespace_manifest_root="${tmp_root}/whitespace-manifest"
make_project "$whitespace_manifest_root"
mkdir -p "${whitespace_manifest_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${whitespace_manifest_root}/app/src/main/assets/fastmd-renderers/math/bad name.js"
(
  cd "${whitespace_manifest_root}/app/src/main/assets/fastmd-renderers"
  hash="$(shasum -a 256 'math/bad name.js' | awk '{print $1}')"
  printf 'math/bad name.js|FastMD offline fixture|test-fixture|Test-only local fixture|%s\n' "$hash" > renderer-assets.lock
  shasum -a 256 'math/bad name.js' renderer-assets.lock > renderer-assets.sha256
)
expect_fail 'renderer asset manifest paths cannot contain whitespace' "$whitespace_manifest_root"

invalid_packaged_asset_root="${tmp_root}/invalid-packaged-asset"
make_project "$invalid_packaged_asset_root"
mkdir -p "${invalid_packaged_asset_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${invalid_packaged_asset_root}/app/src/main/assets/fastmd-renderers/math/math.js"
printf 'const extra = "bad path";\n' > "${invalid_packaged_asset_root}/app/src/main/assets/fastmd-renderers/math/bad name.js"
write_renderer_asset_metadata "${invalid_packaged_asset_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'packaged renderer asset paths cannot contain whitespace even when unlisted' "$invalid_packaged_asset_root"

unsupported_manifest_asset_root="${tmp_root}/unsupported-manifest-asset"
make_project "$unsupported_manifest_asset_root"
mkdir -p "${unsupported_manifest_asset_root}/app/src/main/assets/fastmd-renderers/math"
printf '{"remote":"https://cdn.example/math.js"}\n' > "${unsupported_manifest_asset_root}/app/src/main/assets/fastmd-renderers/math/config.json"
write_renderer_asset_metadata "${unsupported_manifest_asset_root}/app/src/main/assets/fastmd-renderers" math/config.json
expect_fail 'renderer asset manifests cannot list unsupported file extensions' "$unsupported_manifest_asset_root"

unsupported_packaged_asset_root="${tmp_root}/unsupported-packaged-asset"
make_project "$unsupported_packaged_asset_root"
mkdir -p "${unsupported_packaged_asset_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${unsupported_packaged_asset_root}/app/src/main/assets/fastmd-renderers/math/math.js"
printf '00asm-offline-placeholder\n' > "${unsupported_packaged_asset_root}/app/src/main/assets/fastmd-renderers/math/renderer.wasm"
write_renderer_asset_metadata "${unsupported_packaged_asset_root}/app/src/main/assets/fastmd-renderers" math/math.js
expect_fail 'packaged renderer assets with unsupported file extensions fail even when unlisted' "$unsupported_packaged_asset_root"

self_hash_manifest_root="${tmp_root}/self-hash-manifest"
make_project "$self_hash_manifest_root"
mkdir -p "${self_hash_manifest_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${self_hash_manifest_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${self_hash_manifest_root}/app/src/main/assets/fastmd-renderers" math/math.js
(
  cd "${self_hash_manifest_root}/app/src/main/assets/fastmd-renderers"
  hash="$(printf '' | shasum -a 256 | awk '{print $1}')"
  lock_hash="$(shasum -a 256 renderer-assets.lock | awk '{print $1}')"
  printf '%s  renderer-assets.sha256\n%s  renderer-assets.lock\n' "$hash" "$lock_hash" > renderer-assets.sha256
)
expect_fail 'renderer asset manifest cannot hash itself' "$self_hash_manifest_root"

malformed_manifest_root="${tmp_root}/malformed-manifest"
make_project "$malformed_manifest_root"
mkdir -p "${malformed_manifest_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${malformed_manifest_root}/app/src/main/assets/fastmd-renderers/math/math.js"
write_renderer_asset_metadata "${malformed_manifest_root}/app/src/main/assets/fastmd-renderers" math/math.js
printf 'not-a-sha  math/math.js\n' > "${malformed_manifest_root}/app/src/main/assets/fastmd-renderers/renderer-assets.sha256"
expect_fail 'renderer asset manifest malformed lines fail' "$malformed_manifest_root"

malformed_metadata_root="${tmp_root}/malformed-metadata-lock"
make_project "$malformed_metadata_root"
mkdir -p "${malformed_metadata_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${malformed_metadata_root}/app/src/main/assets/fastmd-renderers/math/math.js"
(
  cd "${malformed_metadata_root}/app/src/main/assets/fastmd-renderers"
  printf 'math/math.js|missing-fields\n' > renderer-assets.lock
  shasum -a 256 math/math.js renderer-assets.lock > renderer-assets.sha256
)
expect_fail 'renderer asset metadata lock malformed lines fail' "$malformed_metadata_root"

metadata_url_marker_root="${tmp_root}/metadata-url-marker"
make_project "$metadata_url_marker_root"
mkdir -p "${metadata_url_marker_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${metadata_url_marker_root}/app/src/main/assets/fastmd-renderers/math/math.js"
(
  cd "${metadata_url_marker_root}/app/src/main/assets/fastmd-renderers"
  hash="$(shasum -a 256 math/math.js | awk '{print $1}')"
  printf 'math/math.js|FastMD offline fixture|https://cdn.example/math.js|Test-only local fixture|%s\n' "$hash" > renderer-assets.lock
  shasum -a 256 math/math.js renderer-assets.lock > renderer-assets.sha256
)
expect_fail 'renderer asset metadata lock URL markers fail' "$metadata_url_marker_root"

metadata_encoded_url_marker_root="${tmp_root}/metadata-encoded-url-marker"
make_project "$metadata_encoded_url_marker_root"
mkdir -p "${metadata_encoded_url_marker_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${metadata_encoded_url_marker_root}/app/src/main/assets/fastmd-renderers/math/math.js"
(
  cd "${metadata_encoded_url_marker_root}/app/src/main/assets/fastmd-renderers"
  hash="$(shasum -a 256 math/math.js | awk '{print $1}')"
  printf 'math/math.js|FastMD offline fixture|test-fixture|See https%%3A%%2F%%2Fcdn.example%%2Fmath.js|%s\n' "$hash" > renderer-assets.lock
  shasum -a 256 math/math.js renderer-assets.lock > renderer-assets.sha256
)
expect_fail 'renderer asset metadata lock encoded URL markers fail' "$metadata_encoded_url_marker_root"

metadata_double_encoded_url_marker_root="${tmp_root}/metadata-double-encoded-url-marker"
make_project "$metadata_double_encoded_url_marker_root"
mkdir -p "${metadata_double_encoded_url_marker_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${metadata_double_encoded_url_marker_root}/app/src/main/assets/fastmd-renderers/math/math.js"
(
  cd "${metadata_double_encoded_url_marker_root}/app/src/main/assets/fastmd-renderers"
  hash="$(shasum -a 256 math/math.js | awk '{print $1}')"
  printf 'math/math.js|FastMD offline fixture|test-fixture|See https%%253A%%252F%%252Fcdn.example%%252Fmath.js|%s\n' "$hash" > renderer-assets.lock
  shasum -a 256 math/math.js renderer-assets.lock > renderer-assets.sha256
)
expect_fail 'renderer asset metadata lock double-encoded URL markers fail' "$metadata_double_encoded_url_marker_root"

metadata_entity_url_marker_root="${tmp_root}/metadata-entity-url-marker"
make_project "$metadata_entity_url_marker_root"
mkdir -p "${metadata_entity_url_marker_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${metadata_entity_url_marker_root}/app/src/main/assets/fastmd-renderers/math/math.js"
(
  cd "${metadata_entity_url_marker_root}/app/src/main/assets/fastmd-renderers"
  hash="$(shasum -a 256 math/math.js | awk '{print $1}')"
  printf 'math/math.js|FastMD offline fixture|test-fixture|See https&#58;//cdn.example/math.js|%s\n' "$hash" > renderer-assets.lock
  shasum -a 256 math/math.js renderer-assets.lock > renderer-assets.sha256
)
expect_fail 'renderer asset metadata lock HTML entity URL markers fail' "$metadata_entity_url_marker_root"

metadata_js_escape_url_marker_root="${tmp_root}/metadata-js-escape-url-marker"
make_project "$metadata_js_escape_url_marker_root"
mkdir -p "${metadata_js_escape_url_marker_root}/app/src/main/assets/fastmd-renderers/math"
printf 'const fastmdMath = "offline";\n' > "${metadata_js_escape_url_marker_root}/app/src/main/assets/fastmd-renderers/math/math.js"
(
  cd "${metadata_js_escape_url_marker_root}/app/src/main/assets/fastmd-renderers"
  hash="$(shasum -a 256 math/math.js | awk '{print $1}')"
  printf 'math/math.js|FastMD offline fixture|test-fixture|See \\u0068\\u0074\\u0074\\u0070\\u0073\\u003a//cdn.example/math.js|%s\n' "$hash" > renderer-assets.lock
  shasum -a 256 math/math.js renderer-assets.lock > renderer-assets.sha256
)
expect_fail 'renderer asset metadata lock JavaScript-escaped URL markers fail' "$metadata_js_escape_url_marker_root"

webview_root="${tmp_root}/webview"
make_project "$webview_root"
printf 'package com.fastmd.mobile\nclass Renderer { val name = "WebView" }\n' > "${webview_root}/app/src/main/java/com/fastmd/mobile/Renderer.kt"
expect_fail 'WebView implementation fails until request-blocking tests exist' "$webview_root"

react_native_root="${tmp_root}/react-native"
make_project "$react_native_root"
printf 'implementation("com.facebook.react:react-native:0.76.0")\n' > "${react_native_root}/app/build.gradle.kts"
expect_fail 'React Native runtime dependency fails the native Android lane audit' "$react_native_root"
