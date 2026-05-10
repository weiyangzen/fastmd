#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="${FASTMD_ANDROID_AUDIT_ROOT:-"${script_dir}/.."}"
cd "$repo_root"

failure=0
dangerous_renderer_asset_pattern='https?://|(^|[^:])//[[:alnum:].-]+|https?%3a|javascript%3a|data%3a|blob%3a|filesystem%3a|file%3a|content%3a|%25|%2f|%5c|cdnjs|unpkg|jsdelivr|<script|<iframe|<meta[^>]+http-equiv=["'\'' ]*refresh|<form[[:space:]>]|srcdoc=|[[:space:]]on(load|click|error)=|javascript:|data:|blob:|filesystem:|file:|content:|window\.location|document\.location|location\.href|location\.assign|location\.replace|window\.open'
html_entity_dangerous_renderer_asset_pattern='https?(&#0*58;|&#x0*3a;)|javascript(&#0*58;|&#x0*3a;)|data(&#0*58;|&#x0*3a;)|blob(&#0*58;|&#x0*3a;)|filesystem(&#0*58;|&#x0*3a;)|file(&#0*58;|&#x0*3a;)|content(&#0*58;|&#x0*3a;)|(&#0*47;|&#x0*2f;){2}[[:alnum:].-]+|window(&#0*46;|&#x0*2e;)location|document(&#0*46;|&#x0*2e;)location|location(&#0*46;|&#x0*2e;)(href|assign|replace)|window(&#0*46;|&#x0*2e;)open'
network_api_pattern='\bfetch[[:space:]]*\(|\bXMLHttpRequest\b|\bWebSocket[[:space:]]*\(|\bEventSource[[:space:]]*\(|\bsendBeacon[[:space:]]*\(|\bimportScripts[[:space:]]*\(|\bimport[[:space:]]*\(|\bWorker[[:space:]]*\(|\bSharedWorker[[:space:]]*\(|\bServiceWorker\b|\bnavigator\.serviceWorker\b'
dynamic_code_pattern="\beval[[:space:]]*\(|\bnew[[:space:]]+function[[:space:]]*\(|\bfunction[[:space:]]*\([[:space:]]*['\"\`]|\bsetTimeout[[:space:]]*\([[:space:]]*['\"\`]|\bsetInterval[[:space:]]*\([[:space:]]*['\"\`]"
metadata_dangerous_pattern='https?://|(^|[^:])//[[:alnum:].-]+|https?%3a|https?%253a|javascript:|javascript%3a|javascript%253a|data:|data%3a|data%253a|blob:|blob%3a|blob%253a|filesystem:|filesystem%3a|filesystem%253a|file:|file%3a|file%253a|content:|content%3a|content%253a|%25|cdnjs|unpkg|jsdelivr|//cdn\.|//unpkg\.|//jsdelivr\.'

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failure=1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

scan_decoded_javascript_escapes() {
  local asset="$1"
  local decoded_asset

  decoded_asset="$(mktemp)"
  perl -CSDA -0777 -pe '
    s/\\u\{([0-9a-fA-F]{1,6})\}/chr(hex($1))/ge;
    s/\\u([0-9a-fA-F]{4})/chr(hex($1))/ge;
    s/\\x([0-9a-fA-F]{2})/chr(hex($1))/ge;
  ' "$asset" > "$decoded_asset"

  if rg -n -i "$dangerous_renderer_asset_pattern" "$decoded_asset"; then
    fail "JavaScript-escaped remote subresource, external navigation, iframe, javascript/data/file/content URL reference found in ${asset#./}."
  fi
  if rg -n "$network_api_pattern" "$decoded_asset"; then
    fail "JavaScript-escaped network-capable renderer API found in ${asset#./}; isolated renderer assets must not initiate network requests."
  fi
  if rg -n -i "$dynamic_code_pattern" "$decoded_asset"; then
    fail "JavaScript-escaped dynamic code execution marker found in ${asset#./}; isolated renderer assets must not evaluate generated code."
  fi

  rm -f "$decoded_asset"
}

