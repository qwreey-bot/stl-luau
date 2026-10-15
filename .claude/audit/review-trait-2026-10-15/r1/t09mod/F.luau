--!strict
-- t09 의 정의를 다른 모듈로 옮긴 판
local stl = require("../../../../../src")
local Trait = stl.Trait
type Tok = stl.TraitToken<string>
local F = Trait.Trait("T09.F", function<Self, T>(of: (Self & stl.TraitItem<T>) | Tok)
	return table.freeze({
		Each = Trait.Fn<<(bag: Self, fn: (T) -> ()) -> ()>>(),
		Map = Trait.Fn<<<U>(bag: Self, fn: (T) -> U) -> { U }>>(), -- 필수 칸에 제네릭
		Fold = Trait.Default(function(ops: any): <U>(bag: Self, init: U, fn: (U, T) -> U) -> U
			return function<U>(bag: Self, init: U, fn: (U, T) -> U): U
				return init
			end
		end),
		Count = Trait.Default(function(ops: any): (bag: Self) -> number -- 비제네릭 기본 구현(대조)
			return function(bag: Self): number
				return 0
			end
		end),
	})
end)
return F
