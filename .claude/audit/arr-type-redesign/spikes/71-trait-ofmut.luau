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
stl.Map.Of(tm).Set(tm, "k", 1) -- NEG: 읽기 보기에 Set 없음(대입 없는 문장 — 대입이면 "값을 0개 돌려줌" 이 같은 줄을 메워 돌연변이가 살았음, 리뷰 1라운드 F5)
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
Bag.Of(dr).PutAll(dr, { 1 }) -- NEG: 기본 구현이어도 쓰기 칸은 읽기 보기에 없음(대입 없는 문장 — F5)
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

-- 6. 진입점의 읽기 전용 인덱서(리뷰 1라운드 T2 — 다시 지으며 `read` 를 잃어 `Map.Iter` 결과에 쓰기가 0건, 맵 안쪽이 오염됐음)
local hmIter = stl.HashMap.New<<string, number>>()
local inner = stl.Map.Iter(hmIter)
if type(inner) == "table" then
	inner.evil = 999 -- NEG: 안쪽 테이블에 바로 씀
end

-- 7. 리스트의 위치는 불변(리뷰 1라운드 T1 — 공변 `() -> I` 라 엉뚱한 위치가 합집합으로 넓어져 0건, 라이브러리 줄에서 터졌음)
local ldPos = stl.LinkedDeque.Of(1, 2)
local arrPos = stl.Arr.Of(10, 20)
local okGet: number? = stl.List.Get(arrPos, 1)
local okFirst = stl.List.FirstIndex(ldPos)
local okNext = if okFirst then stl.List.NextIndex(ldPos, okFirst) else nil
local okWide: stl.ListRead<number?, number> = arrPos -- 원소는 그대로 공변(위치가 숫자인 종류)
local negGetPos = stl.List.Get(ldPos, 123) -- NEG: 연결 덱의 위치는 노드
local negNextPos = stl.List.NextIndex(arrPos, "x") -- NEG: 배열의 위치는 숫자
local negPrevPos = stl.List.PrevIndex(ldPos, 5) -- NEG

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

	has,
	negAddRead,
	size,

	bagOk,
	bagBad,
	negThreeParams,
	okGet,
	okNext,
	okWide,
	negGetPos,
	negNextPos,
	negPrevPos,
	canary,
}
