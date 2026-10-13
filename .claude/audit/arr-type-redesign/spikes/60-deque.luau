--!strict
--[[
	CircularDeque — 새 컨테이너의 음성 대조군 (2026-10-07, M5).

	지키는 성질: 꺼내기·조회는 **`?`**, 원소 타입은 넣기·꺼내기·순회·`ToArr` 를 지나며 그대로,
	**타입 토큰**이 리터럴과 다른 종류(`Arr`)를 막음(서로 바꿔 넣을 수 없음).

	⭐ **읽기 함수는 공변**(2026-10-12 사용자 결정, 질문 AK — `CircularDequeRead`, `spikes/56` 의 CircularDeque 판):
	좁은 덱을 넓은 읽기 자리에 넘길 수 있고, 그렇게 빌린 참조로는 **쓰지 못합니다**(넣기·꺼내기·
	`Clear`·쓰는 제네릭). `ToArr`·`Clone` 은 새 컨테이너라 넓은 타입으로 받아도 건전합니다.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 29 + CANARY 1)
]]
local stl = require("../../../../src")
local CircularDeque, Arr = stl.CircularDeque, stl.Arr
type CircularDeque<T> = stl.CircularDeque<T>

local d = CircularDeque.Of(10, 20)
local holed = CircularDeque.New<<number?>>()

--[[ POS ]]
CircularDeque.PushBack(d, 30)
CircularDeque.PushFront(d, 0)
CircularDeque.PushBack(holed, nil)
local popped: number? = CircularDeque.PopFront(d)
local front: number? = CircularDeque.Front(d)
local at: number? = CircularDeque.At(d, -1)
local asArr: stl.Arr<number> = CircularDeque.ToArr(d)
local found: number? = stl.List.IndexOf(d, 20)
local fromList: CircularDeque<string> = CircularDeque.FromList({ "a", "b" })
local sum = 0
for _, v in CircularDeque.Iter(d) do
	sum += v
end

--[[ NEG — `?` 를 지킴 ]]
local negPopFront: number = CircularDeque.PopFront(d)
local negPopBack: number = CircularDeque.PopBack(d)
local negFront: number = CircularDeque.Front(d)
local negBack: number = CircularDeque.Back(d)
local negAt: number = CircularDeque.At(d, 1)

--[[ NEG — 원소 타입 ]]
CircularDeque.PushBack(d, "x")
CircularDeque.PushFront(d, nil)
local negToArr: stl.Arr<string> = CircularDeque.ToArr(d)
local negFromList: CircularDeque<string> = CircularDeque.FromList({ 1, 2 })
for _, v in CircularDeque.Iter(d) do
	local _negIter: string = v
end

--[[ NEG — 리터럴과 다른 종류는 못 들어옴(모양·마커·토큰 이름) ]]
CircularDeque.PushBack({ head = 0, size = 0, cap = 4 }, 1)
-- 마커까지 다 있고 **토큰만 없는** 꼴 — 이 줄만 토큰 때문에 에러(1라운드: 위 셋은 토큰을 지워도
-- 모양·마커 때문에 에러라 토큰을 지키지 못했음 — spikes/55 의 교훈과 같은 자리)
CircularDeque.PushBack({ head = 0, size = 0, cap = 4, __list = 1, __listIndex = 1 }, 1)
CircularDeque.PushBack(Arr.Of(1), 2)
Arr.PushBack(d, 2)

--[[ POS — 읽기는 공변(CircularDequeRead) ]]
type Base = { id: number }
type Derived = { id: number, name: string }
local derived = CircularDeque.Of<<Derived>>({ id = 1, name = "a" })
local function firstId(list: stl.CircularDequeRead<Base>): number?
	const head = CircularDeque.Front(list)
	return if head then head.id else nil
end
local function countHoles(list: stl.CircularDequeRead<number?>): number
	local holes = 0
	for i = 1, CircularDeque.Len(list) do
		if CircularDeque.At(list, i) == nil then
			holes += 1
		end
	end
	return holes
