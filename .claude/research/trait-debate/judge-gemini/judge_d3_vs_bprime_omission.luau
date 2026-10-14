--!strict
-- probe 1: B' vs D3 에서 정의자의 모드 누락/오기 시 동작 대조
local TraitV9 = require("../.claude/research/trait-v9/Trait")
local stl = require("../src")

-- 1. B' 방식 흉내: def: (mode: "full") -> F, implDef: (mode: "impl") -> G
type BPrimeObject<F, G> = { read Of: F, read ImplOf: G }
local function TraitBPrime<F, G>(name: string, def: (mode: "full") -> F, implDef: (mode: "impl") -> G): BPrimeObject<F, G>
	return nil :: any
end

local function stackDefBPrime<M>(mode: M)
	return function<Self, T>(of: Self)
		return {
			Push = function(s: Self, x: T): Self return s end,
			IsEmpty = TraitV9.Default(mode, function(ops: any)
				return function(s: Self): boolean return true end
			end),
		}
	end
end

-- [B'의 함정]: <<"full">>, <<"impl">> 누락 시 정의부는 0건 통과!
const StackBPrimeMistake = TraitBPrime("StackBPrimeMistake", stackDefBPrime, stackDefBPrime)
type StackBPMistake<Self, T> = typeof(StackBPrimeMistake.Of<<Self, T>>(nil :: any))

local bpm: StackBPMistake<{ n: number }, number> = nil :: any
-- B' 실수 시: 기본 구현 반환 타입이 never로 축약되어 string, number 어디에 대입해도 0건! (조용한 구멍)
local bpm_hole1: string = bpm.IsEmpty(nil :: any) -- 침묵 통과 (never <: string)
local bpm_hole2: number = bpm.IsEmpty(nil :: any) -- 침묵 통과 (never <: number)


-- 2. D3 방식 (v9): 모드를 값 Trait.FULL, Trait.IMPL 로 전달
local function stackDefD3<M>(mode: M)
	return function<Self, T>(of: Self)
		return {
			Push = function(s: Self, x: T): Self return s end,
			IsEmpty = TraitV9.Default(mode, function(ops: any)
				return function(s: Self): boolean return true end
			end),
		}
	end
end

-- [D3]: 정상 호출은 값으로 호출하여 전달
const StackD3Correct = TraitV9.Trait("StackD3Correct", stackDefD3(TraitV9.FULL), stackDefD3(TraitV9.IMPL))
type StackD3Correct<Self, T> = typeof(StackD3Correct.Of<<Self, T>>(nil :: any))

local d3c: StackD3Correct<{ n: number }, number> = nil :: any
local d3c_ok: boolean = d3c.IsEmpty(nil :: any)
-- NEG_d3c: D3 정상 정의에서는 boolean -> string 대입이 정확히 잡힘!
const NEG_d3c_ret: string = d3c.IsEmpty(nil :: any) -- NEG

-- [D3 실수 테스트]: 함수를 호출하지 않고 넘긴 경우 (B'처럼 넘긴 경우)
-- const StackD3Uncalled = TraitV9.Trait("StackD3Uncalled", stackDefD3, stackDefD3)
-- -> 이것은 definer-mistakes.luau 에서 증명되었듯 정의부에서 즉시 TypeError!

local canary: string = 1
return { bpm_hole1, bpm_hole2, d3c_ok, NEG_d3c_ret, canary }
