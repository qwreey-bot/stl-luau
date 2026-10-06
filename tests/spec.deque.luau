--!strict
--[[
	Deque 테스트. 프레임워크 없음 — assert + print.

	⭐ 링 버퍼라 **감김**(물리 칸이 끝을 넘어 앞으로 돌아감)과 **감긴 채로 늘리기**가 눈에 안 보이는
	곳입니다. 그래서 `Arr`(PushFront/PopFront 가 O(n) 이지만 단순한 모델)과 무작위 연산 수천 번을
	대조합니다. 값은 위치와 다르게 고릅니다(10, 20, …).
]]
local stl = require("../src")
local Deque = stl.Deque
local Arr = stl.Arr

type Deque<T> = stl.Deque<T>

-- 앞에서 뒤 순서의 내용이 기대한 목록과 같은지. 크기와 `Iter`·`At`·`ToArr` 를 같이 봅니다.
local function same<T>(d: Deque<T>, expected: { T }, label: string)
	const count = #expected
	assert(Deque.Len(d) == count, `{label}: Len {Deque.Len(d)} ~= {count}`)
	assert(Deque.Empty(d) == (count == 0), `{label}: Empty`)
	for idx = 1, count do
		assert(Deque.At(d, idx) == expected[idx], `{label}: At({idx}) = {tostring(Deque.At(d, idx))}`)
		assert(Deque.At(d, idx - count - 1) == expected[idx], `{label}: 음수 At`)
	end
	local seen = 0
	for i, v in Deque.Iter(d) do
		seen += 1
		assert(i == seen and v == expected[i], `{label}: Iter {i}`)
	end
	assert(seen == count, `{label}: Iter 수 {seen}`)
	const a = Deque.ToArr(d)
	assert(Arr.isArr(a) and a.n == count, `{label}: ToArr n`)
	for idx = 1, count do
		assert(a[idx] == expected[idx], `{label}: ToArr {idx}`)
	end
	assert(Deque.Front(d) == expected[1] and Deque.Back(d) == expected[count], `{label}: Front/Back`)
end

print("=== 1. 생성자와 기본 ===")
do
	const d = Deque.New<<number>>()
	assert(stl.isDeque(d) and not stl.isDeque({}) and not stl.isDeque(Arr.Of(1)) and not stl.isArr(d), "술어")
	assert(getmetatable(d) == nil, "메타테이블 없음")
	same(d, {}, "빈 것")
	assert(Deque.PopFront(d) == nil and Deque.PopBack(d) == nil and Deque.Len(d) == 0, "빈 Pop")
	assert(Deque.Front(d) == nil and Deque.Back(d) == nil and Deque.At(d, 1) == nil, "빈 조회")

	same(Deque.Of(10, 20, 30), { 10, 20, 30 }, "Of")
	same(Deque.FromList({ 10, 20, 30 }), { 10, 20, 30 }, "FromList 평범한 표")
	same(Deque.FromList(Arr.Of(10, 20)), { 10, 20 }, "FromList Arr")
	const packed = Deque.FromList(table.pack(10, nil, 30) :: any)
	assert(
		Deque.Len(packed) == 3 and Deque.At(packed, 2) == nil and Deque.At(packed, 3) == 30,
		"FromList 는 n 을 따름"
	)
	-- 다른 종류의 컨테이너는 리스트가 아님(Common.listLength — Deque 자신도)
	assert(not pcall(Deque.FromList, Deque.Of(1, 2) :: any), "Deque 는 리스트 진입점이 거절")
	assert(not pcall(Arr.FromTable, Deque.Of(1, 2) :: any), "Arr.FromTable 도 Deque 를 거절")
	-- 반대 방향은 ToArr
	same(Deque.FromList(Deque.ToArr(Deque.Of(10, 20))), { 10, 20 }, "ToArr 왕복")

	-- capacity: 미리 잡기, 정책
	const big = Deque.New<<number>>(100)
	assert(big.cap == 100 and Deque.Len(big) == 0, "capacity")
	assert(Deque.New<<number>>(0).cap == 4 and Deque.New<<number>>(2.9).cap == 4, "최소 4")
	assert(not pcall(Deque.New, -1) and not pcall(Deque.New, 0 / 0) and not pcall(Deque.New, 2 ^ 27), "capacity 정책")
	assert(not pcall(Deque.New, 2 ^ 26 + 1) and Deque.New<<number>>(-0.5).cap == 4, "capacity 경계(소수는 0 쪽)")
	-- 빈 입력에서 만든 것도 최소 4칸 — 0 칸이면 두 배로 늘릴 수 없음(1라운드: 바닥을 지워도 값은
	-- 맞아 테스트가 통과했지만 cap 0·head -1 로 불변식이 깨졌음)
	for _, empty in { Deque.Of(), Deque.FromList({}), Deque.Clone(Deque.New<<number>>()) } :: { Deque<number> } do
		assert(empty.cap >= 4, `빈 입력 cap {empty.cap}`)
		for i = 1, 6 do
			Deque.PushFront(empty, i * 10)
		end
		assert(empty.size <= empty.cap and empty.head >= 0 and empty.head < empty.cap, "빈 입력 뒤 불변식")
		same(empty, { 60, 50, 40, 30, 20, 10 }, "빈 입력 뒤 PushFront")
	end
