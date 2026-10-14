--!strict
-- probes/probe16_cyclic_defaults.luau
-- 기본 구현끼리 서로를 ops로 호출하는 상호 재귀(cyclic defaults)가 정의될 때
-- B'의 타입 시스템이 이를 어떻게 취급하는가?

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

local function mutualDef<M>(mode: M)
	return function<Self, T>(of: (Self & Item<T>) | Token)
		return {
			Ping = Default(mode, function(ops: Mutual<Self, T>)
				return function(s: Self, n: number): boolean
					if n <= 0 then return true end
					return ops.Pong(s, n - 1)
				end
			end),
			Pong = Default(mode, function(ops: Mutual<Self, T>)
				return function(s: Self, n: number): boolean
					if n <= 0 then return false end
					return ops.Ping(s, "not_a_number") -- NEG: number여야 함!
				end
			end),
		}
	end
end

const Mutual = Trait("Mutual", mutualDef<<"full">>, mutualDef<<"impl">>)
export type Mutual<Self, T> = typeof(Mutual.Of<<Self, T>>(nil :: any))
export type MutualImpl<Self, T> = typeof(Mutual.ImplOf<<Self, T>>(nil :: any))

type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local a: Arr<number> = nil :: any
local ops = Mutual.Of(a)

local r: boolean = ops.Ping(a, 5)
local NEG_mismatch: string = ops.Ping(a, 5) -- NEG: boolean이어야 함!

local canary: string = 1
return { canary, r, NEG_mismatch }
