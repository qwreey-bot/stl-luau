--!strict
--[[
	시제품(trait-ofmut, 2026-10-15 — 사용자: "OfMut 이랑 Of 가 있는 느낌"): 칸을 읽기(`Fn`·`Default`)와 쓰기(`FnMut`·`DefaultMut`)로
	적고, `X.Of` 는 읽기 보기(쓰기 칸 없음 — 빌린 참조도 받음), `X.OfMut` 은 완성 표(바꿀 수 있는 참조만).

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 줄마다 + CANARY 1).
]]
local stl = require("../../../../src")
local Trait = stl.Trait
type A = { read __probeA: true }
type CircularDeque<T> = stl.CircularDeque<T>

--[[ 1. Collection — 예전 구멍: 빌린 참조가 완성 표를 거쳐 Clear 를 얻었음 ]]
local a = stl.Arr.Of(1, 2, 3)
local r: stl.ArrRead<number> = a
local len: number = stl.Collection.Of(r).Len(r)
local negClearRead = stl.Collection.Of(r).Clear(r) -- NEG: 읽기 보기에 Clear 없음
local negClearMut = stl.Collection.OfMut(r) -- NEG: 빌린 참조는 완성 표를 못 얻음
local cleared: stl.Arr<number> = stl.Collection.OfMut(a).Clear(a)

--[[ 2. Deque — 예전 과잉: 빌린 참조가 읽기 함수만 쓰려 해도 표를 못 얻었음 ]]
local d = stl.CircularDeque.Of(1, 2)
local dr: stl.CircularDequeRead<number> = d
local front: number? = stl.Deque.Of(dr).Front(dr)
local negFront: string? = stl.Deque.Of(dr).Back(dr) -- NEG: 원소 타입은 그대로 섬
local negPushRead = stl.Deque.Of(d).PushBack(d, 3) -- NEG: 읽기 보기엔 쓰기 칸이 없음(바꿀 수 있는 값이어도)
local pushed: CircularDeque<number> = stl.Deque.OfMut(d).PushBack(d, 3)
local negPushElem = stl.Deque.OfMut(d).PushBack(d, "x") -- NEG: 원소

--[[ 3. 보기를 받는 사용자 제네릭 — 완성 표는 읽기 보기 자리에 들어가고, 반대는 안 됨 ]]
local function peekBoth<C, T>(v: stl.DequeReadFull<C, T>, c: C): T?
	return v.Front(c) or v.Back(c)
end
local function drainAll<C, T>(v: stl.DequeFull<C, T>, c: C): { T }
	const out = {}
	local x = v.PopBack(c)
	while x ~= nil do
		table.insert(out, x)
		x = v.PopBack(c)
	end
	return out
end
local p1: number? = peekBoth(stl.Deque.Of(dr), dr)
local p2: number? = peekBoth(stl.Deque.OfMut(d), d)
local negPeek: string? = peekBoth(stl.Deque.Of(dr), dr) -- NEG
local drained: { number } = drainAll(stl.Deque.OfMut(d), d)
local negDrainRead = drainAll(stl.Deque.Of(d), d) -- NEG: 읽기 보기를 완성 표 자리에

--[[ 4. Map·Set — 읽기 보기도 키는 불변(질문 AM: 조회만 해도 키가 입력) ]]
local tm = stl.TreeMap.New<<string, number>>(function(x: string, y: string): number
	return if x < y then -1 elseif x > y then 1 else 0
end)
local got: number? = stl.Map.Of(tm).Get(tm, "k")
local negGetKey = stl.Map.Of(tm).Get(tm, 1) -- NEG: 숫자 키
local negSetRead = stl.Map.Of(tm).Set(tm, "k", 1) -- NEG: 읽기 보기에 Set 없음
stl.Map.OfMut(tm).Set(tm, "k", 1)
local hs = stl.HashSet.Of(1, 2)
local has: boolean = stl.Set.Of(hs).Has(hs, 1)
local negAddRead = stl.Set.Of(hs).Add(hs, 3) -- NEG

--[[ 5. 사용자 트레이트 — DefaultMut, 정의자 실수 ]]
local Bag
do
	Bag = Trait.Trait(
		"Spike71.Bag",
		function<Self, T>(
			of: (Self & stl.DequeRead<T>) | stl.TraitToken<string>,
			ofMut: (Self & stl.Deque<T>) | stl.TraitToken<string>
		)
			return table.freeze({
				Peek = Trait.Fn<<(bag: Self) -> T?>>(),
				Put = Trait.FnMut<<(bag: Self, item: T) -> ()>>(),
				Size = Trait.Default(function(_ops: any): (bag: Self) -> number
					return function(_bag)
						return 0
					end
				end),
				PutAll = Trait.DefaultMut(function(ops: any): (bag: Self, items: { T }) -> ()
					return function(bag, items)
						for _, x in items do
							ops.Put(bag, x)
						end
					end
				end),
			})
		end
	)
end
local size: number = Bag.Of(dr).Size(dr)
local negPutAllRead = Bag.Of(dr).PutAll(dr, { 1 }) -- NEG: 기본 구현이어도 쓰기 칸은 읽기 보기에 없음
Bag.OfMut(d).PutAll(d, { 1 })
Bag.OfMut(d).PutAll(d, { "x" }) -- NEG
local bagOk: typeof(Bag.ImplOf<<CircularDeque<A>, A>>(nil :: any)) = {
	Peek = function(_b: CircularDeque<A>): A?
		return nil
	end,
	Put = function(_b: CircularDeque<A>, _x: A) end,
}
local bagBad: typeof(Bag.ImplOf<<CircularDeque<A>, A>>(nil :: any)) = {
	Peek = function(_b: CircularDeque<A>): A?
		return nil
	end,
	Put = function(_b: CircularDeque<A>, _x: A) end,
	PutAll = function(_b: CircularDeque<A>, _xs: { string }) end, -- NEG: 기본 구현(쓰기) 칸의 재정의도 검사됨
}
local negThreeParams = Trait.Trait(
	"Spike71.Three",
	function<Self>(of: Self, ofMut: Self, extra: Self) -- NEG: 매개변수 셋
		return table.freeze({ Run = Trait.Fn<<(x: Self) -> ()>>() })
	end
)

local canary: string = 1
return {
	len,
	negClearRead,
	negClearMut,
	cleared,
	front,
	negFront,
	negPushRead,
	pushed,
	negPushElem,
	p1,
	p2,
	negPeek,
	drained,
	negDrainRead,
	got,
	negGetKey,
	negSetRead,
	has,
	negAddRead,
	size,
	negPutAllRead,
	bagOk,
	bagBad,
	negThreeParams,
	canary,
}
