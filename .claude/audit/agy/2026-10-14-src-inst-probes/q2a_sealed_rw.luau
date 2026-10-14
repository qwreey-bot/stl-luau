--!strict
type ReadAny = { read x: any }
type ReadUnknown = { read x: unknown }
type RWAny = { x: any }
type RWUnknown = { x: unknown }

local sealed = table.freeze({ a = 1 })
local s1: ReadAny = sealed -- 통과?
local s2: ReadUnknown = sealed -- 통과?
local s3: RWAny = sealed -- 실패해야 함! (read-only nil vs read-write)
local s4: RWUnknown = sealed -- 실패해야 함!
local canary: string = 1
