--!strict
--[[
	LinkedDeque·Node·Deque 트레이트 테스트. 프레임워크 없음 — assert + print.

	⭐ 연결 리스트의 결함은 **연결이 한쪽만 고쳐진 것**(앞에서 따라가면 맞는데 뒤에서 따라가면 틀림)과
	**머리·꼬리·크기가 어긋난 것**이라 눈에 안 보입니다. 그래서 검사할 때마다 앞에서 뒤로, 뒤에서 앞으로 둘 다
	따라가 보고, 무작위 연산 수천 번을 평범한 배열 모델·`CircularDeque` 와 대조합니다.
	값은 위치와 다르게 고릅니다(10, 20, …).
]]
local stl = require("../src")
local LinkedDeque, CircularDeque, Node, Deque = stl.LinkedDeque, stl.CircularDeque, stl.Node, stl.Deque

type LinkedDeque<T> = stl.LinkedDeque<T>
type NodeRead<T> = stl.NodeRead<T>

-- 내용이 기대한 목록과 같고 **불변식이 전부 서는지**: 크기, 머리·꼬리, 앞→뒤와 뒤→앞 연결, 양끝의 nil.
local function same<T>(d: LinkedDeque<T>, expected: { T }, count: number, label: string)
	assert(LinkedDeque.Len(d) == count, `{label}: Len {LinkedDeque.Len(d)} ~= {count}`)
	assert(LinkedDeque.Empty(d) == (count == 0), `{label}: Empty`)
	-- 앞 → 뒤
	local at, node: NodeRead<T>?, last: NodeRead<T>? = 0, LinkedDeque.FirstIndex(d), nil
	while node ~= nil do
		at += 1
		assert(at <= count, `{label}: 앞→뒤가 크기를 넘음`)
		assert(LinkedDeque.Get(d, node) == expected[at], `{label}: 앞→뒤 {at} = {tostring(node.value)}`)
		assert(LinkedDeque.PrevIndex(d, node) == last, `{label}: {at} 의 앞 연결`)
		last = node
		node = LinkedDeque.NextIndex(d, node)
	end
	assert(at == count, `{label}: 앞→뒤 수 {at}`)
	assert(last == LinkedDeque.LastIndex(d), `{label}: 꼬리`)
	-- 뒤 → 앞
	at, node = count, LinkedDeque.LastIndex(d)
	while node ~= nil do
		assert(at >= 1 and node.value == expected[at], `{label}: 뒤→앞 {at}`)
		at -= 1
		node = LinkedDeque.PrevIndex(d, node)
	end
	assert(at == 0, `{label}: 뒤→앞 수`)
	if count == 0 then
		assert(
			LinkedDeque.FirstIndex(d) == nil and LinkedDeque.LastIndex(d) == nil,
			`{label}: 빈 덱의 머리·꼬리`
		)
		assert(LinkedDeque.Front(d) == nil and LinkedDeque.Back(d) == nil, `{label}: 빈 덱의 Front·Back`)
	else
		assert(LinkedDeque.Front(d) == expected[1] and LinkedDeque.Back(d) == expected[count], `{label}: Front·Back`)
	end
	-- Iter·ToArr 도 같은 순서
	local seen = 0
	for iterNode, value in LinkedDeque.Iter(d) do
		seen += 1
		assert(value == expected[seen] and iterNode.value == value, `{label}: Iter {seen}`)
	end
	assert(seen == count, `{label}: Iter 수 {seen}`)
	const arr = LinkedDeque.ToArr(d)
	assert(stl.isArr(arr) and arr.n == count, `{label}: ToArr 크기`)
	for idx = 1, count do
		assert(arr[idx] == expected[idx], `{label}: ToArr {idx}`)
	end
end

