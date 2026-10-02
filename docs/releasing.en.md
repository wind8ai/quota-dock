# Build, signing, and distribution

[中文](releasing.md) | **English**

## Build inputs

Maintain the version and build number only in `Resources/Info.plist`. Before distribution, commit the project changes and record the macOS, Swift, SDK, and target architecture. Use `DEVELOPER_DIR` to select an installed toolchain when needed.

```sh
./scripts/package.sh
```

The script runs tests, creates a release build, verifies the signature, and packages the app with `ditto`. It writes these files to `dist/`:

- `QuotaDock-<version>-<build>-<arch>.zip`
- A matching `.sha256`
- A matching `.build-info.txt` with the source commit, working-tree state, toolchain, and signing identity

The build targets the host architecture; it is not a universal binary. Keep the ZIP, checksum, and build record together. The workflow can be rerun, but different SDKs, signing timestamps, and archive metadata can produce different hashes.

## Signing

The default ad-hoc signature is for local verification. It is not Developer ID signing or Apple notarization.

With an existing Developer ID Application certificate:

```sh
SIGNING_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)' ./scripts/package.sh
```

Certificate signing enables the hardened runtime and a secure timestamp. Manage certificates and private keys in the local Keychain; do not commit them.

For public binary distribution, follow Apple's [Developer ID](https://developer.apple.com/developer-id/) and [notarization documentation](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution). This repository currently has no published notarized binary.

After notarization is accepted, staple and verify the ticket on the `.app`, then repackage it with `ditto -c -k --sequesterRsrc --keepParent` and update the checksum. Do not rerun `package.sh` over an already stapled app.

## Source and artifacts

Public source is at [wind8ai/quota-dock](https://github.com/wind8ai/quota-dock). Standalone repository tags use `v<version>`; the maintenance monorepo uses `quota-dock/v<version>`. Source pushes, version tags, and binary releases are separate steps. A source push does not mean a binary has been published.

Git stores source, tests, scripts, and documentation assets. Build caches, app bundles, ZIP archives, real sessions, quota caches, and screenshots of actual usage are excluded. Documentation previews use synthetic quota values and show only the gauge and example avatar.

## Tooling

Build with Apple's `swiftc` and run tests with native Swift assertions. SwiftPM and the XCTest runtime are not required. Tests compile with `-Onone`; failed assertions return a nonzero exit code. Data and geometry rules live in `Sources/QuotaCore/`; AppKit windows and drawing live in `Sources/QuotaDock/`.
