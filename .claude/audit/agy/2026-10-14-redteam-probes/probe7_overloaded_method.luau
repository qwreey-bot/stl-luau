--!strict
-- probes/probe7_overloaded_method.luau
-- 오버로드된 함수를 가진 기본 구현 및 재정의

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

type OverloadFn = ((s: any, x: number) -> number) & ((s: any, x: string) -> string)

local function ovDef<M>(mode: M)
	return function<Self, T>(of: (Self & Item<T>) | Token)
		return {
			-- 오버로드된 기본 구현
			Process = Default(mode, function(ops: any): OverloadFn
				local function impl(s: any, x: any): any
					return x
				end
				return impl :: any
			end),
		}
	end
end

const OvTrait = Trait("OvTrait", ovDef<<"full">>, ovDef<<"impl">>)
export type OvTrait<Self, T> = typeof(OvTrait.Of<<Self, T>>(nil :: any))
export type OvTraitImpl<Self, T> = typeof(OvTrait.ImplOf<<Self, T>>(nil :: any))

type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local a: Arr<number> = nil :: any
local ops = OvTrait.Of(a)

local r_num: number = ops.Process(a, 10)
local r_str: string = ops.Process(a, "hello")
local NEG_mismatch: string = ops.Process(a, 10) -- NEG: number는 string이 아님!

type A = { read __probeA: true }
local ok_impl: OvTraitImpl<Arr<A>, A> = {
	-- 재정의 생략 (기본 구현)
}

-- 불완전한 오버로드 재정의: number만 처리하고 string은 처리하지 않는 함수로 재정의 시도
local NEG_partial_ov: OvTraitImpl<Arr<A>, A> = {
	Process = function(s: Arr<A>, x: number): number return x end, -- NEG: string 갈래가 없음!
}

local canary: string = 1
return { canary, r_num, r_str, NEG_mismatch, ok_impl }
