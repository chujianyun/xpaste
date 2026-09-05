#!/bin/zsh
set -euo pipefail

script_dir="${0:A:h}"
project_root="${script_dir:h}"
build_dir="${project_root}/build"
archive_path="${build_dir}/WPaste.xcarchive"
dmg_path="${build_dir}/WPaste.dmg"

mkdir -p "${build_dir}"
"/opt/homebrew/opt/xcodegen/bin/xcodegen" generate --spec "${project_root}/project.yml" --project "${project_root}"

signing_identity=DC86852A3142B093C0D6EF89F9978BC63349E0AF
signing_requirement="identifier \"com.chujianyun.wpaste\" and anchor apple generic and certificate leaf = H\"${signing_identity}\""
if ! security find-identity -v -p codesigning | /usr/bin/grep -Fq "${signing_identity}"; then
  echo "Required WPaste signing certificate is unavailable: ${signing_identity}" >&2
  exit 1
fi

xcodebuild test \
  -quiet \
  -project "${project_root}/WPaste.xcodeproj" \
  -scheme WPaste \
  -destination "platform=macOS,arch=$(uname -m)"

xcodebuild archive \
  -quiet \
  -project "${project_root}/WPaste.xcodeproj" \
  -scheme WPaste \
  -destination 'generic/platform=macOS' \
  -configuration Release \
  -archivePath "${archive_path}"

codesign --verify --deep --strict -R "=${signing_requirement}" \
  "${archive_path}/Products/Applications/WPaste.app"

rm -f "${dmg_path}"
hdiutil create \
  -volname WPaste \
  -srcfolder "${archive_path}/Products/Applications/WPaste.app" \
  -ov \
  -format UDZO \
  "${dmg_path}"

echo "Created ${dmg_path}"
