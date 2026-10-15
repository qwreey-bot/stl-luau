--!strict
--[[
	타입 함수 `Trait.View`(2026-10-15 — 정의를 한 번만 넘기는 레코드 안, `.claude/research/trait-udtf`)가 **제네릭을 지키는지**.

	`View` 는 정의 함수의 타입을 직렬화했다 다시 지어 돌려줍니다(사용자 타입 함수의 동작). 다시 지은 뒤에도
	- 등록 표의 기본 구현 칸에 든 **제네릭 함수**(`Fold<U>`)의 `U` 를 못박거나 원소를 못박거나 반환을 바꾸면 잡히는지(인라인 표 포함),
	- 완성 표의 `Fold` 가 부르는 자리마다 `U` 를 새로 정하는지,
	- 완성 표를 받는 **사용자 제네릭 함수**(`drain<C, T>`, `useFull<Self, E, I>`)가 원소 타입을 이어 주는지.
	Sonnet 이 시제품에서 만든 70·72(`trait-udtf/sonnet/repoB-spikes`)를 합친 것. Gemini 가 "안 됨" 이라 한 장면(바깥 제네릭이
	정해지지 않은 별칭에 타입 함수를 거는 모양)은 이 모양이 아닙니다 — `trait-udtf/README.md`.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 줄마다 + CANARY 1).
]]
local stl = require("../../../../src")
type A = { read __probeA: true }
type Arr<T> = stl.Arr<T>
local d = stl.CircularDeque.Of(1, 2, 3)
local l = stl.List.Of(d)
local get, first, last = stl.Arr.Get, stl.Arr.FirstIndex, stl.Arr.LastIndex
local nextI, prevI = stl.Arr.NextIndex, stl.Arr.PrevIndex

--[[ 등록 표의 기본 구현 칸 — 제네릭 함수 ]]
local okGeneric: stl.ListProvided<Arr<A>, A, number> = {
	Get = get, FirstIndex = first, LastIndex = last, NextIndex = nextI, PrevIndex = prevI,
	Fold = function<U>(_list: Arr<A>, init: U, _fn: (U, A, number, ...any) -> U): U
		return init
	end,
}
local negPinU: stl.ListProvided<Arr<A>, A, number> = {
	Get = get, FirstIndex = first, LastIndex = last, NextIndex = nextI, PrevIndex = prevI,
	Fold = function(_list: Arr<A>, init: number, _fn: (number, A, number, ...any) -> number): number -- NEG: U 를 못박음
		return init
	end,
}
local negPinE: stl.ListProvided<Arr<A>, A, number> = {
	Get = get, FirstIndex = first, LastIndex = last, NextIndex = nextI, PrevIndex = prevI,
	Fold = function<U>(_list: Arr<A>, init: U, _fn: (U, string, number, ...any) -> U): U -- NEG: 원소를 못박음
		return init
	end,
}
local negRetU: stl.ListProvided<Arr<A>, A, number> = {
	Get = get, FirstIndex = first, LastIndex = last, NextIndex = nextI, PrevIndex = prevI,
	Fold = function<U>(_list: Arr<A>, _init: U, _fn: (U, A, number, ...any) -> U): number -- NEG: 반환
		return 1
	end,
}
local negFind: stl.ListProvided<Arr<A>, A, number> = {
	Get = get, FirstIndex = first, LastIndex = last, NextIndex = nextI, PrevIndex = prevI,
	Find = stl.Arr.Len, -- NEG: 배선
}
local okArrFold: stl.ListProvided<Arr<A>, A, number> = {
	Get = get, FirstIndex = first, LastIndex = last, NextIndex = nextI, PrevIndex = prevI, Fold = stl.Arr.Fold,
}

--[[ 완성 표의 Fold — U 는 부르는 자리에서 ]]
local sum: number = l.Fold(d, 0, function(a: number, x: number, _i: number): number
	return a + x
end)
local joined: string = l.Fold(d, "", function(a: string, x: number, _i: number): string
	return a .. x
end)
local negFoldRet: string = l.Fold(d, 0, function(a: number, x: number, _i: number): number -- NEG
	return a + x
end)
local contains = l.Contains
local c: boolean = contains(d, 1)

--[[ 완성 표를 받는 사용자 제네릭 함수 ]]
local function useFull<Self, E, I>(t: stl.ListFull<Self, E, I>, v: Self): E?
	const at = t.FirstIndex(v)
	return if at == nil then nil else t.Get(v, at)
end
local got: number? = useFull(l, d)
local negGot: string? = useFull(l, d) -- NEG
local function drain<C, T>(st: stl.StackFull<C, T>, c: C): { T }
	const out = {}
	local x = st.Pop(c)
	while x ~= nil do
		table.insert(out, x)
		x = st.Pop(c)
	end
	return out
end
local all: { number } = drain(stl.Stack.Of(d), d)
local negAll: { string } = drain(stl.Stack.Of(d), d) -- NEG

--[[ 같은 모듈의 경계(질문 AZ — 2026-10-15 사용자: (가) 유지) — 트레이트를 **이 파일 꼭대기에서** 정의하고 여기서 등록하면 칸 자체가
     제네릭인 함수(`Fold<U>`)의 실수가 0건(다시 지은 `<U>` 가 모듈 스코프를 받고 상류 `Subtyping.cpp:830` 이 통과시킴). 규약: 같은 파일에서
     등록하려면 정의를 `do … end` 에. 아래 `-- 경계` 줄은 **지금 0건이 기대값** — 상류가 고치면 건수가 바뀌어 배터리가 알립니다. ]]
type Bag<T> = { read __type: stl.TraitToken<string>, read __generics: { read Item: (T) -> T }, items: { T } }
local Top = stl.Trait.Trait("Spike70.Top", function<Self, T>(of: (Self & stl.TraitItem<T>) | stl.TraitToken<string>)
	return table.freeze({
		Fold = stl.Trait.Default(function(_ops: any): <U>(bag: Self, init: U, fn: (U, T) -> U) -> U
			return function<U>(_bag: Self, init: U, _fn: (U, T) -> U): U
				return init
			end
		end),
	})
end)
local topPinned: typeof(Top.ImplOf<<Bag<A>, A>>(nil :: any)) = {
	Fold = function(_b: Bag<A>, init: number, _fn: (number, A) -> number): number -- 경계: 같은 모듈이라 0건(규약으로 피함)
		return init
	end,
}
local Boxed
do
	Boxed = stl.Trait.Trait("Spike70.Boxed", function<Self, T>(of: (Self & stl.TraitItem<T>) | stl.TraitToken<string>)
		return table.freeze({
			Fold = stl.Trait.Default(function(_ops: any): <U>(bag: Self, init: U, fn: (U, T) -> U) -> U
				return function<U>(_bag: Self, init: U, _fn: (U, T) -> U): U
					return init
				end
			end),
		})
	end)
end
local boxedPinned: typeof(Boxed.ImplOf<<Bag<A>, A>>(nil :: any)) = {
	Fold = function(_b: Bag<A>, init: number, _fn: (number, A) -> number): number -- NEG: 정의를 do 블록에 두면 잡힘
		return init
	end,
}

local canary: string = 1
return { okGeneric, negPinU, negPinE, negRetU, negFind, okArrFold, sum, joined, negFoldRet, c, got, negGot, all, negAll, topPinned, boxedPinned, canary }
