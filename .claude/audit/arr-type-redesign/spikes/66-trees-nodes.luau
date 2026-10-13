--!strict
--[[
	66 — 트리부(RedBlack·Avl)와 Node 도구의 음성 대조군 (2026-10-13).

	지키는 성질: 찾기는 옵셔널 / 키·값 타입 / `Insert` 의 세 반환 / 밖으로 나온 노드(`RbNodeRead`)는 읽기 전용 /
	두 방식의 노드는 서로 다른 타입 / `Remove` 는 뿌리가 있어야 하고 비면 `nil` 을 돌려줌 / 비교자의 타입 /
	노드 도구의 인자(노드여야 함, 읽기 노드는 고치는 도구에 못 들어감) / 균형 계약에 모양이 다른 것은 안 들어감.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 19 + CANARY 1)
]]
local stl = require("../../../../src")
local RedBlack, Avl, Node = stl.RedBlack, stl.Avl, stl.Node
type RbNode = stl.RbNode<string, number>

local compare = stl.Common.compareString
local root, node, isNew = RedBlack.Insert(nil :: RbNode?, "a", 1, compare)

--[[ POS ]]
local okRoot: RbNode = root
local okNew: boolean = isNew
local found: stl.RbNodeRead<string, number>? = RedBlack.Find(root, "a", compare)
local value: number? = if found then stl.Search.Value(found) else nil
local foundKey: string? = if found then stl.Search.Key(found) else nil
local after: RbNode? = RedBlack.Remove(root, node)
local avlRoot: stl.AvlNode<string, number> = (Avl.Insert(nil :: stl.AvlNode<string, number>?, "a", 1, compare))
local nextNode: stl.BinaryNodeRead<number>? = Node.Binary.Next(Node.Binary.New(1))
-- 트리 노드를 따라갈 땐 `Search` 의 것(키 타입이 그대로). `Node.Binary.Next(트리노드)` 는 `NodeRead<K | V>` 로 넓어짐
local viaSearch: stl.RbNodeRead<string, number>? = stl.Search.Next(found :: stl.RbNodeRead<string, number>) :: any
local nextKey: stl.KeyNodeRead<string, number>? = stl.Search.Next(root)
local firstKey: string = stl.Search.Key(stl.Search.First(root))
local asBalance: stl.TreeBalance = RedBlack
local avlBalance: stl.TreeBalance = Avl
local copy: RbNode? = RedBlack.Clone(root)

--[[ NEG ]]
-- 찾기는 옵셔널
local negFind: stl.RbNodeRead<string, number> = RedBlack.Find(root, "a", compare)
local negBound: stl.RbNodeRead<string, number> = RedBlack.LowerBound(root, "a", compare)
-- 키·값 타입
RedBlack.Insert(root, 5, 1, compare)
RedBlack.Insert(root, "b", "not a number", compare)
local negFindKey = RedBlack.Find(root, 5, compare)
-- 셋째 반환은 불리언
local _r, _n, negIsNew: number = RedBlack.Insert(root, "c", 3, compare)
-- 밖으로 나온 노드는 읽기 전용
if found then
	found.value = 99
	found[1] = nil
	Node.Binary.SetValue(found, 99)
end
-- 두 방식의 노드는 서로 다른 타입
local negCross: RbNode = avlRoot
local negCrossRemove = RedBlack.Remove(root, avlRoot)
-- Remove 는 뿌리가 있어야 하고(옵셔널을 못 받음) 비면 nil 을 돌려줌
local negRemoved: RbNode = RedBlack.Remove(root, node)
-- 비교자의 타입
RedBlack.Insert(root, "d", 4, stl.Common.compareNumber)
-- 노드 도구: 노드여야 하고, 읽기 노드는 고치는 도구에 못 들어감
local negNotNode = Node.Binary.Next(5)
local readOnly: stl.BinaryNodeRead<number> = Node.Binary.New(1)
Node.Binary.RotateLeft(readOnly)
-- 균형 계약에 모양이 다른 것은 안 들어감
local negBalance: stl.TreeBalance = { Insert = RedBlack.Insert, Remove = RedBlack.Remove }

-- 노드의 종류는 타입으로 갈림: 양방향 노드는 이진 도구에 못 들어가고, 옵셔널 자리에서도 값 타입을 지킴
local negKind = Node.Binary.Next(Node.Double.New(1))
local negOptionalNode: stl.BinaryNodeRead<string>? = Node.Binary.Next(Node.Binary.New(1))
local negKeyType: number = stl.Search.Key(root)

local canary: string = 42

return {
	okRoot,
	okNew,
	value,
	after,
	nextNode,
	asBalance,
	avlBalance,
	copy,
	negFind,
	negBound,
	negFindKey,
	negIsNew,
	negCross,
	negCrossRemove,
	negRemoved,
	negNotNode,
	negBalance,
	foundKey,
	viaSearch,
	nextKey,
	firstKey,
	negKind,
	negOptionalNode,
	negKeyType,
	canary,
}