end
print("PASS")

print("=== 2. 양끝 넣기·꺼내기, 감김, 늘리기 ===")
do
	const d = Deque.New<<number>>()
	assert(Deque.PushBack(d, 20) == d and Deque.PushFront(d, 10) == d, "자기 자신을 돌려줌")
	Deque.PushBack(d, 30)
	same(d, { 10, 20, 30 }, "양끝")
	-- PushFront 가 감김(head 가 cap 끝으로)
	assert(d.head ~= 0, "PushFront 는 감김")
	Deque.PushFront(d, 5)
	same(d, { 5, 10, 20, 30 }, "꽉 참(cap 4)")
	assert(d.cap == 4, "아직 cap 4")
	-- 감긴 채로 늘리기
	Deque.PushBack(d, 40)
	assert(d.cap == 8, "두 배")
	same(d, { 5, 10, 20, 30, 40 }, "감긴 채 늘림")
	Deque.PushFront(d, 1)
	same(d, { 1, 5, 10, 20, 30, 40 }, "늘린 뒤 PushFront")
	assert(Deque.PopFront(d) == 1 and Deque.PopBack(d) == 40, "양끝 꺼내기")
	same(d, { 5, 10, 20, 30 }, "꺼낸 뒤")
	-- 쓰지 않는 물리 칸은 비어 있음(꺼낸 원소를 붙잡지 않음 — GC)
	local live = 0
	for idx = 1, d.cap do
		if rawget(d :: any, idx) ~= nil then
			live += 1
		end
	end
	assert(live == 4, `살아 있는 칸 {live}`)
	-- 비울 때까지
	assert(
		Deque.PopFront(d) == 5 and Deque.PopFront(d) == 10 and Deque.PopBack(d) == 30 and Deque.PopBack(d) == 20,
		"비우기"
	)
	same(d, {}, "다 꺼냄")
	-- 큐로: 오래 돌려도 cap 이 안 늘어남(링)
	const q = Deque.New<<number>>()
	for i = 1, 3 do
		Deque.PushBack(q, i * 10)
	end
	for i = 4, 1000 do
		Deque.PushBack(q, i * 10)
		assert(Deque.PopFront(q) == (i - 3) * 10, "큐 순서")
	end
	assert(q.cap == 4 and Deque.Len(q) == 3, `큐 cap {q.cap}`)
	same(q, { 9980, 9990, 10000 }, "큐 끝")
end
print("PASS")

print("=== 3. At 규약 / Clear / Clone / 구멍 ===")
do
	const d = Deque.Of(10, 20, 30)
	Deque.PushFront(d, 0)
	assert(Deque.At(d, -1) == 30 and Deque.At(d, -4) == 0 and Deque.At(d, -5) == nil, "음수")
	assert(Deque.At(d, 0) == nil and Deque.At(d, 5) == nil, "범위 밖")
	assert(Deque.At(d, 2.9) == 10 and Deque.At(d, -1.5) == 30, "소수는 0 쪽")
	assert(Deque.At(d, math.huge) == nil and Deque.At(d, -math.huge) == nil, "무한대")
	assert(not pcall(Deque.At, d, 0 / 0), "NaN 은 에러")

	-- Clone: 펴서 담음, 원본과 독립
	const c = Deque.Clone(d)
	same(c, { 0, 10, 20, 30 }, "Clone")
	assert(c.head == 0, "Clone 은 편 것")
	Deque.PushBack(c, 99)
	same(d, { 0, 10, 20, 30 }, "원본 그대로")
	assert(stl.isDeque(Deque.Clone(Deque.New<<number>>())), "빈 Clone")

	-- Clear: 칸 수 유지, 칸은 비움, 이어 쓸 수 있음
	const cap = d.cap
	assert(Deque.Clear(d) == d, "자기 자신")
	same(d, {}, "Clear")
	assert(d.cap == cap, "cap 유지")
	for idx = 1, d.cap do
		assert(rawget(d :: any, idx) == nil, "칸 비움")
	end
	Deque.PushFront(d, 7)
	same(d, { 7 }, "Clear 뒤 PushFront")
	-- 감긴 상태의 Clear — 두 구간을 다 지움(O(size) 판)
	const wrapped = Deque.New<<number>>(8)
	for i = 1, 5 do
		Deque.PushBack(wrapped, i * 10)
	end
	for _ = 1, 4 do
		Deque.PopFront(wrapped)
	end
	for i = 6, 9 do
		Deque.PushBack(wrapped, i * 10)
	end
	assert(wrapped.head + wrapped.size > wrapped.cap, "감긴 상태여야 함")
	Deque.Clear(wrapped)
	for idx = 1, wrapped.cap do
		assert(rawget(wrapped :: any, idx) == nil, `감긴 Clear 칸 {idx}`)
	end
	same(wrapped, {}, "감긴 Clear")

	-- 구멍
	const h = Deque.New<<number?>>()
	Deque.PushBack(h, nil)
	Deque.PushFront(h, 10)
	Deque.PushBack(h, nil)
	assert(Deque.Len(h) == 3 and Deque.At(h, 1) == 10 and Deque.At(h, 2) == nil, "구멍 넣기")
	assert(Deque.PopBack(h) == nil and Deque.Len(h) == 2, "구멍 꺼내기 — 길이는 줄어듦")
	const ha = Deque.ToArr(h)
	assert(ha.n == 2 and ha[1] == 10 and ha[2] == nil, "구멍 ToArr")
	const ho = Deque.Of(nil, 20, nil)
	assert(Deque.Len(ho) == 3 and Deque.At(ho, 2) == 20, "Of 구멍")
