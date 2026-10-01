--!strict
--[[
	Heap 테스트.

	⭐ 힙은 **불변식이 깨져도 겉으로 안 보입니다** — 몇 개는 맞게 나오다가
	어느 입력에서만 틀립니다. 그래서 매 연산 뒤에 힙 성질을 직접 검사하고,
	무작위 입력에 대해 정렬 결과와 대조합니다.
]]
local stl = require("../src")
local Heap = stl.Heap

type Heap<T> = stl.Heap<T>

const lessNum = function(a: number, b: number): boolean
	return a < b
end

-- 힙 성질: 모든 부모가 자식보다 앞서야 합니다.
const function checkHeap(h: Heap<number>, label: string)
	const items = h.items
	for idx = 2, h.size do
		const parent = idx // 2
		assert(
			not lessNum(items[idx], items[parent]),
			`{label}: 힙 성질이 깨졌습니다 (부모 {items[parent]} > 자식 {items[idx]})`
		)
	end
end

print("=== 1. Push / Peek / Pop ===")
do
	const h = Heap.New(lessNum) :: Heap<number>
	assert(Heap.Empty(h) and Heap.Len(h) == 0, "New")
	assert(stl.isHeap(h), "isHeap")
	assert(not stl.isHeap({}), "평범한 테이블은 isHeap 이 아님")
	assert(Heap.Peek(h) == nil and Heap.Pop(h) == nil, "빈 힙의 Peek/Pop 은 nil")

	Heap.Push(h, 5)
	assert(Heap.Peek(h) == 5 and Heap.Len(h) == 1, "한 개")
	Heap.Push(h, 3)
	Heap.Push(h, 8)
	Heap.Push(h, 1)
	checkHeap(h, "Push 후")
	assert(Heap.Peek(h) == 1, "가장 앞서는 것이 꼭대기")
	assert(Heap.Len(h) == 4, "크기")

	assert(Heap.Pop(h) == 1, "Pop 1")
	checkHeap(h, "Pop 후")
	assert(Heap.Pop(h) == 3, "Pop 2")
	assert(Heap.Pop(h) == 5, "Pop 3")
	assert(Heap.Pop(h) == 8, "Pop 4")
	assert(Heap.Pop(h) == nil and Heap.Empty(h), "다 꺼내면 빔")
end
print("PASS")

print("=== 2. 중복과 한 개짜리 경계 ===")
do
	const h = Heap.FromList({ 2, 2, 2 }, lessNum)
	checkHeap(h, "중복")
	-- 한 줄로 이어 쓰면 린터가 같은 조건을 반복한 것으로 봅니다(Pop 은
	-- 부수효과가 있으므로 오탐이지만, 나눠 쓰는 편이 읽기에도 낫습니다).
	for _ = 1, 3 do
		assert(Heap.Pop(h) == 2, "중복 원소")
	end
	assert(Heap.Pop(h) == nil, "중복 전부 꺼낸 뒤")

	const one = Heap.FromList({ 7 }, lessNum)
	assert(Heap.Peek(one) == 7 and Heap.Pop(one) == 7 and Heap.Empty(one), "한 개")

	const none = Heap.FromList({}, lessNum)
	assert(Heap.Empty(none) and Heap.Pop(none) == nil, "빈 입력")
end
print("PASS")

print("=== 3. FromList 는 O(n) 으로 한 번에 힙을 만드는가 ===")
do
	-- 거꾸로 정렬된 입력이 가장 나쁜 경우입니다.
	const list = table.create(64) :: { number }
	for idx = 1, 64 do
		list[idx] = 65 - idx
	end
	const h = Heap.FromList(list, lessNum)
	checkHeap(h, "FromList")
	assert(Heap.Len(h) == 64 and Heap.Peek(h) == 1, "FromList 결과")
	-- 입력을 건드리지 않아야 합니다
	assert(list[1] == 64, "FromList 는 입력을 복사해야 합니다")
end
print("PASS")

print("=== 4. PushPop / Replace ===")
do
	const h = Heap.FromList({ 3, 5, 7 }, lessNum)
	-- 넣으려는 것이 이미 가장 앞서면 그대로 돌아오고 힙은 안 바뀝니다
	assert(Heap.PushPop(h, 1) == 1, "PushPop 이 가장 앞서는 경우")
	assert(Heap.Len(h) == 3 and Heap.Peek(h) == 3, "힙이 안 바뀌어야 합니다")
	-- 아니면 꼭대기가 나오고 새 것이 들어갑니다
	assert(Heap.PushPop(h, 6) == 3, "PushPop 일반")
	checkHeap(h, "PushPop 후")
	assert(Heap.Len(h) == 3, "PushPop 은 크기를 안 바꿈")
	assert(Heap.Peek(h) == 5, "PushPop 후 꼭대기")

	assert(Heap.Replace(h, 2) == 5, "Replace 는 원래 꼭대기를 돌려줍니다")
	checkHeap(h, "Replace 후")
	assert(Heap.Peek(h) == 2 and Heap.Len(h) == 3, "Replace 후")

	const empty = Heap.New(lessNum) :: Heap<number>
	assert(Heap.Replace(empty, 9) == nil, "빈 힙의 Replace 는 nil")
	assert(Heap.Len(empty) == 1 and Heap.Peek(empty) == 9, "빈 힙의 Replace 는 넣기만 합니다")
	const empty2 = Heap.New(lessNum) :: Heap<number>
	assert(Heap.PushPop(empty2, 9) == 9, "빈 힙의 PushPop")
	assert(Heap.Empty(empty2), "빈 힙의 PushPop 은 안 담습니다")
