#!/usr/bin/env bash
# Builds an unsigned Release Runner.app for SideStore to sign.
# flutter's --no-codesign build can still trip "requires a development team"
# on package targets, so configure with flutter and build with xcodebuild,
# turning signing off for every target.
set -euo pipefail
ruby tools/ios/add_extension.rb
cd apps/remote
flutter build ios --release --config-only --no-codesign
log=$(mktemp)
set +e
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/xcode \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" \
  build >"$log" 2>&1
code=$?
set -e
grep -E "(error|warning: .*(entitlement|signing))[: ]|BUILD (SUCCEEDED|FAILED)" "$log" | grep -v "^ld: warning" | tail -80 || true
if [ $code != 0 ]; then tail -60 "$log"; exit $code; fi
app=$(find build/xcode/Build/Products/Release-iphoneos -maxdepth 1 -name 'Runner.app' | head -1)
mkdir -p build/ios/iphoneos
rm -rf build/ios/iphoneos/Runner.app
cp -R "$app" build/ios/iphoneos/Runner.app
ls build/ios/iphoneos/Runner.app | head
