#!/usr/bin/env node
'use strict';

const { spawnSync } = require('node:child_process');
const { binaryPath } = require('../index.js');

let bin;
try {
  bin = binaryPath();
} catch (err) {
  process.stderr.write(`${err.message}\n`);
  process.exit(1);
}

const result = spawnSync(bin, process.argv.slice(2), { stdio: 'inherit' });
if (result.error) {
  process.stderr.write(`@ai-swfactory-oss/shfmt: cannot run ${bin}: ${result.error.message}\n`);
  process.exit(1);
}
if (result.signal) {
  process.kill(process.pid, result.signal);
}
process.exit(result.status ?? 1);
