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
		const first, second, third = walk(), walk(), walk()
		assert(first == n10 and second == nil and third == nil, `{order.name}: 끝난 뒤에도 nil`)
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

print("=== 7. CompleteArray — 배열에 담은 완전 이진 트리 (2026-10-13) ===")
do
	const Complete = stl.CompleteArray
	local function less(a: number, b: number): boolean
		return a < b
	end

	-- (1) 자리 계산 — 값이 아니라 위치. 7개짜리 트리:      1
	--                                                 2     3
	--                                                4 5   6 7
	assert(
		Complete.Parent(1) == nil and Complete.Parent(2) == 1 and Complete.Parent(3) == 1,
		"Parent 뿌리·둘째 층"
	)
	assert(Complete.Parent(6) == 3 and Complete.Parent(7) == 3 and Complete.Parent(5) == 2, "Parent 셋째 층")
	assert(Complete.Left(1, 7) == 2 and Complete.Right(1, 7) == 3, "뿌리의 자식")
	assert(Complete.Left(3, 7) == 6 and Complete.Right(3, 7) == 7, "3 의 자식")
	-- 경계: 왼쪽만 있는 노드(count = 6 → 3 의 왼쪽 6 은 있고 오른쪽 7 은 없음), 잎, 빈 트리, 하나
	assert(Complete.Left(3, 6) == 6 and Complete.Right(3, 6) == nil, "왼쪽 자식만")
	assert(Complete.Left(4, 7) == nil and Complete.Right(4, 7) == nil, "잎")
	assert(Complete.Left(1, 0) == nil and Complete.Right(1, 1) == nil and Complete.Left(1, 1) == nil, "빈 것·하나")
	assert(Complete.Right(2, 5) == 5 and Complete.Right(2, 4) == nil, "오른쪽 자식의 경계")
	-- 높이: 층의 수. 2의 거듭제곱 앞뒤에서 바뀜
	for count, want in { [0] = 0, [1] = 1, [2] = 2, [3] = 2, [4] = 3, [7] = 3, [8] = 4, [1023] = 10, [1024] = 11 } do
		assert(Complete.Height(count) == want, `Height({count}) = {Complete.Height(count)}, 기대 {want}`)
	end
	-- 자리 계산끼리 맞물림: 자식의 부모는 자기
	for idx = 1, 200 do
		const left, right = Complete.Left(idx, 401), Complete.Right(idx, 401)
		assert(left ~= nil and Complete.Parent(left) == idx, `Left·Parent {idx}`)
		assert(right ~= nil and Complete.Parent(right) == idx and right == left + 1, `Right·Parent {idx}`)
	end

	-- (2) IsHeap — 빈 것·하나는 참, 어긋난 자리가 맨 끝·오른쪽 자식에 있어도 잡음
	assert(Complete.IsHeap({}, 0, less) and Complete.IsHeap({ 50 }, 1, less), "IsHeap 빈 것·하나")
	assert(Complete.IsHeap({ 10, 30, 20, 40, 50 }, 5, less), "IsHeap 참")
	assert(not Complete.IsHeap({ 10, 30, 20, 40, 25 }, 5, less), "IsHeap: 맨 끝이 부모보다 앞섬")
	assert(not Complete.IsHeap({ 10, 30, 20, 40, 50, 60, 15 }, 7, less), "IsHeap: 오른쪽 자식")
	assert(not Complete.IsHeap({ 20, 10 }, 2, less), "IsHeap: 뿌리의 왼쪽")
	-- count 밖은 보지 않음
	assert(Complete.IsHeap({ 10, 30, 20, 5 }, 3, less), "IsHeap 은 count 까지만")
	-- 같은 값은 힙 순서를 어기지 않음
	assert(Complete.IsHeap({ 10, 10, 10 }, 3, less), "IsHeap 같은 값")

	-- (3) SiftUp — 맨 뒤에 놓은 원소가 올라갈 만큼만. 다른 원소의 상대 순서(경로 밖)는 그대로
	do
		const list = { 10, 30, 20, 40, 50, 60, 70, 5 }
		Complete.SiftUp(list, 8, less)
		-- 8 → 4 → 2 → 1 로 올라감: 경로의 40·30·10 이 한 칸씩 내려옴
		assert(table.concat(list, ",") == "5,10,20,30,50,60,70,40", `SiftUp 끝까지: {table.concat(list, ",")}`)
		const mid = { 10, 30, 20, 40, 50, 60, 70, 35 }
		Complete.SiftUp(mid, 8, less)
		assert(table.concat(mid, ",") == "10,30,20,35,50,60,70,40", `SiftUp 한 칸: {table.concat(mid, ",")}`)
		const stay = { 10, 30, 20, 40, 50, 60, 70, 45 }
		Complete.SiftUp(stay, 8, less)
		assert(table.concat(stay, ",") == "10,30,20,40,50,60,70,45", "SiftUp 제자리")
		-- 같은 값은 넘지 않음(부모와 같으면 멈춤), 뿌리에서 부르면 아무 일 없음
		const equal = { 10, 30, 20, 30 }
		Complete.SiftUp(equal, 4, less)
		assert(table.concat(equal, ",") == "10,30,20,30", "SiftUp 같은 값")
		const one = { 99 }
		Complete.SiftUp(one, 1, less)
		assert(one[1] == 99, "SiftUp 뿌리")
	end

	-- (4) SiftDown — 더 앞서는 자식 쪽으로. 자식이 하나뿐인 자리, count 밖은 안 봄
	do
		const list = { 90, 10, 20, 30, 40, 50, 60 }
		Complete.SiftDown(list, 7, 1, less)
		assert(table.concat(list, ",") == "10,30,20,90,40,50,60", `SiftDown 왼쪽으로: {table.concat(list, ",")}`)
		const right = { 90, 20, 10, 30, 40, 50, 60 }
		Complete.SiftDown(right, 7, 1, less)
		assert(
			table.concat(right, ",") == "10,20,50,30,40,90,60",
			`SiftDown 오른쪽으로: {table.concat(right, ",")}`
		)
		-- 왼쪽 자식만 있는 자리(count = 6 → 3 의 자식은 6 뿐)
		const single = { 10, 20, 90, 30, 40, 50 }
		Complete.SiftDown(single, 6, 3, less)
		assert(table.concat(single, ",") == "10,20,50,30,40,90", `SiftDown 자식 하나: {table.concat(single, ",")}`)
		-- count 밖의 더 앞서는 값은 자식이 아님
		const bounded = { 90, 95, 99, 1, 2 }
		Complete.SiftDown(bounded, 3, 1, less)
		assert(table.concat(bounded, ",") == "90,95,99,1,2", "SiftDown 은 count 안에서만")
		const stay = { 10, 20, 30 }
		Complete.SiftDown(stay, 3, 1, less)
		assert(table.concat(stay, ",") == "10,20,30", "SiftDown 제자리")
		-- 같은 값의 자식 아래로는 안 내려감
		const equal = { 20, 20, 30 }
		Complete.SiftDown(equal, 3, 1, less)
		assert(table.concat(equal, ",") == "20,20,30", "SiftDown 같은 값")
	end

	-- (4b) 같은 키는 **넘지 않습니다** — 숫자로는 안 보여(자리를 바꿔도 같은 값) 이름표를 단 레코드로.
	--      넘어도 힙 순서는 맞지만, 전부 같은 키인 입력에서 걸음마다 끝까지 옮기게 됩니다.
	do
		type Tagged = { key: number, tag: string }
		local function lessKey(a: Tagged, b: Tagged): boolean
			return a.key < b.key
		end
		local function tags(list: { Tagged }): string
			const out: { string } = {}
			for idx, item in list do
				out[idx] = item.tag
			end
			return table.concat(out, ",")
		end
		const up: { Tagged } =
			{ { key = 10, tag = "a" }, { key = 30, tag = "b" }, { key = 20, tag = "c" }, { key = 30, tag = "d" } }
		Complete.SiftUp(up, 4, lessKey)
		assert(tags(up) == "a,b,c,d", `SiftUp 은 같은 키의 부모를 넘지 않음: {tags(up)}`)
		const down: { Tagged } = { { key = 20, tag = "a" }, { key = 20, tag = "b" }, { key = 30, tag = "c" } }
		Complete.SiftDown(down, 3, 1, lessKey)
		assert(tags(down) == "a,b,c", `SiftDown 은 같은 키의 자식 아래로 안 내려감: {tags(down)}`)
	end

	-- (5) Heapify — 빈 것·하나·둘, 그리고 무작위를 정렬 결과와 대조(힙에서 하나씩 꺼내면 정렬 순서)
	do
		const empty: { number } = {}
		Complete.Heapify(empty, 0, less)
		const one = { 7 }
		Complete.Heapify(one, 1, less)
		const two = { 20, 10 }
		Complete.Heapify(two, 2, less)
		assert(#empty == 0 and one[1] == 7 and two[1] == 10 and two[2] == 20, "Heapify 빈 것·하나·둘")
		local seed = 4242
		local function rand(limit: number): number
			seed = (seed * 48271) % 2147483647
			return seed % limit
		end
		for round = 1, 300 do
			const count = rand(60)
			const list = table.create(count) :: { number }
			for idx = 1, count do
				list[idx] = rand(40) * 10 -- 중복이 섞이게
			end
			const want = table.clone(list)
			table.sort(want)
			-- count 밖에 값을 하나 둬서 "count 까지만" 을 같이 봄
			list[count + 1] = -1
			Complete.Heapify(list, count, less)
			assert(Complete.IsHeap(list, count, less), `Heapify {round}: 힙 순서가 아님`)
			assert(list[count + 1] == -1, `Heapify {round}: count 밖을 건드림`)
			-- 꺼내기(뿌리를 맨 뒤 것으로 갈아 끼우고 내림)를 손으로 — 힙 정렬의 한 걸음
			local remaining = count
			for idx = 1, count do
				assert(list[1] == want[idx], `Heapify {round}: {idx}번째 꺼낸 값 {list[1]}, 기대 {want[idx]}`)
				list[1] = list[remaining]
				remaining -= 1
				if remaining > 1 then
					Complete.SiftDown(list, remaining, 1, less)
				end
				assert(Complete.IsHeap(list, remaining, less), `꺼낸 뒤 {round}/{idx}: 힙 순서가 아님`)
			end
		end
		-- 하나씩 넣기(맨 뒤에 놓고 올림)도 같은 결과로 — 최대 힙(비교자를 뒤집음)으로
		local function greater(a: number, b: number): boolean
			return a > b
		end
		for round = 1, 100 do
			const count = 1 + rand(50)
			const list: { number } = {}
			local top = -math.huge
			for idx = 1, count do
				const item = rand(1000)
				top = math.max(top, item)
				list[idx] = item
				Complete.SiftUp(list, idx, greater)
				assert(Complete.IsHeap(list, idx, greater) and list[1] == top, `넣기 {round}/{idx}`)
			end
		end
	end

	-- (6) 힙은 이것의 조립 — 같은 입력이면 저장소가 같은 배치(`Heap.Items` 는 저장 순서 그대로)
	do
		const source = { 50, 30, 80, 10, 90, 20, 70 }
		const direct = table.clone(source)
		Complete.Heapify(direct, #direct, less)
		assert(
			table.concat(stl.Heap.Items(stl.Heap.FromList(source, less)), ",") == table.concat(direct, ","),
			"Heap.FromList = Heapify"
		)
		const pushed: { number } = {}
		const heap = stl.Heap.New(less)
		for idx, item in source do
			pushed[idx] = item
			Complete.SiftUp(pushed, idx, less)
			stl.Heap.Push(heap, item)
		end
		assert(
			table.concat(stl.Heap.Items(heap), ",") == table.concat(pushed, ","),
			"Heap.Push = 맨 뒤에 놓고 SiftUp"
		)
	end
end
print("PASS")

print("=== 8. CompleteNode — 노드로 이은 완전 이진 트리 (2026-10-13) ===")
do
	const Complete = stl.CompleteNode
	type N = stl.BinaryNode<number>
	local function less(a: number, b: number): boolean
		return a < b
	end
	-- 값이 10, 20, … 인 노드 `count` 개를 차례로 붙인 트리(자리 i 의 값은 i * 10)
	local function build(count: number): (N?, { N })
		local root: N? = nil
		const nodes: { N } = {}
		for idx = 1, count do
			const node = Binary.New(idx * 10)
			nodes[idx] = node
			root = Complete.Append(root, idx - 1, node)
			assert(Complete.IsComplete(root, idx), `Append {idx}: 완전 이진이 아님`)
		end
		return root, nodes
	end

	-- (1) At — 뿌리에서 번호의 비트를 따라. 경계: 0·음수·개수 밖·빈 트리
	do
		const root, nodes = build(10)
		for idx = 1, 10 do
			assert(Complete.At(root, idx) == nodes[idx], `At({idx})`)
		end
		assert(Complete.At(root, 0) == nil and Complete.At(root, -3) == nil, "At 0·음수")
		assert(
			Complete.At(root, 11) == nil and Complete.At(root, 20) == nil and Complete.At(root, 1000) == nil,
			"At 개수 밖"
		)
		assert(Complete.At(nil :: N?, 1) == nil, "At 빈 트리")
		-- 모양: 자리 i 의 자식은 2i·2i+1, 부모는 i // 2 (배열식과 같은 번호)
		for idx = 1, 10 do
			const node = nodes[idx]
			assert(Binary.Left(node) == nodes[idx * 2] and Binary.Right(node) == nodes[idx * 2 + 1], `자식 {idx}`)
			assert(Binary.Parent(node) == nodes[idx // 2], `부모 {idx}`)
		end
	end

	-- (2) RemoveLast — 붙인 역순으로 나오고, 뗀 노드는 연결이 끊김. 하나·빈 것
	do
		local root, nodes = build(7)
		for count = 7, 2, -1 do
			const nextRoot, removed = Complete.RemoveLast(root, count)
			assert(removed == nodes[count] and nextRoot == nodes[1], `RemoveLast {count}`)
			assert(Binary.Parent(removed :: N) == nil, `뗀 노드의 부모 {count}`)
			root = nextRoot
			assert(Complete.IsComplete(root, count - 1), `RemoveLast 뒤 {count - 1}`)
		end
		const emptied, lastOne = Complete.RemoveLast(root, 1)
		assert(emptied == nil and lastOne == nodes[1], "하나 남은 것을 떼면 빈 트리")
		const none, nothing = Complete.RemoveLast(nil :: N?, 0)
		assert(none == nil and nothing == nil, "빈 트리의 RemoveLast")
	end

	-- (3) Exchange — **모든 쌍**(부모-자식 양방향, 형제, 뿌리, 먼 사이, 같은 노드): 두 자리만 바뀌고 나머지는
	--     그대로, 모양은 완전 이진, 노드의 값은 그대로(값이 아니라 노드가 옮겨감)
	for first = 1, 10 do
		for second = 1, 10 do
			local root, nodes = build(10)
			root = Complete.Exchange(root :: N, nodes[first], nodes[second])
			assert(Complete.IsComplete(root, 10), `Exchange({first}, {second}): 모양이 깨짐`)
			for idx = 1, 10 do
				const want = if idx == first then nodes[second] elseif idx == second then nodes[first] else nodes[idx]
				assert(Complete.At(root, idx) == want, `Exchange({first}, {second}): 자리 {idx}`)
				assert(
					Binary.Value(nodes[idx]) == idx * 10,
					`Exchange({first}, {second}): 노드 {idx} 의 값이 바뀜`
				)
			end
			assert(Binary.Parent(root :: N) == nil, `Exchange({first}, {second}): 뿌리의 부모`)
		end
	end
	-- 노드 둘·셋뿐인 트리(자식이 하나인 부모, 뿌리와 그 자식)
	for _, size in { 2, 3 } do
		for first = 1, size do
			for second = 1, size do
				local root, nodes = build(size)
				root = Complete.Exchange(root :: N, nodes[first], nodes[second])
				assert(Complete.IsComplete(root, size), `작은 트리 {size} Exchange({first}, {second})`)
				assert(
					Complete.At(root, first) == nodes[second] and Complete.At(root, second) == nodes[first],
					"작은 트리 자리"
				)
			end
		end
	end

	-- (4) IsHeap·IsComplete 의 거짓 — 순서가 어긋난 자리, 빈 자리, 개수 불일치, 틀린 부모 칸
	do
		const root, nodes = build(6)
		assert(Complete.IsHeap(root, less) and Complete.IsHeap(nil :: N?, less), "IsHeap 참·빈 것")
		Binary.SetValue(nodes[6], 5) -- 맨 끝(3 의 왼쪽 자식)이 부모보다 앞섬
		assert(not Complete.IsHeap(root, less), "IsHeap: 맨 끝")
		Binary.SetValue(nodes[6], 60)
		Binary.SetValue(nodes[5], 15) -- 2 의 오른쪽 자식
		assert(not Complete.IsHeap(root, less), "IsHeap: 오른쪽 자식")
		Binary.SetValue(nodes[5], 20) -- 부모와 같은 값은 어긋남이 아님
		assert(Complete.IsHeap(root, less), "IsHeap 같은 값")
		assert(not Complete.IsComplete(root, 5) and not Complete.IsComplete(root, 7), "IsComplete 개수 불일치")
		assert(Complete.IsComplete(nil, 0) and not Complete.IsComplete(nil, 1), "IsComplete 빈 트리")
		assert(not Complete.IsComplete(nodes[2], 3), "IsComplete: 부모가 있는 노드는 뿌리가 아님")
		-- 빈 자리: 5번(2 의 오른쪽)을 떼면 6번이 남아 완전 이진이 아님(노드 수는 5)
		Binary.SetRight(nodes[2], nil)
		assert(not Complete.IsComplete(root, 5), "IsComplete: 가운데 빈 자리")
		Binary.SetRight(nodes[2], nodes[5])
		assert(Complete.IsComplete(root, 6), "되돌리면 참")
		const wrong: any = nodes[4]
		wrong[4] = nodes[3] -- 틀린 부모 칸
		assert(not Complete.IsComplete(root, 6), "IsComplete: 틀린 부모 칸")
	end

	-- (5) 힙으로 조립 — 넣기(맨 뒤에 붙이고 올림)·꺼내기(뿌리와 맨 뒤를 맞바꾸고 떼고 내림)를 무작위로, 배열식
	--     (`Heap`)과 **같은 순서로 나오는지**. 그리고 노드식만의 것: 쥔 노드의 값을 고치기, 가운데 노드를 빼기.
	do
		local seed = 987
		local function rand(limit: number): number
			seed = (seed * 48271) % 2147483647
			return seed % limit
		end
		for round = 1, 60 do
			local root: N? = nil
			local count = 0
			const model = stl.Heap.New(less)
			const live: { N } = {} -- 쥐고 있는 노드들(순서 없음)
			local function settle(label: string)
				assert(Complete.IsComplete(root, count), `{label} {round}: 모양`)
				assert(Complete.IsHeap(root, less), `{label} {round}: 힙 순서`)
				assert(count == stl.Heap.Len(model) and count == #live, `{label} {round}: 개수`)
				if root ~= nil then
					assert(Binary.Value(root) == stl.Heap.Peek(model), `{label} {round}: 꼭대기`)
				end
			end
			local function push(value: number)
				const node = Binary.New(value)
				root = Complete.SiftUp(Complete.Append(root, count, node), node, less)
				count += 1
				table.insert(live, node)
				stl.Heap.Push(model, value)
			end
			-- 쥔 노드 하나를 뺌(뿌리든 가운데든): 맨 뒤와 자리를 바꾸고 떼고, 그 자리에 온 노드를 올리거나 내림
			local function remove(node: N)
				const last = Complete.At(root, count) :: N
				local top = Complete.Exchange(root :: N, node, last)
				const afterRoot, removed = Complete.RemoveLast(top, count)
				assert(removed == node, `remove {round}: 뗀 것이 그 노드가 아님`)
				count -= 1
				root = afterRoot
				if root ~= nil and last ~= node then
					root = Complete.SiftDown(Complete.SiftUp(root, last, less), last, less)
				end
				table.remove(live, table.find(live, node) :: number)
			end
			for step = 1, 300 do
				const roll = rand(10)
				if roll < 5 or count == 0 then
					push(rand(50) * 10) -- 중복이 섞이게
				elseif roll < 8 then
					-- 꺼내기: 배열식과 같은 값이 나와야 함
					const top = root :: N
					const want = stl.Heap.Pop(model)
					assert(Binary.Value(top) == want, `Pop {round}/{step}: {Binary.Value(top)}, 기대 {want}`)
					remove(top)
				elseif roll < 9 then
					-- 쥔 노드의 값을 고침(우선순위 바꾸기) — 모델은 다시 지음
					const node = live[1 + rand(#live)]
					Binary.SetValue(node, rand(50) * 10)
					root = Complete.SiftDown(Complete.SiftUp(root :: N, node, less), node, less)
					const values: { number } = {}
					for idx, held in live do
						values[idx] = Binary.Value(held)
					end
					stl.Heap.Clear(model)
					for _, value in values do
						stl.Heap.Push(model, value)
					end
				else
					-- 가운데 노드를 뺌 — 모델은 다시 지음
					const node = live[1 + rand(#live)]
					remove(node)
					stl.Heap.Clear(model)
					for _, held in live do
						stl.Heap.Push(model, Binary.Value(held))
					end
				end
				settle(`걸음 {step}`)
			end
			-- 남은 것을 다 꺼내면 정렬 순서
			local previous = -math.huge
			while root ~= nil do
				const top = root :: N
				assert(Binary.Value(top) >= previous, `마무리 {round}: 순서`)
				previous = Binary.Value(top)
				assert(previous == stl.Heap.Pop(model), `마무리 {round}: 배열식과 다름`)
				remove(top)
			end
			assert(count == 0 and #live == 0, `마무리 {round}: 남음`)
		end
	end

	-- (6) 같은 키는 넘지 않음(걸음마다 연결을 열 군데쯤 고치니 쓸데없이 옮기면 비쌉니다)
	do
		const a, b, c, d = Binary.New(10), Binary.New(30), Binary.New(20), Binary.New(30)
		local root: N? = nil
		for idx, node in { a, b, c, d } do
			root = Complete.Append(root, idx - 1, node)
		end
		root = Complete.SiftUp(root :: N, d, less)
		assert(
			Complete.At(root, 4) == d and Complete.At(root, 2) == b,
			"SiftUp 은 같은 키의 부모를 넘지 않음"
		)
		Binary.SetValue(a, 20) -- 뿌리 20, 자식 30·20: 같은 키(오른쪽 20) 아래로 안 내려감
		root = Complete.SiftDown(root :: N, a, less)
		assert(root == a and Complete.At(root, 3) == c, "SiftDown 은 같은 키의 자식 아래로 안 내려감")
	end
end
print("PASS")

print(
	"=== 9. SortedArray — 정렬 배열로 된 탐색 구조: 찾기, 밀고 당기는 넣기·빼기 (2026-10-14) ==="
)
do
	const Sorted = stl.SortedArray
	type Rec = { key: number, tag: string }
	local function probe(rec: Rec, key: number): number
		return rec.key - key
	end
	local function show(list: { Rec }, count: number): string
		const out: { string } = {}
		for idx = 1, count do
			out[idx] = `{list[idx].key}{list[idx].tag}`
		end
		return table.concat(out, ",")
	end
	const list: { Rec } = { { key = 10, tag = "a" }, { key = 30, tag = "b" }, { key = 50, tag = "c" } }

	-- (1) Locate — 있는 자리 / 들어갈 자리(앞·사이·맨 뒤), 빈 배열
	do
		local pos, found = Sorted.Locate(list, 3, 30, probe)
		assert(pos == 2 and found == true, "Locate 있는 키")
		pos, found = Sorted.Locate(list, 3, 5, probe)
		assert(pos == 1 and found == false, "Locate 맨 앞에 들어갈 키")
		pos, found = Sorted.Locate(list, 3, 40, probe)
		assert(pos == 3 and found == false, "Locate 사이에 들어갈 키")
		pos, found = Sorted.Locate(list, 3, 99, probe)
		assert(pos == 4 and found == false, "Locate 맨 뒤(count + 1)")
		pos, found = Sorted.Locate({} :: { Rec }, 0, 7, probe)
		assert(pos == 1 and found == false, "Locate 빈 배열")
		-- count 밖은 보지 않음: 셋째 칸의 50 은 count = 2 에서는 없는 것
		pos, found = Sorted.Locate(list, 2, 50, probe)
		assert(pos == 3 and found == false, "Locate 는 count 까지만")
		-- 찾기 셋은 BSearch 와 같은 것
		assert(Sorted.Find(list, 3, 50, probe) == 3 and Sorted.Find(list, 3, 40, probe) == nil, "Find")
		assert(Sorted.LowerBound(list, 3, 30, probe) == 2 and Sorted.UpperBound(list, 3, 30, probe) == 3, "경계")
	end

	-- (2) InsertAt — 맨 앞·사이·맨 뒤. 뒤의 것들이 한 칸씩 밀리고 순서가 유지됨
	do
		const work = table.clone(list)
		Sorted.InsertAt(work, 3, 3, { key = 40, tag = "x" })
		assert(show(work, 4) == "10a,30b,40x,50c", `사이: {show(work, 4)}`)
		Sorted.InsertAt(work, 4, 1, { key = 5, tag = "y" })
		assert(show(work, 5) == "5y,10a,30b,40x,50c", `맨 앞: {show(work, 5)}`)
		Sorted.InsertAt(work, 5, 6, { key = 60, tag = "z" })
		assert(show(work, 6) == "5y,10a,30b,40x,50c,60z" and work[7] == nil, `맨 뒤: {show(work, 6)}`)
		const empty: { Rec } = {}
		Sorted.InsertAt(empty, 0, 1, { key = 1, tag = "only" })
		assert(show(empty, 1) == "1only", "빈 배열에 넣기")
	end

	-- (3) RemoveAt — 맨 앞·사이·맨 뒤. 뺀 것을 돌려주고, 당긴 뒤 **맨 끝 칸을 비움**(안 비우면 끝 원소가 둘)
	do
		const work: { Rec } = {
			{ key = 10, tag = "a" },
			{ key = 20, tag = "b" },
			{ key = 30, tag = "c" },
			{ key = 40, tag = "d" },
		}
		assert(Sorted.RemoveAt(work, 4, 2).tag == "b", "RemoveAt 은 뺀 것을 돌려줌")
		assert(show(work, 3) == "10a,30c,40d" and work[4] == nil, `사이: {show(work, 3)}`)
		assert(Sorted.RemoveAt(work, 3, 1).tag == "a" and show(work, 2) == "30c,40d" and work[3] == nil, "맨 앞")
		assert(Sorted.RemoveAt(work, 2, 2).tag == "d" and show(work, 1) == "30c" and work[2] == nil, "맨 뒤")
		assert(Sorted.RemoveAt(work, 1, 1).tag == "c" and work[1] == nil, "하나 남은 것")
	end

	-- (3b) SplitOff·Append — 떼어 낸 것이 0개·**딱 하나**·여럿·전부. 남은 쪽의 뒤 칸이 비었는지, 다시 이으면 원래대로
	--      (5라운드 리뷰: "하나만 떼어 냄" 이 어느 테스트에도 없어 `moved > 0` 을 `> 1` 로 바꿔도 통과했음)
	for _, cut in { 1, 2, 4, 5, 6 } do
		const work: { Rec } = {}
		for idx = 1, 5 do
			work[idx] = { key = idx * 10, tag = `t{idx}` }
		end
		const high = Sorted.SplitOff(work, 5, cut)
		const moved = 5 - cut + 1
		assert(#high == moved and #work == cut - 1, `SplitOff@{cut}: 남은 {#work}, 떼어 낸 {#high}`)
		for idx = 1, cut - 1 do
			assert(work[idx].key == idx * 10, `SplitOff@{cut}: 남은 쪽 {idx}`)
		end
		for idx = cut, 6 do
			assert(work[idx] == nil, `SplitOff@{cut}: 남은 쪽의 뒤 칸 {idx} 가 안 비었음`)
		end
		for idx = 1, moved do
			assert(
				high[idx].key == (cut + idx - 1) * 10 and high[idx].tag == `t{cut + idx - 1}`,
				`SplitOff@{cut}: 떼어 낸 쪽 {idx}`
			)
		end
		assert(high[moved + 1] == nil, `SplitOff@{cut}: 떼어 낸 쪽의 뒤 칸`)
		Sorted.Append(work, cut - 1, high, moved)
		assert(show(work, 5) == "10t1,20t2,30t3,40t4,50t5" and work[6] == nil, `Append@{cut}: {show(work, 5)}`)
		assert(#high == moved, `Append@{cut}: 상대는 그대로`)
	end
	do
		const empty: { Rec } = {}
		assert(#Sorted.SplitOff(empty, 0, 1) == 0, "빈 배열의 SplitOff")
		Sorted.Append(empty, 0, { { key = 7, tag = "x" } }, 1)
		assert(show(empty, 1) == "7x", "빈 배열에 Append")
		Sorted.Append(empty, 1, {} :: { Rec }, 0)
		assert(show(empty, 1) == "7x" and empty[2] == nil, "빈 것을 Append")
	end

	-- (4) 무작위: Locate → InsertAt / RemoveAt 로 짠 맵을 평범한 사전과 대조. 걸음마다 순서·개수·끝 칸
	do
		local seed = 5150
		local function rand(limit: number): number
			seed = (seed * 48271) % 2147483647
			return seed % limit
		end
		for round = 1, 60 do
			const work: { Rec } = {}
			local count = 0
			const model: { [number]: string } = {}
			local modelCount = 0
			for step = 1, 200 do
				const key = rand(80) * 10
				const pos, found = Sorted.Locate(work, count, key, probe)
				if rand(3) > 0 then
					const tag = `t{step}`
					if found then
						work[pos].tag = tag
					else
						Sorted.InsertAt(work, count, pos, { key = key, tag = tag })
						count += 1
						modelCount += 1
					end
					model[key] = tag
				elseif found then
					const removed = Sorted.RemoveAt(work, count, pos)
					assert(removed.key == key and removed.tag == model[key], `뺀 것 {round}/{step}`)
					count -= 1
					modelCount -= 1
					model[key] = nil
				end
				assert(count == modelCount and work[count + 1] == nil, `개수·끝 칸 {round}/{step}`)
				for idx = 1, count do
					assert(model[work[idx].key] == work[idx].tag, `내용 {round}/{step}`)
					assert(idx == 1 or work[idx - 1].key < work[idx].key, `순서 {round}/{step}`)
				end
			end
		end
	end
end
print("PASS")

print("=== 10. Join·Split — 두 트리를 잇기, 부분을 떼어 내기 (2026-10-14) ===")
for _, scheme in
	{
		{ name = "RedBlack", module = stl.RedBlack :: any, balance = redBlackBalance },
		{ name = "Avl", module = stl.Avl :: any, balance = avlBalance },
	}
do
	const name, M = scheme.name, scheme.module
	balanceOf = scheme.balance
	-- 키 `from, from + step, …` 을 `count` 개 든 트리(값은 키 + 1). 넣는 순서를 흩어 모양이 한쪽으로 쏠리지 않게.
	local shuffleSeed = 77
	local function build(from: number, count: number, step: number): any
		const keys = table.create(count) :: { number }
		for at = 1, count do
			keys[at] = from + (at - 1) * step
		end
		for at = count, 2, -1 do
			shuffleSeed = (shuffleSeed * 48271) % 2147483647
			const other = shuffleSeed % at + 1
			keys[at], keys[other] = keys[other], keys[at]
		end
		local root: any = nil
		for _, key in keys do
			root = (M.Insert(root, key, key + 1, compare))
		end
		return root
	end
	local function single(key: number): any
		return (M.Insert(nil, key, key + 1, compare))
	end
	local function same(got: { number }, want: { number }, label: string)
		assert(#got == #want, `{name} {label}: {#got}개, 기대 {#want}`)
		for at, key in want do
			assert(got[at] == key, `{name} {label}: {at}번째 {got[at]}, 기대 {key}`)
		end
	end

	-- (1) Join — 크기의 모든 조합(0~24 × 0~24)과 한쪽이 훨씬 큰 경우. 불변식 전부 + 키 목록
	const sizes: { { number } } = {}
	for left = 0, 24 do
		for right = 0, 24 do
			table.insert(sizes, { left, right })
		end
	end
	for _, pair in
		{
			{ 500, 0 },
			{ 0, 500 },
			{ 700, 1 },
			{ 1, 700 },
			{ 1000, 3 },
			{ 3, 1000 },
			{ 900, 40 },
			{ 40, 900 },
			{ 513, 512 },
		}
	do
		table.insert(sizes, pair)
	end
	for _, pair in sizes do
		const leftCount, rightCount = pair[1], pair[2]
		-- 왼쪽: 10, 20, …  가운데: 그다음  오른쪽: 그 뒤
		const left = build(10, leftCount, 10)
		const midKey = 10 + leftCount * 10
		const mid = single(midKey)
		const right = build(midKey + 10, rightCount, 10)
		const heldLeft = if left ~= nil then Binary.First(left) else nil
		const heldRight = if right ~= nil then Binary.Last(right) else nil
		const joined = M.Join(left, mid, right)
		const keys = check(joined, `Join {leftCount}+1+{rightCount}`)
		const want: { number } = {}
		for at = 1, leftCount + 1 + rightCount do
			want[at] = at * 10
		end
		same(keys, want, `Join {leftCount}+1+{rightCount}`)
		-- 노드는 그대로(새로 만들지 않음): 가운데 노드, 양쪽에서 쥐고 있던 노드
		assert(stl.Search.Find(joined, midKey, compare) == mid, `{name} Join: 가운데 노드가 그 노드가 아님`)
		assert(heldLeft == nil or stl.Search.First(joined) == heldLeft, `{name} Join: 왼쪽 끝 노드`)
		assert(heldRight == nil or stl.Search.Last(joined) == heldRight, `{name} Join: 오른쪽 끝 노드`)
		assert(stl.Search.Value(mid) == midKey + 1, `{name} Join: 가운데 노드의 값`)
	end

	-- (2) Split — 크기 0~40 의 트리를 **모든 자리**에서(있는 키, 키 사이, 맨 앞보다 작게, 맨 뒤보다 크게)
	for count = 0, 40 do
		for probe = 5, count * 10 + 15, 5 do
			const root = build(10, count, 10)
			const held: any = if root ~= nil then (stl.Search.Find :: any)(root, probe, compare) else nil
			const small, found, large = stl.Balance.Split(M, root, probe, compare)
			const smallKeys = check(small, `Split {count}@{probe} 작은 쪽`)
			const largeKeys = check(large, `Split {count}@{probe} 큰 쪽`)
			const wantSmall: { number }, wantLarge: { number } = {}, {}
			for at = 1, count do
				const key = at * 10
				if key < probe then
					table.insert(wantSmall, key)
				elseif key > probe then
					table.insert(wantLarge, key)
				end
			end
			same(smallKeys, wantSmall, `Split {count}@{probe} 작은 쪽`)
			same(largeKeys, wantLarge, `Split {count}@{probe} 큰 쪽`)
			const exists = probe % 10 == 0 and probe >= 10 and probe <= count * 10
			assert((found ~= nil) == exists, `{name} Split {count}@{probe}: 찾은 노드`)
			if found ~= nil then
				assert(
					found == held and found[5] == probe and found[1] == probe + 1,
					`{name} Split: 그 노드 그대로`
				)
				assert(
					found[2] == nil and found[3] == nil and found[4] == nil,
					`{name} Split: 찾은 노드는 연결이 끊김`
				)
			end
		end
	end
	-- 빈 트리
	do
		const small, found, large = stl.Balance.Split(M, nil, 10, compare)
		assert(small == nil and found == nil and large == nil, `{name} 빈 트리의 Split`)
	end

	-- (2b) 비교자가 **몇 번째 비교에서 던지든** 트리는 그대로(관측 — 계약은 아님): 비교를 내려가며 다 하고 나서
	--      올라오며 고칩니다. 예전엔 떼어 낸 뒤에 견줘서, 첫 비교에서 던져도 1000개 맵이 조각났습니다(5라운드 리뷰).
	do
		const root = build(10, 200, 10)
		const before = check(root, "던지기 전")
		for failAt = 1, 12 do
			local calls = 0
			const ok = pcall(function()
				stl.Balance.Split(M, root, 1005, function(a: number, b: number): number
					calls += 1
					if calls == failAt then
						error("boom")
					end
					return compare(a, b)
				end)
			end)
			if ok then
				break -- 비교가 failAt 번에 못 미쳐 끝남: 트리는 갈라졌으니 여기서 멈춤
			end
			same(
				check(root, `{failAt}번째 비교에서 던진 뒤`),
				before,
				`{failAt}번째 비교에서 던진 뒤`
			)
			assert(calls == failAt, `{name}: 던진 뒤에 비교를 더 함`)
		end
	end

	-- (3) 무작위: 넣고 빼서 모양을 흔든 트리를 가르고, 다시 잇고, 그 뒤에도 넣기·지우기가 멀쩡한지
	local seed = 8086
	local function rand(limit: number): number
		seed = (seed * 48271) % 2147483647
		return seed % limit
	end
	for round = 1, 12 do
		local root: any = nil
		const model: { [number]: boolean } = {}
		local function sortedModel(): { number }
			const keys: { number } = {}
			for key in model do
				table.insert(keys, key)
			end
			table.sort(keys)
			return keys
		end
		for _ = 1, 400 do
			const key = rand(600) * 10
			if rand(4) > 0 then
				root = (M.Insert(root, key, key + 1, compare))
				model[key] = true
			else
				const node = stl.Search.Find(root, key, compare)
				if node ~= nil then
					root = M.Remove(root, node)
					model[key] = nil
				end
			end
		end
		for step = 1, 120 do
			const probe = rand(1300) * 5 -- 있는 키·없는 키가 섞임
			local small, found, large = stl.Balance.Split(M, root, probe, compare)
			const all = sortedModel()
			const wantSmall: { number }, wantLarge: { number } = {}, {}
			for _, key in all do
				if key < probe then
					table.insert(wantSmall, key)
				elseif key > probe then
					table.insert(wantLarge, key)
				end
			end
			same(check(small, `무작위 {round}/{step} 작은 쪽`), wantSmall, `무작위 {round}/{step} 작은 쪽`)
			same(check(large, `무작위 {round}/{step} 큰 쪽`), wantLarge, `무작위 {round}/{step} 큰 쪽`)
			assert((found ~= nil) == (model[probe] == true), `{name} 무작위 {round}/{step}: 찾은 노드`)
			-- 가끔은 한쪽을 버림(떼어 낸 채로 계속 씀)
			const roll = rand(10)
			if roll == 0 then
				root = small
				for _, key in wantLarge do
					model[key] = nil
				end
				model[probe] = nil
			elseif roll == 1 then
				root = large
				for _, key in wantSmall do
					model[key] = nil
				end
				model[probe] = nil
			else
				-- 다시 잇기: 가운데 노드가 없으면 한쪽 끝에서 하나를 떼어 가운데로
				local mid = found
				if mid == nil and large ~= nil then
					mid = stl.Search.First(large)
					large = M.Remove(large, mid)
				elseif mid == nil and small ~= nil then
					mid = stl.Search.Last(small)
					small = M.Remove(small, mid)
				end
				if mid ~= nil then
					root = M.Join(small, mid, large)
				else
					root = nil
				end
			end
			same(
				check(root, `무작위 {round}/{step} 이은 뒤`),
				sortedModel(),
				`무작위 {round}/{step} 이은 뒤`
			)
			-- 이은 트리에 넣고 빼기
			for _ = 1, 6 do
				const key = rand(600) * 10
				if rand(3) > 0 then
					root = (M.Insert(root, key, key + 1, compare))
					model[key] = true
				else
					const node = stl.Search.Find(root, key, compare)
					if node ~= nil then
						root = M.Remove(root, node)
						model[key] = nil
					end
				end
			end
			same(
				check(root, `무작위 {round}/{step} 고친 뒤`),
				sortedModel(),
				`무작위 {round}/{step} 고친 뒤`
			)
		end
	end
end
print("PASS")

print()
print("=== ALL PASS (트리부·Node 도구) ===")

return true
