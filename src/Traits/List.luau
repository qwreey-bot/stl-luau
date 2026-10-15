--!strict
--[[
	List — 위치로 원소를 읽는 순차 컨테이너의 트레이트. `Arr`·`CircularDeque`·`LinkedDeque`(위치가 노드)가 구현합니다.

	이 파일이 트레이트의 전부입니다: 정의(필수 — 위치 프리미티브 다섯, **기본 구현** — 프리미티브만으로 도는 읽기
	알고리즘 일곱), 타입 마커, 종류를 모르는 코드의 진입점 서명(`List.IndexOf(list, x)` — 진입점 자체는 시스템이 만듦).

	⭐ **프리미티브 다섯만 구현하면 읽기 알고리즘이 따라옵니다**(2026-10-13, `papers/07`). 등록 표에
	같은 이름을 적으면 그것이 기본 구현을 대신합니다(`Arr` 는 일곱 다 자기 직접 구현으로, `CircularDeque`·`LinkedDeque` 는
	재정의 없이 기본 구현을 받음). 기본 구현은 **바깥에서 리스트를 구현하는 쪽을
	위한 것**이기도 합니다 — 라이브러리 안의 종류가 전부 재정의하더라도 둡니다(사용자 방침).

	⭐ **`List.ImplFor` 에는 넘길 것만 든 표를 넘깁니다**(2026-10-13 사용자 결정, 질문 AS) — 필수 다섯과, 재정의할
	것이 있으면 그 이름만. **표에 적은 이름이 곧 재정의**이고, 트레이트가 모르는 이름이 섞이면 `ImplFor` 가 에러로
	알립니다(모듈 테이블을 통째로 넘길 수 없음). 통째로 넘기던 때는 같은 이름이 전부 재정의가 돼서, 진입점에
	위임하는 같은 이름 함수는 끝없이 돌았고(stack overflow) 뜻이 다른 같은 이름(값으로 찾는 `Find`, 술어를 안 받는
	`Count`)은 조용히 틀린 결과였습니다(2단계 리뷰가 재현, 진단 0건).
	재정의는 기본 구현과 **같은 뜻·같은 인자**여야 합니다 — 인자를 덜 받는 함수는 등록 표 타입(`Provided`)에도 들어가(Luau
	규칙) 타입이 막지 못합니다. 라이브러리 안의 종류가 무엇을 재정의하는지는 `spec.contracts` 13절이 전수로 고정합니다.

	⚠️ **기본 구현은 느린 게 정상입니다.** 원소마다 프리미티브를 간접 호출하므로 직접 구현의 1.1~3.8배
	입니다(perf 31절) — Luau 제네릭은 지워지므로 C++ 템플릿처럼 공짜가 아닙니다. 각 컨테이너 자신의
	뜨거운 함수는 이 계약을 거치지 말고 직접 구현하고(`for i = 1, self.n`), 빨라야 하는 종류는 같은
	이름의 함수로 재정의하세요. 구현 찾기는 호출당 한 번(테이블 조회 둘)이라 원소 수와 무관합니다.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")
type AnyToken = Trait.AnyToken
const Fn, Default, Sig = Trait.Fn, Trait.Default, Trait.Sig

--[[ 마커 — 타입에만 있는 필드 ]]
-- ⚠️ 트레이트 레코드(`__traits`)는 **타입에만** 있습니다 — 읽으면 nil 입니다(타입은 `E` 라고 하지만).
-- 알고리즘이 원소 타입을 추론하는 재료일 뿐 읽는 코드를 쓰지 마세요(quad 의 `StateMarker` 와 같은
-- 약속, 질문 AG 3).

-- 연관 타입 레코드(질문 BA): 컨테이너가 `read __traits: { read List: List.Assoc<원소, 위치> }`(빌린 읽기 타입은 `AssocRead`).
-- 원소·위치는 공변(`() -> E`), `Mut` 은 원소·위치를 **입력으로 받아 넘기는** 제네릭용 불변 팬텀(질문 AM — `Value`).
export type AssocRead<E, I> = { read Item: () -> E, read Index: () -> I }
export type Assoc<E, I> = { read Item: () -> E, read Index: () -> I, read Mut: (E, I) -> (E, I) }
-- 마커 — 꺼내기만 하는 알고리즘(`ValueRead`, 빌린 참조도)과 원소·위치를 넘기는 제네릭(`Value`, 질문 AM).
export type ValueRead<E, I> = { read __type: Trait.Token<any>, read __traits: { read List: AssocRead<E, I> } }
export type Value<E, I> = { read __type: Trait.Token<any>, read __traits: { read List: Assoc<E, I> } }

--[[ 정의 ]]
-- 필수 다섯 — 위치 프리미티브. `Self` 는 컨테이너 자신의 타입, `E` 는 원소, `I` 는 **위치**. 배열 기반은 I = number, 연결 기반은
-- I = 노드 — 그래서 "연결 리스트에서 정수 인덱스로 접근" 이 애초에 **표현 불가능**합니다(.claude/base/container-design-notes.md 2절).
-- 읽기만 하는 트레이트라 조건(`of`)은 공변 레코드(`ValueRead` — `AssocRead`) 하나 — 읽기 전용으로 빌린 참조도 `List.Of` 를 얻습니다.
--
-- 기본 구현 일곱(완성 표의 나머지). 콜백은 원소와 **위치**를 받습니다(`Arr` 의 콜백은 셋째로 읽기 뷰도 받지만 계약은 둘까지).
-- - `Fold` 앞에서부터 접기. `Find` 는 처음 맞는 원소와 그 위치(없으면 `nil, nil`).
-- - `IndexOf`/`Contains` 는 `==` 비교. `Count` 는 술어가 없으면 위치의 수(세어서 구함).
-- - `Some`/`Every` — 빈 리스트의 `Every` 는 참.
-- 서명이 곧 **재정의 자리의 타입**입니다(등록 보기에서 선택 칸): 콜백 타입의 `...any` 는 "원소와 위치, 그리고 구현이 더 넘길 수도
-- 있음"(`Arr` 의 콜백은 셋째로 읽기 뷰). `Some`/`Every` 는 **두 모양의 합**입니다: 계약 그대로 `(list, pred)` 이거나, 뒤에 **선택**
-- 인자를 더 받는 것(`Arr` 의 구간 `start?, last?`) — 꼬리를 `...any` 하나로 두었더니 꼬리 없는 서명을 적은 표가 거절됐고, 셋째
-- 인자를 **꼭** 받는 재정의는 통과해 진입점이 부를 때 라이브러리 줄에서 죽었습니다(옛 시스템 2라운드 리뷰). `Fold` 는 누적 타입을
-- 제네릭 `<U>` 로 — `any` 였던 때는 `Fold = Arr.Len` 도 0건이었습니다(4라운드 리뷰).
-- 기본 구현은 프리미티브를 **호출마다 한 번** `ops` 에서 꺼내 지역에 두고 돕니다(루프형이라 만들 때 붙잡아도 원소당 차이가 없었음
-- — perf 50절). 다른 기본 구현을 부르는 것도 `ops` 로 — 구현이 `IndexOf` 를 재정의했으면 그 판을 씁니다.
type Pred<E, I> = (item: E, idx: I, ...any) -> boolean
type SomeEvery<Self, E, I> =
	((list: Self, pred: Pred<E, I>) -> boolean)
	| ((list: Self, pred: Pred<E, I>, ...nil) -> boolean)

const ListBase = Trait.Trait("List", function<Self, E, I>(of: (Self & ValueRead<E, I>) | AnyToken)
	return table.freeze({
		Get = Fn<<(list: Self, idx: I) -> E?>>(),
		FirstIndex = Fn<<(list: Self) -> I?>>(),
		LastIndex = Fn<<(list: Self) -> I?>>(),
		NextIndex = Fn<<(list: Self, idx: I) -> I?>>(),
		PrevIndex = Fn<<(list: Self, idx: I) -> I?>>(),
		Fold = Default(function(ops: any): <U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U) -> U
			return function<U>(self: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U): U
				const get, nextIndex = ops.Get, ops.NextIndex
				local acc, idx = init, ops.FirstIndex(self)
				while idx ~= nil do
					acc = fn(acc, get(self, idx), idx)
					idx = nextIndex(self, idx)
				end
				return acc
			end
		end, Sig<<<U>(list: Self, init: U, fn: (acc: U, element: E, idx: I) -> U) -> U>>()),
		Find = Default(function(ops: any): (list: Self, pred: Pred<E, I>) -> (E?, I?)
			return function(self: Self, pred: Pred<E, I>): (E?, I?)
				const get, nextIndex = ops.Get, ops.NextIndex
				local idx = ops.FirstIndex(self)
				while idx ~= nil do
					const item = get(self, idx)
					if pred(item, idx) then
						return item, idx
					end
					idx = nextIndex(self, idx)
				end
				return nil, nil
			end
		end, Sig<<(list: Self, pred: (element: E, idx: I) -> boolean) -> (E?, I?)>>()),
		IndexOf = Default(function(ops: any): (list: Self, item: E) -> I?
			return function(self: Self, item: E): I?
				const get, nextIndex = ops.Get, ops.NextIndex
				local idx = ops.FirstIndex(self)
				while idx ~= nil do
					if get(self, idx) == item then
						return idx
					end
					idx = nextIndex(self, idx)
				end
				return nil
			end
		end),
		Contains = Default(function(ops: any): (list: Self, item: E) -> boolean
			return function(self: Self, item: E): boolean
				return ops.IndexOf(self, item) ~= nil
			end
		end),
		Count = Default(function(ops: any): (list: Self, pred: Pred<E, I>?) -> number
			return function(self: Self, pred: Pred<E, I>?): number
				const get, nextIndex = ops.Get, ops.NextIndex
				local total, idx = 0, ops.FirstIndex(self)
				if pred == nil then
					while idx ~= nil do
						total += 1
						idx = nextIndex(self, idx)
					end
				else
					while idx ~= nil do
						if pred(get(self, idx), idx) then
							total += 1
						end
						idx = nextIndex(self, idx)
					end
				end
				return total
			end
		end, Sig<<(list: Self, pred: ((element: E, idx: I) -> boolean)?) -> number>>()),
		Some = Default(function(ops: any): SomeEvery<Self, E, I>
			return function(self: Self, pred: Pred<E, I>): boolean
				const get, nextIndex = ops.Get, ops.NextIndex
				local idx = ops.FirstIndex(self)
				while idx ~= nil do
					if pred(get(self, idx), idx) then
						return true
					end
					idx = nextIndex(self, idx)
				end
				return false
			end
		end, Sig<<(list: Self, pred: (element: E, idx: I) -> boolean) -> boolean>>()),
		Every = Default(function(ops: any): SomeEvery<Self, E, I>
			return function(self: Self, pred: Pred<E, I>): boolean
				const get, nextIndex = ops.Get, ops.NextIndex
				local idx = ops.FirstIndex(self)
				while idx ~= nil do
					if not pred(get(self, idx), idx) then
						return false
					end
					idx = nextIndex(self, idx)
				end
				return true
			end
		end, Sig<<(list: Self, pred: (element: E, idx: I) -> boolean) -> boolean>>()),
	})
end)
-- 완성 표(`List.Of(v)`)와 등록 표(`List.ImplFor` 에 넘기는 표 — 필수 다섯 + 재정의할 것만, 기본 구현 칸은 선택)
export type Full<Self, E, I> = typeof(ListBase.Of<<Self, E, I>>(nil :: any))
export type Provided<Self, E, I> = typeof(ListBase.ImplOf<<Self, E, I>>(nil :: any))

--[[ 진입점 서명 — 종류를 모르는 코드가 부릅니다(진입점 자체는 시스템이 만든 것) ]]
-- 그 종류의 완성 표를 부릅니다 — `Arr` 처럼 자기 구현이 있는 종류는 그것이(빠름), `CircularDeque`·사용자 리스트는
-- 위의 기본 구현이 돕니다. 콜백은 원소와 위치를 받습니다. 종류를 아는 코드는 그 모듈의 함수를 직접
-- 쓰세요(`Arr.IndexOf`).
--
-- ⚠️ **가변인자 함수를 콜백으로 그대로 넘기지 마세요**(`List.Fold(flags, 0, bit32.bor)`, `math.max` …): 콜백은
-- 원소 뒤에 **위치**를 받고 구현에 따라 인자를 더 받습니다(`Arr` 는 읽기 뷰) — 가변인자 함수는 그것까지 값으로
-- 삼아 `Arr` 에서는 라이브러리 줄 에러, 덱에서는 위치가 섞인 틀린 값이 됩니다(JS 의 `map(parseInt)` 와 같은
-- 함정). 람다로 감싸세요: `function(acc, v) return math.max(acc, v) end`. 타입은 이것을 막지 못합니다 — 콜백
-- 타입에 가변 꼬리(`...unknown`)를 두면 가변인자 함수는 잡히지만 **타입을 적은 평범한 콜백 변수·파라미터**
-- (`pred: (E, I) -> boolean`)까지 거절돼, 종류를 모르는 코드가 술어를 받아 넘기는 흔한 모양이 막혔습니다
-- (한 번 넣었다가 리뷰에서 회귀로 확인해 걷음 — `spikes/64` 가 두 쪽을 다 고정).
const List = ListBase -- 진입점 서명은 정의에서 지어짐(`Trait.Entries` — 콜백을 받는 칸은 `Sig` 의 부르는 쪽 서명)

return List
