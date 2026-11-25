export type Result<T, F> = { readonly ok: true; readonly value: T } | { readonly ok: false; readonly failure: F }

export const succeed = <T>(value: T): { readonly ok: true; readonly value: T } => ({ ok: true, value })

export const fail = <F>(failure: F): { readonly ok: false; readonly failure: F } => ({ ok: false, failure })
