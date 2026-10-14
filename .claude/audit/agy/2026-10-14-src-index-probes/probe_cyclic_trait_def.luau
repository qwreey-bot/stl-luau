--!strict
-- probes/probe_cyclic_trait_def.luau

export type Mut<Self, T, M> = index<{ full: Self & { item: T }, impl: Self }, M>
export type DefaultRet<F, M> = index<{ full: F, impl: F? }, M>

local function Fn<F>(): F return nil :: any end
local function Default<F, M>(_mode: M, _build: (ops: any) -> F): DefaultRet<F, M> return nil :: any end

type Object<F, G> = {
	read Of: F,
	read ImplOf: G,
	read [string]: any,
}

local function Trait<F, G>(name: string, def: (mode: "full") -> F, implDef: ((mode: "impl") -> G)?): Object<F, G>
	return nil :: any
end

-- 케이스 A: Default의 ops에 any를 쓴 경우
local function defA<M>(mode: M)
	return function<Self, T>(of: Self)
		return {
			Peek = Fn<<(s: Self) -> T?>>(),
			IsEmpty = Default(mode, function(ops: any)
				return function(s: Self): boolean
					return ops.Peek(s) == nil
				end
			end),
		}
	end
end
local TraitA = Trait("A", defA, defA)
type TraitA<Self, T> = typeof(TraitA.Of<<Self, T>>(nil :: any))

-- 케이스 B: Default의 ops에 typeof(TraitB.Of...)를 직접 쓴 경우
local function defB<M>(mode: M)
	return function<Self, T>(of: Self)
		return {
			Peek = Fn<<(s: Self) -> T?>>(),
			IsEmpty = Default(mode, function(ops: TraitB<Self, T>)
				return function(s: Self): boolean
					return ops.Peek(s) == nil
				end
			end),
		}
	end
end
local TraitB = Trait("B", defB, defB)
export type TraitB<Self, T> = typeof(TraitB.Of<<Self, T>>(nil :: any))

local canary: string = 1