print("=== 1. 생성자와 양끝 ===")
do
	const d = LinkedDeque.New<<number>>()
	assert(stl.isLinkedDeque(d) and not stl.isCircularDeque(d) and not stl.isArr(d), "술어")
	assert(getmetatable(d :: any) == nil, "메타테이블 없음")
	assert(stl.Trait.TokenOf(d) == LinkedDeque.Token, "토큰")
	same(d, {}, 0, "빈 덱")
	assert(LinkedDeque.PopFront(d) == nil and LinkedDeque.PopBack(d) == nil, "빈 덱에서 꺼내기")
	same(d, {}, 0, "빈 덱에서 꺼낸 뒤")

	assert(LinkedDeque.PushBack(d, 20) == d, "PushBack 은 자기 자신")
	same(d, { 20 }, 1, "한 개")
	assert(LinkedDeque.PushFront(d, 10) == d, "PushFront 는 자기 자신")
	LinkedDeque.PushBack(d, 30)
	same(d, { 10, 20, 30 }, 3, "셋")
	assert(LinkedDeque.PopFront(d) == 10, "PopFront")
	same(d, { 20, 30 }, 2, "앞을 꺼낸 뒤")
	assert(LinkedDeque.PopBack(d) == 30, "PopBack")
	same(d, { 20 }, 1, "뒤를 꺼낸 뒤")
	assert(LinkedDeque.PopBack(d) == 20, "마지막 하나를 뒤로")
	same(d, {}, 0, "다 꺼낸 뒤")
	LinkedDeque.PushFront(d, 40)
	assert(LinkedDeque.PopFront(d) == 40, "마지막 하나를 앞으로")
	same(d, {}, 0, "다시 빔")
	-- 비웠다가 다시 쓰기
	LinkedDeque.PushBack(d, 50)
	same(d, { 50 }, 1, "빈 뒤 다시 넣기")

	same(LinkedDeque.Of(10, 20, 30), { 10, 20, 30 }, 3, "Of")
	same(LinkedDeque.Of<<number>>(), {}, 0, "빈 Of")
	same(LinkedDeque.FromList({ 10, 20 }), { 10, 20 }, 2, "FromList")
	same(LinkedDeque.FromList({} :: { number }), {}, 0, "빈 FromList")
	same(LinkedDeque.FromList(stl.Arr.Of(10, 20, 30) :: any), { 10, 20, 30 }, 3, "Arr 에서(n 을 따름)")
	-- 다른 종류의 컨테이너는 리스트 진입점이 거절(위치로 읽으면 틀림)
	assert(not pcall(LinkedDeque.FromList, CircularDeque.Of(1, 2) :: any), "CircularDeque 는 리스트로 안 받음")
	assert(not pcall(LinkedDeque.FromList, LinkedDeque.Of(1, 2) :: any), "LinkedDeque 도")
end
print("PASS")

print("=== 2. 구멍(nil 원소) ===")
do
	const holed = LinkedDeque.Of<<number?>>(10, nil, 30, nil)
	same(holed, { 10, nil, 30, nil } :: { number? }, 4, "구멍 든 Of")
	assert(
		LinkedDeque.PopBack(holed) == nil and LinkedDeque.Len(holed) == 3,
		"구멍을 꺼내면 nil 이지만 크기가 줄어듦"
	)
	assert(LinkedDeque.PopFront(holed) == 10 and LinkedDeque.PopFront(holed) == nil, "앞의 구멍")
	same(holed, { 30 } :: { number? }, 1, "구멍을 꺼낸 뒤")
	const fromPacked = LinkedDeque.FromList(table.pack(10, nil, 30) :: any)
	same(fromPacked, { 10, nil, 30 } :: { any }, 3, "FromList 는 n 을 따름(구멍 포함)")
	const arr = LinkedDeque.ToArr(LinkedDeque.Of<<number?>>(nil, 20))
	assert(arr.n == 2 and arr[1] == nil and arr[2] == 20, "ToArr 는 구멍 그대로")
end
print("PASS")

