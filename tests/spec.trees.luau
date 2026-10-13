--!strict
--[[
	트리부(RedBlack·Avl — 같은 표면)와 Node 의 연결 방식별 도구(Single·Double·Binary) 테스트. 프레임워크 없음.

	⭐ 균형 트리의 결함은 눈에 안 보입니다(조회는 맞는데 균형이 깨져 있거나, 부모 칸 하나가 틀려 순회만
	틀림). 그래서 **연산마다 불변식을 전부** 검사하고 정렬된 모델과 대조합니다. 넣기·지우기·짓기의
	시나리오는 **두 균형 방식에 똑같이** 돌립니다(1~4절) — 균형 검사만 방식마다 다릅니다.
	키·값·위치가 서로 다르게: 키는 10 단위, 값은 키 + 1.

	노드는 전부 번호 칸입니다(계약 — `src/Node/`·`Trees/Search` 머리): `1` = 값, `2` = 왼쪽, `3` = 오른쪽, `4` = 부모,
	`5` = 키, `6` = 균형 정보(레드블랙은 빨강 여부, AVL 은 높이). 검사는 그 칸을 직접 읽습니다.
]]
local stl = require("../src")
local Node = stl.Node
local Binary = Node.Binary
local Traverse = stl.Traverse

-- 두 방식의 노드를 같은 시나리오로 다루려고 느슨하게(타입은 `spikes/66` 이 지킴)
type RbNode = any
type RbRead = any

-- 균형 검사(방식마다 다름): 레드블랙 — 뿌리 검정, 빨강-빨강 없음, 검정 수 같음, 높이 ≤ 2·log2(n+1)
local function redBlackBalance(root: any, count: number, label: string)
	assert(not root[6], `{label}: 뿌리가 빨강`)
	local function walk(node: any, parent: any): number
		if node == nil then
			return 1
		end
		if node[6] then
			assert(parent ~= nil and not parent[6], `{label}: 빨강-빨강 at {node[5]}`)
		end
		const leftBlack, rightBlack = walk(node[2], node), walk(node[3], node)
		assert(leftBlack == rightBlack, `{label}: {node[5]} 에서 검정 수 {leftBlack} ~= {rightBlack}`)
		return leftBlack + (if node[6] then 0 else 1)
	end
	walk(root, nil)
	assert(Binary.Height(root) <= 2 * math.log(count + 1, 2) + 1e-9, `{label}: 높이 {Binary.Height(root)}`)
end
-- AVL — 높이 차 ≤ 1, `height` 필드가 실제 높이, 높이 ≤ 1.4405·log2(n+2)
local function avlBalance(root: any, count: number, label: string)
	local function walk(node: any): number
		if node == nil then
			return 0
		end
		const left, right = walk(node[2]), walk(node[3])
		assert(math.abs(left - right) <= 1, `{label}: {node[5]} 에서 높이 차 {left - right}`)
		assert(node[6] == math.max(left, right) + 1, `{label}: {node[5]} 의 높이 칸 {node[6]}`)
		return node[6]
	end
	assert(walk(root) <= 1.4405 * math.log(count + 2, 2) + 1e-9, `{label}: 높이 {Binary.Height(root)}`)
end
local balanceOf: (root: any, count: number, label: string) -> () = redBlackBalance

local compare = stl.Common.compareNumber

