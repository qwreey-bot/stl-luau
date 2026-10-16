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

				Z0ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
				Z0AddAll = Trait.FnMut<<(bag: Self, items: { read [number]: T }) -> ()>>(),
				Z0FindOpt = Trait.Fn<<(bag: Self, pool: { read [number]: T }) -> T?>>(),
				Z0ChooseOpt = Trait.Fn<<(bag: Self, w: { read [number]: number }) -> T?>>(),
				Z0RetRec = Trait.Fn<<(bag: Self, w: { read [number]: number }) -> { read first: T }>>(),
				Z0RetSelfOpt = Trait.Fn<<(bag: Self, w: { read [number]: number }) -> Self?>>(),
				Z0RetTupOpt = Trait.Fn<<(bag: Self, w: { read [number]: number }) -> (number, T?)>>(),
				Z0EachS = Trait.Fn<<(bag: Self, pool: { read [number]: T }, f: (Self, T) -> ()) -> ()>>(),
				Z0AddArr = Trait.FnMut<<(bag: Self, a: stl.ArrRead<T>) -> ()>>(),
				Z0ToArr = Trait.Fn<<(bag: Self) -> stl.Arr<T>>>(),
				Z0AddOptList = Trait.FnMut<<(bag: Self, pool: { read [number]: T }?) -> ()>>(),
				Z0RetRw = Trait.Fn<<(bag: Self) -> { T }>>(),
				Z0RetGetter = Trait.Fn<<(bag: Self, w: { read [number]: number }) -> () -> T?>>(),
				Z0RetMap = Trait.Fn<<(bag: Self, keys: { read [number]: string }) -> { read [string]: T }>>(),

				Z1ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
				Z1TakeOpt = Trait.FnMut<<(bag: Self, pool: { read [number]: T }) -> T?>>(),
				Z1EachM = Trait.FnMut<<(bag: Self, pool: { read [number]: T }, f: (T) -> ()) -> ()>>(),
				Z1RetainM = Trait.FnMut<<(bag: Self, keep: (T, number) -> boolean, extra: { read [number]: T }) -> number>>(),
				Z1AddOrList = Trait.FnMut<<(bag: Self, x: T | { read [number]: T }) -> ()>>(),
				Z1FindD = Trait.Default(function(_ops: any): (bag: Self, pool: { read [number]: T }) -> T?
					return function(_bag: Self, _pool: { read [number]: T }): T?
						return nil
					end
				end),
				Z1TakeD = Trait.DefaultMut(function(_ops: any): (bag: Self, pool: { read [number]: T }) -> (boolean, T?)
					return function(_bag: Self, _pool: { read [number]: T }): (boolean, T?)
						return false, nil
					end
				end),
				Z1FindSig = Trait.Default(function(_ops: any): (bag: Self, pool: { read [number]: T }, ...any) -> T?
					return function(_bag: Self, _pool: { read [number]: T }, ...: any): T?
						return nil
					end
				end, Trait.Sig<<(bag: Self, pool: { read [number]: T }) -> T?>>()),
				Z1PickSig = Trait.Default(function(_ops: any): (bag: Self, pool: { read [number]: T }, ...any) -> T
					return function(_bag: Self, pool: { read [number]: T }, ...: any): T
						return pool[1]
					end
				end, Trait.Sig<<(bag: Self, pool: { read [number]: T }) -> T>>()),

				Z2PushOptA = Trait.FnMut<<(bag: Self, x: T?, rest: { read [number]: T }) -> ()>>(),
				Z2PushOptB = Trait.FnMut<<(bag: Self, rest: { read [number]: T }, x: T?) -> T?>>(),
				Z2SwapOpt = Trait.FnMut<<(bag: Self, x: T?, pool: { read [number]: T }) -> T?>>(),
				Z2Replace = Trait.FnMut<<(bag: Self, pool: { read [number]: T }, old: T?, new: T?) -> boolean>>(),

				Z3ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
				Z3TryPick = Trait.FnMut<<(bag: Self, pool: { read [number]: T }) -> (boolean, T)>>(),
				Z3Unpack = Trait.Fn<<(bag: Self, w: { read [number]: number }) -> ...T>>(),
				Z3Dump = Trait.Fn<<(bag: Self, pool: { read [number]: T }) -> ...any>>(),
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
local Z0_t1 = Bag.Z0ToList(b) -- POS
Bag.Z0AddAll(b, arr) -- POS
local Z0_a1: number? = Bag.Z0FindOpt(b, { 1 }) -- POS
local Z0_a2: number? = Bag.Z0FindOpt(b, arr) -- POS
local Z0_a3: string? = Bag.Z0FindOpt(b, { 1 }) -- NEG
Bag.Z0FindOpt(b, { "s" }) -- NEG
local Z0_c1: number? = Bag.Z0ChooseOpt(b, w) -- POS
local Z0_c2: string? = Bag.Z0ChooseOpt(b, w) -- NEG
local Z0_r1: number = Bag.Z0RetRec(b, w).first -- POS
local Z0_r2: string = Bag.Z0RetRec(b, w).first -- NEG
local Z0_s1: MyBag<number>? = Bag.Z0RetSelfOpt(b, w) -- POS
local Z0_s2: OtherBag<number>? = Bag.Z0RetSelfOpt(b, w) -- NEG
local Z0_u1: number, u2: number? = Bag.Z0RetTupOpt(b, w) -- POS
local Z0_u3: number, u4: string? = Bag.Z0RetTupOpt(b, w) -- NEG
Bag.Z0EachS(b, { 1 }, function(x: MyBag<number>, v: number) end) -- POS
Bag.Z0EachS(b, arr, function(x: MyBag<number>, v: number) end) -- POS
Bag.Z0EachS(b, { 1 }, function(x: MyBag<number>, v: string) end) -- NEG
Bag.Z0EachS(b, { 1 }, function(x: OtherBag<number>, v: number) end) -- NEG
Bag.Z0AddArr(b, arr) -- POS
Bag.Z0AddArr(b, arrS) -- NEG
local Z0_x1: stl.Arr<number> = Bag.Z0ToArr(b) -- POS
local Z0_x2: stl.Arr<string> = Bag.Z0ToArr(b) -- NEG
Bag.Z0AddOptList(b, nil) -- POS
Bag.Z0AddOptList(b, { 1 }) -- POS
Bag.Z0AddOptList(b, arr) -- POS
Bag.Z0AddOptList(b, { "s" }) -- NEG
local Z0_rw = Bag.Z0RetRw(b) -- POS
local Z0_rw1: number? = Z0_rw[1] -- POS
local Z0_rw2: string? = Z0_rw[1] -- NEG
local Z0_gt1: number? = Bag.Z0RetGetter(b, w)() -- POS
local Z0_gt2: string? = Bag.Z0RetGetter(b, w)() -- NEG
local Z0_m = Bag.Z0RetMap(b, { "a" }) -- POS
local Z0_m1: number? = Z0_m.a -- POS
local Z0_m2: string? = Z0_m.a -- NEG
Z0_m.a = 3 -- NEG
local Z1_t1 = Bag.Z1ToList(b) -- POS
local Z1_a1: number? = Bag.Z1TakeOpt(b, { 1 }) -- POS
local Z1_a2: number? = Bag.Z1TakeOpt(b, arr) -- POS
local Z1_a3: string? = Bag.Z1TakeOpt(b, { 1 }) -- NEG
Bag.Z1TakeOpt(b, { "s" }) -- NEG
Bag.Z1EachM(b, { 1 }, function(x: number) end) -- POS
Bag.Z1EachM(b, arr, function(x) local Z1_y: number = x + 1 end) -- POS
Bag.Z1EachM(b, { 1 }, function(x) local Z1_y: string = x end) -- NEG
Bag.Z1EachM(b, { 1 }, function(x: string) end) -- NEG
local Z1_n1: number = Bag.Z1RetainM(b, function(x: number, i: number): boolean return x > i end, { 1 }) -- POS
local Z1_n2: number = Bag.Z1RetainM(b, function(x, i) return x > i end, arr) -- POS
Bag.Z1RetainM(b, function(x: string, i: number): boolean return true end, { 1 }) -- NEG
Bag.Z1AddOrList(b, 1) -- POS
Bag.Z1AddOrList(b, { 1 }) -- POS
Bag.Z1AddOrList(b, arr) -- POS
Bag.Z1AddOrList(b, "s") -- NEG
local Z1_d1: number? = Bag.Z1FindD(b, { 1 }) -- POS
local Z1_d2: number? = Bag.Z1FindD(b, arr) -- POS
local Z1_d3: string? = Bag.Z1FindD(b, { 1 }) -- NEG
local Z1_e1: boolean, e2: number? = Bag.Z1TakeD(b, { 1 }) -- POS
local Z1_e3: boolean, e4: number? = Bag.Z1TakeD(b, arr) -- POS
local Z1_e5: boolean, e6: string? = Bag.Z1TakeD(b, { 1 }) -- NEG
Bag.Z1TakeD(b, { "s" }) -- NEG
local Z1_g1: number? = Bag.Z1FindSig(b, { 1 }) -- POS
local Z1_g2: number? = Bag.Z1FindSig(b, arr) -- POS
local Z1_g3: string? = Bag.Z1FindSig(b, { 1 }) -- NEG
local Z1_h1: number = Bag.Z1PickSig(b, { 1 }) -- POS
local Z1_h2: number = Bag.Z1PickSig(b, arr) -- BND (맨 반환 → 다시 지음)
local Z1_h3: string = Bag.Z1PickSig(b, { 1 }) -- NEG
Bag.Z2PushOptA(b, 1, { 2 }) -- POS
Bag.Z2PushOptA(b, 1, arr) -- POS
Bag.Z2PushOptA(b, "s", { 2 }) -- NEG
local Z2_x1: number? = Bag.Z2PushOptB(b, { 2 }, 1) -- POS
local Z2_x2: number? = Bag.Z2PushOptB(b, arr, nil) -- POS
Bag.Z2PushOptB(b, { 2 }, "s") -- NEG
local Z2_x3: string? = Bag.Z2PushOptB(b, { 2 }, 1) -- NEG
local Z2_y1: number? = Bag.Z2SwapOpt(b, 1, arr) -- POS
local Z2_y2: number? = Bag.Z2SwapOpt(b, nil, { 1 }) -- POS
Bag.Z2SwapOpt(b, "s", { 1 }) -- NEG
local Z2_z1: boolean = Bag.Z2Replace(b, arr, 1, 2) -- POS
local Z2_z2: boolean = Bag.Z2Replace(b, { 1 }, nil, 2) -- POS
Bag.Z2Replace(b, { 1 }, 1, "s") -- NEG
local Z3_ok1: boolean, v1: number = Bag.Z3TryPick(b, { 1 }) -- POS
local Z3_ok2: boolean, v2: string = Bag.Z3TryPick(b, { 1 }) -- NEG
local Z3_u1: number = Bag.Z3Unpack(b, { 1 }) -- POS
local Z3_u2: string = Bag.Z3Unpack(b, { 1 }) -- NEG
Bag.Z3Dump(b, arr) -- POS
local canary: string = 1
return { picked, folded, self2, p, n, parts, first, same, mapped, negPeek, wideSelf, negMap, negParts, shadow, o, canary }
