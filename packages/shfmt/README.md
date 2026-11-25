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
```

## Use

This package declares no bin and touches no host: it says, as data, which package carries the binary for an os and cpu and where the binary sits inside it. Resolving that package, joining the path and running the binary is the caller's.

```js
import { binaryPathOf, platformPackage, supportedPlatforms, upstreamVersion } from '@ai-swfactory-oss/shfmt'
// supportedPlatforms(): { ok: true, value: ['linux-x64', 'linux-arm64', ...] }, the keys of upstream.json assets
// upstreamVersion():    { ok: true, value: '3.14.1' }, the shfmt version pinned in upstream.json
// binaryPathOf(targets, 'linux', 'x64'):
//   { ok: true, value: { packageName: '@ai-swfactory-oss/shfmt-linux-x64', binRelativePath: 'bin/shfmt' } }
// platformPackage('win32', 'x64'): '@ai-swfactory-oss/shfmt-win32-x64'
```

The package is ESM only. No function throws: a failure is returned as `{ ok: false, failure }`. `binaryPathOf` fails with kind `unsupported-platform` (with `platform`, `arch` and `supported`) when no target covers the os and cpu. A missing or invalid `upstream.json` fails with kind `upstream-pin-invalid`, naming the file.

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
