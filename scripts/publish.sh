#!/bin/zsh
# Publishes the archive scripts/release.sh built: a GitHub release v<version> on
# maxim-golubev/ice-2 carrying Ice-2-<version>.zip, then a new item at the top of appcast.xml,
# committed and pushed, which is what every installed copy's update check reads.
# Refuses an archive built from anything but HEAD, a HEAD that is not pushed, and an existing tag.
# Usage: scripts/publish.sh --notes-file <markdown outside the checkout>
cd "$(dirname "$0")/.."
repo=maxim-golubev/ice-2
fail() { print -u2 -r -- "publish: $1"; exit 1 }

[[ $1 == --notes-file && -r $2 ]] || fail "usage: scripts/publish.sh --notes-file <file>"
notes=$2

app="build/release-dd/Build/Products/Release/Ice 2.app"
plist="$app/Contents/Info.plist"
[[ -r $plist ]] || fail "no release build; run scripts/release.sh first"
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$plist")
build_number=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$plist")
minimum_system=$(/usr/libexec/PlistBuddy -c 'Print LSMinimumSystemVersion' "$plist")
zip=build/release/Ice-2-$version.zip
edsig=build/release/Ice-2-$version.edsig
[[ -r $zip && -r $edsig ]] || fail "no signed archive for $version; run scripts/release.sh"

[[ -z $(git status --porcelain) ]] || fail "the working tree has uncommitted changes"
[[ $build_number == $(git rev-list --count HEAD) ]] || fail "the build ($build_number) is not of HEAD; run scripts/release.sh again"
git fetch -q origin main || fail "origin cannot be reached"
[[ $(git rev-parse HEAD) == $(git rev-parse origin/main) ]] || fail "HEAD is not what origin/main holds; push first"
tag=v$version
git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null && fail "$tag already exists on origin"

gh release create "$tag" "$zip" --repo "$repo" --target "$(git rev-parse HEAD)" \
  --title "Ice 2 $version" --notes-file "$notes" || fail "the GitHub release could not be created"

# The release notes as Sparkle shows them: each "- " line a list item, other lines paragraphs.
description=$(sed -E -e 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' \
  -e 's/^- (.*)$/<li>\1<\/li>/' -e '/^<li>/!s/^(.+)$/<p>\1<\/p>/' "$notes")
item="        <item>
            <title>$version</title>
            <pubDate>$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')</pubDate>
            <sparkle:version>$build_number</sparkle:version>
            <sparkle:shortVersionString>$version</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>$minimum_system</sparkle:minimumSystemVersion>
            <sparkle:hardwareRequirements>arm64</sparkle:hardwareRequirements>
            <description><![CDATA[<ul>$description</ul>]]></description>
            <enclosure url=\"https://github.com/$repo/releases/download/$tag/Ice-2-$version.zip\" length=\"$(stat -f %z "$zip")\" type=\"application/octet-stream\" sparkle:edSignature=\"$(<$edsig)\"/>
        </item>"
print -r -- "$item" > build/release/appcast-item.xml
awk -v itemfile=build/release/appcast-item.xml '
  { print }
  /<title>Ice 2<\/title>/ { while ((getline line < itemfile) > 0) print line }
' appcast.xml > build/release/appcast.xml || fail "appcast.xml could not be updated"
mv build/release/appcast.xml appcast.xml
xmllint --noout appcast.xml || fail "appcast.xml is not well-formed"

git add appcast.xml
git commit -q -m "Appcast: Ice 2 $version" || fail "the appcast could not be committed"
git push -q origin HEAD:main || fail "the appcast commit could not be pushed"
print -r -- "Published Ice 2 $version: https://github.com/$repo/releases/tag/$tag"
