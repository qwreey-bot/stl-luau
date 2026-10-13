--!strict
--[[
	stl-luau — Luau 용 표준 라이브러리 스타일 컨테이너/알고리즘 모음.

	이 파일은 **배럴**입니다. 공개 표면을 한곳에 모아 재수출하기만 하고
	로직을 두지 않습니다.

	## require 경로 규칙 (직관과 반대라 주의)

	`init.luau` 는 곧 그 디렉터리 자신이라 `.` 이 **부모**를 가리킵니다.

	| 어디서 | 폴더 **안** 형제 | 폴더 **밖** 형제 |
	|---|---|---|
	| `Foo/init.luau` | `@self/Bar` | `./Types` (`../Types` 는 실패) |
	| `Foo/Bar.luau` | `./Baz` | `../Types` (`./Types` 는 실패) |

	⚠️ 틀린 경로를 써도 `luau-analyze` 는 **진단 0건으로 통과하고 런타임에서만
	크래시합니다.** 그래서 `scripts/check.sh` 가 모든 모듈을 실제로 require 해
	봅니다. `init.luau` 를 새로 추가할 땐 반드시 그 게이트를 돌리세요.
]]
local Types = require("@self/Types")
local Common = require("@self/Common")
local Trait = require("@self/Trait")
local List = require("@self/Traits/List")
local Map = require("@self/Traits/Map")
local Set = require("@self/Traits/Set")
local Collection = require("@self/Traits/Collection")
local Deque = require("@self/Traits/Deque")
local Node = require("@self/Node")
local NodeSingle = require("@self/Node/Single")
local NodeDouble = require("@self/Node/Double")
local NodeBinary = require("@self/Node/Binary")
local RedBlack = require("@self/Trees/RedBlack")
local Avl = require("@self/Trees/Avl")
local Search = require("@self/Trees/Search")
local BSearch = require("@self/Algorithms/BSearch")
local Arr = require("@self/Collections/Arr")
local HashMap = require("@self/Collections/HashMap")
local HashSet = require("@self/Collections/HashSet")
local FlatMap = require("@self/Collections/FlatMap")
local TreeMap = require("@self/Collections/TreeMap")
local TreeSet = require("@self/Collections/TreeSet")
local FlatSet = require("@self/Collections/FlatSet")
local Heap = require("@self/Collections/Heap")
local CircularDeque = require("@self/Collections/CircularDeque")
local LinkedDeque = require("@self/Collections/LinkedDeque")
local Optional = require("@self/Optional")
local Fut = require("@self/Fut")

-- 계약 타입은 최상위에서도 보이게 재수출합니다.
export type Comparator<T> = Types.Comparator<T>
export type LessThan<T> = Types.LessThan<T>
export type Hasher<T> = Types.Hasher<T>
export type Record<K, V> = Types.Record<K, V>
export type ListOps<C, E, I> = List.Ops<C, E, I>
export type ListFull<C, E, I> = List.Full<C, E, I>
export type ListImpl<C, E, I> = List.Impl<C, E, I>
export type MapOps<C, K, V> = Map.Ops<C, K, V>
export type SetOps<C, T> = Set.Ops<C, T>
export type ListMarker<E, I> = List.Marker<E, I>
export type MapMarker<K, V> = Map.Marker<K, V>
export type SetMarker<T> = Set.Marker<T>
export type ListMarkerMut<E, I> = List.MarkerMut<E, I>
export type MapMarkerMut<K, V> = Map.MarkerMut<K, V>
export type SetMarkerMut<T> = Set.MarkerMut<T>
export type CollectionOps<C> = Collection.Ops<C>
export type CollectionMarker = Collection.Marker
export type CollectionMarkerMut = Collection.MarkerMut
export type DequeOps<C, T> = Deque.Ops<C, T>
export type DequeMarker<T> = Deque.Marker<T>
export type DequeMarkerMut<T> = Deque.MarkerMut<T>
-- 노드(종류별 불투명 핸들 — `src/Node/` 머리). 읽기 타입은 컨테이너가 밖으로 내주는 위치.
export type SingleNode<T> = NodeSingle.Node<T>
export type SingleNodeRead<T> = NodeSingle.NodeRead<T>
export type DoubleNode<T> = NodeDouble.Node<T>
export type DoubleNodeRead<T> = NodeDouble.NodeRead<T>
export type BinaryNode<T> = NodeBinary.Node<T>
export type BinaryNodeRead<T> = NodeBinary.NodeRead<T>
export type RbNode<K, V> = RedBlack.RbNode<K, V>
export type RbNodeRead<K, V> = RedBlack.RbNodeRead<K, V>
export type AvlNode<K, V> = Avl.AvlNode<K, V>
export type AvlNodeRead<K, V> = Avl.AvlNodeRead<K, V>
export type TreeBalance = Search.Balance
export type KeyNodeRead<K, V> = Search.KeyNodeRead<K, V>
export type TraitToken<N> = Trait.Token<N>
export type Trait<I, C = I> = Trait.Trait<I, C>
export type TraitSpec = Trait.TraitSpec
export type TraitDefaults = Trait.Defaults

