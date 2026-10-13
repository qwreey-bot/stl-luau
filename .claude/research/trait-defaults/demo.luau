--!strict
-- 시제품이 도는지: 종류를 모르는 코드가 같은 알고리즘을 리스트 셋·트리 둘에 (papers/07)
local stl = require("../../../src")
local Trait2 = require("./Trait2")
local Traits = require("./Traits")
local C = require("./Containers")

local function listOf(make: () -> any, push: (any, number) -> any): any
	const list = make()
	for _, v in { 30, 10, 20, 40 } do
		push(list, v)
	end
	return list
end
const lists: { [string]: any } = {
	Arr = listOf(function()
		return stl.Arr.Of()
	end, stl.Arr.PushBack),
	Deque = listOf(function()
		return stl.Deque.New()
	end, stl.Deque.PushBack),
	LinkedList = listOf(C.LinkedList.New, C.LinkedList.PushBack),
}
for name, list in lists do
	const ops = Trait2.ImplOf(Traits.List, list)
	const seq = Trait2.ImplOf(Traits.Seq, list)
	assert(ops.Fold(list, 0, function(acc: number, v: number)
		return acc + v
	end) == 100, `{name} Fold`)
	assert(ops.Find(list, function(v: number)
		return v > 25
	end) == 30, `{name} Find`)
	assert(ops.Contains(list, 20) and not ops.Contains(list, 99), `{name} Contains`)
	assert(ops.Count(list) == 4, `{name} Count`)
	assert(table.concat(ops.ToTable(list), ",") == "30,10,20,40", `{name} ToTable`)
	-- Map·Filter 는 **같은 종류**를 돌려줌(Build 를 요구하는 Seq)
	const doubled = seq.Map(list, function(v: number)
		return v * 2
	end)
	assert(rawget(doubled, "__type") == rawget(list, "__type"), `{name} Map 은 같은 종류`)
	assert(table.concat(ops.ToTable(doubled), ",") == "60,20,40,80", `{name} Map`)
	const big = seq.Filter(list, function(v: number)
		return v >= 20
	end)
	assert(table.concat(ops.ToTable(big), ",") == "30,20,40", `{name} Filter`)
end
-- 재정의가 이김: LinkedList.Count 는 세지 않는 자기 판
assert(Traits.List.impls[rawget(lists.LinkedList, "__type")].Count == C.LinkedList.Count, "재정의")
-- 의존이 빠지면 등록이 거절되고, 저절로도 안 따라옴
const Orphan = stl.Trait.NewType("Orphan")
assert(not pcall(function()
	Trait2.Impl(Traits.Seq, Orphan, {})
end), "List·Build 없이 Seq 는 안 됨")
assert(Trait2.ImplOf(Traits.Seq, { __type = Orphan }) == nil, "의존이 없으면 Seq 도 없음")
-- ⭐ Seq 는 Deque·LinkedList 가 **등록한 적이 없음** — List 와 Build 를 구현했으니 저절로
assert(
	Trait2.ImplOf(Traits.Seq, lists.Deque) ~= nil and Trait2.ImplOf(Traits.Seq, lists.LinkedList) ~= nil,
	"저절로"
)
-- Arr 는 자기 빠른 판으로 재정의해 둠
assert(Trait2.ImplOf(Traits.Seq, lists.Arr).Map == stl.Arr.Map, "Arr 는 재정의")

-- ⭐ 바깥에서 새 트레이트를 더하기: 컨테이너 셋을 **고치지 않고** 전부에 적용됨.
-- 트레이트가 자기에게 필요한 것(List)을 알고, 그걸 갖춘 종류는 따라옴.
const Stats = Trait2.New("Stats", {
	required = {},
	requires = { Traits.List },
	defaults = function(_impl, _full, deps)
		const fold = deps[Traits.List].Fold
		return {
			Sum = function(self: any): number
				return fold(self, 0, function(acc: number, v: number)
					return acc + v
				end)
			end,
			Max = function(self: any): number
				return fold(self, -math.huge, function(acc: number, v: number)
					return math.max(acc, v)
				end)
			end,
		}
	end,
})
for name, list in lists do
	const stats = Trait2.ImplOf(Stats, list)
	assert(stats ~= nil and stats.Sum(list) == 100 and stats.Max(list) == 40, `{name} 은 Stats 를 저절로 구현`)
end

-- 트리: 노드 트리(BST)와 배열 트리가 같은 순회·높이
const bst = C.LinkedTree.New()
for _, v in { 50, 30, 70, 20, 40, 60, 80 } do
	C.Bst.Insert(bst, v, function(a: number, b: number): number
		return a - b
	end)
end
const arrayTree = C.ArrayTree.FromList({ 50, 30, 70, 20, 40, 60, 80 })
for name, tree in { Bst = bst, ArrayTree = arrayTree } :: { [string]: any } do
	const ops = Trait2.ImplOf(Traits.Tree, tree)
	const function walk(order: string): string
		const seen: { number } = {}
		ops[order](tree, function(value: number)
			table.insert(seen, value)
		end)
		return table.concat(seen, ",")
	end
	assert(walk("Inorder") == "20,30,40,50,60,70,80", `{name} Inorder: {walk("Inorder")}`)
	assert(walk("Preorder") == "50,30,20,40,70,60,80", `{name} Preorder`)
	assert(walk("Postorder") == "20,40,30,60,80,70,50", `{name} Postorder`)
	assert(ops.Height(tree) == 3 and ops.Size(tree) == 7, `{name} Height/Size`)
end
print("demo OK")
return {}
