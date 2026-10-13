--!strict
--[[
	List — 위치로 원소를 읽는 순차 컨테이너의 트레이트. `Arr`·`Deque` 가 구현합니다.

	이 파일이 트레이트의 전부입니다: 계약(`Ops` — 위치 프리미티브 다섯), **기본 구현**(프리미티브만으로
	도는 읽기 알고리즘), 타입 마커, 종류를 모르는 코드의 진입점(`List.IndexOf(list, x)`).

	⭐ **프리미티브 다섯만 구현하면 읽기 알고리즘이 따라옵니다**(2026-10-13, `papers/07`). 같은 이름의
	함수를 가진 구현은 그것이 기본 구현을 대신합니다(`Arr` 는 모듈을 그대로 등록해 전부 자기 직접
	구현으로). 기본 구현은 **바깥에서 리스트를 구현하는 쪽을 위한 것**이기도 합니다 — 라이브러리 안의
	종류가 전부 재정의하더라도 둡니다(사용자 방침).

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
export type Ops<C, E, I> = {
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
-- 선택 필드로 적어 두어야 재정의의 서명이 검사됩니다 — 필수만 적은 타입이면 재정의 자리는 폭 서브타이핑으로
-- 아무 값이나 통과했습니다(`Fold = "문자열"` 이 0건, 리뷰). 콜백 타입의 `...any` 는 "원소와 위치, 그리고 구현이
-- 더 넘길 수도 있음" 입니다 — `Arr` 의 콜백은 셋째로 읽기 뷰를 받고 `Some`/`Every` 는 구간 인자도 받는데,
-- Luau 는 인자 수가 다른 함수 타입을 서로 넣어 주지 않아 꼬리가 없으면 `Arr` 모듈이 이 타입에 못 들어갑니다(실측).
export type Impl<C, E, I> = {
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
	read Some: ((list: C, pred: (item: E, idx: I, ...any) -> boolean, ...any) -> boolean)?,
	read Every: ((list: C, pred: (item: E, idx: I, ...any) -> boolean, ...any) -> boolean)?,
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
}) :: Trait.Trait<Full<any, any, any>, Impl<any, any, any>>
const dispatch = Trait.Dispatch

--[[ 진입점 — 종류를 모르는 코드가 부릅니다 ]]
-- 그 종류의 완성 표를 부릅니다 — `Arr` 처럼 자기 구현이 있는 종류는 그것이(빠름), `Deque`·사용자 리스트는
-- 위의 기본 구현이 돕니다. 콜백은 원소와 위치를 받습니다. 종류를 아는 코드는 그 모듈의 함수를 직접
-- 쓰세요(`Arr.IndexOf`).

-- 같은 원소가 처음 나오는 위치. 없으면 nil. 비교는 `==` 입니다 — 값 동등성이 필요하면 호출자가 다른 걸
-- 써야 합니다. (원소 타입이 다른 `item` 은 타입 에러가 아닙니다 — `E` 가 둘의 합으로 넓어집니다.
-- 건전하고(그냥 nil), 예전 판도 같았습니다.)
const function IndexOf<E, I>(list: Marker<E, I>, item: E): I?
	return dispatch(List, list, "IndexOf").IndexOf(list, item)
end

-- 같은 원소가 있는가(`==` 비교).
const function Contains<E, I>(list: Marker<E, I>, item: E): boolean
	return dispatch(List, list, "Contains").Contains(list, item)
end

-- 세어서 구한 개수(AE, 2026-10-06 — `Len` 은 알고 있는 크기, `Count` 는 셈). 술어가 있으면 참인 원소만.
-- 길이를 아는 컨테이너는 자기 `Len` 이 빠릅니다(`Collection.Len`).
const function Count<E, I>(list: Marker<E, I>, pred: ((element: E, idx: I) -> boolean)?): number
	return dispatch(List, list, "Count").Count(list, pred)
end

-- 앞에서부터 접기.
const function Fold<E, I, U>(list: Marker<E, I>, init: U, fn: (acc: U, element: E, idx: I) -> U): U
	return dispatch(List, list, "Fold").Fold(list, init, fn)
end

-- 처음으로 조건을 만족하는 원소와 그 위치. 없으면 `nil, nil`.
const function Find<E, I>(list: Marker<E, I>, pred: (element: E, idx: I) -> boolean): (E?, I?)
	return dispatch(List, list, "Find").Find(list, pred)
end

-- 하나라도 만족하는가.
const function Some<E, I>(list: Marker<E, I>, pred: (element: E, idx: I) -> boolean): boolean
	return dispatch(List, list, "Some").Some(list, pred)
end

-- 전부 만족하는가. 빈 리스트면 참.
const function Every<E, I>(list: Marker<E, I>, pred: (element: E, idx: I) -> boolean): boolean
	return dispatch(List, list, "Every").Every(list, pred)
end

-- stylua: ignore
return Trait.Module(List, {
	IndexOf = IndexOf, Contains = Contains, Count = Count,
	Fold = Fold, Find = Find, Some = Some, Every = Every,
})