-- 불변식(부모 칸, 순서, 방식별 균형)을 검사하고 중위 순서의 키 목록을 돌려줍니다.
local function check(root: RbRead?, label: string): { number }
	const keys: { number } = {}
	if root == nil then
		return keys
	end
	assert(root[4] == nil, `{label}: 뿌리의 부모가 nil 이 아님`)
	local function walk(node: RbRead?, parent: RbRead?)
		if node == nil then
			return
		end
		assert(node[4] == parent, `{label}: {node[5]} 의 부모 칸`)
		walk(node[2], node)
		table.insert(keys, node[5])
		walk(node[3], node)
	end
	walk(root, nil)
	balanceOf(root, #keys, label)
	for at = 2, #keys do
		assert(keys[at - 1] < keys[at], `{label}: 순서 {keys[at - 1]} >= {keys[at]}`)
	end
	-- 노드 도구의 순회도 같은 순서(앞으로·뒤로)
	local at = 0
	for node in Traverse.InOrder(root) do
		at += 1
		assert((node :: any)[5] == keys[at], `{label}: InOrder {at}`)
	end
	assert(at == #keys, `{label}: InOrder 수`)
	local back, cursor = #keys, Binary.Last(root) :: any
	while cursor ~= nil do
		assert(cursor[5] == keys[back], `{label}: Prev {back}`)
		back -= 1
		cursor = Binary.Prev(cursor)
	end
	assert(back == 0, `{label}: Prev 수`)
	return keys
end

for _, scheme in
	{
		{ name = "RedBlack", module = stl.RedBlack :: any, balance = redBlackBalance },
		{ name = "Avl", module = stl.Avl :: any, balance = avlBalance },
	}
do
	const schemeName = scheme.name
	const RedBlack = scheme.module -- 아래 시나리오는 두 방식에 똑같이(이름은 처음 쓴 그대로 둠)
	balanceOf = scheme.balance
	print(`=== 1. {schemeName} — 넣기·찾기 — 순서대로·거꾸로·무작위 ===`)
	do
		assert(RedBlack.Find(nil :: RbRead?, 10, compare) == nil, "빈 트리에서 찾기")
		assert(#check(nil, "빈 트리") == 0, "빈 트리")
		local root: RbNode?, first: RbNode, isNew: boolean = nil, nil :: any, false
		root, first, isNew = RedBlack.Insert(root, 50, 51, compare)
		assert(isNew and root == first and first[5] == 50 and first[1] == 51, "첫 노드는 검정 뿌리")
		check(root, "하나")
		-- 같은 키: 값만 바뀌고 같은 노드
		local again: RbNode
		root, again, isNew = RedBlack.Insert(root, 50, 99, compare)
		assert(not isNew and again == first and first[1] == 99, "같은 키는 값만 바꿈")
		for _, order in { "오름", "내림" } do
			local tree: RbNode? = nil
			for step = 1, 200 do
				const key = if order == "오름" then step * 10 else (201 - step) * 10
				tree = (RedBlack.Insert(tree, key, key + 1, compare))
				check(tree, `{order} {step}`)
			end
			const keys = check(tree, order)
			assert(#keys == 200 and keys[1] == 10 and keys[200] == 2000, `{order}: 키들`)
			for key = 10, 2000, 10 do
				const found = RedBlack.Find(tree, key, compare)
				assert(found ~= nil and found[1] == key + 1, `{order}: Find {key}`)
			end
			assert(RedBlack.Find(tree, 15, compare) == nil and RedBlack.Find(tree, 0, compare) == nil, "없는 키")
		end
	end
	print("PASS")

	print(`=== 2. {schemeName} — 경계 찾기 — LowerBound·UpperBound 를 선형 탐색과 ===`)
	do
		local root: RbNode? = nil
		const keys = { 10, 20, 30, 40, 50, 60, 70 }
		for _, key in keys do
			root = (RedBlack.Insert(root, key, key + 1, compare))
		end
		for probe = 0, 80, 5 do
			local wantLower: number?, wantUpper: number? = nil, nil
			for _, key in keys do
				if wantLower == nil and key >= probe then
					wantLower = key
				end
				if wantUpper == nil and key > probe then
					wantUpper = key
				end
			end
			const lower, upper = RedBlack.LowerBound(root, probe, compare), RedBlack.UpperBound(root, probe, compare)
			assert((if lower then lower[5] else nil) == wantLower, `LowerBound({probe})`)
			assert((if upper then upper[5] else nil) == wantUpper, `UpperBound({probe})`)
		end
		assert(
			RedBlack.LowerBound(nil :: RbRead?, 10, compare) == nil
				and RedBlack.UpperBound(nil :: RbRead?, 10, compare) == nil,
			"빈 트리"
		)
	end
	print("PASS")

	print(
		`=== 3. {schemeName} — 지우기 — 잎·자식 하나·자식 둘·뿌리, 그리고 무작위 대조 ===`
	)
	do
		-- 손으로: 하나 남은 것, 뿌리, 전부
		local root: RbNode? = nil
		root = (RedBlack.Insert(root, 10, 11, compare))
		root = RedBlack.Remove(root :: RbNode, RedBlack.Find(root, 10, compare) :: RbRead)
		assert(root == nil, "하나 남은 것을 지우면 빈 트리")
		for key = 10, 150, 10 do
			root = (RedBlack.Insert(root, key, key + 1, compare))
		end
		-- 쥐고 있던 다른 노드는 지운 뒤에도 유효(노드를 옮기지 값만 베끼지 않음)
		const held = RedBlack.Find(root, 90, compare) :: RbRead
		const heldNext = Binary.Next(held) :: any
		const gone = RedBlack.Find(root, 80, compare) :: RbRead
		root = RedBlack.Remove(root :: RbNode, gone)
		assert(gone[2] == nil and gone[3] == nil and gone[4] == nil, "뗀 노드는 연결이 끊김")
		assert(
			held[5] == 90 and held[1] == 91 and RedBlack.Find(root, 90, compare) == held,
			"다른 위치는 그대로"
		)
		assert(Binary.Next(held) == heldNext and heldNext[5] == 100, "다음 노드도 그대로")
		assert(RedBlack.Find(root, 80, compare) == nil, "지운 키는 없음")
		check(root, "하나 지운 뒤")
		-- 뿌리가 아닌, 자식이 둘인 노드도(두 방식의 모양이 달라 한 키로는 한쪽이 뿌리였음 — 리뷰): 뗀 뒤 세 칸이 nil
		for _, key in { 20, 120, 60 } do
			const target = RedBlack.Find(root, key, compare)
			if target ~= nil then
				root = RedBlack.Remove(root :: RbNode, target)
				assert(
					target[2] == nil and target[3] == nil and target[4] == nil,
					`{key}: 뗀 노드의 왼쪽·오른쪽·부모 칸`
				)
				check(root, `{key} 지운 뒤`)
			end
		end
		-- 뿌리를 되풀이해 지움
		local removed = 0
		while root ~= nil do
			root = RedBlack.Remove(root, root)
			removed += 1
			check(root, `뿌리 지우기 {removed}`)
		end
		assert(removed == 11, `뿌리만 지워 다 비움: {removed}`)

		-- 무작위: 넣기·지우기 섞어 모델과, 연산마다 불변식
		math.randomseed(20261013)
		for round = 1, 40 do
			local tree: RbNode? = nil
			const model: { [number]: number } = {}
			local size = 0
			for step = 1, 300 do
				const key = math.random(1, 120) * 10
				if math.random() < 0.6 then
					local isNew: boolean
					tree, _, isNew = RedBlack.Insert(tree, key, key + step, compare)
					assert(isNew == (model[key] == nil), "새로 만들었나")
					size += if isNew then 1 else 0
					model[key] = key + step
				else
					const found = RedBlack.Find(tree, key, compare)
					assert((found ~= nil) == (model[key] ~= nil), "Find 와 모델")
					if found ~= nil then
						tree = RedBlack.Remove(tree :: RbNode, found)
						model[key] = nil
						size -= 1
					end
				end
				if step % 7 == 0 or size < 6 then
					const keys = check(tree, `무작위 {round}/{step}`)
					assert(#keys == size, `크기 {#keys} ~= {size}`)
					for _, k in keys do
						assert(model[k] == (RedBlack.Find(tree, k, compare) :: RbRead)[1], "값 대조")
					end
				end
			end
			-- 순회하며 전부 지움(다음을 먼저 읽음)
			local cursor = if tree then Binary.First(tree) :: any else nil
			while cursor ~= nil do
				const after = Binary.Next(cursor)
				tree = RedBlack.Remove(tree :: RbNode, cursor)
				size -= 1
				cursor = after
			end
			assert(tree == nil and size == 0, "순회하며 전부 지움")
		end
	end
	print("PASS")

	print(`=== 4. {schemeName} — 한 번에 짓기(FromSorted)와 베끼기(Clone) ===`)
	do
		for count = 0, 130 do
			const keys, values = table.create(count), table.create(count)
			for at = 1, count do
				keys[at] = at * 10
				values[at] = at * 10 + 1
			end
			const root = RedBlack.FromSorted(keys, values, count)
			const got = check(root, `FromSorted {count}`)
			assert(#got == count, `FromSorted {count}: 수 {#got}`)
			for at = 1, count do
				assert(
					got[at] == at * 10 and (RedBlack.Find(root, at * 10, compare) :: RbRead)[1] == at * 10 + 1,
					"키·값"
				)
			end
			const copy = RedBlack.Clone(root)
			const copied = check(copy, `Clone {count}`)
			assert(#copied == count and (count == 0 or copy ~= root), "Clone 은 새 노드")
			if copy ~= nil and root ~= nil then
				copy[1] = -1
				assert(root[1] ~= -1, "사본을 고쳐도 원본은 그대로")
			end
			-- 지은 뒤에도 평범한 트리: 넣고 지우기가 불변식을 지킴(뿌리가 바뀔 수 있어 맨 뒤에)
			if count % 13 == 0 then
				local tree = root
				tree = (RedBlack.Insert(tree, 5, 6, compare))
				tree = (RedBlack.Insert(tree, count * 10 + 5, 0, compare))
				check(tree, `FromSorted {count} 뒤 넣기`)
				tree = RedBlack.Remove(tree :: RbNode, RedBlack.Find(tree, 5, compare) :: RbRead)
				check(tree, `FromSorted {count} 뒤 지우기`)
			end
		end
		assert(RedBlack.FromSorted({}, {}, 0) == nil and RedBlack.Clone(nil :: RbRead?) == nil, "빈 것")
	end
	print("PASS")
end

print("=== 5. Node 의 연결 방식별 도구 — 칸 배치(계약)와 불투명 핸들 ===")
do
	const Single, Double = Node.Single, Node.Double
	-- 칸 배치는 계약: 값은 모든 종류에서 1번 칸
	assert(Single.VALUE == 1 and Single.NEXT == 2, "단방향의 칸")
	assert(Double.VALUE == 1 and Double.PREV == 2 and Double.NEXT == 3, "양방향의 칸")
	assert(Binary.VALUE == 1 and Binary.LEFT == 2 and Binary.RIGHT == 3 and Binary.PARENT == 4, "이진의 칸")
	assert(stl.Search.KEY == 5 and stl.Search.BALANCE == 6 and stl.Search.VALUE == 1, "탐색 트리 노드의 칸")
	-- 노드는 메타테이블 없는, 전부 번호 칸인 테이블(이름 필드가 하나도 없음)
	for _, node in { Single.New("x") :: any, Double.New("x"), Binary.New("x") } do
		assert(getmetatable(node) == nil and node[1] == "x", "값은 1번 칸")
		for key in node do
			assert(type(key) == "number", `이름 필드가 있음: {tostring(key)}`)
		end
	end

	-- 단방향: 내 뒤에 넣기·내 뒤를 떼기
	const a, b, c = Single.New("a"), Single.New("b"), Single.New("c")
	assert(Single.InsertNext(a, c) == c and Single.Next(a) == c and Single.Next(c) == nil, "Single.InsertNext")
	Single.InsertNext(a, b)
	assert(Single.Next(a) == b and Single.Next(b) == c and Single.Count(a) == 3, "가운데에 InsertNext")
	const walked: { string } = {}
	for node in Single.Walk(a) do
		table.insert(walked, Single.Value(node))
	end
	assert(table.concat(walked, ",") == "a,b,c", "Single.Walk")
	assert(Single.RemoveNext(a) == b and Single.Next(a) == c and Single.Next(b) == nil, "RemoveNext")
	assert(
		Single.RemoveNext(c) == nil and Single.Count(nil :: stl.SingleNodeRead<string>?) == 0,
		"뒤가 없으면 nil"
	)
	Single.SetValue(a, "z")
	assert(Single.Value(a) == "z", "SetValue")

	-- 양방향: 넣기는 양쪽 연결을 다 고치고, 떼기는 이웃을 돌려줌
	const x, y, z = Double.New(10), Double.New(20), Double.New(30)
	assert(
		Double.InsertNext(x, z) == z and Double.Next(x) == z and Double.Prev(z) == x and Double.Next(z) == nil,
		"Double.InsertNext(꼬리)"
	)
	assert(Double.InsertNext(x, y) == y and Double.Next(x) == y and Double.Prev(y) == x, "가운데(앞쪽 연결)")
	assert(Double.Next(y) == z and Double.Prev(z) == y, "가운데(뒤쪽 연결)")
	const w = Double.New(5)
	assert(
		Double.InsertPrev(x, w) == w and Double.Prev(w) == nil and Double.Next(w) == x and Double.Prev(x) == w,
		"Double.InsertPrev(머리)"
	)
	const v = Double.New(25)
	Double.InsertPrev(z, v)
	assert(
		Double.Next(y) == v and Double.Prev(v) == y and Double.Next(v) == z and Double.Prev(z) == v,
		"InsertPrev 가운데"
	)
	assert(
		Double.Count(w) == 5 and Double.Count(v) == 2 and Double.Count(nil :: stl.DoubleNodeRead<number>?) == 0,
		"Count 는 뒤쪽으로"
	)
	const forward: { number }, backward: { number } = {}, {}
	for node in Double.Walk(w) do
		table.insert(forward, Double.Value(node))
	end
	for node in Double.WalkBack(z) do
		table.insert(backward, Double.Value(node))
	end
	assert(
		table.concat(forward, ",") == "5,10,20,25,30" and table.concat(backward, ",") == "30,25,20,10,5",
		"Walk·WalkBack"
	)
	local before, after = Double.Unlink(v)
	assert(
		before == y and after == z and Double.Next(y) == z and Double.Prev(z) == y,
		"Unlink 가운데 — 이웃끼리 이음"
	)
	assert(
		Double.Prev(v) == nil and Double.Next(v) == nil and Double.Value(v) == 25,
		"뗀 노드는 연결이 끊기고 값은 남음"
	)
	before, after = Double.Unlink(w)
	assert(before == nil and after == x and Double.Prev(x) == nil, "Unlink 머리 — 앞 이웃이 nil")
	before, after = Double.Unlink(z)
	assert(before == y and after == nil and Double.Next(y) == nil, "Unlink 꼬리 — 뒤 이웃이 nil")
	before, after = Double.Unlink(Double.New(1))
	assert(before == nil and after == nil, "외톨이 Unlink")
	-- Walk 는 도는 동안 지금 노드를 떼어도 이어 돎(다음을 미리 읽음)
	local cut = 0
	for node in Double.Walk(x) do
		cut += 1
		Double.Unlink(node :: any)
	end
	assert(cut == 2 and Double.Next(x) == nil, "떼면서 돌기")

	-- 이진: 회전은 부모의 자식 칸과 부모 칸 셋을 다 고치고, 중위 순서를 바꾸지 않음
	local function inorder(root: stl.BinaryNodeRead<number>): string
		const out: { string } = {}
		for node in Traverse.InOrder(root) do
			table.insert(out, tostring(Binary.Value(node)))
		end
		return table.concat(out, ",")
	end
	--        40
	--      20    60
	--    10 30  50 70
	const n10, n20, n30, n40 = Binary.New(10), Binary.New(20), Binary.New(30), Binary.New(40)
	const n50, n60, n70 = Binary.New(50), Binary.New(60), Binary.New(70)
	Binary.SetLeft(n40, n20)
	Binary.SetRight(n40, n60)
	Binary.SetLeft(n20, n10)
	Binary.SetRight(n20, n30)
	Binary.SetLeft(n60, n50)
	Binary.SetRight(n60, n70)
	assert(
		Binary.Left(n40) == n20 and Binary.Right(n40) == n60 and Binary.Parent(n20) == n40 and Binary.Parent(n40) == nil,
		"SetLeft·SetRight"
	)
	assert(inorder(n40) == "10,20,30,40,50,60,70", "InOrder")
	assert(Binary.First(n40) == n10 and Binary.Last(n40) == n70 and Binary.First(n60) == n50, "First·Last")
	assert(Binary.Next(n30) == n40 and Binary.Next(n40) == n50 and Binary.Next(n70) == nil, "Next")
	assert(Binary.Prev(n50) == n40 and Binary.Prev(n40) == n30 and Binary.Prev(n10) == nil, "Prev")
	assert(Binary.Height(n40) == 3 and Binary.Height(nil :: stl.BinaryNodeRead<number>?) == 0, "Height")
	-- 한쪽으로 기운 트리의 높이(왼쪽만 세는 실수를 잡음)
	const lean1, lean2, lean3 = Binary.New(1), Binary.New(2), Binary.New(3)
	Binary.SetRight(lean1, lean2)
	Binary.SetRight(lean2, lean3)
	assert(Binary.Height(lean1) == 3 and Binary.Height(lean2) == 2, "오른쪽으로 기운 트리의 Height")
	-- 가운데 노드를 회전(부모가 있음)
	assert(Binary.RotateLeft(n20) == n30, "RotateLeft 가 올라온 노드를 돌려줌")
	assert(Binary.Left(n40) == n30 and Binary.Parent(n30) == n40 and Binary.Left(n30) == n20, "RotateLeft 연결(위)")
	assert(Binary.Parent(n20) == n30 and Binary.Right(n20) == nil, "RotateLeft 연결(아래)")
	assert(inorder(n40) == "10,20,30,40,50,60,70", "회전은 순서를 안 바꿈")
	assert(
		Binary.RotateRight(n30) == n20 and Binary.Left(n40) == n20 and Binary.Right(n20) == n30,
		"RotateRight 로 되돌림"
	)
	assert(Binary.Parent(n30) == n20, "되돌린 뒤 부모 칸")
	-- 뿌리를 회전: 올라온 노드의 부모가 nil(새 뿌리), 안쪽 자식이 건너감
	const top = Binary.RotateLeft(n40)
	assert(
		top == n60 and Binary.Parent(n60) == nil and Binary.Left(n60) == n40 and Binary.Parent(n40) == n60,
		"뿌리 RotateLeft"
	)
	assert(Binary.Right(n40) == n50 and Binary.Parent(n50) == n40, "안쪽 자식이 건너감")
	assert(inorder(n60) == "10,20,30,40,50,60,70", "뿌리 회전 뒤 순서")
	assert(
		Binary.RotateRight(n60) == n40 and Binary.Parent(n40) == nil and Binary.Left(n60) == n50,
		"뿌리 RotateRight"
	)
	assert(Binary.Parent(n50) == n60, "되돌린 뒤 안쪽 자식")
	-- Replace: 자리만 바꿔 달고 뿌리였는지 알려 줌
	const fresh = Binary.New(65)
	assert(
		Binary.Replace(n70, fresh) == false and Binary.Right(n60) == fresh and Binary.Parent(fresh) == n60,
		"Replace 잎"
	)
	assert(Binary.Replace(n10, nil) == false and Binary.Left(n20) == nil, "Replace 를 nil 로(떼기)")
	assert(inorder(n40) == "20,30,40,50,60,65", "Replace 뒤 순서")
	const newRoot = Binary.New(1)
	assert(Binary.Replace(n40, newRoot) == true and Binary.Parent(newRoot) == nil, "뿌리의 Replace 는 true")
	Binary.SetValue(newRoot, 2)
	assert(Binary.Value(newRoot) == 2, "SetValue")
	local never = 0
	for _ in Traverse.InOrder(nil :: stl.BinaryNodeRead<number>?) do
		never += 1
	end
	assert(never == 0, "InOrder(nil)")
	-- 트리부의 노드는 이진 노드 + 키·균형 칸: 접근 함수와 칸이 같은 것을 읽음
	const rbRoot = (stl.RedBlack.Insert(nil :: stl.RbNode<string, number>?, "k", 7, stl.Common.compareString))
	assert(stl.Search.Key(rbRoot) == "k" and stl.Search.Value(rbRoot) == 7, "Search.Key·Value")
	assert(
		(rbRoot :: any)[5] == "k" and (rbRoot :: any)[1] == 7 and (rbRoot :: any)[6] == false,
		"계약의 칸과 같음"
	)
	assert(Binary.Value(rbRoot) == 7, "트리 노드는 이진 노드의 도구에도 들어감")
end
print("PASS")

print("=== 6. Traverse — 전위·중위·후위·층별 순회자 (2026-10-13) ===")
do
	-- 대조군: 재귀로 쓴 네 순회(칸을 직접 읽음 — `2` = 왼쪽, `3` = 오른쪽).
	local function refPre(node: any, out: { any })
		if node ~= nil then
			table.insert(out, node)
			refPre(node[2], out)
			refPre(node[3], out)
		end
	end
	local function refIn(node: any, out: { any })
		if node ~= nil then
			refIn(node[2], out)
			table.insert(out, node)
			refIn(node[3], out)
		end
	end
	local function refPost(node: any, out: { any })
		if node ~= nil then
			refPost(node[2], out)
			refPost(node[3], out)
			table.insert(out, node)
		end
	end
	local function refLevel(root: any, out: { any })
		local layer = if root ~= nil then { root } else {}
		while #layer > 0 do
			const nextLayer = {}
			for _, node in layer do
				table.insert(out, node)
				if node[2] ~= nil then
					table.insert(nextLayer, node[2])
				end
				if node[3] ~= nil then
					table.insert(nextLayer, node[3])
				end
			end
			layer = nextLayer
		end
	end
	const orders = {
		{ name = "PreOrder", walk = Traverse.PreOrder, ref = refPre },
		{ name = "InOrder", walk = Traverse.InOrder, ref = refIn },
		{ name = "PostOrder", walk = Traverse.PostOrder, ref = refPost },
		{ name = "LevelOrder", walk = Traverse.LevelOrder, ref = refLevel },
	}
	-- 한 부분 트리를 네 순회로 돌아 대조군과 **같은 노드가 같은 순서로** 나오는지(값이 아니라 노드의 정체성).
	local function same(root: any, label: string)
		for _, order in orders do
			const want: { any } = {}
			order.ref(root, want)
			local at = 0
			for node in (order.walk :: any)(root) do
				at += 1
				assert(node == want[at], `{label} {order.name}: {at}번째가 다름`)
			end
			assert(at == #want, `{label} {order.name}: {at}개를 냄, 기대 {#want}`)
		end
	end

	-- (1) 손으로 지은 트리 — 순서를 값으로 고정(키·값·위치가 서로 다르게: 값은 10 단위)
	--            40
	--        20      60
	--      10  30      70
	--            35  65
	const n40, n20, n60 = Binary.New(40), Binary.New(20), Binary.New(60)
	const n10, n30, n70, n35, n65 = Binary.New(10), Binary.New(30), Binary.New(70), Binary.New(35), Binary.New(65)
	Binary.SetLeft(n40, n20)
	Binary.SetRight(n40, n60)
	Binary.SetLeft(n20, n10)
	Binary.SetRight(n20, n30)
	Binary.SetRight(n30, n35)
	Binary.SetRight(n60, n70)
	Binary.SetLeft(n70, n65)
	local function values(
		walk: (stl.BinaryNode<number>?) -> () -> stl.BinaryNode<number>?,
		root: stl.BinaryNode<number>?
	): string
		const out: { string } = {}
		for node in walk(root) do
			table.insert(out, tostring(Binary.Value(node)))
		end
		return table.concat(out, ",")
	end
	assert(values(Traverse.PreOrder, n40) == "40,20,10,30,35,60,70,65", `PreOrder: {values(Traverse.PreOrder, n40)}`)
	assert(values(Traverse.InOrder, n40) == "10,20,30,35,40,60,65,70", `InOrder: {values(Traverse.InOrder, n40)}`)
	assert(values(Traverse.PostOrder, n40) == "10,35,30,20,65,70,60,40", `PostOrder: {values(Traverse.PostOrder, n40)}`)
	assert(
		values(Traverse.LevelOrder, n40) == "40,20,60,10,30,70,35,65",
		`LevelOrder: {values(Traverse.LevelOrder, n40)}`
	)

	-- (2) ⭐ 부분 트리 안에서만 — 가운데 노드를 넘기면 그 위(부모·형제)로 나가지 않음.
	--     부모 칸을 따라 올라가는 구현이라 멈출 자리를 놓치면 트리 전체를 돕니다.
	assert(values(Traverse.PreOrder, n20) == "20,10,30,35", `부분 PreOrder: {values(Traverse.PreOrder, n20)}`)
	assert(values(Traverse.InOrder, n20) == "10,20,30,35", `부분 InOrder: {values(Traverse.InOrder, n20)}`)
	assert(values(Traverse.PostOrder, n20) == "10,35,30,20", `부분 PostOrder: {values(Traverse.PostOrder, n20)}`)
	assert(values(Traverse.LevelOrder, n20) == "20,10,30,35", `부분 LevelOrder: {values(Traverse.LevelOrder, n20)}`)
	-- 오른쪽 부분 트리(왼쪽 형제가 있는 쪽), 잎 하나, 오른쪽 자식만 있는 가운데 노드
	assert(
		values(Traverse.PreOrder, n60) == "60,70,65" and values(Traverse.PostOrder, n60) == "65,70,60",
		"오른쪽 부분"
	)
	assert(
		values(Traverse.InOrder, n60) == "60,65,70" and values(Traverse.LevelOrder, n60) == "60,70,65",
		"오른쪽 부분 2"
	)
	for _, order in orders do
		assert(values(order.walk :: any, n10) == "10", `잎 하나 {order.name}`)
		assert(
			values(order.walk :: any, n30) == "30,35" or order.name == "PostOrder",
			`오른쪽 자식만 {order.name}`
		)
		same(n30, "오른쪽 자식만")
		same(n70, "왼쪽 자식만")
	end
	assert(values(Traverse.PostOrder, n30) == "35,30", "오른쪽 자식만 PostOrder")

	-- (3) 빈 트리, 노드 하나
	for _, order in orders do
		local never = 0
		for _ in (order.walk :: any)(nil) do
			never += 1
		end
		assert(never == 0, `{order.name}(nil)`)
		-- 끝난 순회자를 더 불러도 계속 `nil`
		const walk = (order.walk :: any)(n10)
		assert(walk() == n10 and walk() == nil and walk() == nil, `{order.name}: 끝난 뒤에도 nil`)
	end
	same(nil, "빈 트리")
	same(Binary.New(5), "노드 하나")

	-- (4) 한쪽으로만 뻗은 트리(왼쪽 사슬·오른쪽 사슬·지그재그) — 올라가기 루프의 양 끝
	for _, shape in { "left", "right", "zigzag" } do
		const top = Binary.New(1000)
		local tip = top
		for step = 1, 40 do
			const fresh = Binary.New(1000 + step * 10)
			const goLeft = shape == "left" or (shape == "zigzag" and step % 2 == 1)
			if goLeft then
				Binary.SetLeft(tip, fresh)
			else
				Binary.SetRight(tip, fresh)
			end
			tip = fresh
		end
		same(top, shape)
		same(Binary.Left(top) or Binary.Right(top), `{shape} 의 부분`)
	end

	-- (5) 무작위 모양 — 두 균형 방식이 지은 트리(넣고 빼기를 섞어 모양을 흔듦)와 그 안의 **모든 부분 트리**
	local seed = 20261013
	local function rand(limit: number): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed % limit
	end
	for _, scheme in { stl.RedBlack :: any, stl.Avl :: any } do
		for round = 1, 30 do
			local root: any = nil
			const size = 1 + rand(120)
			for _ = 1, size do
				root = (scheme.Insert(root, rand(400) * 10, rand(9), stl.Common.compareNumber))
			end
			for _ = 1, rand(size) do
				const victim = stl.Search.Find(root, rand(400) * 10, stl.Common.compareNumber)
				if victim ~= nil then
					root = scheme.Remove(root, victim)
				end
			end
			same(root, `무작위 {round}`)
			const all: { any } = {}
			refPre(root, all)
			for _, node in all do
				same(node, `무작위 {round} 의 부분 트리`)
			end
		end
	end

	-- (6) 트리부의 노드도 그대로 — 중위 순회는 키 순서
	local rb: stl.RbNode<number, string>? = nil
	for _, key in { 50, 20, 80, 10, 30, 70, 90 } do
		rb = (stl.RedBlack.Insert(rb, key, `v{key}`, stl.Common.compareNumber))
	end
	const seen: { string } = {}
	for node in Traverse.InOrder(rb) do
		table.insert(seen, `{stl.Search.Key(node)}={stl.Search.Value(node)}`)
	end
	assert(table.concat(seen, ",") == "10=v10,20=v20,30=v30,50=v50,70=v70,80=v80,90=v90", table.concat(seen, ","))
end
print("PASS")

print()
print("=== ALL PASS (트리부·Node 도구) ===")

return true
