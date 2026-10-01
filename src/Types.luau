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
	없으니(메타테이블 없는 평범한 테이블) 디스패치는 **구현 함수 묶음을 컨테이너와
	같이 넘기는** 모양입니다 — Rust 트레이트의 vtable 과 같은 결이고, **모듈
	테이블이 그대로 구현체**입니다: `Algorithm.IndexOf(Arr, a, x)`.
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
-- 리터럴에서 제네릭을 못 뽑고 `FromRecords(m:Records())` 왕복까지 막혀 접었습니다.
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

return {}
