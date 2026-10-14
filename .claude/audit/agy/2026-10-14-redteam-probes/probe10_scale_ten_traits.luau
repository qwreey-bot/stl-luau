--!strict
-- probes/probe10_scale_ten_traits.luau
-- 10개 이상의 트레이트를 한 파일에 정의하고,
-- 단일 컨테이너가 4개 이상의 트레이트를 구현할 때
-- Luau 솔버의 성능, 메모리, 타입 검사 안정성 실측

type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
local function Fn<F>(): F return nil :: any end
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end

local function Trait<F, G>(
	name: string,
	def: (mode: "full") -> F,
	implDef: (mode: "impl") -> G
): { read Of: F, read ImplOf: G }
	return nil :: any
end

-- 트레이트 매크로처럼 10개 정의
local function t1Def<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return { M1 = Fn<<(s: Self, x: T) -> Self>>(), D1 = Default(mode, function(ops) return function(s: Self): boolean return true end end) }
end end
const T1 = Trait("T1", t1Def<<"full">>, t1Def<<"impl">>)
export type T1<Self, T> = typeof(T1.Of<<Self, T>>(nil :: any))
export type T1Impl<Self, T> = typeof(T1.ImplOf<<Self, T>>(nil :: any))

local function t2Def<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return { M2 = Fn<<(s: Self) -> T?>>(), D2 = Default(mode, function(ops) return function(s: Self): number return 0 end end) }
end end
const T2 = Trait("T2", t2Def<<"full">>, t2Def<<"impl">>)
export type T2<Self, T> = typeof(T2.Of<<Self, T>>(nil :: any))
export type T2Impl<Self, T> = typeof(T2.ImplOf<<Self, T>>(nil :: any))

local function t3Def<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return { M3 = Fn<<(s: Self) -> number>>(), D3 = Default(mode, function(ops) return function(s: Self): boolean return true end end) }
end end
const T3 = Trait("T3", t3Def<<"full">>, t3Def<<"impl">>)
export type T3<Self, T> = typeof(T3.Of<<Self, T>>(nil :: any))
export type T3Impl<Self, T> = typeof(T3.ImplOf<<Self, T>>(nil :: any))

local function t4Def<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return { M4 = Fn<<(s: Self, x: T) -> boolean>>(), D4 = Default(mode, function(ops) return function(s: Self): T? return nil end end) }
end end
const T4 = Trait("T4", t4Def<<"full">>, t4Def<<"impl">>)
export type T4<Self, T> = typeof(T4.Of<<Self, T>>(nil :: any))
export type T4Impl<Self, T> = typeof(T4.ImplOf<<Self, T>>(nil :: any))

local function t5Def<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return { M5 = Fn<<(s: Self) -> ()>>(), D5 = Default(mode, function(ops) return function(s: Self): boolean return true end end) }
end end
const T5 = Trait("T5", t5Def<<"full">>, t5Def<<"impl">>)
export type T5<Self, T> = typeof(T5.Of<<Self, T>>(nil :: any))
export type T5Impl<Self, T> = typeof(T5.ImplOf<<Self, T>>(nil :: any))

local function t6Def<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return { M6 = Fn<<(s: Self, x: T) -> Self>>(), D6 = Default(mode, function(ops) return function(s: Self): number return 1 end end) }
end end
const T6 = Trait("T6", t6Def<<"full">>, t6Def<<"impl">>)
export type T6<Self, T> = typeof(T6.Of<<Self, T>>(nil :: any))
export type T6Impl<Self, T> = typeof(T6.ImplOf<<Self, T>>(nil :: any))

local function t7Def<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return { M7 = Fn<<(s: Self) -> T?>>(), D7 = Default(mode, function(ops) return function(s: Self): boolean return false end end) }
end end
const T7 = Trait("T7", t7Def<<"full">>, t7Def<<"impl">>)
export type T7<Self, T> = typeof(T7.Of<<Self, T>>(nil :: any))
export type T7Impl<Self, T> = typeof(T7.ImplOf<<Self, T>>(nil :: any))

local function t8Def<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return { M8 = Fn<<(s: Self) -> number>>(), D8 = Default(mode, function(ops) return function(s: Self): T? return nil end end) }
end end
const T8 = Trait("T8", t8Def<<"full">>, t8Def<<"impl">>)
export type T8<Self, T> = typeof(T8.Of<<Self, T>>(nil :: any))
export type T8Impl<Self, T> = typeof(T8.ImplOf<<Self, T>>(nil :: any))

local function t9Def<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return { M9 = Fn<<(s: Self, x: T) -> ()>>(), D9 = Default(mode, function(ops) return function(s: Self): boolean return true end end) }
end end
const T9 = Trait("T9", t9Def<<"full">>, t9Def<<"impl">>)
export type T9<Self, T> = typeof(T9.Of<<Self, T>>(nil :: any))
export type T9Impl<Self, T> = typeof(T9.ImplOf<<Self, T>>(nil :: any))

local function t10Def<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return { M10 = Fn<<(s: Self) -> Self>>(), D10 = Default(mode, function(ops) return function(s: Self): number return 42 end end) }
end end
const T10 = Trait("T10", t10Def<<"full">>, t10Def<<"impl">>)
export type T10<Self, T> = typeof(T10.Of<<Self, T>>(nil :: any))
export type T10Impl<Self, T> = typeof(T10.ImplOf<<Self, T>>(nil :: any))

-- 컨테이너 정의: MyContainer가 T1, T2, T3, T4 구현
type MyContainer<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
type A = { read __probeA: true }

local i1: T1Impl<MyContainer<A>, A> = { M1 = function(s, x) return s end }
local i2: T2Impl<MyContainer<A>, A> = { M2 = function(s) return nil end }
local i3: T3Impl<MyContainer<A>, A> = { M3 = function(s) return s.n end }
local i4: T4Impl<MyContainer<A>, A> = { M4 = function(s, x) return true end }

-- 사용 시험
local c: MyContainer<number> = nil :: any
local r1: boolean = T1.Of(c).D1(c)
local r2: number = T2.Of(c).D2(c)
local r3: boolean = T3.Of(c).D3(c)
local r4: number? = T4.Of(c).D4(c)

local NEG_scale_mismatch: string = T1.Of(c).D1(c) -- NEG: boolean -> string 에러 잡혀야 함

local canary: string = 1
return { canary, i1, i2, i3, i4, r1, r2, r3, r4, NEG_scale_mismatch }
