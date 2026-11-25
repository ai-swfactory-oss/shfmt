import { parseUpstreamPin, supportedPlatformsOf, type UpstreamPinInvalid, upstreamVersionOf } from './pin'
import type { Result } from './result'
import pinned from './upstream.json' with { type: 'json' }

export { type BinaryLocation, binaryPathOf, platformPackage, type UnsupportedPlatform } from './binary-path'
export type { UpstreamPinInvalid } from './pin'
export type { Result } from './result'

const PIN_FILE = 'upstream.json'

export const upstreamVersion = (): Result<string, UpstreamPinInvalid> => upstreamVersionOf(parseUpstreamPin(pinned, PIN_FILE))

export const supportedPlatforms = (): Result<readonly string[], UpstreamPinInvalid> =>
  supportedPlatformsOf(parseUpstreamPin(pinned, PIN_FILE))
