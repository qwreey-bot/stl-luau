--!strict
-- probe15_bench_d3: 20 trait definitions with D3 (builtin index)

local Trait = require("../.claude/research/trait-v9/Trait")
local stl = require("../src")
type Arr<T> = stl.Arr<T>
type CircularDeque<T> = stl.CircularDeque<T>

local Fn, Default = Trait.Fn, Trait.Default

-- D3 definitions
local function makeListDef(i: number)
	return function<M>(mode: M)
		return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
			return {
				Get = Fn<<(list: Self, idx: I) -> E?>>(),
				FirstIndex = Fn<<(list: Self) -> I?>>(),
				LastIndex = Fn<<(list: Self) -> I?>>(),
				NextIndex = Fn<<(list: Self, idx: I) -> I?>>(),
				PrevIndex = Fn<<(list: Self, idx: I) -> I?>>(),
				IndexOf = Default(mode, function(ops: any)
					return function(list: Self, item: E): I? return nil end
				end),
				Fold = Default(mode, function(ops: any)
					return function<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U): U
						return init
					end
				end),
			}
		end
	end
end

-- Generate 10 traits
local d0 = makeListDef(0) const T0 = Trait.Trait("T0", d0(Trait.FULL), d0(Trait.IMPL))
local d1 = makeListDef(1) const T1 = Trait.Trait("T1", d1(Trait.FULL), d1(Trait.IMPL))
local d2 = makeListDef(2) const T2 = Trait.Trait("T2", d2(Trait.FULL), d2(Trait.IMPL))
local d3 = makeListDef(3) const T3 = Trait.Trait("T3", d3(Trait.FULL), d3(Trait.IMPL))
local d4 = makeListDef(4) const T4 = Trait.Trait("T4", d4(Trait.FULL), d4(Trait.IMPL))
local d5 = makeListDef(5) const T5 = Trait.Trait("T5", d5(Trait.FULL), d5(Trait.IMPL))
local d6 = makeListDef(6) const T6 = Trait.Trait("T6", d6(Trait.FULL), d6(Trait.IMPL))
local d7 = makeListDef(7) const T7 = Trait.Trait("T7", d7(Trait.FULL), d7(Trait.IMPL))
local d8 = makeListDef(8) const T8 = Trait.Trait("T8", d8(Trait.FULL), d8(Trait.IMPL))
local d9 = makeListDef(9) const T9 = Trait.Trait("T9", d9(Trait.FULL), d9(Trait.IMPL))

export type T0Impl<Self, E, I> = typeof(T0.ImplOf<<Self, E, I>>(nil :: any))
export type T1Impl<Self, E, I> = typeof(T1.ImplOf<<Self, E, I>>(nil :: any))
export type T2Impl<Self, E, I> = typeof(T2.ImplOf<<Self, E, I>>(nil :: any))
export type T3Impl<Self, E, I> = typeof(T3.ImplOf<<Self, E, I>>(nil :: any))
export type T4Impl<Self, E, I> = typeof(T4.ImplOf<<Self, E, I>>(nil :: any))
export type T5Impl<Self, E, I> = typeof(T5.ImplOf<<Self, E, I>>(nil :: any))
export type T6Impl<Self, E, I> = typeof(T6.ImplOf<<Self, E, I>>(nil :: any))
export type T7Impl<Self, E, I> = typeof(T7.ImplOf<<Self, E, I>>(nil :: any))
export type T8Impl<Self, E, I> = typeof(T8.ImplOf<<Self, E, I>>(nil :: any))
export type T9Impl<Self, E, I> = typeof(T9.ImplOf<<Self, E, I>>(nil :: any))

-- Instantiations
type A = Trait.A
local _i0: T0Impl<Arr<A>, A, number> = { Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex }
local _i1: T1Impl<Arr<A>, A, number> = { Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex }
local _i2: T2Impl<Arr<A>, A, number> = { Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex }
local _i3: T3Impl<Arr<A>, A, number> = { Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex }
local _i4: T4Impl<Arr<A>, A, number> = { Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex }

local canary: string = 1
