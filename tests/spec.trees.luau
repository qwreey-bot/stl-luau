--!strict
--[[
	트리부(RedBlack·Avl — 같은 표면)와 Node 의 연결 방식별 도구(Single·Double·Binary) 테스트. 프레임워크 없음.

	⭐ 균형 트리의 결함은 눈에 안 보입니다(조회는 맞는데 균형이 깨져 있거나, 부모 칸 하나가 틀려 순회만
	틀림). 그래서 **연산마다 불변식을 전부** 검사하고 정렬된 모델과 대조합니다. 넣기·지우기·짓기의
	시나리오는 **두 균형 방식에 똑같이** 돌립니다(1~4절) — 균형 검사만 방식마다 다릅니다.
	키·값·위치가 서로 다르게: 키는 10 단위, 값은 키 + 1.
]]
local stl = require("../src")
local Node = stl.Node
local Binary = Node.Binary

-- 두 방식의 노드를 같은 시나리오로 다루려고 느슨하게(타입은 `spikes/66` 이 지킴)
type RbNode = any
type RbRead = any

-- 균형 검사(방식마다 다름): 레드블랙 — 뿌리 검정, 빨강-빨강 없음, 검정 수 같음, 높이 ≤ 2·log2(n+1)
local function redBlackBalance(root: any, count: number, label: string)
	assert(not root.red, `{label}: 뿌리가 빨강`)
	local function walk(node: any, parent: any): number
		if node == nil then
			return 1
		end
		if node.red then
			assert(parent ~= nil and not parent.red, `{label}: 빨강-빨강 at {node.key}`)
		end
		const leftBlack, rightBlack = walk(node[1], node), walk(node[2], node)
		assert(leftBlack == rightBlack, `{label}: {node.key} 에서 검정 수 {leftBlack} ~= {rightBlack}`)
		return leftBlack + (if node.red then 0 else 1)
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
		const left, right = walk(node[1]), walk(node[2])
		assert(math.abs(left - right) <= 1, `{label}: {node.key} 에서 높이 차 {left - right}`)
		assert(node.height == math.max(left, right) + 1, `{label}: {node.key} 의 height 필드 {node.height}`)
		return node.height
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
	assert(root[3] == nil, `{label}: 뿌리의 부모가 nil 이 아님`)
	local function walk(node: RbRead?, parent: RbRead?)
		if node == nil then
			return
		end
		assert(node[3] == parent, `{label}: {node.key} 의 부모 칸`)
		walk(node[1], node)
		table.insert(keys, node.key)
		walk(node[2], node)
	end
	walk(root, nil)
	balanceOf(root, #keys, label)
	for at = 2, #keys do
		assert(keys[at - 1] < keys[at], `{label}: 순서 {keys[at - 1]} >= {keys[at]}`)
	end
	-- 노드 도구의 순회도 같은 순서(앞으로·뒤로)
	local at = 0
	for node in Binary.InOrder(root) do
		at += 1
		assert((node :: any).key == keys[at], `{label}: InOrder {at}`)
	end
	assert(at == #keys, `{label}: InOrder 수`)
	local back, cursor = #keys, Binary.Last(root) :: any
	while cursor ~= nil do
		assert(cursor.key == keys[back], `{label}: Prev {back}`)
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
		assert(
			isNew and root == first and first.key == 50 and first.value == 51 and not first.red,
			"첫 노드는 검정 뿌리"
		)
		check(root, "하나")
		-- 같은 키: 값만 바뀌고 같은 노드
		local again: RbNode
		root, again, isNew = RedBlack.Insert(root, 50, 99, compare)
		assert(not isNew and again == first and first.value == 99, "같은 키는 값만 바꿈")
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
				assert(found ~= nil and found.value == key + 1, `{order}: Find {key}`)
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
			assert((if lower then lower.key else nil) == wantLower, `LowerBound({probe})`)
			assert((if upper then upper.key else nil) == wantUpper, `UpperBound({probe})`)
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
		assert(gone[1] == nil and gone[2] == nil and gone[3] == nil, "뗀 노드는 연결이 끊김")
		assert(
			held.key == 90 and held.value == 91 and RedBlack.Find(root, 90, compare) == held,
			"다른 위치는 그대로"
		)
		assert(Binary.Next(held) == heldNext and heldNext.key == 100, "다음 노드도 그대로")
		assert(RedBlack.Find(root, 80, compare) == nil, "지운 키는 없음")
		check(root, "하나 지운 뒤")
		-- 뿌리를 되풀이해 지움
		local removed = 0
		while root ~= nil do
			root = RedBlack.Remove(root, root)
			removed += 1
			check(root, `뿌리 지우기 {removed}`)
		end
		assert(removed == 14, `뿌리만 지워 다 비움: {removed}`)

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
						assert(model[k] == (RedBlack.Find(tree, k, compare) :: RbRead).value, "값 대조")
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
					got[at] == at * 10 and (RedBlack.Find(root, at * 10, compare) :: RbRead).value == at * 10 + 1,
					"키·값"
				)
			end
			const copy = RedBlack.Clone(root)
			const copied = check(copy, `Clone {count}`)
			assert(#copied == count and (count == 0 or copy ~= root), "Clone 은 새 노드")
			if copy ~= nil and root ~= nil then
				copy.value = -1
				assert(root.value ~= -1, "사본을 고쳐도 원본은 그대로")
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

print("=== 5. Node 의 연결 방식별 도구 ===")
do
	-- 단방향: 내 뒤에 넣기·내 뒤를 떼기
	const a, b, c = Node.New("a", 1), Node.New("b", 1), Node.New("c", 1)
	assert(Node.Single.InsertNext(a, c) == c and a[1] == c and c[1] == nil, "Single.InsertNext")
	Node.Single.InsertNext(a, b)
	assert(a[1] == b and b[1] == c and Node.Count(a, 1) == 3, "가운데에 InsertNext")
	assert(Node.Single.RemoveNext(a) == b and a[1] == c and b[1] == nil, "RemoveNext")
	assert(Node.Single.RemoveNext(c) == nil, "뒤가 없으면 nil")

	-- 양방향: 넣기는 양쪽 연결을 다 고치고, 떼기는 이웃을 돌려줌
	const x, y, z = Node.New(10), Node.New(20), Node.New(30)
	assert(Node.Double.InsertNext(x, z) == z and x[2] == z and z[1] == x and z[2] == nil, "Double.InsertNext(꼬리)")
	assert(Node.Double.InsertNext(x, y) == y and x[2] == y and y[1] == x and y[2] == z and z[1] == y, "가운데")
	const w = Node.New(5)
	assert(Node.Double.InsertPrev(x, w) == w and w[1] == nil and w[2] == x and x[1] == w, "Double.InsertPrev(머리)")
	const v = Node.New(25)
	Node.Double.InsertPrev(z, v)
	assert(y[2] == v and v[1] == y and v[2] == z and z[1] == v, "InsertPrev 가운데")
	assert(Node.Count(w, 2) == 5 and Node.Count(z, 1) == 5, "앞뒤로 다섯")
	local before, after = Node.Double.Unlink(v)
	assert(before == y and after == z and y[2] == z and z[1] == y and v[1] == nil and v[2] == nil, "Unlink 가운데")
	before, after = Node.Double.Unlink(w)
	assert(before == nil and after == x and x[1] == nil, "Unlink 머리 — 앞 이웃이 nil")
	before, after = Node.Double.Unlink(z)
	assert(before == y and after == nil and y[2] == nil, "Unlink 꼬리 — 뒤 이웃이 nil")
	const lone = Node.New(1)
	before, after = Node.Double.Unlink(lone)
	assert(before == nil and after == nil, "외톨이 Unlink")

	-- 이진: 회전은 부모의 자식 칸과 부모 칸 셋을 다 고치고, 중위 순서를 바꾸지 않음
	local function bnode(value: number): stl.Node<number>
		return { nil, nil, nil, value = value } :: any
	end
	local function link(parent: stl.Node<number>, slot: number, child: stl.Node<number>)
		parent[slot] = child
		child[3] = parent
	end
	local function inorder(root: stl.NodeRead<number>): string
		const out: { string } = {}
		for node in Binary.InOrder(root) do
			table.insert(out, tostring(node.value))
		end
		return table.concat(out, ",")
	end
	--        40
	--      20    60
	--    10 30  50 70
	const n10, n20, n30, n40, n50, n60, n70 =
		bnode(10), bnode(20), bnode(30), bnode(40), bnode(50), bnode(60), bnode(70)
	link(n40, 1, n20)
	link(n40, 2, n60)
	link(n20, 1, n10)
	link(n20, 2, n30)
	link(n60, 1, n50)
	link(n60, 2, n70)
	assert(inorder(n40) == "10,20,30,40,50,60,70", "InOrder")
	assert(Binary.First(n40) == n10 and Binary.Last(n40) == n70 and Binary.First(n60) == n50, "First·Last")
	assert(Binary.Next(n30) == n40 and Binary.Next(n40) == n50 and Binary.Next(n70) == nil, "Next")
	assert(Binary.Prev(n50) == n40 and Binary.Prev(n40) == n30 and Binary.Prev(n10) == nil, "Prev")
	assert(Binary.Height(n40) == 3 and Binary.Height(nil :: stl.NodeRead<number>?) == 0, "Height")
	-- 가운데 노드를 회전(부모가 있음)
	assert(Binary.RotateLeft(n20) == n30, "RotateLeft 가 올라온 노드를 돌려줌")
	assert(n40[1] == n30 and n30[3] == n40 and n30[1] == n20 and n20[3] == n30 and n20[2] == nil, "RotateLeft 연결")
	assert(inorder(n40) == "10,20,30,40,50,60,70", "회전은 순서를 안 바꿈")
	assert(
		Binary.RotateRight(n30) == n20 and n40[1] == n20 and n20[2] == n30 and n30[3] == n20,
		"RotateRight 로 되돌림"
	)
	-- 뿌리를 회전: 올라온 노드의 부모가 nil(새 뿌리), 안쪽 자식이 건너감
	const top = Binary.RotateLeft(n40)
	assert(top == n60 and n60[3] == nil and n60[1] == n40 and n40[3] == n60, "뿌리 RotateLeft")
	assert(n40[2] == n50 and n50[3] == n40, "안쪽 자식이 건너감")
	assert(inorder(n60) == "10,20,30,40,50,60,70", "뿌리 회전 뒤 순서")
	assert(Binary.RotateRight(n60) == n40 and n40[3] == nil and n60[1] == n50 and n50[3] == n60, "뿌리 RotateRight")
	-- Replace: 자리만 바꿔 달고 뿌리였는지 알려 줌
	const fresh = bnode(65)
	assert(Binary.Replace(n70, fresh) == false and n60[2] == fresh and fresh[3] == n60, "Replace 잎")
	assert(Binary.Replace(n10, nil) == false and n20[1] == nil, "Replace 를 nil 로(떼기)")
	assert(inorder(n40) == "20,30,40,50,60,65", "Replace 뒤 순서")
	const newRoot = bnode(1)
	assert(Binary.Replace(n40, newRoot) == true and newRoot[3] == nil, "뿌리의 Replace 는 true")
	local never = 0
	for _ in Binary.InOrder(nil :: stl.NodeRead<number>?) do
		never += 1
	end
	assert(never == 0, "InOrder(nil)")
end
print("PASS")

print()
print("=== ALL PASS (트리부·Node 도구) ===")

return true
