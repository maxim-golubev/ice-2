# Releasing Ice 2

Releases are built, signed and published from the Mac that holds the signing
identity and the Sparkle key. Nothing runs in CI.

## What is needed

- The **Apple Development** certificate of team `N42Q7FY9FL` in the login
  keychain (`security find-identity -v -p codesigning` lists it). The Release
  configuration signs manually with it, hardened runtime on. Releases are not
  notarized, so a download opened on another Mac needs **Open Anyway** once.
- The Sparkle EdDSA private key at `~/.ice2-signing/sparkle_ed25519` (base64 of
  the 32-byte seed, mode 600). Its public half is `SUPublicEDKey` in
  `App/Info.plist`. Back this file up: without it no installed copy accepts
  another update, and a new key means everyone reinstalls by hand.
- `gh` signed in to the `maxim-golubev` account.

## Cutting a release

1. Bump `MARKETING_VERSION` in `Ice.xcodeproj` (app target, Debug and Release),
   add the version's entry to `CHANGELOG.md`, and commit. The build number is
   not edited by hand: `scripts/release.sh` sets `CURRENT_PROJECT_VERSION` to
   the commit count, which only grows, and Sparkle compares it.
2. `scripts/release.sh` builds a clean Release of HEAD, checks the signature
   (identity, team, hardened runtime) before and after zipping, and writes
   `build/release/Ice-2-<version>.zip` with its Sparkle signature beside it.
   It refuses a dirty working tree.
3. Use that build on this Mac before publishing it: quit Ice 2, replace
   `/Applications/Ice 2.app` with
   `ditto "build/release-dd/Build/Products/Release/Ice 2.app" "/Applications/Ice 2.app"`
   (after moving the old copy away), and try everything the release changed.
4. `git push`, then `scripts/publish.sh --notes-file ~/ice2-notes.md` (notes kept
   outside the checkout). It refuses a build that is not of HEAD, a HEAD that is
   not on `origin/main`, and an existing tag. It creates the GitHub release
   `v<version>` with the zip, adds the release to the top of `appcast.xml`,
   commits that and pushes it.
5. Check the feed the app reads:

   ```bash
   curl -s https://raw.githubusercontent.com/maxim-golubev/ice-2/main/appcast.xml | grep shortVersionString
   ```

## Notes

- The bundle id is `com.maximgolubev.Ice2` (`com.maximgolubev.Ice2.debug` for
  Debug builds); its settings, permissions and backups are separate from
  Teddy Chan's Ice 2 (`com.dragonapp.ice`).
- Keep only `/Applications/Ice 2.app` on the Mac. Spotlight and LaunchServices
  list every other copy, so after installing, unregister and delete build
  products that hold an app: `lsregister -u <path>` (in
  `/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/`),
  then `rm -rf` the copy.
