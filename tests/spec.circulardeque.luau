--!strict
--[[
	CircularDeque 테스트. 프레임워크 없음 — assert + print.

	⭐ 링 버퍼라 **감김**(물리 칸이 끝을 넘어 앞으로 돌아감)과 **감긴 채로 늘리기**가 눈에 안 보이는
	곳입니다. 그래서 `Arr`(PushFront/PopFront 가 O(n) 이지만 단순한 모델)과 무작위 연산 수천 번을
	대조합니다. 값은 위치와 다르게 고릅니다(10, 20, …).
]]
local stl = require("../src")
local CircularDeque = stl.CircularDeque
local Arr = stl.Arr

type CircularDeque<T> = stl.CircularDeque<T>

-- 앞에서 뒤 순서의 내용이 기대한 목록과 같은지. 크기와 `Iter`·`At`·`ToArr` 를 같이 봅니다.
local function same<T>(d: CircularDeque<T>, expected: { T }, label: string)
	const count = #expected
	assert(CircularDeque.Len(d) == count, `{label}: Len {CircularDeque.Len(d)} ~= {count}`)
	assert(CircularDeque.Empty(d) == (count == 0), `{label}: Empty`)
	for idx = 1, count do
		assert(CircularDeque.At(d, idx) == expected[idx], `{label}: At({idx}) = {tostring(CircularDeque.At(d, idx))}`)
		assert(CircularDeque.At(d, idx - count - 1) == expected[idx], `{label}: 음수 At`)
	end
	local seen = 0
	for i, v in CircularDeque.Iter(d) do
		seen += 1
		assert(i == seen and v == expected[i], `{label}: Iter {i}`)
	end
	assert(seen == count, `{label}: Iter 수 {seen}`)
	const a = CircularDeque.ToArr(d)
	assert(Arr.isArr(a) and a.n == count, `{label}: ToArr n`)
	for idx = 1, count do
		assert(a[idx] == expected[idx], `{label}: ToArr {idx}`)
	end
	assert(CircularDeque.Front(d) == expected[1] and CircularDeque.Back(d) == expected[count], `{label}: Front/Back`)
end

