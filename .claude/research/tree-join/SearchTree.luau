--[[
	시제품 — `Join` 하나 위에 세운 균형 이진 탐색 트리 (2026-10-13, `papers/07` 9-3).

	질문: (1) 어떤 키보다 작거나 큰 영역을 **떼어 트리로** 둘 수 있는가, (2) 균형 방식(AVL·레드블랙 …)을
	여럿 두면서 나머지 연산을 **한 번만** 쓸 수 있는가.
	답의 후보: 균형 방식은 `Join(left, mid, right)` 하나만 구현하고, `Split`·넣기·지우기·합집합은 그 위에
	한 번 씁니다(Blelloch·Ferizovic·Sun, "Just Join for Parallel Ordered Sets").

	노드는 `src/Node.luau` 의 모양(값 필드 + 번호 칸): `{ [1] = 왼쪽, [2] = 오른쪽, key, value, rank }`.
	`rank` 는 균형 방식이 쓰는 칸 하나(AVL 은 높이).
	이 파일은 **재 보려는 시제품**입니다 — 에러 규약·타입·구멍 처리가 없습니다.
]]
local LEFT, RIGHT = 1, 2

--#region ---------- 균형 방식 하나: AVL 의 Join ----------
local function height(t)
	return if t then t.rank else 0
end
local function fix(t)
	local a, b = height(t[LEFT]), height(t[RIGHT])
	t.rank = (if a > b then a else b) + 1
	return t
end
local function rotateLeft(t)
	local r = t[RIGHT]
	t[RIGHT] = r[LEFT]
	r[LEFT] = fix(t)
	return fix(r)
end
local function rotateRight(t)
	local l = t[LEFT]
	t[LEFT] = l[RIGHT]
	l[RIGHT] = fix(t)
	return fix(l)
end
-- 왼쪽이 더 높을 때: 왼쪽의 오른쪽 등뼈를 내려가 높이가 맞는 자리에 (mid, right) 를 붙임
local function joinRight(l, mid, r)
	local c = l[RIGHT]
	if height(c) <= height(r) + 1 then
		mid[LEFT], mid[RIGHT] = c, r
		fix(mid)
		if mid.rank <= height(l[LEFT]) + 1 then
			l[RIGHT] = mid
			return fix(l)
		end
		l[RIGHT] = rotateRight(mid)
		return rotateLeft(l)
	end
	local t = joinRight(c, mid, r)
	l[RIGHT] = t
	if t.rank <= height(l[LEFT]) + 1 then
		return fix(l)
	end
	return rotateLeft(l)
end
local function joinLeft(l, mid, r)
	local c = r[LEFT]
	if height(c) <= height(l) + 1 then
		mid[LEFT], mid[RIGHT] = l, c
		fix(mid)
		if mid.rank <= height(r[RIGHT]) + 1 then
			r[LEFT] = mid
			return fix(r)
		end
		r[LEFT] = rotateLeft(mid)
		return rotateRight(r)
	end
	local t = joinLeft(l, mid, c)
	r[LEFT] = t
	if t.rank <= height(r[RIGHT]) + 1 then
		return fix(r)
	end
	return rotateRight(r)
end
-- ⭐ 균형 방식이 구현하는 것은 이것 하나: 왼쪽 트리 < mid 노드 < 오른쪽 트리를 균형 맞춰 하나로
local function avlJoin(l, mid, r)
	local hl, hr = height(l), height(r)
	if hl > hr + 1 then
		return joinRight(l, mid, r)
	elseif hr > hl + 1 then
		return joinLeft(l, mid, r)
	end
	mid[LEFT], mid[RIGHT] = l, r
	return fix(mid)
end
--#endregion

