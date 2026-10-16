--!strict
--[[
	바깥에서 트레이트를 붙이는 중간자(질문 BA, 2026-10-15 — 사용자: "<T>(Arr<T>) -> Stack<T> 를 주는 뭔가", "a to b 계약자가 두 점이 확실한지",
	"깔끔하게 … Stack<T> 와 Arr<T> 를 두고 진짜 변환"). 등록(런타임)은 타입을 못 바꾸니 그 쌍을 아는 쪽이 `Trait.Converter` 에 **타입을 적어**
	씁니다. 위로 바꾼 값은 그 트레이트로만 보이고(`Arr` 함수·덱 진입점은 못 받음), 아래로 바꾸면 다시 그 종류.
	⚠️ 타입만 봅니다(런타임에 돌리지 않음 — 실제로는 `Stack.ImplFor(stl.Arr, …)` 뒤에 만들어야 `Converter` 가 받음, `spec.traitrebuild` 9절).
	종류는 닫힌 트레이트(질문 BB): 위로는 `Converter(stl.Stack, stl.Arr)`(그 종류를), 아래로는 `Converter(stl.Arr)`(닫힌 트레이트로) — 토큰을 안 만짐.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 줄마다 + CANARY 1).
]]
local stl = require("../../../../src")
type Arr<T> = stl.Arr<T>
local Trait = stl.Trait

local asStack: <T>(a: Arr<T>) -> stl.Stack<T> = Trait.Converter(stl.Stack, stl.Arr)
local asArr: <T>(s: stl.Stack<T>) -> Arr<T> = Trait.Converter(stl.Arr)
local asPeek: <T>(a: stl.ArrRead<T>) -> stl.StackRead<T> = Trait.Converter(stl.Stack, stl.Arr)

local a = stl.Arr.Of(1, 2, 3)
local s = asStack(a)
stl.Stack.Push(s, 4)
local top: number? = stl.Stack.Pop(s)
local back: Arr<number> = asArr(s)
-- 덱도 변환자로(`Deque.AsStack` — 스택은 덱을 모름, 덱 쪽이 변환자를 내줌)
local d = stl.CircularDeque.Of(1, 2)
local pushed: stl.Stack<number> = stl.Stack.Push(stl.Deque.AsStack(d), 3)
local negPush = stl.Stack.Push(s, "x") -- NEG: 원소 타입이 이어짐
local negTop: string? = stl.Stack.Peek(s) -- NEG
local negRaw = stl.Stack.Push(a, 4) -- NEG: 바꾸지 않은 Arr 은 스택이 아님(타입은 등록으로 안 바뀜 — 뿌리)
local negArrFn = stl.Arr.Len(s) -- NEG: 위로 바꾼 값은 스택으로만(진짜 변환)
local negDeque = stl.Deque.PushFront(s, 1) -- NEG: 스택은 덱이 아님(덱 레코드를 빌리던 때는 여기가 열렸음)
local negBackElem: Arr<string> = asArr(s) -- NEG: 아래로 바꿔도 원소 타입 그대로
local negDequeRaw = stl.Stack.Push(d, 3) -- NEG: 덱도 바꾸지 않으면 타입으로는 스택이 아님
local r: stl.ArrRead<number> = a
local negBorrow = asStack(r) -- NEG: 빌린 읽기 참조는 바꿀 수 있는 스택이 못 됨
local p: number? = stl.Stack.Peek(asPeek(r))
local negPeekPush = stl.Stack.Push(asPeek(r), 1) -- NEG: 읽기로 바꾼 값은 쓰기 진입점을 못 받음
-- 덱 변환자의 읽기·쓰기 경계(리뷰 1라운드 F6 — 빌린 참조를 받게, 읽기 판이 쓰기 스택을 돌려주게 바꿔도 통과했음)
local borrowedDeque: stl.CircularDequeRead<number> = d
local peekBorrowed: number? = stl.Stack.Peek(stl.Deque.AsStackRead(borrowedDeque))
local negAsStackBorrowed = stl.Deque.AsStack(borrowedDeque) -- NEG: 빌린 덱은 바꿀 수 있는 스택이 못 됨
local negAsQueueBorrowed = stl.Deque.AsQueue(borrowedDeque) -- NEG
local negReadPush = stl.Stack.Push(stl.Deque.AsStackRead(borrowedDeque), 1) -- NEG: 읽기 판은 쓰기 진입점을 못 받음
local negReadQueue = stl.Queue.Push(stl.Deque.AsQueueRead(borrowedDeque), 1) -- NEG

