--!strict
type Token = { read name: string }
type ItemRead<T> = { read __genericsRead: { read Item: () -> T } }
type ArrRead<T> = { read n: number, read __genericsRead: { read Item: () -> T }, read [number]: T }
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, read __genericsRead: { read Item: () -> T }, [number]: T }
type Ops<Self, T> = { IndexOf: (Self, T) -> number?, Get: (Self, number) -> T? }
local function Of<Self, T>(x: (Self & ItemRead<T>) | Token): Ops<Self, T>
	return nil :: any
end
local r: ArrRead<number> = nil :: any
local a: Arr<string> = nil :: any
const g1: number? = Of(r).Get(r, 1)
const g2: string? = Of(a).Get(a, 1)
const NEG1: string? = Of(r).Get(r, 1) -- NEG
const NEG2: number? = Of(a).Get(a, 1) -- NEG
local i1 = Of(r).IndexOf(r, "x") -- NEG?
-- Arr 를 ArrRead 로 빌려 줌
local function borrow(x: ArrRead<string>) return x end
borrow(a)
-- 공변: ArrRead<number> 를 ArrRead<number?> 자리로
local function wide(x: ArrRead<number?>) return Of(x).Get(x, 1) end
wide(r)
local canary: string = 1
return { g1, g2, NEG1, NEG2, i1 }
