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
  "Scripts/capture_finder_ax_snapshot.swift"
  "Scripts/generate_xcodeproj.rb"
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
ruby -c "Scripts/generate_xcodeproj.rb"
swiftc -typecheck "Scripts/capture_finder_ax_snapshot.swift"

echo "==> Verifying script executability"
for script in "Scripts/capture_finder_ax_snapshot.swift" "Scripts/generate_xcodeproj.rb" "Scripts/run_local_checks.sh" "Scripts/run_manual_smoke.sh"; do
  if [[ ! -x "${script}" ]]; then
    echo "Script is not executable: ${script}" >&2
    exit 1
  fi
done

echo "==> swift build"
swift build

echo "==> swift test"
swift test

echo "==> Regenerating Xcode project"
Scripts/generate_xcodeproj.rb

generated_paths=(
  "FastMD.xcodeproj/project.pbxproj"
  "FastMD.xcodeproj/xcshareddata/xcschemes/FastMD.xcscheme"
)

echo "==> Verifying generated Xcode project artifacts"
for path in "${generated_paths[@]}"; do
  if [[ ! -e "${path}" ]]; then
    echo "Missing generated Xcode project artifact: ${path}" >&2
    exit 1
  fi
done

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is required to validate FastMD.xcodeproj" >&2
  exit 1
fi

echo "==> xcodebuild -list"
xcodebuild -list -project FastMD.xcodeproj >/dev/null

echo "==> xcodebuild build"
xcodebuild -project FastMD.xcodeproj -scheme FastMD -destination 'platform=macOS,arch=arm64' build >/dev/null

echo "==> xcodebuild test"
xcodebuild -project FastMD.xcodeproj -scheme FastMD -destination 'platform=macOS,arch=arm64' test >/dev/null

echo "==> Local checks completed successfully"
