# @ai-swfactory-oss/shfmt

[shfmt](https://github.com/mvdan/sh) (mvdan/sh), the shell parser, formatter and interpreter, as an npm package that runs the **native upstream binary** for your platform (no WASM, no download at install time, no install scripts).

Platforms: `linux-x64`, `linux-arm64`, `darwin-x64`, `darwin-arm64`, `win32-x64`. The binary comes from the matching optional dependency `@ai-swfactory-oss/shfmt-<platform>-<arch>`, which is the unmodified upstream release asset, verified against its sha256 digest.

## Install

The packages are on GitHub Packages. Point the scope at it (in your project's `.npmrc`):

```
@ai-swfactory-oss:registry=https://npm.pkg.github.com
```

GitHub Packages requires a token even for public packages: a classic personal access token with `read:packages`, in your user `~/.npmrc` (never commit it):

```
//npm.pkg.github.com/:_authToken=<token>
```

In GitHub Actions, `actions/setup-node` with `registry-url: https://npm.pkg.github.com` and `NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}` does this (the workflow needs `packages: read`).

```sh
npm install --save-dev @ai-swfactory-oss/shfmt
npx shfmt --version
```

## Use

```sh
shfmt -d script.sh
```

From Node, spawn the binary directly:

```js
const { binaryPath, upstreamVersion } = require('@ai-swfactory-oss/shfmt');
// binaryPath(): absolute path to the native shfmt binary for this os and cpu
// upstreamVersion: the shfmt version, e.g. "3.14.1"
```

`binaryPath()` throws `UnsupportedPlatformError` (with `platform` and `arch`) when no binary is published for this os and cpu, and `PlatformPackageMissingError` when one is but its package was not installed (for example with `--omit=optional`).

## Verify

Every published tarball and binary has a GitHub build-provenance attestation:

```sh
gh attestation verify node_modules/@ai-swfactory-oss/shfmt-linux-x64/bin/shfmt \
  --repo ai-swfactory-oss/shfmt
```

The binary itself is upstream's release binary, unmodified, its sha256 pinned (see `NOTICE` in the platform package). Details: https://github.com/ai-swfactory-oss/shfmt#verify-what-you-installed

## Versions

The package version equals the shfmt version. A rare re-pack of the same shfmt release (packaging fix only) is published as `<version>-r.<n>` with the `latest` dist-tag.

## License

BSD-3-Clause, the license of shfmt. See `LICENSE` and `NOTICE`.