print("=== 3. 위치(노드)로 넣기·빼기 ===")
do
	const d = LinkedDeque.Of(10, 30)
	const first = LinkedDeque.FirstIndex(d) :: NodeRead<number>
	const last = LinkedDeque.LastIndex(d) :: NodeRead<number>
	const mid = LinkedDeque.InsertAfter(d, first, 20)
	assert(mid.value == 20 and mid[1] == first and mid[2] == last, "InsertAfter 가 돌려준 노드")
	same(d, { 10, 20, 30 }, 3, "가운데에 InsertAfter")
	const tailNode = LinkedDeque.InsertAfter(d, last, 40)
	assert(LinkedDeque.LastIndex(d) == tailNode, "꼬리 뒤에 넣으면 새 꼬리")
	same(d, { 10, 20, 30, 40 }, 4, "꼬리 뒤 InsertAfter")
	const headNode = LinkedDeque.InsertBefore(d, first, 5)
	assert(LinkedDeque.FirstIndex(d) == headNode, "머리 앞에 넣으면 새 머리")
	same(d, { 5, 10, 20, 30, 40 }, 5, "머리 앞 InsertBefore")
	LinkedDeque.InsertBefore(d, last, 25)
	same(d, { 5, 10, 20, 25, 30, 40 }, 6, "가운데에 InsertBefore")

	assert(LinkedDeque.Remove(d, mid) == 20, "Remove 는 값을 돌려줌")
	same(d, { 5, 10, 25, 30, 40 }, 5, "가운데 Remove")
	assert(mid[1] == nil and mid[2] == nil, "떼어 낸 노드는 연결이 끊김")
	assert(LinkedDeque.Remove(d, headNode) == 5, "머리 Remove")
	same(d, { 10, 25, 30, 40 }, 4, "머리 Remove 뒤")
	assert(LinkedDeque.Remove(d, tailNode) == 40, "꼬리 Remove")
	same(d, { 10, 25, 30 }, 3, "꼬리 Remove 뒤")
	-- 하나 남은 것을 Remove
	const single = LinkedDeque.Of("only")
	assert(
		LinkedDeque.Remove(single, LinkedDeque.FirstIndex(single) :: NodeRead<string>) == "only",
		"하나 남은 것"
	)
	same(single, {}, 0, "하나를 Remove 한 뒤")
	-- 꺼낸(Pop) 노드도 연결이 끊김
	const popped = LinkedDeque.Of(10, 20, 30)
	const poppedHead = LinkedDeque.FirstIndex(popped) :: NodeRead<number>
	const poppedTail = LinkedDeque.LastIndex(popped) :: NodeRead<number>
	LinkedDeque.PopFront(popped)
	LinkedDeque.PopBack(popped)
	assert(poppedHead[2] == nil and poppedTail[1] == nil, "꺼낸 노드의 연결")
	same(popped, { 20 }, 1, "양끝을 꺼낸 뒤")

	-- ⭐ 이 덱에 이어져 있지 않은 노드: 사용자 줄 에러(두 번 지우기, 떼어 낸 노드에 넣기, 다른 덱의 머리·꼬리)
	local where = 0
	const other = LinkedDeque.Of(1, 2)
	const stale: { { name: string, call: () -> () } } = {
		{
			name = "Remove",
			call = function()
				where = debug.info(1, "l") + 1
				LinkedDeque.Remove(d, mid)
			end,
		},
		{
			name = "InsertAfter",
			call = function()
				where = debug.info(1, "l") + 1
				LinkedDeque.InsertAfter(d, mid, 99)
			end,
		},
		{
			name = "InsertBefore",
			call = function()
				where = debug.info(1, "l") + 1
				LinkedDeque.InsertBefore(d, poppedHead, 99)
			end,
		},
		{
			name = "Remove",
			call = function()
				where = debug.info(1, "l") + 1
				LinkedDeque.Remove(d, LinkedDeque.FirstIndex(other) :: NodeRead<number>)
			end,
		},
		{
			name = "InsertAfter",
			call = function()
				where = debug.info(1, "l") + 1
				LinkedDeque.InsertAfter(d, LinkedDeque.LastIndex(other) :: NodeRead<number>, 99)
			end,
		},
	}
	for _, case in stale do
		const ok, err = pcall(case.call)
		assert(
			not ok
				and string.find(tostring(err), `LinkedDeque: {case.name} got a node that is not in this deque`, 1, true),
			`{case.name} 메시지: {err}`
		)
		assert(
			string.find(tostring(err), `spec.linkeddeque.luau:{where}:`, 1, true),
			`{case.name} 사용자 줄: {err}`
		)
	end
	same(d, { 10, 25, 30 }, 3, "거절된 호출은 덱을 안 바꿈")
	same(other, { 1, 2 }, 2, "다른 덱도 그대로")

	-- Clear 는 O(1) 로 비우고 자기 자신을 돌려줌. 쥐고 있던 양끝 노드는 더는 이 덱의 것이 아님
	const kept = LinkedDeque.FirstIndex(d) :: NodeRead<number>
	assert(LinkedDeque.Clear(d) == d, "Clear 는 자기 자신")
	same(d, {}, 0, "Clear 뒤")
	assert(not pcall(LinkedDeque.Remove, d, kept), "비운 덱의 옛 머리는 에러")
	LinkedDeque.PushBack(d, 70)
	same(d, { 70 }, 1, "Clear 뒤 다시 쓰기")
