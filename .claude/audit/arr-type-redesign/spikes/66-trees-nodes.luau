--!strict
--[[
	66 — 트리부(RedBlack·Avl)와 Node 도구의 음성 대조군 (2026-10-13).

	지키는 성질: 찾기는 옵셔널 / 키·값 타입 / `Insert` 의 세 반환 / 밖으로 나온 노드(`RbNodeRead`)는 읽기 전용 /
	두 방식의 노드는 서로 다른 타입 / `Remove` 는 뿌리가 있어야 하고 비면 `nil` 을 돌려줌 / 비교자의 타입 /
	노드 도구의 인자(노드여야 함, 읽기 노드는 고치는 도구에 못 들어감) / 균형 계약에 모양이 다른 것은 안 들어감.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 57 + CANARY 1)
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
-- 트리 노드를 따라가도 그 타입 그대로(`Search.Next` 든 `Node.Binary.Next` 든 — 예전엔 뒤의 것이 `NodeRead<K | V>` 로 넓어졌음)
local viaSearch: stl.RbNodeRead<string, number>? = if found then Node.Binary.Next(found) else nil
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

--[[ 리뷰 1라운드(2026-10-13) — 찾기·따라가기는 받은 노드의 타입 그대로 ]]
-- POS: 균형 방식의 노드를 공유 조각에 그대로(예전엔 값 타입이 unknown) / 따라가 얻은 노드를 그 방식의 Remove 에 /
-- 자기가 만든 사슬·트리는 따라간 뒤에도 고칠 수 있음
local okShared = stl.Search.Find(root, "a", compare)
local okSharedValue: number? = if okShared then stl.Search.Value(okShared) else nil
local okWalkRemove: RbNode? = RedBlack.Remove(root, RedBlack.First(root))
local okNextRead: stl.RbNodeRead<string, number>? = if found then RedBlack.Next(found) else nil
local okChain = Node.Double.New(1)
local okChainNext = Node.Double.Next(okChain)
if okChainNext then
	Node.Double.SetValue(okChainNext, 5)
end
for walked in Node.Double.Walk(okChain) do
	Node.Double.Unlink(walked)
end
-- NEG: 읽기 노드는 따라가도 읽기 노드(고치는 도구에 못 들어감) — 양방향·단방향·이진
local readChain: stl.DoubleNodeRead<number> = okChain
local readNext = Node.Double.Next(readChain)
if readNext then
	Node.Double.SetValue(readNext, 5)
end
for walked in Node.Double.Walk(readChain) do
	Node.Double.Unlink(walked)
end
local readSingle: stl.SingleNodeRead<number> = Node.Single.New(1)
Node.Single.RemoveNext(readSingle)
Node.Binary.SetLeft(readOnly, nil)
-- NEG: 단방향 노드는 다른 종류의 도구에 못 들어감 / 따라간 결과의 값 타입
local negSingleKind = Node.Double.Next(Node.Single.New(1))
local negSharedValue: string? = if okShared then stl.Search.Value(okShared) else nil
-- NEG: Avl 도 같은 서명(찾기는 옵셔널, 값 타입, 뿌리는 옵셔널이 아님)
local avlFound: stl.AvlNodeRead<string, number> = Avl.Find(avlRoot, "a", compare)
Avl.Insert(avlRoot, "b", "not a number", compare)
local negAvlRemove = Avl.Remove(Avl.Find(avlRoot, "a", compare), avlRoot)

--[[ Traverse — 순회자는 받은 노드의 타입 그대로 냄(레드블랙 노드를 돌면 레드블랙 노드 — 그 방식의 Remove 에 넘길 수 있음) ]]
local okTraverse: RbNode? = stl.Traverse.PreOrder(root)()
local okTraverseRead: stl.RbNodeRead<string, number>? = stl.Traverse.InOrder(found)()
local okTraverseRemove: RbNode? = RedBlack.Remove(root, stl.Traverse.PostOrder(root)() :: RbNode)
-- NEG: 다른 방식의 노드로 받기 / 양방향 노드는 이진 순회에 못 들어감 / 읽기 노드를 돌아 얻은 것은 고칠 수 있는 노드가 아님
local negTraverseScheme: stl.AvlNode<string, number>? = stl.Traverse.PostOrder(root)()
local negTraverseKind = stl.Traverse.LevelOrder(Node.Double.New(1))
local negTraverseRead: RbNode? = stl.Traverse.InOrder(found)()

--[[ CompleteArray — 배열에 담은 완전 이진 트리(자리 계산과 힙 순서) ]]
local numbers = { 30, 10, 20 }
local function lessNumber(a: number, b: number): boolean
	return a < b
end
stl.CompleteArray.Heapify(numbers, 3, lessNumber)
local okParent: number? = stl.CompleteArray.Parent(3)
local okIsHeap: boolean = stl.CompleteArray.IsHeap(numbers, 3, lessNumber)
-- NEG: 자리는 옵셔널(뿌리의 부모, 없는 자식) / 원소 타입과 비교자가 어긋남 / `IsHeap` 은 불리언
local negParent: number = stl.CompleteArray.Parent(1)
local negLeft: number = stl.CompleteArray.Left(1, 3)
stl.CompleteArray.SiftUp({ "a", "b" }, 2, lessNumber)
local negIsHeap: number = stl.CompleteArray.IsHeap(numbers, 3, lessNumber)

--[[ CompleteNode — 노드로 이은 완전 이진 트리(노드가 곧 위치) ]]
local cnRoot = stl.CompleteNode.Append(nil :: stl.BinaryNode<number>?, 0, Node.Binary.New(10))
local cnRead: stl.BinaryNodeRead<number> = cnRoot
local okAt: stl.BinaryNode<number>? = stl.CompleteNode.At(cnRoot, 1)
local okSift: stl.BinaryNode<number> = stl.CompleteNode.SiftUp(cnRoot, cnRoot, lessNumber)
local okShape: boolean = stl.CompleteNode.IsComplete(cnRead, 1) and stl.CompleteNode.IsHeap(cnRead, lessNumber)
-- NEG: 자리는 옵셔널 / 양방향 노드는 못 붙임 / 원소 타입과 비교자가 어긋남 / 읽기 노드는 자리를 바꿀 수 없음
local negAt: stl.BinaryNode<number> = stl.CompleteNode.At(cnRoot, 2)
stl.CompleteNode.Append(cnRoot, 1, Node.Double.New(20))
stl.CompleteNode.SiftDown(cnRoot, cnRoot, string.lower)
stl.CompleteNode.Exchange(cnRoot, cnRoot, cnRead)

--[[ 3라운드 리뷰가 짚은 빈 곳 — 순회자 넷 각각의 종류·옵셔널, 내리기·한 번에 짓기의 비교자 ]]
-- NEG: 종류가 다른 노드(순회자마다) / 순회자가 내는 것은 옵셔널(끝나면 nil — 순회자마다)
local negPreKind = stl.Traverse.PreOrder(Node.Double.New(1))
local negInKind = stl.Traverse.InOrder(Node.Single.New(1))
local negPostKind = stl.Traverse.PostOrder(Node.Double.New(1))
local negPreEnd: RbNode = stl.Traverse.PreOrder(root)()
local negInEnd: RbNode = stl.Traverse.InOrder(root)()
local negPostEnd: RbNode = stl.Traverse.PostOrder(root)()
local negLevelEnd: RbNode = stl.Traverse.LevelOrder(root)()
-- NEG: 원소 타입과 비교자가 어긋남(내리기 / 한 번에 짓기)
stl.CompleteArray.SiftDown({ "a", "b" }, 2, 1, lessNumber)
stl.CompleteArray.Heapify({ "a", "b" }, 2, lessNumber)

--[[ SortedArray — 정렬 배열로 된 탐색 구조(찾기, 밀고 당기는 넣기·빼기) ]]
local sortedList = { 10, 20, 30 }
local function probeNumber(item: number, key: number): number
	return item - key
end
local okPos, okFound = stl.SortedArray.Locate(sortedList, 3, 20, probeNumber)
local okRemoved: number = stl.SortedArray.RemoveAt(sortedList, 3, 1)
-- NEG: 자리와 "있는가" 의 타입 / 원소 타입이 다른 것을 끼워 넣음 / 키 타입과 probe 가 어긋남 / 뺀 것의 타입
local negLocatePos: string = okPos
local negLocateFound: number = okFound
stl.SortedArray.InsertAt(sortedList, 2, 1, "ten")
stl.SortedArray.Locate(sortedList, 2, "20", probeNumber)
local negRemovedType: string = stl.SortedArray.RemoveAt(sortedList, 2, 1)

--[[ Balance.Split — 받은 뿌리의 타입 그대로 셋을 돌려줌(5라운드 리뷰: 전부 `any` 라 키 타입·노드 핸들을 잃었음) ]]
local splitRoot = (RedBlack.Insert(nil :: RbNode?, "m", 1, compare))
local okSmall, okMid, okLarge = stl.Balance.Split(RedBlack, splitRoot, "k", compare)
local okSmallTyped: RbNode? = okSmall
local okRejoined: RbNode? = if okMid then RedBlack.Join(okSmall, okMid, okLarge) else okLarge
-- NEG: 키 타입 / 돌려받은 뿌리를 다른 타입으로 / 가운데 노드는 옵셔널
stl.Balance.Split(RedBlack, splitRoot, 5, compare)
local negSplitRoot: string = okSmall
local negSplitMid: RbNode = okMid
-- NEG: 읽기 노드(컨테이너가 내준 뿌리 같은 것)는 가를 수 없음 — 원래 트리를 없애는 도구
stl.Balance.Split(RedBlack, found, "k", compare)

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
	okSharedValue,
	okWalkRemove,
	okNextRead,
	negSingleKind,
	negSharedValue,
	avlFound,
	negAvlRemove,
	okTraverse,
	okTraverseRead,
	okTraverseRemove,
	negTraverseScheme,
	negTraverseKind,
	negTraverseRead,
	okParent,
	okIsHeap,
	negParent,
	negLeft,
	negIsHeap,
	okAt,
	okSift,
	okShape,
	negAt,
	negPreKind,
	negInKind,
	negPostKind,
	negPreEnd,
	negInEnd,
	negPostEnd,
	negLevelEnd,
	okRemoved,
	negLocatePos,
	negLocateFound,
	negRemovedType,
	okSmallTyped,
	okRejoined,
	negSplitRoot,
	negSplitMid,
	canary,
}
