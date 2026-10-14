--!strict
type ReadUnknown = { read x: unknown }
type ReadAny = { read x: any }
type ReadNumber = { read x: number }

local sealed = table.freeze({ a = 1 })
local s1: ReadUnknown = sealed
local s2: ReadAny = sealed
local s3: ReadNumber = sealed -- 에러 기대
local canary: string = 1
