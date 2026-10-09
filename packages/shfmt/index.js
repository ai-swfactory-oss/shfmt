'use strict';

const path = require('node:path');
const { version: packageVersion } = require('./package.json');

const SUPPORTED = ['linux-x64', 'linux-arm64', 'darwin-x64', 'darwin-arm64'];

/** The upstream shfmt version, without the re-pack suffix (3.14.1-r.1 -> 3.14.1). */
const version = packageVersion.replace(/-r\.\d+$/, '');

/**
 * Absolute path of the native shfmt binary for this platform. Spawn it
 * directly; there is no node process in between.
 */
function binaryPath() {
  const key = `${process.platform}-${process.arch}`;
  const name = `@ai-swfactory-oss/shfmt-${key}`;
  let dir;
  try {
    dir = path.dirname(require.resolve(`${name}/package.json`));
  } catch {
    const why = SUPPORTED.includes(key)
      ? `${name} is not installed (optional dependencies omitted, or a lockfile made on another platform?)`
      : `no binary is published for ${key}; supported: ${SUPPORTED.join(', ')}`;
    throw new Error(`@ai-swfactory-oss/shfmt: ${why}`);
  }
  return path.join(dir, 'bin', 'shfmt');
}

module.exports = { binaryPath, version };
