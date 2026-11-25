import { fail, type Result, succeed } from './result'

const PREFIX = '@ai-swfactory-oss/shfmt-'

export interface UnsupportedPlatform {
  readonly kind: 'unsupported-platform'
  readonly platform: string
  readonly arch: string
  readonly supported: readonly string[]
}

export interface BinaryLocation {
  readonly packageName: string
  readonly binRelativePath: string
}

export const platformPackage = (platform: string, arch: string): string => `${PREFIX}${platform}-${arch}`

export const binaryPathOf = (targets: readonly string[], platform: string, arch: string): Result<BinaryLocation, UnsupportedPlatform> => {
  if (!targets.includes(`${platform}-${arch}`)) {
    return fail({ kind: 'unsupported-platform', platform, arch, supported: targets })
  }
  return succeed({
    packageName: platformPackage(platform, arch),
    binRelativePath: platform === 'win32' ? 'bin/shfmt.exe' : 'bin/shfmt',
  })
}