print("=== 1. 생성자와 기본 ===")
do
	const d = CircularDeque.New<<number>>()
	assert(
		stl.isCircularDeque(d)
			and not stl.isCircularDeque({})
			and not stl.isCircularDeque(Arr.Of(1))
			and not stl.isArr(d),
		"술어"
	)
	assert(getmetatable(d) == nil, "메타테이블 없음")
	same(d, {}, "빈 것")
	assert(
		CircularDeque.PopFront(d) == nil and CircularDeque.PopBack(d) == nil and CircularDeque.Len(d) == 0,
		"빈 Pop"
	)
	assert(
		CircularDeque.Front(d) == nil and CircularDeque.Back(d) == nil and CircularDeque.At(d, 1) == nil,
		"빈 조회"
	)

	same(CircularDeque.Of(10, 20, 30), { 10, 20, 30 }, "Of")
	same(CircularDeque.FromList({ 10, 20, 30 }), { 10, 20, 30 }, "FromList 평범한 표")
	same(CircularDeque.FromList(Arr.Of(10, 20)), { 10, 20 }, "FromList Arr")
	const packed = CircularDeque.FromList(table.pack(10, nil, 30) :: any)
	assert(
		CircularDeque.Len(packed) == 3 and CircularDeque.At(packed, 2) == nil and CircularDeque.At(packed, 3) == 30,
		"FromList 는 n 을 따름"
	)
	-- 다른 종류의 컨테이너는 리스트가 아님(Common.listLength — CircularDeque 자신도)
	-- 거절하며 바꾸는 길(ToArr)을 안내(가로지른 리뷰)
	const okList, errList = pcall(CircularDeque.FromList, CircularDeque.Of(1, 2) :: any)
	assert(not okList and string.find(tostring(errList), "CircularDeque.ToArr", 1, true), tostring(errList))
	const okAdopt, errAdopt = pcall(Arr.Adopt, CircularDeque.Of(1, 2) :: any)
	assert(not okAdopt and string.find(tostring(errAdopt), "CircularDeque.ToArr", 1, true), tostring(errAdopt))
	-- 반대 방향은 ToArr
	same(CircularDeque.FromList(CircularDeque.ToArr(CircularDeque.Of(10, 20))), { 10, 20 }, "ToArr 왕복")

	-- capacity: 미리 잡기, 정책
	const big = CircularDeque.New<<number>>(100)
	assert(big.cap == 100 and CircularDeque.Len(big) == 0, "capacity")
	assert(CircularDeque.New<<number>>(0).cap == 4 and CircularDeque.New<<number>>(2.9).cap == 4, "최소 4")
	assert(
		not pcall(CircularDeque.New, -1)
			and not pcall(CircularDeque.New, 0 / 0)
			and not pcall(CircularDeque.New, 2 ^ 27),
		"capacity 정책"
	)
	-- 우리 메시지까지 봄 — `table.create(2^26 + 1)` 도 "table overflow" 로 터져 pcall 만으로는 경계를
	-- 못 지켰음(2라운드)
	const okBig, errBig = pcall(CircularDeque.New, 2 ^ 26 + 1)
	assert(not okBig and string.find(tostring(errBig), "CircularDeque: capacity must be in", 1, true), tostring(errBig))
	assert(CircularDeque.New<<number>>(-0.5).cap == 4, "capacity 경계(소수는 0 쪽)")
	-- 빈 입력에서 만든 것도 최소 4칸 — 0 칸이면 두 배로 늘릴 수 없음(1라운드: 바닥을 지워도 값은
	-- 맞아 테스트가 통과했지만 cap 0·head -1 로 불변식이 깨졌음)
	for _, empty in
		{ CircularDeque.Of(), CircularDeque.FromList({}), CircularDeque.Clone(CircularDeque.New<<number>>()) } :: { CircularDeque<number> }
	do
		assert(empty.cap >= 4, `빈 입력 cap {empty.cap}`)
		for i = 1, 6 do
			CircularDeque.PushFront(empty, i * 10)
		end
		assert(empty.size <= empty.cap and empty.head >= 0 and empty.head < empty.cap, "빈 입력 뒤 불변식")
		same(empty, { 60, 50, 40, 30, 20, 10 }, "빈 입력 뒤 PushFront")
	end
end
print("PASS")

print("=== 2. 양끝 넣기·꺼내기, 감김, 늘리기 ===")
do
	const d = CircularDeque.New<<number>>()
	assert(CircularDeque.PushBack(d, 20) == d and CircularDeque.PushFront(d, 10) == d, "자기 자신을 돌려줌")
	CircularDeque.PushBack(d, 30)
	same(d, { 10, 20, 30 }, "양끝")
	-- PushFront 가 감김(head 가 cap 끝으로)
	assert(d.head ~= 0, "PushFront 는 감김")
	CircularDeque.PushFront(d, 5)
	same(d, { 5, 10, 20, 30 }, "꽉 참(cap 4)")
	assert(d.cap == 4, "아직 cap 4")
	-- 감긴 채로 늘리기
	CircularDeque.PushBack(d, 40)
	assert(d.cap == 8, "두 배")
	same(d, { 5, 10, 20, 30, 40 }, "감긴 채 늘림")
	CircularDeque.PushFront(d, 1)
	same(d, { 1, 5, 10, 20, 30, 40 }, "늘린 뒤 PushFront")
	assert(CircularDeque.PopFront(d) == 1 and CircularDeque.PopBack(d) == 40, "양끝 꺼내기")
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
		CircularDeque.PopFront(d) == 5
			and CircularDeque.PopFront(d) == 10
			and CircularDeque.PopBack(d) == 30
			and CircularDeque.PopBack(d) == 20,
		"비우기"
	)
	same(d, {}, "다 꺼냄")
	-- 큐로: 오래 돌려도 cap 이 안 늘어남(링)
	const q = CircularDeque.New<<number>>()
	for i = 1, 3 do
		CircularDeque.PushBack(q, i * 10)
	end
	for i = 4, 1000 do
		CircularDeque.PushBack(q, i * 10)
		assert(CircularDeque.PopFront(q) == (i - 3) * 10, "큐 순서")
	end
	assert(q.cap == 4 and CircularDeque.Len(q) == 3, `큐 cap {q.cap}`)
	same(q, { 9980, 9990, 10000 }, "큐 끝")