validate_renderer_asset_path() {
  local label="$1"
  local path="$2"

  if [ -z "$path" ]; then
    fail "${label} cannot be blank."
    return
  fi

  case "$path" in
    /*|*://*|*:*|*\\*|*\?*|*#*|*%*|*[[:space:]]*)
      fail "${label} must be a relative clean asset path without schemes, whitespace, escapes, query/fragment markers, or backslashes: ${path}."
      ;;
  esac

  local segment
  local -a segments
  local old_ifs="$IFS"
  IFS='/'
  read -r -a segments <<< "$path"
  IFS="$old_ifs"

  for segment in "${segments[@]}"; do
    case "$segment" in
      ""|"."|"..")
        fail "${label} cannot contain blank, current-directory, or parent-directory segments: ${path}."
        ;;
    esac
  done

  if [ "$path" = "renderer-assets.lock" ]; then
    return
  fi

  local filename="${path##*/}"
  local extension="${filename##*.}"
  if [ "$filename" = "$extension" ] || [ -z "$extension" ] || [[ "$filename" == .* ]]; then
    fail "${label} must include a supported renderer asset file extension: ${path}."
    return
  fi

  case "$extension" in
    js|mjs|css|html|htm|woff|woff2|ttf|otf|svg|png|jpg|jpeg|webp)
      ;;
    *)
      fail "${label} uses unsupported renderer asset file extension: ${path}."
      ;;
  esac
}