end
print("PASS")

print("=== 4. 순회하며 떼어 내기, Clone ===")
do
	-- Iter 는 지금 노드를 Remove 해도 이어서 돎(다음 노드를 미리 읽어 둠)
	const d = LinkedDeque.Of(10, 15, 20, 25, 30, 35)
	local visited = 0
	for node, value in LinkedDeque.Iter(d) do
		visited += 1
		if value % 10 == 5 then
			LinkedDeque.Remove(d, node)
		end
	end
	assert(visited == 6, `전부 방문: {visited}`)
	same(d, { 10, 20, 30 }, 3, "홀수 줄을 떼어 낸 뒤")
	-- 전부 떼어 내기(머리·꼬리가 차례로 바뀜)
	for node in LinkedDeque.Iter(d) do
		LinkedDeque.Remove(d, node)
	end
	same(d, {}, 0, "순회하며 전부 떼어 냄")

	const original = LinkedDeque.Of(10, 20, 30)
	const copy = LinkedDeque.Clone(original)
	assert(
		copy ~= original and LinkedDeque.FirstIndex(copy) ~= LinkedDeque.FirstIndex(original),
		"Clone 은 노드도 새로"
	)
	LinkedDeque.PushBack(copy, 40)
	LinkedDeque.PopFront(original)
	same(copy, { 10, 20, 30, 40 }, 4, "사본")
	same(original, { 20, 30 }, 2, "원본")
	same(LinkedDeque.Clone(LinkedDeque.New<<number>>()), {}, 0, "빈 Clone")
	-- Clone 은 구멍과 false 도 그대로(값이 있을 때만 옮기는 실수를 잡음 — 리뷰)
	same(
		LinkedDeque.Clone(LinkedDeque.Of<<number?>>(10, nil, 30, nil)),
		{ 10, nil, 30, nil } :: { number? },
		4,
		"구멍 든 Clone"
	)
	same(LinkedDeque.Clone(LinkedDeque.Of(false, true, false)), { false, true, false }, 3, "false 든 Clone")
end
print("PASS")

print(
	"=== 4b. false 원소 — nil 과 다르게 다뤄짐(두 구현 모두), 위치가 노드가 아닐 때 (리뷰 1라운드) ==="
)
do
	const flags = LinkedDeque.Of(false, true, false)
	same(flags, { false, true, false }, 3, "false 든 덱")
	assert(LinkedDeque.Front(flags) == false and LinkedDeque.Back(flags) == false, "Front·Back 이 false")
	const mid = LinkedDeque.NextIndex(flags, LinkedDeque.FirstIndex(flags) :: NodeRead<boolean>) :: NodeRead<boolean>
	assert(
		LinkedDeque.Remove(flags, LinkedDeque.LastIndex(flags) :: NodeRead<boolean>) == false,
		"Remove 가 false 를 돌려줌"
	)
	assert(
		LinkedDeque.PopFront(flags) == false and LinkedDeque.Len(flags) == 1 and mid.value == true,
		"PopFront 가 false"
	)
	const ring = CircularDeque.Of(false, true, false)
	assert(CircularDeque.Front(ring) == false and CircularDeque.PopBack(ring) == false, "원형도 false")
	assert(
		CircularDeque.PopFront(ring) == false and CircularDeque.Len(ring) == 1 and CircularDeque.Front(ring) == true,
		"원형에 true 하나 남음"
	)
	local seenFalse = 0
	for _, value in LinkedDeque.Iter(LinkedDeque.Of(false, false)) do
		seenFalse += if value == false then 1 else 0
	end
	assert(seenFalse == 2, "Iter 가 false 를 그대로")

	-- 위치가 노드가 아니면(못 찾은 `IndexOf`, 빈 덱의 `LastIndex` — nil) 사용자 줄 에러
	local where = 0
	const d = LinkedDeque.Of(10, 20)
	const notNodes: { { name: string, call: () -> (), got: string } } = {
		{
			name = "Remove",
			got = "nil",
			call = function()
				where = debug.info(1, "l") + 1
				LinkedDeque.Remove(d, stl.List.IndexOf(d, 99) :: any)
			end,
		},
		{
			name = "InsertAfter",
			got = "nil",
			call = function()
				where = debug.info(1, "l") + 1
				LinkedDeque.InsertAfter(d, LinkedDeque.LastIndex(LinkedDeque.New<<number>>()) :: any, 1)
			end,
		},
		{
			name = "InsertBefore",
			got = "number",
			call = function()
				where = debug.info(1, "l") + 1
				LinkedDeque.InsertBefore(d, 1 :: any, 1)
			end,
		},
	}
	for _, case in notNodes do
		const ok, err = pcall(case.call)
		assert(
			not ok and string.find(tostring(err), `LinkedDeque: {case.name} needs a node, got {case.got}`, 1, true),
			`{case.name}: {err}`
		)
		assert(
			string.find(tostring(err), `spec.linkeddeque.luau:{where}:`, 1, true),
			`{case.name} 사용자 줄: {err}`
		)
	end
	same(d, { 10, 20 }, 2, "거절된 호출은 덱을 안 바꿈")
