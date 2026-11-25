import { describe, expect, it } from 'vitest'

import fixture from './__fixtures__/upstream.json' with { type: 'json' }
import { parseUpstreamPin, supportedPlatformsOf } from './pin'

describe('supportedPlatforms', () => {
  it('supportedPlatforms lists exactly the keys of upstream.json assets', () => {
    const platforms = supportedPlatformsOf(parseUpstreamPin(fixture, '__fixtures__/upstream.json'))

    expect(platforms).toEqual({ ok: true, value: ['linux-x64', 'darwin-arm64', 'win32-x64'] })
  })
})
