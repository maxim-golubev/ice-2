#!/bin/zsh
# Runs the IceTests suite (hosted in the Debug app) and prints the failures and the summary.
# Usage: scripts/test.sh
cd "$(dirname "$0")/.."
out=$(xcodebuild test -project Ice.xcodeproj -scheme Ice \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath build/dd 2>&1)
rc=$?
print -r -- "$out" | grep -E 'error:|^✘|Test run with|TEST (SUCCEEDED|FAILED)' | grep -v 'failed after'
exit $rc