end
print("PASS")

print("=== 5. Node 조각 ===")
do
	const node = Node.New(10)
	assert(node.value == 10 and node[1] == nil and node[2] == nil and getmetatable(node :: any) == nil, "Node.New")
	const wide = Node.New("root", 4)
	assert(wide.value == "root" and wide[4] == nil, "연결 칸 수를 미리")
	-- 손으로 이은 사슬을 Walk·Count 로
	const a, b, c = Node.New(10), Node.New(20), Node.New(30)
	a[2], b[2] = b, c
	c[1], b[1] = b, a
	const forward: { number } = {}
	for at in Node.Walk(a, 2) do
		table.insert(forward, at.value)
	end
	assert(table.concat(forward, ",") == "10,20,30", "Walk 앞으로")
	const backward: { number } = {}
	for at in Node.Walk(c, 1) do
		table.insert(backward, at.value)
	end
	assert(table.concat(backward, ",") == "30,20,10", "Walk 뒤로")
	assert(Node.Count(a, 2) == 3 and Node.Count(b, 2) == 2 and Node.Count(c, 2) == 1, "Count")
	assert(
		Node.Count(c, 1) == 3 and Node.Count(b, 1) == 2 and Node.Count(a, 1) == 1,
		"Count 는 그 칸을 따라감(뒤로)"
	)
	-- New 의 연결 칸 수: 숫자 인자 정책(소수는 자름, NaN·음수·너무 큼·숫자 아님은 사용자 줄 에러)
	assert(Node.New(1, 2.7).value == 1 and Node.New(1, 0).value == 1, "소수·0")
	local newWhere = 0
	for _, bad in { -1, 0 / 0, 2 ^ 26 + 1, math.huge, "x" :: any } do
		const ok, err = pcall(function()
			newWhere = debug.info(1, "l") + 1
			Node.New(1, bad)
		end)
		assert(
			not ok and string.find(tostring(err), "Node: New links must be a number in", 1, true),
			`links {tostring(bad)}: {err}`
		)
		assert(string.find(tostring(err), `spec.linkeddeque.luau:{newWhere}:`, 1, true), `links 사용자 줄: {err}`)
	end
	assert(Node.Count(nil :: stl.NodeRead<number>?, 2) == 0, "Count(nil)")
	local never = 0
	for _ in Node.Walk(nil :: stl.NodeRead<number>?, 2) do
		never += 1
	end
	assert(never == 0, "Walk(nil) 은 돌지 않음")
	-- Walk 는 도는 동안 지금 노드의 그 칸을 고쳐도 됨(다음을 미리 읽음)
	local cut = 0
	for at in Node.Walk(a, 2) do
		cut += 1
		(at :: any)[2] = nil
	end
	assert(cut == 3 and a[2] == nil and b[2] == nil, "끊으면서 돌기")
	-- LinkedDeque 의 노드가 이 모양(값 필드 + 번호 칸)
	const d = LinkedDeque.Of(10, 20)
	const head = LinkedDeque.FirstIndex(d) :: NodeRead<number>
	assert(head.value == 10 and head[1] == nil and (head[2] :: NodeRead<number>).value == 20, "덱의 노드 모양")
	assert(Node.Count(head, 2) == 2, "덱의 노드를 Node 도구로")
end
print("PASS")

