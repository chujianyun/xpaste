#!/bin/zsh
set -euo pipefail

script_dir="${0:A:h}"
project_root="${script_dir:h}"
build_dir="${project_root}/build"
archive_path="${build_dir}/WPaste.xcarchive"
dmg_path="${build_dir}/WPaste.dmg"

mkdir -p "${build_dir}"
"/opt/homebrew/opt/xcodegen/bin/xcodegen" generate --spec "${project_root}/project.yml" --project "${project_root}"

signing_args=(CODE_SIGNING_ALLOWED=NO)
if [[ -n "${WP_DEVELOPMENT_TEAM:-}" && -n "${WP_CODE_SIGN_IDENTITY:-}" ]]; then
  signing_args=(
    CODE_SIGNING_ALLOWED=YES
    CODE_SIGN_STYLE=Manual
    "DEVELOPMENT_TEAM=${WP_DEVELOPMENT_TEAM}"
    "CODE_SIGN_IDENTITY=${WP_CODE_SIGN_IDENTITY}"
  )
fi

xcodebuild test \
  -quiet \
  -project "${project_root}/WPaste.xcodeproj" \
  -scheme WPaste \
  -destination "platform=macOS,arch=$(uname -m)" \
  "${signing_args[@]}"

xcodebuild archive \
  -quiet \
  -project "${project_root}/WPaste.xcodeproj" \
  -scheme WPaste \
  -destination 'generic/platform=macOS' \
  -configuration Release \
  -archivePath "${archive_path}" \
  "${signing_args[@]}"

rm -f "${dmg_path}"
hdiutil create \
  -volname WPaste \
  -srcfolder "${archive_path}/Products/Applications/WPaste.app" \
  -ov \
  -format UDZO \
  "${dmg_path}"

echo "Created ${dmg_path}"
