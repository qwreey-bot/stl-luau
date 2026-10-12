--!strict
--[[
	Types — 여러 컨테이너가 공유하는 **계약**만 둡니다.

	⭐ **말단 모듈입니다**: 다른 컨테이너 모듈을 require 하지 않습니다. 그래서
	(a) 순환 require 가 원천적으로 불가능하고 (b) 선언 순서 의존 누수가
	생기지 않습니다 — 같은 코드인데 선언 순서만 바꾸면 제네릭이 `{K & string}`
	으로 새는 것을 확인했고(진단 0건!), 다른 모듈에서 이미 풀린 타입으로
	들어오면 그 문제가 안 생깁니다.
	근거: .claude/audit/container-contracts/REPORT.md 3절, quad §8.21 계열.

	⭐ **계약은 "함수 묶음" 입니다**(2026-10-01, 질문 AB). 컨테이너에 메소드가
	없으니(메타테이블 없는 평범한 테이블) **모듈 테이블이 그대로 구현체**이고 — Rust
	트레이트의 vtable 과 같은 결 — 트레이트(`Trait.luau`)에 `[타입 토큰] = 모듈` 로
	등록됩니다. 공용 알고리즘은 값의 토큰으로 구현을 찾습니다: `Algorithm.IndexOf(a, x)`
	(2026-10-06 트레이트 — 예전엔 `Algorithm.IndexOf(Arr, a, x)` 로 손으로 넘김).
	필드를 **`read`(읽기 전용)** 로 두는 게 핵심입니다 — 읽기·쓰기 필드는 불변이라
	제네릭 함수(`<T>(ArrData<T>, number) -> T?`)가 단형 필드에 안 들어가고, 읽기
	전용이면 "제네릭 함수는 자기 인스턴스의 서브타입" 규칙이 먹습니다(실측).
]]

--[[ 전략 주입 — 컨테이너가 키/원소 타입을 모른 채 일하게 해줍니다. ]]

-- 3방향 비교. a < b 면 음수, 같으면 0, a > b 면 양수.
-- **3방향이 정본입니다**: 이분 탐색이나 트리처럼 "작다/같다/크다" 를 한 번에
-- 알아야 하는 곳에서 비교 횟수가 절반이 됩니다. 불리언 비교자만 있으면
-- 같은지 알려고 두 번 물어야 합니다.
export type Comparator<T> = (a: T, b: T) -> number

-- Lua 관용의 "a 가 b 보다 앞이냐". `table.sort` 가 받는 모양입니다.
-- 정본은 Comparator 이고 이건 그 옆에 두는 편의형입니다 — Common 에 서로
-- 바꾸는 어댑터가 있습니다.
export type LessThan<T> = (a: T, b: T) -> boolean

-- 값을 정수 해시로 접습니다.
-- ⚠️ **아직 소비자가 없습니다.** Luau 테이블 자체가 해시맵이라 문자열/숫자
-- 키에는 필요가 없고, 테이블을 값으로 비교해 키로 쓰고 싶을 때만 값집니다.
-- 그 기능을 만들지 말지는 question.md 의 열린 질문입니다. 자리만 남깁니다.
export type Hasher<T> = (value: T, maxHash: number) -> number

--[[ 맵 계열이 공유하는 항목 표현 ]]

-- 키-값 한 쌍. 구현마다 `iter()` / `orderedIter()` 로 이름이 갈라지는 것을
-- 막으려고 계약에 포함합니다.
-- 받은 레코드를 고쳐도 컨테이너는 안 망가집니다 — 컨테이너들은 레코드를
-- **새로 만들어서** 내줍니다(2026-09-30 리뷰). `read` 필드로 막는 안도 재봤는데,
-- 리터럴에서 제네릭을 못 뽑고 `FromRecords(Records(m))` 왕복까지 막혀 접었습니다.
export type Record<K, V> = { key: K, value: V }

--[[ 컨테이너 계약 — 함수 묶음 ]]

-- 위치 타입을 파라미터로 뺀 순차 컨테이너. `C` 는 컨테이너 자신의 타입.
-- 배열 기반은 I = number, 연결 기반은 I = 노드. 그래서 "연결 리스트에서
-- 정수 인덱스로 접근" 이 애초에 **표현 불가능**해집니다.
--
-- ⚠️ 이 계약을 **경유해서** 순회하면 간접 호출 비용이 붙습니다. Luau 제네릭은
-- 지워지므로 C++ 템플릿처럼 공짜가 아닙니다. 각 컨테이너 자신의 뜨거운 함수는
-- 이 계약을 거치지 말고 직접 구현하세요(`for i = 1, self.n`). 이 계약은
-- **구현을 모르는 공용 알고리즘**(Algorithm.luau)을 위한 것입니다.
-- 근거: .claude/base/container-design-notes.md 2절.
export type ListOps<C, E, I> = {
	read Get: (list: C, idx: I) -> E?,
	read FirstIndex: (list: C) -> I?,
	read LastIndex: (list: C) -> I?,
	read NextIndex: (list: C, idx: I) -> I?,
	read PrevIndex: (list: C, idx: I) -> I?,
}

