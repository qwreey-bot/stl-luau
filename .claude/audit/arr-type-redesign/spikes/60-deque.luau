--!strict
--[[
	Deque — 새 컨테이너의 음성 대조군 (2026-10-07, M5).

	지키는 성질: 꺼내기·조회는 **`?`**, 원소 타입은 넣기·꺼내기·순회·`ToArr` 를 지나며 그대로,
	**타입 토큰**이 리터럴과 다른 종류(`Arr`)를 막음(서로 바꿔 넣을 수 없음).

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 13 + CANARY 1)
]]
local stl = require("../../../../src")
local Deque, Arr = stl.Deque, stl.Arr
type Deque<T> = stl.Deque<T>

local d = Deque.Of(10, 20)
local holed = Deque.New<<number?>>()

--[[ POS ]]
Deque.PushBack(d, 30)
Deque.PushFront(d, 0)
Deque.PushBack(holed, nil)
local popped: number? = Deque.PopFront(d)
local front: number? = Deque.Front(d)
local at: number? = Deque.At(d, -1)
local asArr: stl.Arr<number> = Deque.ToArr(d)
local found: number? = stl.Algorithm.IndexOf(d, 20)
local fromList: Deque<string> = Deque.FromList({ "a", "b" })
local sum = 0
for _, v in Deque.Iter(d) do
	sum += v
end

--[[ NEG — `?` 를 지킴 ]]
local negPopFront: number = Deque.PopFront(d)
local negPopBack: number = Deque.PopBack(d)
local negFront: number = Deque.Front(d)
local negBack: number = Deque.Back(d)
local negAt: number = Deque.At(d, 1)

--[[ NEG — 원소 타입 ]]
Deque.PushBack(d, "x")
Deque.PushFront(d, nil)
local negToArr: stl.Arr<string> = Deque.ToArr(d)
local negFromList: Deque<string> = Deque.FromList({ 1, 2 })
for _, v in Deque.Iter(d) do
	local _negIter: string = v
end

--[[ NEG — 타입 토큰: 리터럴과 다른 종류는 못 들어옴 ]]
Deque.PushBack({ head = 0, size = 0, cap = 4 }, 1)
Deque.PushBack(Arr.Of(1), 2)
Arr.PushBack(d, 2)

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
	canary,
}
