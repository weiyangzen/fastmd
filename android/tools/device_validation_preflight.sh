#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
ADB_BIN="$SDK_DIR/platform-tools/adb"
EMULATOR_BIN="$SDK_DIR/emulator/emulator"
SYSTEM_IMAGES_DIR="$SDK_DIR/system-images"

failures=0

section() {
  printf '\n== %s ==\n' "$1"
}

pass() {
  printf 'PASS: %s\n' "$1"
}

blocked() {
  printf 'BLOCKED: %s\n' "$1"
  failures=$((failures + 1))
}

info() {
  printf 'INFO: %s\n' "$1"
}

device_prop() {
  local serial="$1"
  local prop="$2"
  "$ADB_BIN" -s "$serial" shell getprop "$prop" 2>/dev/null | tr -d '\r'
}

device_wm_size() {
  local serial="$1"
  "$ADB_BIN" -s "$serial" shell wm size 2>/dev/null | tr -d '\r' | sed -n 's/^Physical size: //p' | head -n 1
}

device_mem_total_kb() {
  local serial="$1"
  "$ADB_BIN" -s "$serial" shell cat /proc/meminfo 2>/dev/null |
    tr -d '\r' |
    awk '/^MemTotal:/ { print $2; exit }'
}

section "Android Device Validation Preflight"
info "Android project: $ROOT_DIR"
info "Android SDK: $SDK_DIR"
info "JAVA_HOME: ${JAVA_HOME:-unset}"

if [ ! -x "$ADB_BIN" ]; then
  blocked "ADB is unavailable at $ADB_BIN."
  exit 1
fi

section "ADB Devices"
"$ADB_BIN" devices -l

attached_devices=()
while IFS= read -r serial; do
  if [ -n "$serial" ]; then
    attached_devices+=("$serial")
  fi
done < <("$ADB_BIN" devices | awk 'NR > 1 && $2 == "device" { print $1 }')
if [ "${#attached_devices[@]}" -eq 0 ]; then
  blocked "No attached Android device or booted emulator is available for connectedDebugAndroidTest."
else
  pass "Found ${#attached_devices[@]} attached Android device(s)."
fi

api27_device_found=0
low_memory_device_found=0
modern_device_found=0

if [ "${#attached_devices[@]}" -gt 0 ]; then
  for serial in "${attached_devices[@]}"; do
    api_level="$(device_prop "$serial" ro.build.version.sdk)"
    model="$(device_prop "$serial" ro.product.model)"
    manufacturer="$(device_prop "$serial" ro.product.manufacturer)"
    size="$(device_wm_size "$serial")"
    mem_kb="$(device_mem_total_kb "$serial")"
    mem_mb=0
    if [[ "$mem_kb" =~ ^[0-9]+$ ]]; then
      mem_mb=$((mem_kb / 1024))
    fi

    printf 'DEVICE: serial=%s api=%s model="%s %s" size=%s memMb=%s\n' \
      "$serial" "${api_level:-unknown}" "${manufacturer:-unknown}" "${model:-unknown}" "${size:-unknown}" "$mem_mb"

    if [ "$api_level" = "27" ]; then
      api27_device_found=1
    fi

    if [[ "$mem_mb" -gt 0 && "$mem_mb" -le 2048 ]]; then
      low_memory_device_found=1
    fi

    if [[ "$api_level" =~ ^[0-9]+$ && "$api_level" -ge 34 ]]; then
      modern_device_found=1
    fi
  done
fi

section "System Images"
if [ -d "$SYSTEM_IMAGES_DIR" ]; then
  find "$SYSTEM_IMAGES_DIR" -maxdepth 4 -type d | sort
else
  blocked "Android SDK system-images directory is missing at $SYSTEM_IMAGES_DIR."
fi

if find "$SYSTEM_IMAGES_DIR" -maxdepth 2 -type d -name 'android-27' 2>/dev/null | grep -q .; then
  pass "Android API 27 system image is installed."
else
  blocked "No Android API 27 system image is installed under $SYSTEM_IMAGES_DIR."
fi

section "AVDs"
if [ -x "$EMULATOR_BIN" ]; then
  "$EMULATOR_BIN" -list-avds || true
else
  blocked "Android emulator binary is unavailable at $EMULATOR_BIN."
fi

section "Checklist Readiness"
if [ "$api27_device_found" -eq 1 ]; then
  pass "An attached API 27 device/emulator is ready for Android 8.1 validation."
else
  blocked "No attached API 27 device/emulator is ready for Android 8.1 validation."
fi

if [ "$low_memory_device_found" -eq 1 ]; then
  pass "An attached low-memory device/emulator is ready for small-screen or low-memory validation."
else
  blocked "No attached low-memory device/emulator was detected for low-memory/small-screen validation."
fi

if [ "$modern_device_found" -eq 1 ]; then
  pass "An attached API 34+ device/emulator is ready for modern-device validation."
else
  blocked "No attached API 34+ device/emulator is ready for modern-device validation."
fi

section "Summary"
if [ "$failures" -eq 0 ]; then
  pass "Android device validation preflight passed."
else
  printf 'BLOCKED: Android device validation preflight found %s blocker(s).\n' "$failures"
  exit 2
fi
