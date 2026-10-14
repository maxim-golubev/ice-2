#!/bin/zsh
# Builds the app (Debug, ad-hoc signed) into build/dd and prints the .app path. Exits non-zero on failure.
# Usage: scripts/build.sh [-q]
cd "$(dirname "$0")/.."
out=$(xcodebuild -project Ice.xcodeproj -scheme Ice -configuration Debug \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath build/dd build 2>&1)
rc=$?
print -r -- "$out" | grep -E 'error:|BUILD (SUCCEEDED|FAILED)' | sort -u
[[ $1 == -q ]] || print -r -- "$out" | grep -E 'warning:' | grep -v -E 'SourcePackages|appintentsmetadataprocessor|SwiftLint not installed' | sort -u | head -40
(( rc == 0 )) && ls -d "build/dd/Build/Products/Debug/Ice 2 Debug.app"
exit $rc
