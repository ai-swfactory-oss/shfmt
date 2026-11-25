import { fail, type Result, succeed } from './result'

const SEMVER = /^\d+\.\d+\.\d+$/

export interface UpstreamPin {
  readonly version: string
  readonly platforms: readonly string[]
}

export interface UpstreamPinInvalid {
  readonly kind: 'upstream-pin-invalid'
  readonly file: string
  readonly reason: string
}

const isRecord = (value: unknown): value is Readonly<Record<string, unknown>> =>
  typeof value === 'object' && value !== null && !Array.isArray(value)

const invalid = (file: string, reason: string): UpstreamPinInvalid => ({ kind: 'upstream-pin-invalid', file, reason })

export const parseUpstreamPin = (data: unknown, file: string): Result<UpstreamPin, UpstreamPinInvalid> => {
  if (!isRecord(data)) return fail(invalid(file, 'is not a JSON object'))
  const version = data.version
  if (typeof version !== 'string' || !SEMVER.test(version)) {
    return fail(invalid(file, 'pins no version of the form <major>.<minor>.<patch>'))
  }
  const assets = data.assets
  if (!isRecord(assets) || Object.keys(assets).length === 0) {
    return fail(invalid(file, 'pins no assets'))
  }
  return succeed({ version, platforms: Object.keys(assets) })
}

export const upstreamVersionOf = (pin: Result<UpstreamPin, UpstreamPinInvalid>): Result<string, UpstreamPinInvalid> =>
  pin.ok ? succeed(pin.value.version) : pin

export const supportedPlatformsOf = (pin: Result<UpstreamPin, UpstreamPinInvalid>): Result<readonly string[], UpstreamPinInvalid> =>
  pin.ok ? succeed(pin.value.platforms) : pin
