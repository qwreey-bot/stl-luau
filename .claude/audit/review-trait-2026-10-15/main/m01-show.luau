--!strict
local stl = require("../../../../src")
local Trait = stl.Trait
type Tok = stl.TraitToken<string>
type A = { read __probeA: true }
type Bag<T> = { read __type: Tok, read __generics: { read Item: (T) -> T }, items: { T } }
local F = Trait.Trait("M01.F", function<Self, T>(of: (Self & stl.TraitItem<T>) | Tok)
	return table.freeze({
		Map = Trait.Fn<<<U>(bag: Self, fn: (T) -> U) -> { U }>>(),
		Fold = Trait.Default(function(ops: any): <U>(bag: Self, init: U, fn: (U, T) -> U) -> U
			return function<U>(bag: Self, init: U, fn: (U, T) -> U): U
				return init
			end
		end),
	})
end)
type P = typeof(F.ImplOf<<Bag<A>, A>>(nil :: any))
type Q = typeof(F.Of<<Bag<A>, A>>(nil :: any))
local showP: nil = (nil :: any) :: P
local showQ: nil = (nil :: any) :: Q
local showOf: nil = F.Of
local negFullPin: Q = { Map = function(_b: Bag<A>, _fn: (A) -> number): { number } return {} end,
	Fold = function(_b: Bag<A>, init: number, _fn: (number, A) -> number): number return init end }
return { showP, showQ, showOf, negFullPin }
