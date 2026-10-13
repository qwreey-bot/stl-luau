--!strict
--[[
	List — 위치로 원소를 읽는 순차 컨테이너의 트레이트. `Arr`·`CircularDeque`·`LinkedDeque`(위치가 노드)가 구현합니다.

	이 파일이 트레이트의 전부입니다: 계약(`Core` — 위치 프리미티브 다섯), **기본 구현**(프리미티브만으로
	도는 읽기 알고리즘), 타입 마커, 종류를 모르는 코드의 진입점(`List.IndexOf(list, x)`).

	⭐ **프리미티브 다섯만 구현하면 읽기 알고리즘이 따라옵니다**(2026-10-13, `papers/07`). 같은 이름의
	함수를 가진 구현은 그것이 기본 구현을 대신합니다(`Arr` 는 모듈을 그대로 등록해 전부 자기 직접
	구현으로, `CircularDeque`·`LinkedDeque` 는 재정의 없이 기본 구현을 받음). 기본 구현은 **바깥에서 리스트를 구현하는 쪽을
	위한 것**이기도 합니다 — 라이브러리 안의 종류가 전부 재정의하더라도 둡니다(사용자 방침).

	⭐ **`Trait.Impl` 에는 넘길 것만 든 표를 넘깁니다**(2026-10-13 사용자 결정, 질문 AS) — 필수 다섯과, 재정의할
	것이 있으면 그 이름만. **표에 적은 이름이 곧 재정의**이고, 트레이트가 모르는 이름이 섞이면 `Trait.Impl` 이 에러로
	알립니다(모듈 테이블을 통째로 넘길 수 없음). 통째로 넘기던 때는 같은 이름이 전부 재정의가 돼서, 진입점에
	위임하는 같은 이름 함수는 끝없이 돌았고(stack overflow) 뜻이 다른 같은 이름(값으로 찾는 `Find`, 술어를 안 받는
	`Count`)은 조용히 틀린 결과였습니다(2단계 리뷰가 재현, 진단 0건).
	재정의는 기본 구현과 **같은 뜻·같은 인자**여야 합니다 — 인자를 덜 받는 함수는 `Provided` 타입에도 들어가(Luau
	규칙) 타입이 막지 못합니다. 라이브러리 안의 종류가 무엇을 재정의하는지는 `spec.contracts` 13절이 전수로 고정합니다.

	⚠️ **기본 구현은 느린 게 정상입니다.** 원소마다 프리미티브를 간접 호출하므로 직접 구현의 1.1~3.8배
	입니다(perf 31절) — Luau 제네릭은 지워지므로 C++ 템플릿처럼 공짜가 아닙니다. 각 컨테이너 자신의
	뜨거운 함수는 이 계약을 거치지 말고 직접 구현하고(`for i = 1, self.n`), 빨라야 하는 종류는 같은
	이름의 함수로 재정의하세요. 구현 찾기는 호출당 한 번(테이블 조회 둘)이라 원소 수와 무관합니다.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")

--[[ 계약 ]]

-- 필수 함수 다섯 — 위치 프리미티브. `C` 는 컨테이너 자신의 타입, `E` 는 원소, `I` 는 **위치**.
-- 배열 기반은 I = number, 연결 기반은 I = 노드. 그래서 "연결 리스트에서 정수 인덱스로 접근" 이
-- 애초에 **표현 불가능**해집니다(.claude/base/container-design-notes.md 2절).
export type Core<C, E, I> = {
	read Get: (list: C, idx: I) -> E?,
	read FirstIndex: (list: C) -> I?,
	read LastIndex: (list: C) -> I?,
	read NextIndex: (list: C, idx: I) -> I?,
	read PrevIndex: (list: C, idx: I) -> I?,
}

-- **완성 표** — 필수 다섯에 기본 구현이 채우는 읽기 알고리즘이 더해진 것(`Trait.ImplOf(List, v)` 가
-- 돌려주는 것). 콜백은 원소와 **위치**를 받습니다(`Arr` 의 콜백은 셋째로 읽기 뷰도 받지만 계약은 둘까지).
-- - `Fold` 앞에서부터 접기. `Find` 는 처음 맞는 원소와 그 위치(없으면 `nil, nil`).
-- - `IndexOf`/`Contains` 는 `==` 비교. `Count` 는 술어가 없으면 위치의 수(세어서 구함).
-- - `Some`/`Every` — 빈 리스트의 `Every` 는 참.
export type Full<C, E, I> = {
	read Get: (list: C, idx: I) -> E?,
	read FirstIndex: (list: C) -> I?,
	read LastIndex: (list: C) -> I?,
	read NextIndex: (list: C, idx: I) -> I?,
	read PrevIndex: (list: C, idx: I) -> I?,
	read Fold: (list: C, init: any, fn: (acc: any, item: E, idx: I) -> any) -> any,
	read Find: (list: C, pred: (item: E, idx: I) -> boolean) -> (E?, I?),
	read IndexOf: (list: C, item: E) -> I?,
	read Contains: (list: C, item: E) -> boolean,
	read Count: (list: C, pred: ((item: E, idx: I) -> boolean)?) -> number,
	read Some: (list: C, pred: (item: E, idx: I) -> boolean) -> boolean,
	read Every: (list: C, pred: (item: E, idx: I) -> boolean) -> boolean,
}

-- 구현이 **`Trait.Impl` 에 넘기는 표**의 타입: 필수 다섯 + **재정의할 수 있는 것은 선택 필드**.
-- 선택 필드로 적어 두어야 재정의 자리가 검사됩니다 — 필수만 적은 타입이면 폭 서브타이핑으로 아무 값이나
-- 통과했습니다(`Fold = "문자열"` 이 0건, 리뷰).
-- ⚠️ **어디까지 잡히는가**(2라운드 리뷰 실측): `Trait.Impl(List, 토큰, 표)` 호출에서는 타입 인자가 `any` 라
-- "필수가 빠짐 / 함수가 아님" 까지만 잡힙니다. 반환·원소·위치 타입과 인자 순서는 **구체 타입으로 적은 대입**
-- (`const _list: List.Provided<Arr<any>, any, number> = ArrModule` — 모듈 끝에 한 줄)이 잡습니다. 인자를 **덜**
-- 받는 함수(술어를 안 받는 `Count`)는 어느 쪽도 못 잡습니다(Luau 는 덜 받는 함수를 받아 줌).
-- 콜백 타입의 `...any` 는 "원소와 위치, 그리고 구현이 더 넘길 수도 있음" 입니다(`Arr` 의 콜백은 셋째로 읽기
-- 뷰를 받음). `Some`/`Every` 는 **두 모양의 합**입니다: 계약 그대로 `(list, pred)` 이거나, 뒤에 **선택** 인자를
-- 더 받는 것(`Arr` 의 구간 `start?, last?`). 꼬리를 `...any` 하나로 두었더니 꼬리 없는 서명을 손으로 적은 표
-- (`List.Full` 로 적은 표, 다른 종류의 완성 표)가 거절됐고, 셋째 인자를 **꼭** 받는 재정의는 통과해 진입점이
-- 부를 때 라이브러리 줄에서 죽었습니다(둘 다 2라운드 리뷰).
export type Provided<C, E, I> = {
	read Get: (list: C, idx: I) -> E?,
	read FirstIndex: (list: C) -> I?,
	read LastIndex: (list: C) -> I?,
	read NextIndex: (list: C, idx: I) -> I?,
	read PrevIndex: (list: C, idx: I) -> I?,
	read Fold: ((list: C, init: any, fn: (acc: any, item: E, idx: I, ...any) -> any) -> any)?,
	read Find: ((list: C, pred: (item: E, idx: I, ...any) -> boolean) -> (E?, I?))?,
	read IndexOf: ((list: C, item: E) -> I?)?,
	read Contains: ((list: C, item: E) -> boolean)?,
	read Count: ((list: C, pred: ((item: E, idx: I, ...any) -> boolean)?) -> number)?,
	read Some: (
		((list: C, pred: (item: E, idx: I, ...any) -> boolean) -> boolean)
		| ((list: C, pred: (item: E, idx: I, ...any) -> boolean, ...nil) -> boolean)
	)?,
	read Every: (
		((list: C, pred: (item: E, idx: I, ...any) -> boolean) -> boolean)
		| ((list: C, pred: (item: E, idx: I, ...any) -> boolean, ...nil) -> boolean)
	)?,
}

--[[ 마커 — 타입에만 있는 필드 ]]
-- ⚠️ 마커 필드(`__list` 등)는 **타입에만** 있습니다 — 읽으면 nil 입니다(타입은 `E` 라고 하지만).
-- 알고리즘이 원소 타입을 추론하는 재료일 뿐 읽는 코드를 쓰지 마세요(quad 의 `StateMarker` 와 같은
-- 약속, 질문 AG 3).

-- 읽기 마커(공변). `E` 는 원소, `I` 는 위치. 꺼내기만 하는 알고리즘용 — 빌린 참조(`ArrRead`)도 받습니다.
export type Marker<E, I> = { read __type: Trait.Token<any>, read __list: E, read __listIndex: I }
-- 원소·위치를 **입력으로 받아 컨테이너에 넘기는** 제네릭용 불변 마커(2026-10-12, 질문 AM — 읽기 마커로
-- 쓰면 그 타입이 조용히 넓어집니다. 자세한 것은 `Traits/Map` 의 `MarkerMut`). `==` 비교만 하는 값
-- (`IndexOf` 의 `item`)은 넓어져도 "없음" 일 뿐이라 읽기 마커로 됩니다. 읽기 전용으로 빌린 타입
-- (`ArrRead`)에는 이 팬텀이 없습니다.
export type MarkerMut<E, I> = {
	read __type: Trait.Token<any>,
	read __list: E,
	read __listIndex: I,
	-- 위치 `I` 도 같이 — `(E) -> E` 뿐일 땐 위치를 받아 쓰는 제네릭이 `Arr` 에 문자열 키로 썼습니다
	-- (진단 0건, AM 리뷰 1라운드).
	read __listMut: (E, I) -> (E, I),
}

--[[ 기본 구현 ]]
-- 프리미티브는 **부를 때** `ops`(그 종류의 살아 있는 완성 표)에서 꺼냅니다 — 나중에 재정의가 등록돼도
-- 그것을 씁니다.
const function defaults(ops: any): { [string]: any }
	return {
		Fold = function(self: any, init: any, fn: (any, any, any) -> any): any
			const get, nextIndex = ops.Get, ops.NextIndex
			local acc, idx = init, ops.FirstIndex(self)
			while idx ~= nil do
				acc = fn(acc, get(self, idx), idx)
				idx = nextIndex(self, idx)
			end
			return acc
		end,
		Find = function(self: any, pred: (any, any) -> boolean): (any, any)
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
		end,
		IndexOf = function(self: any, item: any): any
			const get, nextIndex = ops.Get, ops.NextIndex
			local idx = ops.FirstIndex(self)
			while idx ~= nil do
				if get(self, idx) == item then
					return idx
				end
				idx = nextIndex(self, idx)
			end
			return nil
		end,
		-- 다른 기본 구현을 부르는 것도 `ops` 로 — 구현이 `IndexOf` 를 재정의했으면 그 판을 씁니다.
		Contains = function(self: any, item: any): boolean
			return ops.IndexOf(self, item) ~= nil
		end,
		Count = function(self: any, pred: ((any, any) -> boolean)?): number
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
		end,
		Some = function(self: any, pred: (any, any) -> boolean): boolean
			const get, nextIndex = ops.Get, ops.NextIndex
			local idx = ops.FirstIndex(self)
			while idx ~= nil do
				if pred(get(self, idx), idx) then
					return true
				end
				idx = nextIndex(self, idx)
			end
			return false
		end,
		Every = function(self: any, pred: (any, any) -> boolean): boolean
			const get, nextIndex = ops.Get, ops.NextIndex
			local idx = ops.FirstIndex(self)
			while idx ~= nil do
				if not pred(get(self, idx), idx) then
					return false
				end
				idx = nextIndex(self, idx)
			end
			return true
		end,
	}
end

const List = Trait.New<<Full<any, any, any>>>("List", {
	required = { "Get", "FirstIndex", "LastIndex", "NextIndex", "PrevIndex" },
	defaults = defaults,
}) :: Trait.Trait<Full<any, any, any>, Provided<any, any, any>>
const expectImpl = Trait.ExpectImpl

--[[ 진입점 — 종류를 모르는 코드가 부릅니다 ]]
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

-- 같은 원소가 처음 나오는 위치. 없으면 nil. 비교는 `==` 입니다 — 값 동등성이 필요하면 호출자가 다른 걸
-- 써야 합니다. (원소 타입이 다른 `item` 은 타입 에러가 아닙니다 — `E` 가 둘의 합으로 넓어집니다.
-- 건전하고(그냥 nil), 예전 판도 같았습니다.)
const function IndexOf<E, I>(list: Marker<E, I>, item: E): I?
	return expectImpl(List, list, "IndexOf").IndexOf(list, item)
end

-- 같은 원소가 있는가(`==` 비교).
const function Contains<E, I>(list: Marker<E, I>, item: E): boolean
	return expectImpl(List, list, "Contains").Contains(list, item)
end

-- 세어서 구한 개수(AE, 2026-10-06 — `Len` 은 알고 있는 크기, `Count` 는 셈). 술어가 있으면 참인 원소만.
-- 길이를 아는 컨테이너는 자기 `Len` 이 빠릅니다(`Collection.Len`).
const function Count<E, I>(list: Marker<E, I>, pred: ((element: E, idx: I) -> boolean)?): number
	return expectImpl(List, list, "Count").Count(list, pred)
end

-- 앞에서부터 접기.
const function Fold<E, I, U>(list: Marker<E, I>, init: U, fn: (acc: U, element: E, idx: I) -> U): U
	return expectImpl(List, list, "Fold").Fold(list, init, fn)
end

-- 처음으로 조건을 만족하는 원소와 그 위치. 없으면 `nil, nil`.
const function Find<E, I>(list: Marker<E, I>, pred: (element: E, idx: I) -> boolean): (E?, I?)
	return expectImpl(List, list, "Find").Find(list, pred)
end

-- 하나라도 만족하는가.
const function Some<E, I>(list: Marker<E, I>, pred: (element: E, idx: I) -> boolean): boolean
	return expectImpl(List, list, "Some").Some(list, pred)
end

-- 전부 만족하는가. 빈 리스트면 참.
const function Every<E, I>(list: Marker<E, I>, pred: (element: E, idx: I) -> boolean): boolean
	return expectImpl(List, list, "Every").Every(list, pred)
end

-- stylua: ignore
return Trait.Expose(List, {
	IndexOf = IndexOf, Contains = Contains, Count = Count,
	Fold = Fold, Find = Find, Some = Some, Every = Every,
})