-- 키로 값을 찾는 컨테이너. HashMap/TreeMap 이 만족합니다.
export type MapOps<C, K, V> = {
	read Get: (map: C, key: K) -> V?,
	read Set: (map: C, key: K, value: V) -> (),
	read Records: (map: C) -> { Record<K, V> },
}

-- 원소의 존재만 다루는 컨테이너. HashSet/TreeSet 이 만족합니다.
-- **이름을 맵과 일부러 가릅니다**: 셋은 Add/Has/Remove, 맵은 Set/Get.
-- 셋이 맵 위에 얹혀 있어도 바깥 어휘는 완전히 분리합니다.
export type SetOps<C, T> = {
	read Add: (set: C, item: T) -> boolean,
	read Has: (set: C, item: T) -> boolean,
	read Remove: (set: C, item: T) -> boolean,
	read Items: (set: C) -> { T },
}

--[[ 트레이트 마커 — 타입에만 있는 필드(런타임엔 없음, `Trait.luau` 머리) ]]

-- 타입 토큰(`Trait.NewType` 이 만듦). `N` 은 이름의 리터럴 타입. 여기(말단)에 두는 것은
-- 마커가 토큰을 요구하게 하려고 — 토큰 없는 평범한 테이블이 마커만 흉내 내면 타입은
-- 통과하고 런타임에 터졌습니다(2026-10-06 Gemini 트레이트 검토).
export type Token<N> = { read name: N }

-- ⚠️ 마커 필드(`__list` 등)는 **타입에만** 있습니다 — 읽으면 nil 입니다(타입은 `T` 라고
-- 하지만). 알고리즘이 원소 타입을 추론하는 재료일 뿐 읽는 코드를 쓰지 마세요(quad 의
-- `StateMarker` 와 같은 약속, 질문 AG 3).
-- 리스트(`Trait.List` 를 구현하는 종류). `E` 는 원소, `I` 는 위치.
export type ListMarker<E, I> = { read __type: Token<any>, read __list: E, read __listIndex: I }
-- 맵(`Trait.Map`). `K` 는 키, `V` 는 값.
export type MapMarker<K, V> = { read __type: Token<any>, read __mapKey: K, read __mapValue: V }
-- 셋(`Trait.Set`). `T` 는 원소.
export type SetMarker<T> = { read __type: Token<any>, read __setItem: T }

-- ⭐ **키·위치·값을 입력으로 받는 제네릭을 위한 불변 마커**(2026-10-12, 질문 AM). 위 읽기 마커는
-- `read` 라 **공변**입니다 — 컨테이너에서 꺼내기만 하는 알고리즘엔 맞지만(`Keys`, `Count`), 마커와 함께
-- **값·키·위치를 받아 넘기는** 제네릭에서는 그 타입이 조용히 넓어집니다: `Set`/`Add` 로 쓰면
-- `HashMap<string, number>` 에 문자열이 들어가고, 조회만 해도 `TreeMap<string, …>` 에 숫자 키를 넘겨
-- 비교자가 라이브러리 줄에서 터졌습니다(진단 0건, `spikes/61`). 그런 제네릭은 이쪽을 받으세요. 팬텀이 **함수 타입**이라(인자·반환 양쪽에 타입 변수) 불변이고, 읽기 마커의 필드도 다
-- 있어 읽는 알고리즘에 그대로 넘어갑니다. 읽기 전용으로 빌린 타입(`ArrRead`)에는 이 팬텀이 없습니다.
-- (팬텀을 읽기·쓰기 필드로 선언하는 길도 불변이 되지만 사용자가 팬텀에 쓰는 코드가 통과했습니다.)
export type ListMarkerMut<E, I> = {
	read __type: Token<any>,
	read __list: E,
	read __listIndex: I,
	-- 위치 `I` 도 같이 — `(E) -> E` 뿐일 땐 위치를 받아 쓰는 제네릭이 `Arr` 에 문자열 키로 썼습니다
	-- (진단 0건, AM 리뷰 1라운드).
	read __listMut: (E, I) -> (E, I),
}
export type MapMarkerMut<K, V> = {
	read __type: Token<any>,
	read __mapKey: K,
	read __mapValue: V,
	read __mapMut: (K, V) -> (K, V),
}
export type SetMarkerMut<T> = { read __type: Token<any>, read __setItem: T, read __setMut: (T) -> T }

return {}