end
print("PASS")

print("=== 3. At 규약 / Clear / Clone / 구멍 ===")
do
	const d = CircularDeque.Of(10, 20, 30)
	CircularDeque.PushFront(d, 0)
	assert(CircularDeque.At(d, -1) == 30 and CircularDeque.At(d, -4) == 0 and CircularDeque.At(d, -5) == nil, "음수")
	assert(CircularDeque.At(d, 0) == nil and CircularDeque.At(d, 5) == nil, "범위 밖")
	assert(CircularDeque.At(d, 2.9) == 10 and CircularDeque.At(d, -1.5) == 30, "소수는 0 쪽")
	assert(CircularDeque.At(d, math.huge) == nil and CircularDeque.At(d, -math.huge) == nil, "무한대")
	assert(not pcall(CircularDeque.At, d, 0 / 0), "NaN 은 에러")

	-- Clone: 펴서 담음, 원본과 독립
	const c = CircularDeque.Clone(d)
	same(c, { 0, 10, 20, 30 }, "Clone")
	assert(c.head == 0, "Clone 은 편 것")
	CircularDeque.PushBack(c, 99)
	same(d, { 0, 10, 20, 30 }, "원본 그대로")
	assert(stl.isCircularDeque(CircularDeque.Clone(CircularDeque.New<<number>>())), "빈 Clone")

	-- Clear: 칸 수 유지, 칸은 비움, 이어 쓸 수 있음
	const cap = d.cap
	assert(CircularDeque.Clear(d) == d, "자기 자신")
	same(d, {}, "Clear")
	assert(d.cap == cap, "cap 유지")
	for idx = 1, d.cap do
		assert(rawget(d :: any, idx) == nil, "칸 비움")
	end
	CircularDeque.PushFront(d, 7)
	same(d, { 7 }, "Clear 뒤 PushFront")
	-- 감긴 상태의 Clear — 두 구간을 다 지움(O(size) 판)
	const wrapped = CircularDeque.New<<number>>(8)
	for i = 1, 5 do
		CircularDeque.PushBack(wrapped, i * 10)
	end
	for _ = 1, 4 do
		CircularDeque.PopFront(wrapped)
	end
	for i = 6, 9 do
		CircularDeque.PushBack(wrapped, i * 10)
	end
	assert(wrapped.head + wrapped.size > wrapped.cap, "감긴 상태여야 함")
	CircularDeque.Clear(wrapped)
	for idx = 1, wrapped.cap do
		assert(rawget(wrapped :: any, idx) == nil, `감긴 Clear 칸 {idx}`)
	end
	same(wrapped, {}, "감긴 Clear")

	-- 구멍
	const h = CircularDeque.New<<number?>>()
	CircularDeque.PushBack(h, nil)
	CircularDeque.PushFront(h, 10)
	CircularDeque.PushBack(h, nil)
	assert(
		CircularDeque.Len(h) == 3 and CircularDeque.At(h, 1) == 10 and CircularDeque.At(h, 2) == nil,
		"구멍 넣기"
	)
	assert(CircularDeque.PopBack(h) == nil and CircularDeque.Len(h) == 2, "구멍 꺼내기 — 길이는 줄어듦")
	const ha = CircularDeque.ToArr(h)
	assert(ha.n == 2 and ha[1] == 10 and ha[2] == nil, "구멍 ToArr")
	const ho = CircularDeque.Of(nil, 20, nil)
	assert(CircularDeque.Len(ho) == 3 and CircularDeque.At(ho, 2) == 20, "Of 구멍")
end
print("PASS")

