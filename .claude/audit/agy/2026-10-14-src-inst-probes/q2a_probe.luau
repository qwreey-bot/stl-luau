--!strict
type ReadAny = { read x: any }
type ReadUnknown = { read x: unknown }
type ReadNumber = { read x: number }
type ReadWriteAny = { x: any }
type ReadWriteUnknown = { x: unknown }

local t1: ReadAny = {} -- 만족하나?
local t2: ReadUnknown = {} -- 만족하나?
local t3: ReadNumber = {} -- 에러여야 함 (음성 대조군)
local t4: ReadWriteAny = {} -- ?
local t5: ReadWriteUnknown = {} -- ?
local canary: string = 1