print("=== 6. 트레이트 — Deque·List·Collection, 종류를 몰라도 같은 답 ===")
do
	const T = stl.Trait
	for _, value in { LinkedDeque.Of(1) :: any, CircularDeque.Of(1) } do
		assert(
			T.Implements(Deque, value) and T.Implements(stl.List, value) and T.Implements(stl.Collection, value),
			"셋 다 구현"
		)
	end
	assert(T.ImplOf(Deque, LinkedDeque.Of(1)) == LinkedDeque :: any, "Deque 구현은 모듈 그대로")
	assert(T.ImplOf(Deque, CircularDeque.Of(1)) == CircularDeque :: any, "원형도")
	assert(not T.Implements(Deque, stl.Arr.Of(1)), "Arr 은 Deque 가 아님")

	-- 리스트 알고리즘(기본 구현)이 노드 위치로 돎
	const d = LinkedDeque.Of(10, 20, 30, 20)
	const found = stl.List.IndexOf(d, 20)
	assert(
		found ~= nil and found == LinkedDeque.NextIndex(d, LinkedDeque.FirstIndex(d) :: NodeRead<number>),
		"IndexOf 는 처음 맞는 노드"
	)
	assert(stl.List.IndexOf(d, 99) == nil and stl.List.Contains(d, 30) and not stl.List.Contains(d, 99), "Contains")
	assert(stl.List.Count(d) == 4, "Count")
	assert(stl.List.Fold(d, 0, function(acc: number, v: number): number
		return acc + v
	end) == 80, "Fold")
	const item, at = stl.List.Find(d, function(v: number): boolean
		return v > 15
	end)
	assert(item == 20 and at == found, "Find 는 원소와 노드")
	assert(stl.Collection.Len(d) == 4 and stl.Collection.Clear(d) == d and LinkedDeque.Len(d) == 0, "Collection")

	-- ⭐ 종류를 모르는 코드: 같은 함수가 두 구현에서 같은 답
	const function drain<C>(deque: C & stl.DequeMarkerMut<number>): string
		Deque.PushBack(deque, 30)
		Deque.PushFront(Deque.PushFront(deque, 20), 10)
		const parts = { tostring(Deque.Front(deque)), tostring(Deque.Back(deque)) }
		table.insert(parts, tostring(Deque.PopBack(deque)))
		table.insert(parts, tostring(Deque.PopFront(deque)))
		table.insert(parts, tostring(Deque.PopFront(deque)))
		table.insert(parts, tostring(Deque.PopFront(deque)))
		table.insert(parts, tostring(Deque.Back(deque)))
		return table.concat(parts, ",")
	end
	const want = "10,30,30,10,20,nil,nil"
	assert(drain(LinkedDeque.New<<number>>()) == want, `연결: {drain(LinkedDeque.New<<number>>())}`)
	assert(drain(CircularDeque.New<<number>>()) == want, `원형: {drain(CircularDeque.New<<number>>())}`)
	const kept = LinkedDeque.New<<number>>()
	assert(
		Deque.PushBack(kept, 1) == kept and Deque.PushFront(kept, 0) == kept,
		"진입점의 넣기는 넣은 덱을 돌려줌"
	)
	-- 진입점이 **그 끝**에 넣는지: 비어 있지 않은 덱에(빈 덱에 한 번만 넣으면 앞·뒤가 구별되지 않음 — 리뷰)
	const makers: { (...number) -> any } = { LinkedDeque.Of :: any, CircularDeque.Of :: any }
	for _, make in makers do
		const dq = make(10, 20)
		Deque.PushBack(dq, 30)
		Deque.PushFront(dq, 5)
		assert(Deque.Front(dq) == 5 and Deque.Back(dq) == 30, "PushFront 는 앞에, PushBack 은 뒤에")
		assert(Deque.PopBack(dq) == 30 and Deque.PopFront(dq) == 5 and Deque.PopFront(dq) == 10, "꺼내는 끝")
	end

	-- 덱이 아닌 것: 트레이트 이름을 머리로 한 사용자 줄 에러(여섯 진입점 전부)
	local where = 0
	-- (줄은 진입점을 부른 그 줄 — 래퍼 안에서 부르므로 `where` 도 래퍼 안에서 잽니다)
	const entries: { { name: string, call: (any) -> any } } = {
		{
			name = "PushFront",
			call = function(v: any): any
				where = debug.info(1, "l") + 1
				return Deque.PushFront(v, 1)
			end,
		},
		{
			name = "PushBack",
			call = function(v: any): any
				where = debug.info(1, "l") + 1
				return Deque.PushBack(v, 1)
			end,
		},
		{
			name = "PopFront",
			call = function(v: any): any
				where = debug.info(1, "l") + 1
				return Deque.PopFront(v)
			end,
		},
		{
			name = "PopBack",
			call = function(v: any): any
				where = debug.info(1, "l") + 1
				return Deque.PopBack(v)
			end,
		},
		{
			name = "Front",
			call = function(v: any): any
				where = debug.info(1, "l") + 1
				return Deque.Front(v)
			end,
		},
		{
			name = "Back",
			call = function(v: any): any
				where = debug.info(1, "l") + 1
				return Deque.Back(v)
			end,
		},
	}
	for _, entry in entries do
		const ok, err = pcall(entry.call, stl.Arr.Of(1))
		assert(
			not ok
				and string.find(
					tostring(err),
					`Deque: {entry.name} needs a Deque — Arr does not implement Deque`,
					1,
					true
				),
			`{entry.name}: {err}`
		)
		assert(
			string.find(tostring(err), `spec.linkeddeque.luau:{where}:`, 1, true),
			`{entry.name} 사용자 줄: {err}`
		)
	end
