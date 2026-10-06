--!strict
--[[
	Trait — 타입 토큰과 트레이트(인터페이스) 레지스트리.

	⭐ **값에는 타입 토큰 하나**(`__t` 필드), **구현은 트레이트가 듭니다**(2026-10-06,
	사용자와 설계 — quad 의 Brand 를 "값 단위" 가 아니라 "타입 단위" 로).
	- **타입 토큰**: 컨테이너 종류마다 하나인 공유 테이블(`Trait.Types.Arr`). 값은
	  `__t = Trait.Types.Arr` 로 자기 종류를 가리킵니다 — 생성 비용은 예전 문자열
	  태그(`__arr__ = true`)와 같은 필드 하나.
	- **트레이트**: 공유 테이블 하나가 `[타입 토큰] = 구현 테이블` 을 듭니다(quad Brand 의
	  `[값] = true` 자리에 구현이 들어간 모양). 모듈 테이블이 그대로 구현체입니다 —
	  함수가 바깥(서비스)에 있으니 값(엔티티)이 아니라 타입이 구현을 찾는 열쇠입니다.
	- 한 타입이 **여러 트레이트**를 구현할 수 있고(문자열 태그 하나로는 하드코딩이 필요했음),
	  **바깥에서** 자기 트레이트를 만들어 우리 타입에 붙이거나, 자기 타입을 우리 트레이트에
	  넣을 수 있습니다 — 이름(문자열)이 아니라 정체성(테이블)으로 구분하니 충돌이 없습니다.
	- 조회는 숫자·nil·userdata 를 넣어도 안전합니다(`t[nil]` 읽기는 에러가 아님).

	위조는 막지 않습니다(사용자: *"유저가 막 의도적으로 배껴간다는 솔찍히 막을 이유
	모르겠음"*). 토큰을 베껴 넣으면 그 종류로 취급됩니다. 대신 **우연한 충돌은 없습니다** —
	문자열 태그와 달리 직렬화했다 되읽은 테이블은 토큰의 정체성을 잃어 그 종류가 아닙니다.
	대가: 라이브러리 사본이 둘이면(다른 버전) 서로의 값을 그 종류로 보지 않습니다.

	## 타입 쪽 — 팬텀 마커

	런타임 조회는 토큰으로 하지만 정적 타입은 그걸 따라가지 못하니, 트레이트마다
	**타입에만 있는 필드**를 둡니다(`Types.ListMarker<E>` = `{ read __list: E }`). 런타임엔
	없습니다(quad 의 `StateMarker` 와 같은 결). 덕분에 `Algorithm.Keys(m)` 가 타입 인자
	없이 `{ K }` 를 추론합니다 — 예전 `Algorithm.Keys<<HashMap<…>, K, V>>(HashMap, m)`.
]]
local Common = require("./Common")
Common.registerSource(debug.info(1, "s"))
local Types = require("./Types")

-- 타입 토큰. `N` 은 이름의 리터럴 타입 — 종류마다 구조가 달라 정적으로도 갈립니다.
export type Token<N> = { read name: N }
-- 트레이트. `I` 는 구현 테이블의 타입(팬텀 — `impls` 의 값 타입).
export type Trait<I> = { read name: string, read impls: { [any]: I } }

-- 값에 타입 토큰을 싣는 필드 이름. **라이브러리 예약어**입니다. 짧은 `__t` 인 것은 해시
-- 배치 때문입니다 — `__type` 은 `n`(Arr)·`data`/`size`(HashMap)와 해시 칸이 부딪혀 생성이
-- 3~7% 느렸고 `__t` 는 옛 태그와 같았습니다(perf 21절). 모듈들은 이 문자열을 **리터럴로**
-- 다시 적습니다(상수 접기 — 이 값을 받아 쓰면 생성이 느려짐).
const TYPE_KEY = "__t"

-- 새 타입 토큰. 사용자 컨테이너도 이걸로 만듭니다.
const function NewType(name: string): Token<string>
	return table.freeze({ name = name }) :: any
end

-- 새 트레이트. 구현 테이블의 타입을 알려 주면 `ImplOf` 가 그 타입을 돌려줍니다:
--     local Show = Trait.New<<{ read Show: (any) -> string }>>("Show")
const function New<I>(name: string): Trait<I>
	return { name = name, impls = {} } :: any
end

-- `token` 종류가 `trait` 를 구현한다고 등록합니다. 보통 모듈을 불러올 때 한 번.
const function Impl<I>(trait: Trait<I>, token: Token<any>, impl: I)
	if type(token) ~= "table" or not table.isfrozen(token) then
		Common.raise(`Trait: Impl needs a type token (from Trait.NewType), got {typeof(token)}`)
	end
	(trait.impls :: any)[token] = impl
end

-- 값의 타입 토큰. 테이블이 아니거나 토큰이 없으면 nil.
const function TypeOf(value: any): Token<any>?
	if type(value) ~= "table" then
		return nil
	end
	return rawget(value, TYPE_KEY) :: any
end

-- 값의 종류가 `trait` 를 구현하면 그 구현 테이블, 아니면 nil.
const function ImplOf<I>(trait: Trait<I>, value: any): I?
	-- `impls[nil]` 읽기는 에러가 아닙니다 — 토큰이 없으면 그대로 nil.
	return trait.impls[TypeOf(value) :: any]
end

const function Implements<I>(trait: Trait<I>, value: any): boolean
	return ImplOf(trait, value) ~= nil
end

-- 값에 타입 토큰을 붙입니다. 생성자들이 씁니다.
const function Stamp<T>(value: T, token: Token<any>): T
	(value :: any)[TYPE_KEY] = token
	return value
end

--[[ 라이브러리의 트레이트와 타입 토큰 ]]

const List = New<<Types.ListOps<any, any, any>>>("List")
const Map = New<<Types.MapOps<any, any, any>>>("Map")
const Set = New<<Types.SetOps<any, any>>>("Set")

const BuiltinTypes = table.freeze({
	Arr = NewType("Arr") :: Token<"Arr">,
	HashMap = NewType("HashMap") :: Token<"HashMap">,
	HashSet = NewType("HashSet") :: Token<"HashSet">,
	TreeMap = NewType("TreeMap") :: Token<"TreeMap">,
	TreeSet = NewType("TreeSet") :: Token<"TreeSet">,
	Heap = NewType("Heap") :: Token<"Heap">,
	Fut = NewType("Fut") :: Token<"Fut">,
})

-- stylua: ignore
return {
	TYPE_KEY = TYPE_KEY,
	NewType = NewType, New = New, Impl = Impl,
	TypeOf = TypeOf, ImplOf = ImplOf, Implements = Implements, Stamp = Stamp,
	List = List, Map = Map, Set = Set,
	Types = BuiltinTypes,
}
