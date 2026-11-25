import { describe, expect, it } from 'vitest'

import { binaryPathOf } from './index'

describe('binaryPathOf', () => {
  it('binaryPathOf returns packageName and binRelativePath for a declared platform, bin/shfmt.exe on win32 and bin/shfmt elsewhere, and no host path', () => {
    const targets = ['linux-x64', 'win32-x64']

    const linux = binaryPathOf(targets, 'linux', 'x64')
    const windows = binaryPathOf(targets, 'win32', 'x64')

    expect(linux).toEqual({
      ok: true,
      value: { packageName: '@ai-swfactory-oss/shfmt-linux-x64', binRelativePath: 'bin/shfmt' },
    })
    expect(windows).toEqual({
      ok: true,
      value: { packageName: '@ai-swfactory-oss/shfmt-win32-x64', binRelativePath: 'bin/shfmt.exe' },
    })
  })
})
