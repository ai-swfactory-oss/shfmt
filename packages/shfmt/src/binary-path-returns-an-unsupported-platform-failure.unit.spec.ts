import { describe, expect, it } from 'vitest'

import { binaryPathOf } from './index'

describe('binaryPathOf', () => {
  it('binaryPathOf returns a failure naming the platform for an os and cpu that no target in a targets literal covers, without throwing', () => {
    const targets = ['linux-x64', 'darwin-arm64']

    const result = binaryPathOf(targets, 'sunos', 'sparc')

    expect(result).toEqual({
      ok: false,
      failure: { kind: 'unsupported-platform', platform: 'sunos', arch: 'sparc', supported: targets },
    })
  })
})