validate_renderer_metadata_field() {
  local metadata_field_label="$1"
  local metadata_field_value="$2"
  local metadata_path="$3"
  local decoded_metadata

  if [ -z "$metadata_field_value" ] ||
    [ "$metadata_field_value" != "$(printf '%s' "$metadata_field_value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')" ] ||
    printf '%s' "$metadata_field_value" | LC_ALL=C rg -n -i '[[:cntrl:]]|[|]' >/dev/null ||
    printf '%s' "$metadata_field_value" | LC_ALL=C rg -n -i "$metadata_dangerous_pattern" >/dev/null ||
    printf '%s' "$metadata_field_value" | LC_ALL=C rg -n -i "$html_entity_dangerous_renderer_asset_pattern" >/dev/null
  then
    fail "Renderer asset metadata ${metadata_field_label} must be non-blank, trimmed, and free of URL, escape, dangerous-scheme, or control markers for ${metadata_path}."
    return
  fi

  decoded_metadata="$(printf '%s' "$metadata_field_value" | perl -CSDA -0777 -pe '
    s/\\u\{([0-9a-fA-F]{1,6})\}/chr(hex($1))/ge;
    s/\\u([0-9a-fA-F]{4})/chr(hex($1))/ge;
    s/\\x([0-9a-fA-F]{2})/chr(hex($1))/ge;
  ')"
  if printf '%s' "$decoded_metadata" | LC_ALL=C rg -n -i "$metadata_dangerous_pattern" >/dev/null ||
    printf '%s' "$decoded_metadata" | LC_ALL=C rg -n -i "$html_entity_dangerous_renderer_asset_pattern" >/dev/null
  then
    fail "Renderer asset metadata ${metadata_field_label} must not hide URL or dangerous-scheme markers behind JavaScript escapes for ${metadata_path}."
  fi
}

main_code_paths=(
  app/src/main/java
  core/src/main/java
  feature/reader/src/main/java
  feature/library/src/main/java
  feature/settings/src/main/java
)

gradle_paths=(
  app/build.gradle.kts
  core/build.gradle.kts
  feature/reader/build.gradle.kts
  feature/library/build.gradle.kts
  feature/settings/build.gradle.kts
  settings.gradle.kts
  gradle/libs.versions.toml
)

existing_main_code_paths=()
for path in "${main_code_paths[@]}"; do
  if [ -e "$path" ]; then
    existing_main_code_paths+=("$path")
  fi
done

existing_gradle_paths=()
for path in "${gradle_paths[@]}"; do
  if [ -e "$path" ]; then
    existing_gradle_paths+=("$path")
  fi
done

if [ "${#existing_main_code_paths[@]}" -gt 0 ] && rg -n 'WebView|android\.webkit' "${existing_main_code_paths[@]}"; then
  fail 'Android WebView renderer code is present; request-blocking tests must be added before this gate can pass.'
else
  pass 'No Android WebView or android.webkit implementation is present.'
fi

runtime_scan_paths=("${existing_main_code_paths[@]}" "${existing_gradle_paths[@]}")
if [ "${#runtime_scan_paths[@]}" -gt 0 ] && rg -n -i 'react[-_ ]?native|com\.facebook\.react|flutter|io\.flutter|cordova|org\.apache\.cordova|capacitor|@capacitor' "${runtime_scan_paths[@]}"; then
  fail 'A web/app-shell runtime dependency is present in Android code or Gradle configuration.'
else
  pass 'No React Native, Flutter, Cordova, or equivalent web runtime dependency is present.'
fi

renderer_roots=()
while IFS= read -r root; do
  renderer_roots+=("$root")
done < <(find . -path '*/src/*/assets/fastmd-renderers' -type d | sort)

if [ "${#renderer_roots[@]}" -eq 0 ]; then
  pass 'No vendored JS/CSS/font renderer asset tree is present; Android rich blocks use native fallback paths.'
else
  for root in "${renderer_roots[@]}"; do
    case "$root" in
      ./app/src/main/assets/fastmd-renderers)
        pass "Renderer asset root is app-local: ${root#./}."
        ;;
      *)
        fail "Renderer assets must be app-local under app/src/main/assets/fastmd-renderers, found ${root#./}."
        ;;
    esac

    manifest="${root}/renderer-assets.sha256"
    if [ ! -f "$manifest" ]; then
      fail "Renderer asset hash manifest is missing at ${manifest#./}."
      continue
    fi

    metadata_lock="${root}/renderer-assets.lock"
    if [ ! -f "$metadata_lock" ]; then
      fail "Renderer asset metadata lock is missing at ${metadata_lock#./}."
      continue
    fi

    manifest_paths=()
    while IFS= read -r manifest_line || [ -n "$manifest_line" ]; do
      if [ -z "$manifest_line" ]; then
        continue
      fi

      if [[ ! "$manifest_line" =~ ^[0-9a-f]{64}[[:space:]][[:space:]\*](.+)$ ]]; then
        fail "Renderer asset hash manifest has malformed line in ${manifest#./}."
        continue
      fi

      manifest_path="${BASH_REMATCH[1]}"
      manifest_paths+=("$manifest_path")

      validate_renderer_asset_path "Renderer asset hash manifest path inside ${root#./}" "$manifest_path"

      if [ "$manifest_path" = "renderer-assets.sha256" ]; then
        fail "Renderer asset hash manifest must not hash itself."
      elif [ ! -f "${root}/${manifest_path}" ]; then
        fail "Renderer asset hash manifest references missing asset: ${manifest_path}."
      fi
    done < "$manifest"

    metadata_paths=()
    while IFS= read -r metadata_line || [ -n "$metadata_line" ]; do
      case "$metadata_line" in
        ""|"#"*)
          continue
          ;;
      esac

      if [[ ! "$metadata_line" =~ ^([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)\|([0-9a-f]{64})$ ]]; then
        fail "Renderer asset metadata lock has malformed line in ${metadata_lock#./}."
        continue
      fi

      metadata_path="${BASH_REMATCH[1]}"
      metadata_upstream_name="${BASH_REMATCH[2]}"
      metadata_upstream_version="${BASH_REMATCH[3]}"
      metadata_license="${BASH_REMATCH[4]}"
      metadata_hash="${BASH_REMATCH[5]}"

      validate_renderer_asset_path "Renderer asset metadata path inside ${root#./}" "$metadata_path"

      case "$metadata_path" in
        renderer-assets.sha256|renderer-assets.lock)
          fail "Renderer asset metadata lock must describe renderer assets, not manifest files: ${metadata_path}."
          ;;
      esac

      metadata_fields=(
        "upstream name:${metadata_upstream_name}"
        "upstream version:${metadata_upstream_version}"
        "license notes:${metadata_license}"
      )
      for metadata_field in "${metadata_fields[@]}"; do
        metadata_field_label="${metadata_field%%:*}"
        metadata_field_value="${metadata_field#*:}"
        validate_renderer_metadata_field "$metadata_field_label" "$metadata_field_value" "$metadata_path"
      done

      metadata_asset="${root}/${metadata_path}"
      if [ ! -f "$metadata_asset" ]; then
        fail "Renderer asset metadata lock references missing asset: ${metadata_path}."
      else
        computed_hash="$(shasum -a 256 "$metadata_asset" | awk '{print $1}')"
        if [ "$computed_hash" != "$metadata_hash" ]; then
          fail "Renderer asset metadata lock hash does not match packaged asset: ${metadata_path}."
        fi
      fi

      listed_in_manifest=0
      for manifest_path in "${manifest_paths[@]}"; do
        if [ "$manifest_path" = "$metadata_path" ]; then
          listed_in_manifest=1
          break
        fi
      done

      if [ "$listed_in_manifest" -eq 0 ]; then
        fail "Renderer asset metadata lock path is missing from SHA-256 manifest: ${metadata_path}."
      fi

      metadata_paths+=("$metadata_path")
    done < "$metadata_lock"

    metadata_lock_listed=0
    for manifest_path in "${manifest_paths[@]}"; do
      if [ "$manifest_path" = "renderer-assets.lock" ]; then
        metadata_lock_listed=1
        break
      fi
    done

    if [ "$metadata_lock_listed" -eq 0 ]; then
      fail "Renderer asset metadata lock must be included in renderer-assets.sha256."
    fi

    while IFS= read -r packaged_asset; do
      packaged_path="${packaged_asset#"$root"/}"
      if [ "$packaged_path" = "renderer-assets.sha256" ]; then
        continue
      fi

      validate_renderer_asset_path "Packaged renderer asset path inside ${root#./}" "$packaged_path"

      listed=0
      for manifest_path in "${manifest_paths[@]}"; do
        if [ "$manifest_path" = "$packaged_path" ]; then
          listed=1
          break
        fi
      done

      if [ "$listed" -eq 0 ]; then
        fail "Renderer asset is packaged but missing from hash manifest: ${packaged_path}."
      fi

      if [ "$packaged_path" != "renderer-assets.lock" ]; then
        metadata_listed=0
        for metadata_path in "${metadata_paths[@]}"; do
          if [ "$metadata_path" = "$packaged_path" ]; then
            metadata_listed=1
            break
          fi
        done

        if [ "$metadata_listed" -eq 0 ]; then
          fail "Renderer asset is packaged but missing from metadata lock: ${packaged_path}."
        fi
      fi
    done < <(find "$root" -type f | sort)

    if (cd "$root" && shasum -a 256 -c renderer-assets.sha256); then
      pass "Renderer asset SHA-256 manifest verifies for ${root#./}."
    else
      fail "Renderer asset SHA-256 manifest verification failed for ${root#./}."
    fi

    while IFS= read -r asset; do
      if rg -n -i "$dangerous_renderer_asset_pattern" "$asset"; then
        fail "Remote subresource, external navigation, iframe, javascript/data/file/content URL reference found in ${asset#./}."
      fi
      if rg -n -i "$html_entity_dangerous_renderer_asset_pattern" "$asset"; then
        fail "HTML entity-encoded remote subresource, external navigation, or dangerous URL reference found in ${asset#./}."
      fi
      if rg -n "$network_api_pattern" "$asset"; then
        fail "Network-capable renderer API found in ${asset#./}; isolated renderer assets must not initiate network requests."
      fi
      if rg -n -i "$dynamic_code_pattern" "$asset"; then
        fail "Dynamic code execution marker found in ${asset#./}; isolated renderer assets must not evaluate generated code."
      fi
      scan_decoded_javascript_escapes "$asset"
    done < <(find "$root" -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.html' -o -name '*.htm' -o -name '*.svg' \) | sort)
  done
fi

if [ "$failure" -ne 0 ]; then
  exit 1
fi
