#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
repo_root="${script_dir:h}"
project="${repo_root}/WarGamesScreenSaver/wgss/wgss.xcodeproj"
build_root="${repo_root}/build"
built_saver="${build_root}/Build/Products/Release/wgss.saver"
install_root="${HOME}/Library/Screen Savers"
installed_saver="${install_root}/wgss.saver"

/usr/bin/xcodebuild \
  -project "${project}" \
  -scheme wgss \
  -configuration Release \
  -derivedDataPath "${build_root}" \
  CODE_SIGN_IDENTITY=- \
  build

if [[ ! -d "${built_saver}" ]]; then
  print -u2 "Build succeeded but ${built_saver} was not created."
  exit 1
fi

/bin/mkdir -p "${install_root}"

# Guard the only destructive operation so it can target only this saver bundle.
if [[ "${installed_saver}" != "${install_root}/wgss.saver" ]]; then
  print -u2 "Refusing to replace unexpected path: ${installed_saver}"
  exit 1
fi

/bin/rm -rf -- "${installed_saver}"
/usr/bin/ditto "${built_saver}" "${installed_saver}"
/usr/bin/codesign --verify --deep --strict "${installed_saver}"

print "Installed ${installed_saver}"
print "Select wgss in System Settings > Screen Saver."
