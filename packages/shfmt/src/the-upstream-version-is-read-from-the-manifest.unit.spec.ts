import { describe, expect, it } from 'vitest'

import fixture from './__fixtures__/upstream.json' with { type: 'json' }
import withoutVersion from './__fixtures__/upstream-without-a-version.json' with { type: 'json' }
import withoutAssets from './__fixtures__/upstream-without-assets.json' with { type: 'json' }
import { parseUpstreamPin, upstreamVersionOf } from './pin'

describe('upstreamVersion', () => {
  it('the upstream version is read from upstream.json, and a missing or invalid pin is refused as data naming the file', () => {
    expect(upstreamVersionOf(parseUpstreamPin(fixture, 'upstream.json'))).toEqual({ ok: true, value: '9.8.7' })

    expect(upstreamVersionOf(parseUpstreamPin(undefined, 'upstream.json'))).toEqual({
      ok: false,
      failure: { kind: 'upstream-pin-invalid', file: 'upstream.json', reason: 'is not a JSON object' },
    })
    expect(upstreamVersionOf(parseUpstreamPin(withoutVersion, 'upstream.json'))).toEqual({
      ok: false,
      failure: {
        kind: 'upstream-pin-invalid',
        file: 'upstream.json',
        reason: 'pins no version of the form <major>.<minor>.<patch>',
      },
    })
    expect(upstreamVersionOf(parseUpstreamPin(withoutAssets, 'upstream.json'))).toEqual({
      ok: false,
      failure: { kind: 'upstream-pin-invalid', file: 'upstream.json', reason: 'pins no assets' },
    })
  })
})