print("=== 4. 리스트 트레이트 — List 의 진입점 ===")
do
	const d = CircularDeque.Of(20, 30)
	CircularDeque.PushFront(d, 10)
	CircularDeque.PushFront(d, 30) -- 감긴 상태에서 찾기
	assert(stl.List.IndexOf(d, 30) == 1 and stl.List.IndexOf(d, 20) == 3, "IndexOf")
	assert(stl.List.IndexOf(d, 99) == nil, "없음")
	assert(stl.List.Count(d) == 4, "Count")
	-- (2026-10-13: List 의 완성 표는 "모듈이 준 것 + 기본 구현" 이라 모듈과 다른 표 — 함수로 견줍니다)
	const listOps = stl.Trait.ImplOf(stl.List, d)
	assert(stl.Trait.Implements(stl.List, d) and listOps ~= nil and listOps.Get == CircularDeque.Get, "구현 등록")
	assert(
		CircularDeque.Get(d, 0) == nil and CircularDeque.Get(d, 5) == nil and CircularDeque.Get(d, 4) == 30,
		"Get 범위"
	)
	assert(
		CircularDeque.FirstIndex(CircularDeque.New<<number>>()) == nil and CircularDeque.LastIndex(d) == 4,
		"First/LastIndex"
	)
	assert(
		CircularDeque.NextIndex(d, 4) == nil
			and CircularDeque.PrevIndex(d, 1) == nil
			and CircularDeque.NextIndex(d, 1) == 2,
		"Next/Prev"
	)
end
print("PASS")

print("=== 5. 무작위 대조 — Arr 모델 ===")
do
	math.randomseed(20261007)
	for _round = 1, 200 do
		const d: CircularDeque<number> = if math.random() < 0.5
			then CircularDeque.New<<number>>()
			else CircularDeque.New<<number>>(math.random(0, 9))
		const model = Arr.Sized(0, 0)
		local nextValue = 0
		for _op = 1, math.random(0, 120) do
			const r = math.random()
			if r < 0.3 then
				nextValue += 10
				CircularDeque.PushBack(d, nextValue)
				Arr.PushBack(model, nextValue)
			elseif r < 0.55 then
				nextValue += 10
				CircularDeque.PushFront(d, nextValue)
				Arr.PushFront(model, nextValue)
			elseif r < 0.75 then
				assert(CircularDeque.PopFront(d) == Arr.PopFront(model), "PopFront 대조")
			elseif r < 0.95 then
				assert(CircularDeque.PopBack(d) == Arr.PopBack(model), "PopBack 대조")
			elseif r < 0.98 then
				const c = CircularDeque.Clone(d)
				CircularDeque.Clear(d)
				for _, v in CircularDeque.Iter(c) do
					CircularDeque.PushBack(d, v)
				end
			else
				CircularDeque.Clear(d)
				Arr.Clear(model)
			end
			assert(CircularDeque.Len(d) == model.n, "길이 대조")
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

print(
	"=== 읽기 함수는 공변(CircularDequeRead) — 좁은 덱을 넓은 읽기 자리에 (2026-10-12, 질문 AK) ==="
)
do
	-- 타입 쪽(빌린 참조로 못 씀)은 spikes/60 이 지킵니다. 여기는 그 모양의 사용자 함수가 도는지.
	type Base = { id: number }
	type Derived = { id: number, name: string }
	local function sumIds(list: stl.CircularDequeRead<Base>): number
		local total = 0
		for _, item in CircularDeque.Iter(list) do
			total += item.id
		end
		return total
	end
	local function holes(list: stl.CircularDequeRead<number?>): number
		local count = 0
		for i = 1, CircularDeque.Len(list) do
			if CircularDeque.At(list, i) == nil then
				count += 1
			end
		end
		return count
	end
	const derived = CircularDeque.Of<<Derived>>({ id = 10, name = "a" }, { id = 20, name = "b" })
	CircularDeque.PushFront(derived, { id = 5, name = "z" })
	assert(sumIds(derived) == 35, "CircularDeque<Derived> → CircularDequeRead<Base>")
	const nums = CircularDeque.Of(1, 2, 3)
	assert(holes(nums) == 0, "CircularDeque<number> → CircularDequeRead<number?>")
	const holed = CircularDeque.Of<<number?>>(1, nil, 3)
	assert(holes(holed) == 1, "구멍 든 덱")
	-- 새 컨테이너를 만드는 읽기(ToArr·Clone)는 넓은 타입으로 받아도 원본과 독립
	const wide: stl.CircularDeque<number?> = CircularDeque.Clone<<number?>>(nums)
	CircularDeque.PushBack(wide, nil)
	assert(
		CircularDeque.Len(wide) == 4 and CircularDeque.Len(nums) == 3 and CircularDeque.Back(nums) == 3,
		"Clone 은 독립"
	)
end
print("PASS")

print()
print("=== ALL PASS (CircularDeque) ===")

return true
