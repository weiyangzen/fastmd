#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
fixture_dir="${repo_root}/Tests/Fixtures/Markdown"
fixture_file="${fixture_dir}/basic.md"
manual_plan="${repo_root}/Docs/Manual_Test_Plan.md"
logs_dir="${repo_root}/Docs/Test_Logs"
screenshots_dir="${repo_root}/Docs/Screenshots"

if [[ ! -f "${fixture_file}" ]]; then
  echo "Primary smoke fixture not found: ${fixture_file}" >&2
  exit 1
fi

mkdir -p "${logs_dir}" "${screenshots_dir}"

timestamp="$(date +%Y%m%d-%H%M%S)"
session_note="${logs_dir}/manual-smoke-${timestamp}.md"
app_log="${logs_dir}/manual-smoke-${timestamp}.app.log"

accessibility_status="$(
  swift -e 'import ApplicationServices; print(AXIsProcessTrusted() ? "trusted" : "not trusted")' 2>/dev/null || echo "unknown"
)"

cat > "${session_note}" <<EOF
# Manual Smoke Session ${timestamp}

- Repo: ${repo_root}
- Fixture directory: ${fixture_dir}
- Primary fixture: ${fixture_file}
- Manual plan: Docs/Manual_Test_Plan.md
- App log: Docs/Test_Logs/$(basename "${app_log}")
- Accessibility trusted before launch: ${accessibility_status}

## Checklist

- [ ] FastMD status item appears in the menu bar
- [ ] Pause/Resume monitoring toggles correctly
- [ ] Permission request menu action is reachable
- [ ] Finder list-view hover previews \`basic.md\`
- [ ] Finder list-view hover previews \`cjk.md\`
- [ ] Non-Markdown files do not preview
- [ ] Preview hides on mouse movement or scroll
- [ ] Preview hides when Finder loses focus

## Notes

EOF

cd "${repo_root}"

echo "==> Building FastMD"
swift build

app_binary="${repo_root}/.build/debug/FastMD"
if [[ ! -x "${app_binary}" ]]; then
  echo "Expected app binary not found after build: ${app_binary}" >&2
  exit 1
fi

echo "==> Opening manual plan and fixture directory"
open "${manual_plan}"
open "${fixture_dir}"
/usr/bin/osascript -e 'tell application "Finder" to activate' >/dev/null 2>&1 || true

echo "==> Launching FastMD"
"${app_binary}" > "${app_log}" 2>&1 &
app_pid=$!

cleanup() {
  if kill -0 "${app_pid}" >/dev/null 2>&1; then
    kill "${app_pid}" >/dev/null 2>&1 || true
    wait "${app_pid}" 2>/dev/null || true
  fi
}

trap cleanup EXIT

printf '\n'
printf 'Manual smoke session started.\n'
printf 'Accessibility status before launch: %s\n' "${accessibility_status}"
printf 'Manual plan: %s\n' "${manual_plan}"
printf 'Session log template: %s\n' "${session_note}"
printf 'App log: %s\n' "${app_log}"
printf 'Fixture directory: %s\n' "${fixture_dir}"
printf '\n'
printf 'Use Finder list view and hover basic.md or cjk.md for at least 1 second.\n'
printf 'Record screenshots under %s if needed.\n' "${screenshots_dir}"
printf '\n'
read -r -p "Press Enter after the smoke pass to stop FastMD..."

printf 'FastMD stopped. Update %s with the observed pass or fail results.\n' "${session_note}"
