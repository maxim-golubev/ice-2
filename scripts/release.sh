#!/bin/zsh
# Builds the release archive from HEAD: a clean Release build numbered by the commit count,
# signed with the project's identity and team, its signature verified before and after zipping,
# as build/release/Ice-2-<version>.zip, plus the Sparkle signature of that zip in
# build/release/Ice-2-<version>.edsig. Refuses a dirty working tree. Exits non-zero, leaving no
# archive, when the build or any check fails.
# Usage: scripts/release.sh
cd "$(dirname "$0")/.."
key=~/.ice2-signing/sparkle_ed25519
fail() { print -u2 -r -- "release: $1"; rm -f "${zip:-}" "${edsig:-}"; rm -rf build/release/check; exit 1 }

[[ -z $(git status --porcelain) ]] || fail "the working tree has uncommitted changes; commit them first"
[[ -r $key ]] || fail "no Sparkle signing key at $key"

settings=$(xcodebuild -project Ice.xcodeproj -scheme Ice -configuration Release -showBuildSettings 2>/dev/null) \
  || fail "the project's build settings cannot be read"
setting() { print -r -- "$settings" | sed -n "s/^ *$1 = //p" | head -1 }
identity=$(setting 'CODE_SIGN_IDENTITY')
team=$(setting DEVELOPMENT_TEAM)
[[ -n $identity && -n $team ]] || fail "the project names no signing identity or team"

build_number=$(git rev-list --count HEAD)
commit_date=$(git log -1 --format=%cI)
out=$(xcodebuild -project Ice.xcodeproj -scheme Ice -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath build/release-dd \
  CURRENT_PROJECT_VERSION="$build_number" DRAGON_COMMIT_DATE="$commit_date" clean build 2>&1)
rc=$?
print -r -- "$out" | grep -E 'error:|BUILD (SUCCEEDED|FAILED)' | sort -u
(( rc == 0 )) || fail "the build failed"
app="build/release-dd/Build/Products/Release/Ice 2.app"
[[ -d $app ]] || fail "no app at $app"

# The signature holds, is the project's, and has the hardened runtime
codesign --verify --deep --strict "$app" || fail "the signature of $app does not verify"
signature=$(codesign -dvv "$app" 2>&1)
print -r -- "$signature" | grep -q "^Authority=$identity" || fail "$app is not signed with \"$identity\""
print -r -- "$signature" | grep -q "^TeamIdentifier=$team\$" || fail "$app is not signed by team $team"
print -r -- "$signature" | grep -q '^CodeDirectory.*flags=.*runtime' || fail "$app is not signed with the hardened runtime"

plist="$app/Contents/Info.plist"
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$plist") || fail "the app has no version"
[[ $(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$plist") == $build_number ]] \
  || fail "the app's build number is not $build_number"

mkdir -p build/release
zip=build/release/Ice-2-$version.zip
edsig=build/release/Ice-2-$version.edsig
rm -f "$zip" "$edsig"
ditto -c -k --keepParent "$app" "$zip" || fail "the archive could not be written"

# What a download unpacks to must verify too
rm -rf build/release/check
ditto -x -k "$zip" build/release/check || fail "the archive cannot be unpacked"
codesign --verify --deep --strict "build/release/check/Ice 2.app" || fail "the unpacked app's signature does not verify"
rm -rf build/release/check

sign_update=build/release-dd/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update
[[ -x $sign_update ]] || fail "Sparkle's sign_update is missing from $sign_update"
"$sign_update" --ed-key-file "$key" -p "$zip" > "$edsig" || fail "the archive could not be signed for Sparkle"
"$sign_update" --verify --ed-key-file "$key" "$zip" "$(<$edsig)" || fail "the archive's Sparkle signature does not verify"

print -r -- "Ice 2 $version ($build_number), built from $(git rev-parse --short HEAD), signed by $(print -r -- "$signature" | sed -n 's/^Authority=//p' | head -1)"
print -r -- "$zip"
shasum -a 256 "$zip" | cut -d ' ' -f 1