end
print("PASS")

print("=== 7. 무작위 대조 — 배열 모델·CircularDeque 와 (양끝 + 노드 연산) ===")
do
	math.randomseed(20261013)
	for _round = 1, 60 do
		const linked = LinkedDeque.New<<number>>()
		const ring = CircularDeque.New<<number>>()
		const model: { number } = {}
		-- 모델의 위치마다 그 노드(노드 연산을 무작위 위치에 하려고)
		const nodes: { NodeRead<number> } = {}
		for step = 1, 120 do
			const op = math.random(1, 9)
			const value = step * 10
			if op <= 2 then
				LinkedDeque.PushBack(linked, value)
				CircularDeque.PushBack(ring, value)
				table.insert(model, value)
				table.insert(nodes, LinkedDeque.LastIndex(linked) :: NodeRead<number>)
			elseif op == 3 then
				LinkedDeque.PushFront(linked, value)
				CircularDeque.PushFront(ring, value)
				table.insert(model, 1, value)
				table.insert(nodes, 1, LinkedDeque.FirstIndex(linked) :: NodeRead<number>)
			elseif op == 4 then
				const want = table.remove(model, 1)
				table.remove(nodes, 1)
				assert(LinkedDeque.PopFront(linked) == want and CircularDeque.PopFront(ring) == want, "PopFront 대조")
			elseif op == 5 then
				const want = table.remove(model)
				table.remove(nodes)
				assert(LinkedDeque.PopBack(linked) == want and CircularDeque.PopBack(ring) == want, "PopBack 대조")
			elseif #model > 0 then
				-- 노드 연산(원형 덱에는 없음 — 모델에 맞춰 원형을 다시 만듦)
				const pos = math.random(1, #model)
				if op == 6 then
					const fresh = LinkedDeque.InsertAfter(linked, nodes[pos], value)
					table.insert(model, pos + 1, value)
					table.insert(nodes, pos + 1, fresh)
				elseif op == 7 then
					const fresh = LinkedDeque.InsertBefore(linked, nodes[pos], value)
					table.insert(model, pos, value)
					table.insert(nodes, pos, fresh)
				else
					assert(LinkedDeque.Remove(linked, nodes[pos]) == model[pos], "Remove 대조")
					table.remove(model, pos)
					table.remove(nodes, pos)
				end
				CircularDeque.Clear(ring)
				for _, v in model do
					CircularDeque.PushBack(ring, v)
				end
			end
			assert(LinkedDeque.Len(linked) == #model and CircularDeque.Len(ring) == #model, "크기 대조")
			assert(LinkedDeque.Front(linked) == model[1] and LinkedDeque.Back(linked) == model[#model], "양끝 대조")
			assert(
				CircularDeque.Front(ring) == model[1] and CircularDeque.Back(ring) == model[#model],
				"원형 양끝 대조"
			)
		end
		same(linked, model, #model, "무작위 뒤 전체 불변식")
		for pos, node in nodes do
			assert(node.value == model[pos], "쥐고 있던 노드가 제자리")
		end
	end
end
print("PASS")

print()
print("=== ALL PASS (LinkedDeque) ===")

return true
