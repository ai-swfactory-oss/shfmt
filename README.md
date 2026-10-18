# shfmt

[![update](https://github.com/ai-swfactory-oss/shfmt/actions/workflows/update.yml/badge.svg)](https://github.com/ai-swfactory-oss/shfmt/actions/workflows/update.yml)
[![build](https://github.com/ai-swfactory-oss/shfmt/actions/workflows/build.yml/badge.svg)](https://github.com/ai-swfactory-oss/shfmt/actions/workflows/build.yml)

[shfmt](https://github.com/mvdan/sh) (mvdan/sh) as npm packages: the **native upstream binary** per platform, updated and published automatically to GitHub Packages. No WASM, no download at install time, no install scripts.

| Package | What |
|---|---|
| `@ai-swfactory-oss/shfmt` | Thin: the `shfmt` bin, and `binaryPath()` / `upstreamVersion` for Node. Depends optionally on the five platform packages, pinned exactly. |
| `@ai-swfactory-oss/shfmt-linux-x64` | `bin/shfmt` from upstream `shfmt_v<ver>_linux_amd64` |
| `@ai-swfactory-oss/shfmt-linux-arm64` | `bin/shfmt` from upstream `shfmt_v<ver>_linux_arm64` |
| `@ai-swfactory-oss/shfmt-darwin-x64` | `bin/shfmt` from upstream `shfmt_v<ver>_darwin_amd64` |
| `@ai-swfactory-oss/shfmt-darwin-arm64` | `bin/shfmt` from upstream `shfmt_v<ver>_darwin_arm64` |
| `@ai-swfactory-oss/shfmt-win32-x64` | `bin/shfmt.exe` from upstream `shfmt_v<ver>_windows_amd64.exe` |

npm installs only the platform package whose `os`/`cpu` match. The binaries are the unmodified upstream release assets, verified against the sha256 digests pinned in [`upstream.json`](upstream.json).

## Install

The packages live on GitHub Packages, which needs two things even for public packages.

1. The scope line, in your project's `.npmrc` (safe to commit):

   ```
   @ai-swfactory-oss:registry=https://npm.pkg.github.com
   ```

2. A token with `read:packages` (a classic personal access token), in your **user** `~/.npmrc`, never in the repository:

   ```
   //npm.pkg.github.com/:_authToken=<token>
   ```

   In GitHub Actions, use `actions/setup-node` with `registry-url: https://npm.pkg.github.com`, `scope: "@ai-swfactory-oss"` and `NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}`, and grant the job `packages: read`.

Then:

```sh
npm install --save-dev @ai-swfactory-oss/shfmt
npx shfmt --version
npx shfmt -d scripts/*.sh
```

From Node, spawn the binary directly; there is no node process in between:

```js
const { spawnSync } = require('node:child_process');
const { binaryPath, upstreamVersion } = require('@ai-swfactory-oss/shfmt');

const ast = spawnSync(binaryPath(), ['--to-json'], { input: 'a=1\n', encoding: 'utf8' });
```

- `binaryPath(platform = process.platform, arch = process.arch)` returns the absolute path of the binary.
  - It throws `UnsupportedPlatformError` (with `platform` and `arch`) when no binary is published for that os and cpu.
  - It throws `PlatformPackageMissingError` (with `platform`, `arch` and `packageName`) when one is published but its package is not installed, for example after `--omit=optional`.
- `upstreamVersion` is the shfmt version the binary reports, for example `3.14.1` (`shfmt --version` prints `v3.14.1`).
- `supportedPlatforms` lists the `<os>-<cpu>` pairs a binary is published for.

Installing with `--omit=optional` (or `--no-optional`) leaves no binary; `shfmt` then says so and exits 1.

## Verify what you installed

The binaries are **upstream's release binaries, unmodified**. `scripts/fetch.sh` downloads each asset and refuses it unless its sha256 matches the digest pinned in [`upstream.json`](upstream.json). That digest comes from the GitHub API for the upstream release. Nothing is rebuilt.

On top of that, every publish run creates **GitHub build-provenance attestations** ([`actions/attest-build-provenance`](https://github.com/actions/attest-build-provenance), SLSA provenance signed through Sigstore) for each npm tarball and each `shfmt` binary it publishes. Verify with the [GitHub CLI](https://cli.github.com/):

```sh
gh attestation verify node_modules/@ai-swfactory-oss/shfmt-linux-x64/bin/shfmt \
  --repo ai-swfactory-oss/shfmt \
  --signer-workflow ai-swfactory-oss/shfmt/.github/workflows/build.yml
```

To tie a binary back to upstream yourself, take the upstream asset named in the platform package's `NOTICE`. Check its sha256 against the digest there, then `cmp` it with the installed binary.

The attestation proves that this repository's `build.yml` packaged the file from the named commit. It does not say who compiled shfmt: upstream did, and the pinned digest is what ties the binary to upstream's release.

## Versions

- The package version **equals the shfmt version** (`3.14.1`), for all six packages.
- A **re-pack** of the same shfmt release (a packaging fix only, rare) is published as `<version>-r.<n>`, for example `3.14.1-r.1`. You get one by setting `"repack": <n>` in `upstream.json`.
  - Semver orders `3.14.1-r.1` *below* `3.14.1`, so the publish job always passes the explicit dist-tag `latest`.
  - A range like `^3.14.1` does not select a re-pack; pin it exactly if you need it.
- Every published version has a GitHub release `v<package version>`.

## How it stays up to date (no maintenance)

| Workflow | When | What |
|---|---|---|
| `update` | Daily 04:23 UTC; keepalive on the 1st of each month | Reads `mvdan/sh` `releases/latest` (never a prerelease). If it is newer than `upstream.json`, it rewrites `upstream.json` with the asset names and the sha256 digests the GitHub API reports for them, and opens a pull request from `update/shfmt-<version>`. It then builds and tests that branch on every platform. Separately, if the GitHub release for main's version is missing, it runs `build` with publishing, so a failed publish is retried the next day. |
| `build` | Push to `main` touching `upstream.json`, `scripts/`, `packages/`, `test/` or the workflow; manual; called by `update` | Runs the named digest-mismatch test, fetches the five assets (failing on any sha256 mismatch), stages the packages, runs the launcher tests and packs once. Each platform runner installs the packed tarballs into a scratch project. There it checks `binaryPath()`, the binary's sha256, `shfmt --version`, formatting and `--to-json`. Publishing (never on pull requests) attests every tarball and binary, then pushes the tested tarballs to GitHub Packages, platform packages first, skipping versions that already exist. Last, it creates the release. |
| `pr` | Every pull request | `build` without publishing. |
| `failures` | After every `update` or `build` run on `main` | A failure opens one issue labelled `build-failure` (or comments on the open one); the next successful run closes it. |

A failing run publishes nothing new; the previous versions keep being served. Each release carries the npm tarballs as published, the original upstream binaries and `SHA256SUMS` over all of them.

## Local build

```sh
bash test/digest-mismatch.sh                     # named test, offline
bash scripts/fetch.sh build/upstream             # download + verify
bash scripts/stage.sh build/upstream build/npm   # render the packages
env SHFMT_LAUNCHER_DIR=build/npm/shfmt node --test test/launcher.test.js
npm pack ./build/npm/shfmt ./build/npm/shfmt-*/ --pack-destination dist/tgz
bash scripts/smoke.sh dist/tgz darwin-arm64      # install and test like CI
```

Needs `bash`, `curl`, `jq`, `tar` and Node.

## License

- The scripts and workflows in this repository are **MIT** (see [`LICENSE`](LICENSE)).
- The **npm packages are BSD-3-Clause**, the license of shfmt (Copyright (c) 2016, Daniel Martí). Each platform package ships the upstream `LICENSE` and a `NOTICE`.

This project is not affiliated with the mvdan/sh project.
