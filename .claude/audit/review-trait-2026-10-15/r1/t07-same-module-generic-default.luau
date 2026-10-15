--!strict
-- 타입 프로브 t07: 같은 모듈에서 정의하고 쓰는 트레이트 — 제네릭 기본 구현(`<U>`)의 반환·인자, 연관 타입 둘.
local stl = require("../../../../src")
local Trait = stl.Trait
type Tok = stl.TraitToken<string>
type Bag<T> = { read __type: Tok, read __generics: { read Item: (T) -> T }, items: { T } }
local Folds = Trait.Trait("T07.Folds", function<Self, T>(of: (Self & stl.TraitItem<T>) | Tok)
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
local b: Bag<number> = nil :: any
local ok: string = Folds.Of(b).Fold(b, "", function(acc: string, x: number): string
	return acc .. x
end)
local neg1: number = Folds.Of(b).Fold(b, "", function(acc: string, x: number): string -- NEG: 반환
	return acc .. x
end)
local neg2 = Folds.Of(b).Fold(b, 0, function(acc: number, x: string): number -- NEG: 원소
	return acc
end)
type Impl = typeof(Folds.ImplOf<<Bag<number>, number>>(nil :: any))
local negImpl: Impl = {
	Each = function(_b: Bag<number>, _fn: (number) -> ()) end,
	Fold = function(_b: Bag<number>, init: number, _fn: (number, number) -> number): number -- NEG: U 못박음
		return init
	end,
}
local canary: string = 1
return { ok, neg1, neg2, negImpl, canary }
