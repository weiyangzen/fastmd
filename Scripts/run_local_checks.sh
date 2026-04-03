#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

cd "${repo_root}"

required_paths=(
  "Docs/Test_Logs/README.md"
  "Docs/Screenshots/README.md"
  "Docs/Manual_Test_Plan.md"
  "Tests/Fixtures/Markdown/basic.md"
  "Tests/Fixtures/Markdown/cjk.md"
  "Tests/Fixtures/Markdown/not-markdown.txt"
  "Tests/Fixtures/RenderedHTML/basic.html"
  "Tests/Fixtures/RenderedHTML/cjk.html"
  "Tests/Fixtures/FinderAX/README.md"
  "Scripts/run_local_checks.sh"
  "Scripts/run_manual_smoke.sh"
)

echo "==> Verifying required artifact paths"
for path in "${required_paths[@]}"; do
  if [[ ! -e "${path}" ]]; then
    echo "Missing required artifact: ${path}" >&2
    exit 1
  fi
done

echo "==> Verifying script syntax"
bash -n "Scripts/run_local_checks.sh"
bash -n "Scripts/run_manual_smoke.sh"

echo "==> Verifying script executability"
for script in "Scripts/run_local_checks.sh" "Scripts/run_manual_smoke.sh"; do
  if [[ ! -x "${script}" ]]; then
    echo "Script is not executable: ${script}" >&2
    exit 1
  fi
done

echo "==> swift build"
swift build

echo "==> swift test"
swift test

echo "==> Local checks completed successfully"
