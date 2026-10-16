--!strict
--[[
	사용자 트레이트의 진입점 서명(`Trait.Entries`)이 칸의 모양을 잃지 않는지(2026-10-16 리뷰 1라운드 — Opus F1·F2·F3, Gemini T2).
	- 칸에 `{ Self }`·`{ [k]: Self }`·`{ read [number]: Self }` 가 있어도 진입점이 다 있고(예전엔 `occurs` 가 인덱서를 안 봐 트레이트의 진입점 전부가 사라짐)
	- 칸 자신의 제네릭 이름이 정의의 것과 같으면(`<T>`) **그 진입점 서명만** 빠지고 나머지는 있음(예전엔 "Duplicate type parameter" 로 전부 사라짐 —
	  이름을 바꿔 지어도 타입 함수 안에서 바깥 `T` 와 가린 `T` 가 섞여 믿을 수 없어 뺌, 아래 `-- 경계` 줄)
	- 읽기 전용 인덱서(`{ read [number]: T }` 인자, `{ read [K]: V }` 반환)가 진입점에서도 읽기 전용(예전엔 다시 지으며 `read` 를 잃어 `Arr` 를 거절하고
	  결과에 쓰기가 0건 — 타입 함수는 읽기 전용 인덱서를 만들지도 알아보지도 못해 그런 칸은 다시 짓지 않음)
	- `Self` 를 둘째 인자로 받는 칸(돌연변이 E11 이 살아남던 자리)

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 줄마다 + CANARY 1).
]]
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag: Assoc<T> } }

local Bag
do
	Bag = Trait.Trait(
		"Spike74.Bag",
		function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
			return table.freeze({
				Peek = Trait.Fn<<(bag: Self) -> T?>>(),
				MergeAll = Trait.FnMut<<(bag: Self, others: { Self }) -> ()>>(),
				ByName = Trait.Fn<<(bag: Self, named: { [string]: Self }) -> number>>(),
				Split = Trait.FnMut<<(bag: Self) -> { Self }>>(),
				AddAll = Trait.FnMut<<(bag: Self, items: { read [number]: T }) -> ()>>(),
				View = Trait.Fn<<(bag: Self) -> { read [string]: T }>>(),
				Pair = Trait.Fn<<(bag: Self, other: Self) -> boolean>>(),
				PushWithRest = Trait.FnMut<<(bag: Self, first: T, rest: { read [number]: T }) -> ()>>(),
				Configure = Trait.FnMut<<(bag: Self, opts: { read items: { read [number]: T } }) -> ()>>(),
				PushMany = Trait.FnMut<<(bag: Self, pool: { read [number]: T }, ...T) -> ()>>(),
				PushOpt = Trait.FnMut<<(bag: Self, x: T?, rest: { read [number]: T }) -> ()>>(),
				MergeWith = Trait.FnMut<<(bag: Self, other: Self, extra: { read [number]: T }) -> ()>>(),
				Pick = Trait.Fn<<(bag: Self, pool: { read [number]: T }) -> T>>(),
				Log = Trait.Fn<<(bag: Self, pool: { read [number]: T }, ...any) -> ()>>(),
				AddAllS = Trait.FnMut<<(bag: Self, items: { read [number]: T }) -> Self>>(),
				XRetRw = Trait.Fn<<(bag: Self) -> { T }>>(),
				Bucket = Trait.Fn<<(bag: Self, key: T) -> { read [number]: T }>>(),
				FoldIn = Trait.Default(
					function(_ops: any): <U>(bag: Self, init: U, f: (U, T) -> U, pool: { read [number]: T }) -> U
						return function<U>(_bag: Self, init: U, _f: (U, T) -> U, _pool: { read [number]: T }): U
							return init
						end
					end
				),
				MapTo = Trait.Default(function(_ops: any): <U>(bag: Self, f: (U) -> U, init: U) -> U
					return function<U>(_bag: Self, _f: (U) -> U, init: U): U
						return init
					end
				end),
				Shadow = Trait.Default(function(_ops: any): <T>(bag: Self, init: T) -> T
					return function<T>(_bag: Self, init: T): T
						return init
					end
				end),
			})
		end
	)
end
type MyBag<T> = { read __type: stl.TraitToken<"Spike74">, read __traits: { read Bag: Assoc<T> } }
type OtherBag<T> = { read __type: stl.TraitToken<"Spike74.Other">, read __traits: { read Bag: Assoc<T> } }
local b: MyBag<number> = nil :: any
local o: OtherBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)

-- 진입점이 전부 있고 맞는 쓰임은 0건
local p: number? = Bag.Peek(b)
Bag.MergeAll(b, { b })
local n: number = Bag.ByName(b, { x = b })
local parts: { MyBag<number> } = Bag.Split(b)
Bag.AddAll(b, arr) -- 읽기 리스트 자리에 Arr
Bag.AddAll(b, { 1, 2 })
local view = Bag.View(b)
local first: number? = view.x
local same: boolean = Bag.Pair(b, b)
local mapped: string = Bag.MapTo(b, function(s: string): string
	return s
end, "x")