end
print("PASS")

print("=== 5. Items / Sorted / Clear / Clone ===")
do
	const h = Heap.FromList({ 4, 1, 3, 2 }, lessNum)
	assert(#Heap.Items(h) == 4, "Items 개수")
	-- Items 는 복사여야 합니다
	const snapshot = Heap.Items(h)
	snapshot[1] = 999
	assert(Heap.Peek(h) == 1, "Items 는 복사를 돌려줘야 합니다")

	assert(table.concat(Heap.Sorted(h), ",") == "1,2,3,4", "Sorted")
	assert(Heap.Len(h) == 4, "Sorted 는 원본을 안 건드려야 합니다")
	checkHeap(h, "Sorted 후")
	assert(#Heap.Sorted(Heap.New(lessNum) :: Heap<number>) == 0, "빈 힙의 Sorted")
	assert(table.concat(Heap.Sorted(Heap.FromList({ 9 }, lessNum)), ",") == "9", "한 개의 Sorted")

	const cloned = Heap.Clone(h)
	Heap.Push(cloned, 0)
	assert(Heap.Len(h) == 4 and Heap.Len(cloned) == 5, "Clone 은 독립적")
	assert(Heap.Peek(cloned) == 0 and Heap.Peek(h) == 1, "Clone 후 꼭대기")

	Heap.Clear(h)
	assert(Heap.Empty(h) and Heap.Peek(h) == nil, "Clear")
	Heap.Push(h, 1)
	assert(Heap.Len(h) == 1, "Clear 후 다시 쓸 수 있어야 합니다")
end
print("PASS")

print("=== 6. 최대 힙 (비교자를 뒤집기) ===")
do
	const maxHeap = Heap.FromList({ 1, 5, 3 }, function(a: number, b: number): boolean
		return a > b
	end)
	assert(Heap.Peek(maxHeap) == 5, "최대 힙의 꼭대기")
	assert(Heap.Pop(maxHeap) == 5, "최대 힙 순서 1")
	assert(Heap.Pop(maxHeap) == 3, "최대 힙 순서 2")
	assert(Heap.Pop(maxHeap) == 1, "최대 힙 순서 3")
	-- 3방향 비교자도 어댑터로 쓸 수 있어야 합니다
	const viaAdapter = Heap.FromList({ 3, 1, 2 }, stl.Common.lessFrom(stl.Common.compareNumber))
	assert(table.concat(Heap.Sorted(viaAdapter), ",") == "1,2,3", "3방향 어댑터")
end
print("PASS")

print("=== 7. ⭐ 무작위 대조 — 정렬 결과와 같은가 ===")
do
	-- 힙은 불변식이 미묘하게 깨져도 작은 입력에서는 맞는 답이 나옵니다.
	-- 무작위 입력으로 정렬과 대조하고, 매번 힙 성질도 봅니다.
	local seed = 24680
	const nextRand = function(limit: number): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed % limit
	end

	for _trial = 1, 200 do
		const count = nextRand(30)
		const list = table.create(count) :: { number }
		for idx = 1, count do
			list[idx] = nextRand(50)
		end
		const expected = table.create(count) :: { number }
		table.move(list, 1, count, 1, expected)
		table.sort(expected)

		-- (a) FromList 로 한 번에 만든 힙
		const bulk = Heap.FromList(list, lessNum)
		checkHeap(bulk, `FromList count={count}`)
		assert(table.concat(Heap.Sorted(bulk), ",") == table.concat(expected, ","), "FromList + Sorted 불일치")

		-- (b) Push 를 반복해 만든 힙 — 같은 답이 나와야 합니다
		const pushed = Heap.New(lessNum) :: Heap<number>
		for idx = 1, count do
			Heap.Push(pushed, list[idx])
		end
		checkHeap(pushed, `Push count={count}`)
		const drained = table.create(count) :: { number }
		for idx = 1, count do
			drained[idx] = Heap.Pop(pushed) :: number
		end
		assert(table.concat(drained, ",") == table.concat(expected, ","), "Push + Pop 불일치")
		assert(Heap.Empty(pushed), "전부 꺼내면 비어야 합니다")

		-- (c) PushPop 이 Push 후 Pop 과 같은 답을 내는가
		if count > 0 then
			const viaBoth = Heap.FromList(list, lessNum)
			const extra = nextRand(50)
			const a = Heap.PushPop(viaBoth, extra)
			const viaSeparate = Heap.FromList(list, lessNum)
			Heap.Push(viaSeparate, extra)
			const b = Heap.Pop(viaSeparate)
			assert(a == b, `PushPop 과 Push+Pop 이 다릅니다: {a} vs {tostring(b)}`)
			assert(
				table.concat(Heap.Sorted(viaBoth), ",") == table.concat(Heap.Sorted(viaSeparate), ","),
				"PushPop 후 남은 것이 다릅니다"
			)
		end
	end
end
print("PASS")

print()
print("=== ALL PASS (Heap) ===")

return true