-- 바깥 구현자가 배럴만으로 등록 표를 적음(리뷰 1라운드 T5 — 탐침 타입·`MapAssocRead` 가 배럴에 없었음)
type MyMap<K, V> = {
	read __type: stl.TraitToken<"Spike72.MyMap">,
	read __traits: { read Map: stl.MapAssoc<K, V>, read Collection: stl.CollectionAssoc },
}
type MyMapRead<K, V> = {
	read __type: stl.TraitToken<"Spike72.MyMap">,
	read __traits: { read Map: stl.MapAssocRead<K, V> },
}
type MySetRead<T> = { read __type: stl.TraitToken<"Spike72.MySet">, read __traits: { read Set: stl.SetAssocRead<T> } }
local myMapImpl: stl.MapProvided<MyMap<stl.TraitA, stl.TraitB>, stl.TraitA, stl.TraitB> = {
	Get = function(_m: MyMap<stl.TraitA, stl.TraitB>, _k: stl.TraitA): stl.TraitB?
		return nil
	end,
	Set = function(_m: MyMap<stl.TraitA, stl.TraitB>, _k: stl.TraitA, _v: stl.TraitB) end,
	Has = function(_m: MyMap<stl.TraitA, stl.TraitB>, _k: stl.TraitA): boolean
		return false
	end,
	Remove = function(_m: MyMap<stl.TraitA, stl.TraitB>, _k: stl.TraitA): stl.TraitB?
		return nil
	end,
	Iter = function(_m: MyMap<stl.TraitA, stl.TraitB>): { read [stl.TraitA]: stl.TraitB }
		return {}
	end,
}
local negMyMapImpl: stl.MapProvided<MyMap<stl.TraitA, stl.TraitB>, stl.TraitA, stl.TraitB> = {
	-- 아랫줄 NEG: 값을 못박음(탐침 타입이라 샘)
	Get = function(_m: MyMap<stl.TraitA, stl.TraitB>, _k: stl.TraitA): number?
		return nil
	end,
	Set = myMapImpl.Set,
	Has = myMapImpl.Has,
	Remove = myMapImpl.Remove,
	Iter = myMapImpl.Iter,
}
local myRead: MyMapRead<string, number> = nil :: any
local myKeys = stl.Map.Keys(myRead)
local mySetRead: MySetRead<string> = nil :: any
local myProbe: stl.TraitC = nil :: any
-- 배럴의 읽기 레코드는 `Mut` 을 요구하지 않음(리뷰 2라운드 — 돌연변이 M26~M28: `Assoc` 로 바꿔도 통과했음)
local plainMapRec: { read Key: () -> string, read Value: () -> number } = nil :: any
local asMapRead: stl.MapAssocRead<string, number> = plainMapRec
local plainSetRec: { read Item: () -> string } = nil :: any
local asSetRead: stl.SetAssocRead<string> = plainSetRec
local setBorrow: stl.SetRead<string> = mySetRead
stl.Map.Set(myRead, "k", 1) -- NEG: 읽기 레코드엔 `Mut` 이 없어 쓰기 진입점을 못 받음
-- 탐침 타입 TraitA 도 못박음을 잡음(돌연변이 M29 — `TraitA = any` 여도 통과했음)
local negKeyPinned: stl.MapProvided<MyMap<stl.TraitA, stl.TraitB>, stl.TraitA, stl.TraitB> = {
	Get = myMapImpl.Get,
	Set = myMapImpl.Set,
	-- 아랫줄 NEG: 키를 못박음
	Has = function(_m: MyMap<stl.TraitA, stl.TraitB>, _k: number): boolean
		return false
	end,
	Remove = myMapImpl.Remove,
	Iter = myMapImpl.Iter,
}

local canary: string = 1
return {
	peekBorrowed,
	negAsStackBorrowed,
	negAsQueueBorrowed,
	negReadPush,
	negReadQueue,
	negMyMapImpl,
	myKeys,
	mySetRead,
	myProbe,
	top,
	back,
	pushed,
	negPush,
	negTop,
	negRaw,
	negArrFn,
	negDeque,
	negBackElem,
	negDequeRaw,
	negBorrow,
	p,
	negPeekPush,
	canary,
}
