--!strict
-- probes/q2a_missing_props.luau
-- Q2-(a) 읽기 필드가 any/unknown 이면 필드가 없는 테이블도 만족하는 현상
type ReadAny = { read x: any }
type ReadUnknown = { read x: unknown }
type ReadOptNumber = { read x: number? }
type ReadNumber = { read x: number }
type ReadWriteAny = { x: any }
type ReadWriteUnknown = { x: unknown }

-- 1. 빈 테이블 리터럴 {}
local _empty_any: ReadAny = {}           -- 정상 통과 (nil <: any)
local _empty_unknown: ReadUnknown = {}   -- 정상 통과 (nil <: unknown)
local _empty_opt: ReadOptNumber = {}     -- 정상 통과 (nil <: number?)

-- 2. 이미 봉인(sealed/freeze)된 테이블: { a: number }
local sealed = table.freeze({ a = 123 })
local _sealed_any: ReadAny = sealed         -- 정상 통과
local _sealed_unknown: ReadUnknown = sealed -- 정상 통과
local _sealed_opt: ReadOptNumber = sealed   -- 정상 통과

-- 음성 대조군 (-- NEG 3건)
local NEG_missing_req: ReadNumber = sealed        -- NEG 1: nil </: number
local NEG_sealed_rw_any: ReadWriteAny = sealed    -- NEG 2: readonly nil </: read-write any
local NEG_sealed_rw_unk: ReadWriteUnknown = sealed -- NEG 3: readonly nil </: read-write unknown

local canary: string = 1
