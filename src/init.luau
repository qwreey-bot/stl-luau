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
local Stack = require("@self/Traits/Stack")
local Queue = require("@self/Traits/Queue")
local Node = require("@self/Node")
local NodeSingle = require("@self/Node/Single")
local NodeDouble = require("@self/Node/Double")
local NodeBinary = require("@self/Node/Binary")
local RedBlack = require("@self/Trees/RedBlack")
local Avl = require("@self/Trees/Avl")
local Search = require("@self/Trees/Search")
local Traverse = require("@self/Trees/Traverse")
local CompleteArray = require("@self/Trees/CompleteArray")
local CompleteNode = require("@self/Trees/CompleteNode")
local SortedArray = require("@self/Trees/SortedArray")
local Balance = require("@self/Trees/Balance")
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
-- ⭐ 트레이트마다(질문 BA — 사용자: *"값은 Trait, 타입은 런타임 데이터에 붙이는 표식"*):
-- - `X<…>` — 그 트레이트를 구현한 **바꿀 수 있는** 값의 타입(완성 표 `X.OfMut` 의 조건). `XRead<…>` — 읽기로 빌린 값도(읽기 보기 `X.Of`).
--   바깥 컨테이너는 자기 타입에 교집합으로 붙입니다(`type MyBag<T> = { … } & stl.Deque<T>`), 바깥에서 붙인 트레이트는 `Trait.Converter`.
-- - `XFull<C, …>` 완성 표, `XReadFull<C, …>` 읽기 보기, `XProvided<C, …>` 등록 표.
export type List<E, I> = List.Value<E, I>
export type ListRead<E, I> = List.ValueRead<E, I>
export type ListFull<C, E, I> = List.Full<C, E, I>
export type ListProvided<C, E, I> = List.Provided<C, E, I>
export type Map<K, V> = Map.Value<K, V>
export type MapRead<K, V> = Map.ValueRead<K, V>
export type MapFull<C, K, V> = Map.Full<C, K, V>
export type MapReadFull<C, K, V> = Map.ReadFull<C, K, V>
export type MapProvided<C, K, V> = Map.Provided<C, K, V>
export type Set<T> = Set.Value<T>
export type SetRead<T> = Set.ValueRead<T>
export type SetFull<C, T> = Set.Full<C, T>
export type SetReadFull<C, T> = Set.ReadFull<C, T>
export type SetProvided<C, T> = Set.Provided<C, T>
export type Collection = Collection.Value
export type CollectionRead = Collection.ValueRead
export type CollectionFull<C> = Collection.Full<C>
export type CollectionReadFull<C> = Collection.ReadFull<C>
export type CollectionProvided<C> = Collection.Provided<C>
export type Deque<T> = Deque.Value<T>
export type DequeRead<T> = Deque.ValueRead<T>
export type DequeFull<C, T> = Deque.Full<C, T>
export type DequeReadFull<C, T> = Deque.ReadFull<C, T>
export type DequeProvided<C, T> = Deque.Provided<C, T>
export type Stack<T> = Stack.Value<T>
export type StackRead<T> = Stack.ValueRead<T>
export type StackFull<C, T> = Stack.Full<C, T>
export type StackReadFull<C, T> = Stack.ReadFull<C, T>
export type StackProvided<C, T> = Stack.Provided<C, T>
export type Queue<T> = Queue.Value<T>
export type QueueRead<T> = Queue.ValueRead<T>
export type QueueFull<C, T> = Queue.Full<C, T>
export type QueueReadFull<C, T> = Queue.ReadFull<C, T>
export type QueueProvided<C, T> = Queue.Provided<C, T>
-- 연관 타입 레코드 — **바깥 컨테이너를 만드는 쪽**이 자기 타입의 `__traits` 필드에 나열합니다(Rust 의 `impl` 자리):
--   `type MyMap<K, V> = { …, read __type: stl.TraitToken<"My.Map">, read __traits: { read Map: stl.MapAssoc<K, V>, read Collection: stl.CollectionAssoc } }`
-- (빌린 읽기 타입은 `…AssocRead`). ⚠️ `{ … } & stl.Map<K, V>` 처럼 **교집합으로 적지 마세요** — `GroupBy` 처럼 `C & Map<K, V>` 를 받아 `C` 를
-- 돌려주는 제네릭을 거치면 `C` 가 유니온으로 풀려 필드를 잃습니다(상류 결함 후보, `research/trait-ofmut/intersection-generic-repro.luau`).
export type ListAssoc<E, I> = List.Assoc<E, I>
export type ListAssocRead<E, I> = List.AssocRead<E, I>
export type MapAssoc<K, V> = Map.Assoc<K, V>
export type MapAssocRead<K, V> = Map.AssocRead<K, V>
export type SetAssoc<T> = Set.Assoc<T>
export type SetAssocRead<T> = Set.AssocRead<T>
export type CollectionAssoc = Collection.Assoc
export type DequeAssoc<T> = Deque.Assoc<T>
export type DequeAssocRead<T> = Deque.AssocRead<T>
export type StackAssoc<T> = Stack.Assoc<T>
export type StackAssocRead<T> = Stack.AssocRead<T>
export type QueueAssoc<T> = Queue.Assoc<T>
export type QueueAssocRead<T> = Queue.AssocRead<T>
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
export type TreeBalance = Balance.Scheme
export type KeyNodeRead<K, V> = Search.KeyNodeRead<K, V>
export type TraitToken<N> = Trait.Token<N>
export type TraitAnyKind = Trait.AnyKind
-- 탐침 타입 — 바깥 구현자가 등록 표를 주석 단 지역에 적을 때(`const impl: stl.MapProvided<My<stl.TraitA, stl.TraitB>, stl.TraitA, stl.TraitB>`).
-- 서로 다른 불투명 타입이라 원소를 못박은 함수가 샙니다(`any` 로 적으면 인자 수·인자 타입이 0건 — 리뷰 1라운드 T5: 배럴에 없어 `src/Trait` 를 직접 require 해야 했음)
export type TraitA = Trait.A
export type TraitB = Trait.B
export type TraitC = Trait.C
export type TraitObject<R, F, G> = Trait.Object<R, F, G>

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
	-- 덱이면 저절로 따라오는 트레이트(필수 함수 없음, 의존 `Deque`) — 스택(LIFO)·큐(FIFO)
	Stack = Stack,
	Queue = Queue,

	-- 컨테이너 밖의 노드 조각(연결 리스트·트리가 조립해 씀)
	Node = Node,
	-- 트리부 — 노드 도구로 짠 균형 방식(컨테이너가 아니라 뿌리 노드를 받는 함수들). `TreeMap` 등이 조립해 씀
	RedBlack = RedBlack,
	Avl = Avl,
	-- 균형 방식과 무관한 공유 조각(찾기·경계·베끼기)과 탐색 트리 노드의 칸 배치·접근 함수
	Search = Search,
	-- 이진 트리의 순회자(전위·중위·후위·층별) — 받은 부분 트리 안에서만 돎
	Traverse = Traverse,
	-- 배열에 담은 완전 이진 트리 — 자리 계산과 힙 순서를 지키는 도구(`Heap` 이 조립해 씀)
	CompleteArray = CompleteArray,
	-- 노드로 이은 완전 이진 트리 — 자리 찾기·맨 뒤 붙이기/떼기·노드 자리 맞바꾸기, 힙 순서(노드가 곧 위치)
	CompleteNode = CompleteNode,
	-- 정렬 배열로 된 탐색 구조 — 찾기와 밀고 당기는 넣기·빼기(`FlatMap`·`FlatSet` 이 조립해 씀)
	SortedArray = SortedArray,
	-- 자가 균형의 계약(`Balance.Scheme`)과 조립하는 쪽의 인자 확인(`Balance.Expect`)
	Balance = Balance,

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
