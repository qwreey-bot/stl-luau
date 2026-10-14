--!strict
-- A(v6) 에서도 정의·쓰기가 한 파일이면 기본 구현 칸 반환 검사가 빠지는가(B 의 알려진 위험이 B 만의 것인지)
local Trait = require("./trait-v8/Trait")
type ItemIndexRead<E, I> = Trait.ItemIndexRead<E, I>
type AnyToken = Trait.AnyToken
const Fn, Default = Trait.Fn, Trait.Default
const List = Trait.Trait("ListB10", function<M>(mode: M) return function<Self, E, I>(of: (Self & ItemIndexRead<E, I>) | AnyToken)
	return {
		Get = Fn<<(list: Self, idx: I) -> E?>>(),
		FirstIndex = Fn<<(list: Self) -> I?>>(),
		NextIndex = Fn<<(list: Self, idx: I) -> I?>>(),
		Contains = Default(mode, function(ops: List<Self, E, I>)
			const get, firstIndex, nextIndex = ops.Get, ops.FirstIndex, ops.NextIndex
			return function(list: Self, item: E): boolean
				local idx = firstIndex(list)
				while idx ~= nil do
					if get(list, idx) == item then
						return true
					end
					idx = nextIndex(list, idx)
				end
				return false
			end
		end),
	}
end end)
export type List<Self, E, I> = typeof(List.Of<<Self, E, I>>(nil :: any))
export type MyArr<T> = { items: { T }, read __generics: { read Item: (T) -> T }, read __readGenerics: { read Item: () -> T, read Index: () -> number } }
local m: MyArr<number> = nil :: any
const has: boolean = List.Of(m).Contains(m, 1)
const NEG_has: string = List.Of(m).Contains(m, 1) -- NEG
const NEG_arg = List.Of(m).Contains(m, "x") -- NEG
local canary: string = 1
return { has, NEG_has, NEG_arg, canary }
