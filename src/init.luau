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
local Algorithm = require("@self/Algorithm")
local BSearch = require("@self/BSearch")
local Arr = require("@self/Arr")
local HashMap = require("@self/HashMap")
local HashSet = require("@self/HashSet")
local TreeMap = require("@self/TreeMap")
local TreeSet = require("@self/TreeSet")
local Heap = require("@self/Heap")
local Optional = require("@self/Optional")

-- 계약 타입은 최상위에서도 보이게 재수출합니다.
export type Comparator<T> = Types.Comparator<T>
export type LessThan<T> = Types.LessThan<T>
export type Hasher<T> = Types.Hasher<T>
export type Record<K, V> = Types.Record<K, V>
export type ListCore<E, I> = Types.ListCore<E, I>
export type MapCore<K, V> = Types.MapCore<K, V>
export type SetCore<T> = Types.SetCore<T>

-- 컨테이너 타입
export type Arr<T> = Arr.Arr<T>
export type ArrData<T> = Arr.ArrData<T>
export type ArrView<T> = Arr.ArrView<T>
export type HashMap<K, V> = HashMap.HashMap<K, V>
export type HashSet<T> = HashSet.HashSet<T>
export type TreeMap<K, V> = TreeMap.TreeMap<K, V>
export type TreeSet<T> = TreeSet.TreeSet<T>
export type Heap<T> = Heap.Heap<T>
export type Optional<T> = Optional.Optional<T>

return {
	Common = Common,
	Algorithm = Algorithm,
	BSearch = BSearch,

	-- 컨테이너 네임스페이스. **순수 테이블입니다** — 콜러블로 만들면 제네릭
	-- 생성자가 타입 인자를 잃고 모듈 오타도 못 잡습니다(실측).
	Arr = Arr,
	HashMap = HashMap,
	HashSet = HashSet,
	TreeMap = TreeMap,
	TreeSet = TreeSet,
	Heap = Heap,
	Optional = Optional,

	-- 술어는 camelCase 로 최상위에 둡니다.
	isArr = Arr.isArr,
	isHashMap = HashMap.isHashMap,
	isHashSet = HashSet.isHashSet,
	isTreeMap = TreeMap.isTreeMap,
	isTreeSet = TreeSet.isTreeSet,
	isHeap = Heap.isHeap,
	isOptional = Optional.isOptional,
}
