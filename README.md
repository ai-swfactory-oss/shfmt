# shfmt

[![update](https://github.com/ai-swfactory-oss/shfmt/actions/workflows/update.yml/badge.svg)](https://github.com/ai-swfactory-oss/shfmt/actions/workflows/update.yml)
[![build](https://github.com/ai-swfactory-oss/shfmt/actions/workflows/build.yml/badge.svg)](https://github.com/ai-swfactory-oss/shfmt/actions/workflows/build.yml)

[shfmt](https://github.com/mvdan/sh) (mvdan/sh) as npm packages: the **unmodified upstream release binaries**, one package per platform, updated and published automatically to GitHub Packages.

| Package | Contents |
|---|---|
| `@ai-swfactory-oss/shfmt` | Launcher: the `shfmt` command, plus `binaryPath()` and `version` for programs that spawn shfmt themselves. Depends on the four platform packages as exactly pinned optional dependencies; npm installs only the one matching `os`/`cpu`. |
| `@ai-swfactory-oss/shfmt-linux-x64` | `bin/shfmt` = upstream `shfmt_v<version>_linux_amd64` |
| `@ai-swfactory-oss/shfmt-linux-arm64` | `bin/shfmt` = upstream `shfmt_v<version>_linux_arm64` |
| `@ai-swfactory-oss/shfmt-darwin-x64` | `bin/shfmt` = upstream `shfmt_v<version>_darwin_amd64` |
| `@ai-swfactory-oss/shfmt-darwin-arm64` | `bin/shfmt` = upstream `shfmt_v<version>_darwin_arm64` |

No install scripts. Windows is not packaged.

## Installing

GitHub Packages requires a token even for public packages: a classic personal access token with `read:packages` (in GitHub Actions, `GITHUB_TOKEN` with `packages: read`). Point the scope at GitHub Packages and pass the token through the environment, never committed:

```ini
# .npmrc (this repository commits the same scope line)
@ai-swfactory-oss:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${NODE_AUTH_TOKEN}
```

```sh
export NODE_AUTH_TOKEN=...            # read:packages
npm install @ai-swfactory-oss/shfmt   # or: npm install -g @ai-swfactory-oss/shfmt
```

Do not install with `--omit=optional` / `--no-optional`: the binary lives in the optional platform package.

## Usage

```sh
npx shfmt -d script.sh
echo 'a=1' | npx shfmt --to-json
```

From code, spawn the binary directly; there is no node process in between:

```js
import { spawnSync } from 'node:child_process';
import { binaryPath, version } from '@ai-swfactory-oss/shfmt';

const ast = spawnSync(binaryPath(), ['--to-json'], { input: 'a=1\n', encoding: 'utf8' });
```

`binaryPath()` throws with an explanation when no platform package is installed for this `process.platform`/`process.arch`. `version` is the upstream shfmt version (for example `3.14.1`).

## Versions and re-packs

The npm version equals the upstream version: `@ai-swfactory-oss/shfmt@3.14.1` contains shfmt v3.14.1. In the rare case the packaging itself must change for an upstream version that is already published, the packages are re-published as `<upstream>-r.<n>` (for example `3.14.1-r.1`) by raising `revision` in `upstream.json` and running `scripts/set-version.sh`. A re-pack contains the same binaries and becomes the `latest` dist-tag. Note that semver orders `3.14.1-r.1` *below* `3.14.1`, so a range such as `^3.14.1` does not select it; pin it exactly, or install `@latest`.

## Integrity

- `upstream.json` records, for each platform, the upstream asset name and the sha256 digest GitHub's API reports for that release asset. `scripts/fetch.sh` downloads each asset and fails unless it matches; the tests check that the binary installed from the packed tarball still has that hash.
- Every platform package carries the mvdan/sh `LICENSE` (BSD-3-Clause) and `LICENSE-go` (Go's BSD license; the Go standard library is statically linked), fetched from the upstream tag and from the Go release the binaries were built with.
- Upstream builds the binaries with `CGO_ENABLED=0 go build -trimpath -ldflags="-w -s"` and names the Go version in the release notes. The `rebuild` job repeats that build from the tag and compares hashes; the result is in each build run's summary and in the GitHub release notes. It is informational and never blocks a publish.
- Each GitHub release carries the upstream binaries, the npm tarballs and `SHA256SUMS`.

## How it stays up to date (no maintenance)

| Workflow | When | What |
|---|---|---|
| `update` | Daily 04:23 UTC, manual | Moves `upstream.json` and every package version to the latest mvdan/sh release (sha256 digests from the GitHub API) and commits. Then checks that every package of the current version is published; anything missing is built, tested and published. A failed publish is retried the next day. |
| `build` | Push to `main` touching `upstream.json`, `packages/`, `scripts/` or the workflow; manual; called by `update` | Fetches and verifies the binaries, packs the five packages, installs and tests them on linux x64/arm64 and macOS x64/arm64 (`shfmt --version`, `shfmt --to-json`, `binaryPath()`), runs the rebuild check, publishes the packages not yet published (platform packages first) and creates the GitHub release. |
| `pr` | Every pull request | Everything `build` does except publishing. |
| `failures` | After every `update` or `build` run on `main` | A failure opens one issue labelled `build-failure` (or comments on the open one); the next successful run closes it. |

When there is no upstream release for 45 days, `update` pushes an empty keepalive commit, so GitHub never disables the schedule. A failing run publishes nothing: the previous versions keep being served.

## License

The packaging code in this repository is MIT. shfmt is BSD-3-Clause (https://github.com/mvdan/sh/blob/master/LICENSE); the Go standard library linked into it is BSD-3-Clause (https://go.dev/LICENSE). The npm packages declare `BSD-3-Clause`.
