--!strict
local D = require("./defmod")
local stl = require("../../../src")
type Arr<T> = stl.Arr<T>
local function mk(): Arr<number> return nil :: any end
local arr = mk()
local tbl = D.L.Of(arr)
local r1: boolean = tbl.Has(arr, 3)
local r2: string = tbl.Has(arr, 3) -- NEG
local r3: string = tbl.Count(arr) -- NEG
-- 제네릭 사용자 함수
local function usesIt<C, E>(t: D.P2<C, E>, c: C, e: E): string
	return t.Has(c, e) -- NEG
end
local function usesIt2<C, E>(t: D.P2<C, E>, c: C, e: E): boolean
	return t.Count(c) -- NEG
end
local canary: string = 1
return { r1, r2, r3, usesIt, usesIt2, canary }
