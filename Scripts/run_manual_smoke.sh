#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
fixture_dir="${repo_root}/Tests/Fixtures/Markdown"
fixture_file="${fixture_dir}/basic.md"
cjk_fixture="${fixture_dir}/cjk.md"
negative_fixture="${fixture_dir}/not-markdown.txt"
manual_plan="${repo_root}/Docs/Manual_Test_Plan.md"
logs_dir="${repo_root}/Docs/Test_Logs"
screenshots_dir="${repo_root}/Docs/Screenshots"

required_files=(
  "${fixture_file}"
  "${cjk_fixture}"
  "${negative_fixture}"
  "${manual_plan}"
)

for required_file in "${required_files[@]}"; do
  if [[ ! -f "${required_file}" ]]; then
    echo "Required smoke artifact not found: ${required_file}" >&2
    exit 1
  fi
done

attempt_finder_list_view() {
  /usr/bin/osascript <<'APPLESCRIPT' >/dev/null 2>&1 &
tell application "Finder"
  activate
  if (count of Finder windows) is greater than 0 then
    set current view of front Finder window to list view
  end if
end tell
APPLESCRIPT

  local osa_pid=$!
  local elapsed=0

  while kill -0 "${osa_pid}" >/dev/null 2>&1; do
    if (( elapsed >= 5 )); then
      kill "${osa_pid}" >/dev/null 2>&1 || true
      wait "${osa_pid}" 2>/dev/null || true
      printf 'Warning: Finder list-view request timed out; switch Finder to list view manually if needed.\n' >&2
      return 0
    fi

    sleep 1
    elapsed=$((elapsed + 1))
  done

  wait "${osa_pid}" 2>/dev/null || true
}

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
- UTF-8 fixture: ${cjk_fixture}
- Negative fixture: ${negative_fixture}
- Manual plan: Docs/Manual_Test_Plan.md
- App log: Docs/Test_Logs/$(basename "${app_log}")
- Accessibility trusted before launch: ${accessibility_status}

## Checklist

- [ ] FastMD status item appears in the menu bar
- [ ] Pause/Resume monitoring toggles correctly
- [ ] Permission request menu action is reachable
- [ ] Finder list-view hover previews \`basic.md\`
- [ ] Finder list-view hover previews \`cjk.md\`
- [ ] Finder list-view hover does not preview \`not-markdown.txt\`
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
sleep 1
attempt_finder_list_view

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
printf 'Use Finder list view and hover basic.md, cjk.md, and not-markdown.txt for at least 1 second.\n'
printf 'Record screenshots under %s if needed.\n' "${screenshots_dir}"
printf '\n'
read -r -p "Press Enter after the smoke pass to stop FastMD..."

printf 'FastMD stopped. Update %s with the observed pass or fail results.\n' "${session_note}"