end
local baseId: number? = firstId(derived)
local holeCount: number = countHoles(d)
local wideAt: (number | string)? = CircularDeque.At<<number | string>>(d, 1)
local wideArr: stl.Arr<number?> = CircularDeque.ToArr<<number?>>(d)
local wideClone: CircularDeque<number?> = CircularDeque.Clone<<number?>>(d)
local wideIndex: number? = stl.List.IndexOf<<number?, number>>(d, nil)
for _, v in CircularDeque.Iter<<number?>>(d) do
	local _wide: number? = v
end
-- 읽기 함수 **열셋 전부**를 빌린 참조로(리뷰: 일곱을 `CircularDequeData` 로 되돌려도 통과했음)
local function allReads(list: stl.CircularDequeRead<Base>)
	const first = CircularDeque.FirstIndex(list)
	const last = CircularDeque.LastIndex(list)
	const item: Base? = CircularDeque.Get(list, 1)
	const nextIdx: number? = CircularDeque.NextIndex(list, 1)
	const prevIdx: number? = CircularDeque.PrevIndex(list, 2)
	const front: Base? = CircularDeque.Front(list)
	const back: Base? = CircularDeque.Back(list)
	const at: Base? = CircularDeque.At(list, -1)
	const len: number = CircularDeque.Len(list)
	const empty: boolean = CircularDeque.Empty(list)
	const asArrBase: stl.Arr<Base> = CircularDeque.ToArr(list)
	const cloned: CircularDeque<Base> = CircularDeque.Clone(list)
	for _, each in CircularDeque.Iter(list) do
		local _each: Base = each
	end
	return first, last, item, nextIdx, prevIdx, front, back, at, len, empty, asArrBase, cloned
end
allReads(derived)
-- 모듈이 빌린 참조용 리스트 계약을 만족
local readOps: stl.ListCore<stl.CircularDequeRead<Base>, Base, number> = CircularDeque

--[[ NEG — 빌린 읽기 참조로는 못 씀 ]]
local function borrowed(list: stl.CircularDequeRead<number?>, base: stl.CircularDequeRead<Base>)
	CircularDeque.PushBack(list, nil)
	CircularDeque.PushFront(list, 1)
	local _popFront = CircularDeque.PopFront(base)
	local _popBack = CircularDeque.PopBack(base)
	CircularDeque.Clear(list)
	list.size = 0
	list[1] = nil
	list.head = 1
	list.cap = 0
	-- `Iter` 가 돌려주는 **상태**로도 쓰기를 못 얻음(리뷰: 반환 상태를 `CircularDequeData` 로 바꾼 사본이 통과했음)
	const _, state = CircularDeque.Iter(list)
	CircularDeque.PushBack(state, nil)
end
-- 쓰는 제네릭(불변 마커)에도 못 들어감 — 읽는 알고리즘(`IndexOf`)은 받음
local function touch<E>(_list: stl.ListMarkerMut<E, number>, _item: E) end
local function borrowedGeneric(list: stl.CircularDequeRead<number>): number?
	touch(list, 3)
	return stl.List.IndexOf(list, 3)
end
touch(d, 3)
-- 쓰는 함수 자체는 넓어지지 않음(불변)
CircularDeque.PushBack<<number?>>(d, nil)
-- 읽기 자리에도 리터럴·다른 종류는 못 들어옴(토큰)
local negLiteral = CircularDeque.Len({ head = 0, size = 0, cap = 4, __list = 1, __listIndex = 1 })
local negArr = CircularDeque.Front(Arr.Of(1))
-- 읽기라도 원소 타입이 어긋나면 안 됨(공변은 좁은 → 넓은 한 방향)
local negNarrow: number? = firstId(d)

local canary: string = 42

return {
	popped,
	front,
	at,
	asArr,
	found,
	fromList,
	sum,
	negPopFront,
	negPopBack,
	negFront,
	negBack,
	negAt,
	negToArr,
	negFromList,
	baseId,
	holeCount,
	wideAt,
	wideArr,
	wideClone,
	wideIndex,
	borrowed,
	borrowedGeneric,
	allReads,
	readOps,
	negLiteral,
	negArr,
	negNarrow,
	canary,
}