--#region ---------- 공유 구현: Join 만 받아 나머지를 만듦 ----------
local function make(join, newNode)
	local ops = {}
	-- 키를 기준으로 셋으로: 작은 쪽 트리, 그 키의 노드(없으면 nil), 큰 쪽 트리. O(log n)
	local function split(t, key, compare)
		if t == nil then
			return nil, nil, nil
		end
		local c = compare(key, t.key)
		if c == 0 then
			local l, r = t[LEFT], t[RIGHT]
			t[LEFT], t[RIGHT] = nil, nil
			return l, t, r
		elseif c < 0 then
			local ll, mid, lr = split(t[LEFT], key, compare)
			return ll, mid, join(lr, t, t[RIGHT])
		end
		local rl, mid, rr = split(t[RIGHT], key, compare)
		return join(t[LEFT], t, rl), mid, rr
	end
	ops.Split = split
	-- 가장 큰 노드를 떼어 냄 → (나머지, 그 노드)
	local function splitLast(t)
		local r = t[RIGHT]
		if r == nil then
			local l = t[LEFT]
			t[LEFT] = nil
			return l, t
		end
		local rest, last = splitLast(r)
		return join(t[LEFT], t, rest), last
	end
	-- 가운데 노드 없이 둘을 잇기(왼쪽 전부 < 오른쪽 전부)
	local function join2(l, r)
		if l == nil then
			return r
		end
		local rest, last = splitLast(l)
		return join(rest, last, r)
	end
	ops.Join2 = join2
	function ops.Insert(root, key, value, compare)
		local l, mid, r = split(root, key, compare)
		if mid then
			mid.value = value
		else
			mid = newNode(key, value)
		end
		return join(l, mid, r)
	end
	function ops.Remove(root, key, compare)
		local l, mid, r = split(root, key, compare)
		return join2(l, r), mid
	end
	-- 합집합(같은 키는 b 의 값) — 둘 다 소비
	local function union(a, b, compare)
		if a == nil then
			return b
		elseif b == nil then
			return a
		end
		local bl, br = b[LEFT], b[RIGHT]
		local l, _, r = split(a, b.key, compare)
		return join(union(l, bl, compare), b, union(r, br, compare))
	end
	ops.Union = union
	return ops
end
--#endregion

local function avlNode(key, value)
	return { nil, nil, key = key, value = value, rank = 1 }
end

--#region ---------- 대조용: 손으로 짠 AVL 넣기(직접 회전) ----------
local function directInsert(t, key, value, compare)
	if t == nil then
		return avlNode(key, value)
	end
	local c = compare(key, t.key)
	if c == 0 then
		t.value = value
		return t
	elseif c < 0 then
		t[LEFT] = directInsert(t[LEFT], key, value, compare)
	else
		t[RIGHT] = directInsert(t[RIGHT], key, value, compare)
	end
	local hl, hr = height(t[LEFT]), height(t[RIGHT])
	if hl > hr + 1 then
		local l = t[LEFT]
		if height(l[RIGHT]) > height(l[LEFT]) then
			t[LEFT] = rotateLeft(l)
		end
		return rotateRight(t)
	elseif hr > hl + 1 then
		local r = t[RIGHT]
		if height(r[LEFT]) > height(r[RIGHT]) then
			t[RIGHT] = rotateRight(r)
		end
		return rotateLeft(t)
	end
	t.rank = (if hl > hr then hl else hr) + 1
	return t
end
--#endregion

local function get(t, key, compare)
	while t do
		local c = compare(key, t.key)
		if c == 0 then
			return t.value
		end
		t = if c < 0 then t[LEFT] else t[RIGHT]
	end
	return nil
end

-- 중위 순회로 키 목록, 그리고 AVL 불변식(높이 차 ≤ 1, rank 가 맞음) 검사
local function check(t, out)
	if t == nil then
		return 0
	end
	local hl = check(t[LEFT], out)
	table.insert(out, t.key)
	local hr = check(t[RIGHT], out)
	assert(math.abs(hl - hr) <= 1, "균형이 깨짐")
	assert(t.rank == math.max(hl, hr) + 1, "rank 가 틀림")
	return t.rank
end

return {
	Avl = make(avlJoin, avlNode),
	avlJoin = avlJoin,
	avlNode = avlNode,
	directInsert = directInsert,
	get = get,
	check = check,
	make = make,
}