-- NEG
local negPeek: string? = Bag.Peek(b) -- NEG: 원소
Bag.AddAll(b, { "x" }) -- NEG: 원소
view.x = 1 -- NEG: 읽기 전용 인덱서가 진입점에서도 읽기 전용
local wideSelf = Bag.Pair(b, 5) -- 경계(0건): 제네릭 `Self` 가 두 인자에서 합집합으로 넓어짐 — 손으로 쓴 서명도 같음(Luau 의 추론), `Pair(b, b)` 는 돌연변이 E11 을 잡는 자리
local negMap: number = Bag.MapTo(b, function(s: string): string
	return s
end, "x") -- NEG: 칸의 제네릭 U 가 부르는 자리에서 정해짐
local shadow = Bag.Shadow -- 경계: 칸의 제네릭 이름이 정의의 T 와 같아 진입점 서명이 빠짐(이 줄의 에러가 지금의 동작 — 이름을 바꾸세요)
local negParts: { OtherBag<number> } = Bag.Split(b) -- NEG: { Self } 의 Self 가 이어짐

-- 인덱서 칸이 여럿 + 맨 제네릭 인자(리뷰 2라운드 — 정의의 제네릭을 그대로 쓰면 맞는 호출 `PushWithRest(b, 1, { 2 })` 가 거절됐음)
Bag.PushWithRest(b, 1, { 2 })
Bag.PushWithRest(b, "x", { 2 }) -- NEG: 맨 인자 원소
Bag.PushWithRest(b, 1, { "y" }) -- NEG: 리스트 원소
Bag.PushWithRest(b, 1, arr) -- 경계: 맨 제네릭 인자가 있는 칸은 다시 지어 읽기 전용 인덱서를 잃음 → 읽기 전용 칸의 `Arr` 를 거절(이 줄의 에러가 지금의 동작)
-- 중첩된 읽기 전용 인덱서(필드 안)도 그대로(돌연변이 M06 — 필드 안을 안 보면 다시 지어 `Arr` 를 거절)
Bag.Configure(b, { items = arr })
Bag.Configure(b, { items = { "z" } }) -- NEG: 원소
-- 맨 인자의 여러 꼴(리뷰 3라운드): 가변 꼬리 `...T` 도 맨 인자(D1 — 안 보면 `PushMany(b, { 1 }, 2)` 가 거절), 유니온 갈래(`x: T?`)는 그대로 둬도
-- 묶여 읽기 전용을 지킴(D2 — 세면 `PushOpt(b, 1, arr)` 가 거절), 맨 `other: Self` 도 맨 인자(X04 — 안 세면 `MergeWith(b, b, { 1 })` 가 거절)
Bag.PushMany(b, { 1 }, 2, 3)
Bag.PushMany(b, { 1 }, "s") -- NEG: 꼬리 원소
Bag.PushOpt(b, 1, arr)
Bag.PushOpt(b, nil, { 2 })
Bag.PushOpt(b, "s", { 2 }) -- NEG
Bag.MergeWith(b, b, { 1 })
Bag.MergeWith(b, b, { "s" }) -- NEG
-- 반환의 맨 제네릭(리뷰 4라운드 ① — 안 세면 반환이 묶이지 않은 `T`·`Self`), 그리고 다시 짓지 않아야 할 칸들(돌연변이 Y02·Y10 — 세면 `Arr` 거절)
local picked: number = Bag.Pick(b, { 1 })
Bag.Pick(b, { "s" }) -- NEG
Bag.Log(b, arr, "x", 1) -- `...any` 꼬리는 맨 정의 제네릭이 아님
local folded: string = Bag.FoldIn(b, "", function(acc: string, v: number): string
	return acc .. v
end, arr) -- 칸 자신의 `U` 를 맨 인자로 받아도 다시 짓지 않음
local self2: MyBag<number> = Bag.AddAllS(b, { 1 }) -- `-> Self` 도 맨 반환(안 세면 'got Self')
Bag.AddAllS(b, arr) -- 경계: 그래서 다시 지어 읽기 전용 인덱서를 잃음 → `Arr` 거절(이 줄의 에러가 지금의 동작)
local bucket = Bag.Bucket(b, 1)
bucket[1] = 5 -- 경계(0건): 맨 인자 칸은 다시 지어 **반환의** 읽기 전용 인덱서도 잃음(리뷰 4라운드 ② — 받아들인 대가의 다른 쪽)

local arrS = stl.Arr.Of("a")
local w = { 1, 2 }
local rw = Bag.XRetRw(b) -- POS
local rw1: number? = rw[1] -- POS
local rw2: string? = rw[1] -- NEG
local canary: string = 1
return { picked, folded, self2, p, n, parts, first, same, mapped, negPeek, wideSelf, negMap, negParts, shadow, o, canary }
