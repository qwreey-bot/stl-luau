--!strict
-- t08 의 다른 모듈 판: t07 과 같은 정의를 따로 둔 모듈.
local stl = require("../../../../../src")
local Trait = stl.Trait
type Tok = stl.TraitToken<string>
local Folds = Trait.Trait("T08.Folds", function<Self, T>(of: (Self & stl.TraitItem<T>) | Tok)
	return table.freeze({
		Each = Trait.Fn<<(bag: Self, fn: (T) -> ()) -> ()>>(),
		Fold = Trait.Default(function(ops: any): <U>(bag: Self, init: U, fn: (U, T) -> U) -> U
			return function<U>(bag: Self, init: U, fn: (U, T) -> U): U
				local acc = init
				ops.Each(bag, function(x: T)
					acc = fn(acc, x)
				end)
				return acc
			end
		end),
	})
end)
export type Provided<Self, T> = typeof(Folds.ImplOf<<Self, T>>(nil :: any))
return Folds
