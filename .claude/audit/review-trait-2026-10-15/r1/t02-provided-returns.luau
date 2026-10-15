--!strict
-- 타입 프로브 t02: 등록 표(Provided)가 "자기 자신을 돌려줌" 계약(Push/Clear → Self)을 지키게 하는가,
-- 그리고 정의를 조금씩 쌓아 만든 표.
local stl = require("../../../../src")
local Trait = stl.Trait
type A = { read __probeA: true }
type Tok = stl.TraitToken<string>
type MyStack<T> = { read __type: Tok, read __generics: { read Item: (T) -> T }, items: { T } }

-- (1) Push 가 아무것도 안 돌려줌 — 계약은 -> Self
local badPushNoRet: stl.StackProvided<MyStack<A>, A> = {
	Push = function(s: MyStack<A>, x: A) -- NEG(1)? 반환 없음
		table.insert(s.items, x)
	end,
	Pop = function(s: MyStack<A>): A?
		return table.remove(s.items)
	end,
	Peek = function(s: MyStack<A>): A?
		return s.items[#s.items]
	end,
}
-- (2) Push 가 넣은 원소를 돌려줌(다른 라이브러리의 흔한 모양)
local badPushItem: stl.StackProvided<MyStack<A>, A> = {
	Push = function(s: MyStack<A>, x: A): A -- NEG(2)
		table.insert(s.items, x)
		return x
	end,
	Pop = function(s: MyStack<A>): A?
		return table.remove(s.items)
	end,
	Peek = function(s: MyStack<A>): A?
		return s.items[#s.items]
	end,
}
-- (3) Collection.Clear 가 아무것도 안 돌려줌
local badClear: stl.CollectionProvided<MyStack<A>> = {
	Len = function(s: MyStack<A>): number
		return #s.items
	end,
	Clear = function(s: MyStack<A>) -- NEG(3)?
		table.clear(s.items)
	end,
}
-- (4) 정의 표를 조금씩 쌓기
local Built = Trait.Trait("T02.Built", function<Self>(of: Self | Tok)
	local slots = {}
	slots.Len = Trait.Fn<<(v: Self) -> number>>()
	return table.freeze(slots)
end)
local s0: MyStack<number> = nil :: any
local p4: string = Built.Of(s0).Len(s0) -- NEG(4)
local canary: string = 1
return { badPushNoRet, badPushItem, badClear, p4, canary }