-- 컨테이너 타입
export type Arr<T> = Arr.Arr<T>
export type ArrData<T> = Arr.ArrData<T>
export type ArrView<T> = Arr.ArrView<T>
export type ArrRead<T> = Arr.ArrRead<T>
export type Pair<T, U> = Arr.Pair<T, U>
export type HashMap<K, V> = HashMap.HashMap<K, V>
export type HashSet<T> = HashSet.HashSet<T>
export type FlatMap<K, V> = FlatMap.FlatMap<K, V>
export type TreeMap<K, V> = TreeMap.TreeMap<K, V>
export type TreeSet<T> = TreeSet.TreeSet<T>
export type FlatSet<T> = FlatSet.FlatSet<T>
export type Heap<T> = Heap.Heap<T>
export type CircularDeque<T> = CircularDeque.CircularDeque<T>
export type CircularDequeRead<T> = CircularDeque.CircularDequeRead<T>
export type LinkedDeque<T> = LinkedDeque.LinkedDeque<T>
export type LinkedDequeRead<T> = LinkedDeque.LinkedDequeRead<T>
export type Optional<T> = Optional.Optional<T>
export type Fut<T...> = Fut.Fut<T...>
export type FutStatus = Fut.Status
export type FutScheduler = Fut.Scheduler
export type FutProvider = Fut.Provider

return {
	Common = Common,
	Trait = Trait,
	BSearch = BSearch,

	-- 트레이트. 모듈이 곧 트레이트 객체라 `Trait.Impl(stl.List, 토큰, 구현)` 과 종류를 모르는 코드의
	-- 진입점 `stl.List.IndexOf(값, x)` 가 같은 이름으로 됩니다.
	List = List,
	Map = Map,
	Set = Set,
	Collection = Collection,
	Deque = Deque,

	-- 컨테이너 밖의 노드 조각(연결 리스트·트리가 조립해 씀)
	Node = Node,
	-- 트리부 — 노드 도구로 짠 균형 방식(컨테이너가 아니라 뿌리 노드를 받는 함수들). `FlatMap` 등이 조립해 씀
	RedBlack = RedBlack,
	Avl = Avl,
	-- 균형 방식과 무관한 공유 조각(찾기·경계·베끼기)과 탐색 트리 노드의 칸 배치·접근 함수
	Search = Search,

	-- 컨테이너 네임스페이스. **순수 테이블입니다** — 콜러블로 만들면 제네릭
	-- 생성자가 타입 인자를 잃고 모듈 오타도 못 잡습니다(실측).
	Arr = Arr,
	HashMap = HashMap,
	HashSet = HashSet,
	FlatMap = FlatMap,
	TreeMap = TreeMap,
	TreeSet = TreeSet,
	FlatSet = FlatSet,
	Heap = Heap,
	CircularDeque = CircularDeque,
	LinkedDeque = LinkedDeque,
	Optional = Optional,
	Fut = Fut,

	-- 술어는 camelCase 로 최상위에 둡니다.
	isArr = Arr.isArr,
	isHashMap = HashMap.isHashMap,
	isHashSet = HashSet.isHashSet,
	isFlatMap = FlatMap.isFlatMap,
	isTreeMap = TreeMap.isTreeMap,
	isTreeSet = TreeSet.isTreeSet,
	isFlatSet = FlatSet.isFlatSet,
	isHeap = Heap.isHeap,
	isCircularDeque = CircularDeque.isCircularDeque,
	isLinkedDeque = LinkedDeque.isLinkedDeque,
	isOptional = Optional.isOptional,
	isFut = Fut.isFut,
}