end
print("PASS")

print("=== 4. 리스트 트레이트 — Algorithm ===")
do
	const d = Deque.Of(20, 30)
	Deque.PushFront(d, 10)
	Deque.PushFront(d, 30) -- 감긴 상태에서 찾기
	assert(stl.Algorithm.IndexOf(d, 30) == 1 and stl.Algorithm.IndexOf(d, 20) == 3, "IndexOf")
	assert(stl.Algorithm.IndexOf(d, 99) == nil, "없음")
	assert(stl.Algorithm.Count(d) == 4, "Count")
	assert(stl.Trait.Implements(stl.Trait.List, d) and stl.Trait.ImplOf(stl.Trait.List, d) == Deque, "구현 등록")
	assert(Deque.Get(d, 0) == nil and Deque.Get(d, 5) == nil and Deque.Get(d, 4) == 30, "Get 범위")
	assert(Deque.FirstIndex(Deque.New<<number>>()) == nil and Deque.LastIndex(d) == 4, "First/LastIndex")
	assert(Deque.NextIndex(d, 4) == nil and Deque.PrevIndex(d, 1) == nil and Deque.NextIndex(d, 1) == 2, "Next/Prev")
end
print("PASS")

print("=== 5. 무작위 대조 — Arr 모델 ===")
do
	math.randomseed(20261007)
	for _round = 1, 200 do
		const d: Deque<number> = if math.random() < 0.5
			then Deque.New<<number>>()
			else Deque.New<<number>>(math.random(0, 9))
		const model = Arr.Sized(0, 0)
		local nextValue = 0
		for _op = 1, math.random(0, 120) do
			const r = math.random()
			if r < 0.3 then
				nextValue += 10
				Deque.PushBack(d, nextValue)
				Arr.PushBack(model, nextValue)
			elseif r < 0.55 then
				nextValue += 10
				Deque.PushFront(d, nextValue)
				Arr.PushFront(model, nextValue)
			elseif r < 0.75 then
				assert(Deque.PopFront(d) == Arr.PopFront(model), "PopFront 대조")
			elseif r < 0.95 then
				assert(Deque.PopBack(d) == Arr.PopBack(model), "PopBack 대조")
			elseif r < 0.98 then
				const c = Deque.Clone(d)
				Deque.Clear(d)
				for _, v in Deque.Iter(c) do
					Deque.PushBack(d, v)
				end
			else
				Deque.Clear(d)
				Arr.Clear(model)
			end
			assert(Deque.Len(d) == model.n, "길이 대조")
			assert(d.size <= d.cap and d.head >= 0 and d.head < d.cap, "head·size 불변식")
		end
		const expected = table.create(model.n) :: { number }
		for idx = 1, model.n do
			expected[idx] = model[idx]
		end
		same(d, expected, "무작위")
		-- 물리 칸 중 살아 있는 것은 정확히 size 개
		local live = 0
		for idx = 1, d.cap do
			if rawget(d :: any, idx) ~= nil then
				live += 1
			end
		end
		assert(live == d.size, `살아 있는 칸 {live} ~= {d.size}`)
		assert(rawget(d :: any, d.cap + 1) == nil, "cap 밖 칸 없음")
	end
end
print("PASS")

print()
print("=== ALL PASS (Deque) ===")

return true
