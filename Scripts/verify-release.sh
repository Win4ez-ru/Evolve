#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_root="${script_dir:h}"
destination="${EVOLVE_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"
destination_timeout="${EVOLVE_DESTINATION_TIMEOUT:-60}"
derived_data="${EVOLVE_DERIVED_DATA:-${TMPDIR:-/tmp}/EvolveDerivedData}"

cd "$project_root"

echo "==> Running Evolve tests on ${destination}"
xcodebuild \
  -project Evolve.xcodeproj \
  -scheme Evolve \
  -destination "$destination" \
  -destination-timeout "$destination_timeout" \
  -parallel-testing-enabled NO \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  test

echo "==> Compiling the unsigned Release device build"
xcodebuild \
  -project Evolve.xcodeproj \
  -scheme Evolve \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  build

built_app="${derived_data}/Build/Products/Release-iphoneos/Evolve.app"
privacy_manifest="${built_app}/PrivacyInfo.xcprivacy"
info_plist="${built_app}/Info.plist"

echo "==> Verifying release privacy metadata"
test -f "$privacy_manifest"
plutil -lint "$privacy_manifest"
test "$(/usr/libexec/PlistBuddy -c 'Print :ITSAppUsesNonExemptEncryption' "$info_plist")" = "false"

echo "==> Evolve release verification passed"
