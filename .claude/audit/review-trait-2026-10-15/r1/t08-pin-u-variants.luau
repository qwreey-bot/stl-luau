--!strict
-- 타입 프로브 t08: 등록 표의 제네릭 기본 구현 칸(`Fold<U>`)에서 U 를 못박은 재정의 — 어떤 조건에서 잡히나.
local stl = require("../../../../src")
local Trait = stl.Trait
local Folds = require("./t08mod/Folds")
type Tok = stl.TraitToken<string>
type A = { read __probeA: true }
type Bag<T> = { read __type: Tok, read __generics: { read Item: (T) -> T }, items: { T } }
-- (1) 다른 모듈의 정의, 구체 원소(number)
local neg1: Folds.Provided<Bag<number>, number> = {
	Each = function(_b: Bag<number>, _fn: (number) -> ()) end,
	Fold = function(_b: Bag<number>, init: number, _fn: (number, number) -> number): number -- NEG?
		return init
	end,
}
-- (2) 다른 모듈의 정의, 탐침 원소(A)
local neg2: Folds.Provided<Bag<A>, A> = {
	Each = function(_b: Bag<A>, _fn: (A) -> ()) end,
	Fold = function(_b: Bag<A>, init: number, _fn: (number, A) -> number): number -- NEG?
		return init
	end,
}
-- (3) 내장 List, 탐침(스파이크 70 과 같음 — 대조)
type Arr<T> = stl.Arr<T>
local neg3: stl.ListProvided<Arr<A>, A, number> = {
	Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex,
	Fold = function(_list: Arr<A>, init: number, _fn: (number, A, number, ...any) -> number): number -- NEG(대조)
		return init
	end,
}
-- (4) 내장 List, 구체 원소(number)
local neg4: stl.ListProvided<Arr<number>, number, number> = {
	Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex,
	Fold = function(_list: Arr<number>, init: number, _fn: (number, number, number, ...any) -> number): number -- NEG?
		return init
	end,
}
-- (5) 같은 정의를 이 모듈에서, 탐침
local Folds5 = Trait.Trait("T08.Folds5", function<Self, T>(of: (Self & stl.TraitItem<T>) | Tok)
	return table.freeze({
		Each = Trait.Fn<<(bag: Self, fn: (T) -> ()) -> ()>>(),
		Fold = Trait.Default(function(ops: any): <U>(bag: Self, init: U, fn: (U, T) -> U) -> U
			return function<U>(bag: Self, init: U, fn: (U, T) -> U): U
				return init
			end
		end),
	})
end)
local neg5: typeof(Folds5.ImplOf<<Bag<A>, A>>(nil :: any)) = {
	Each = function(_b: Bag<A>, _fn: (A) -> ()) end,
	Fold = function(_b: Bag<A>, init: number, _fn: (number, A) -> number): number -- NEG?
		return init
	end,
}
local canary: string = 1
return { neg1, neg2, neg3, neg4, neg5, canary }
