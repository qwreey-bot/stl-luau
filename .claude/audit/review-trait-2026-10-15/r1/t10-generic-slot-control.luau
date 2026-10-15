--!strict
-- 타입 프로브 t10(대조): t09 의 같은 모듈 구멍이 `View` 탓인지 — 같은 모양을 손으로 적은 별칭, 그리고 View 없이
-- 정의 함수의 반환을 typeof 로 꺼낸 것.
type A = { read __probeA: true }
type Tok = { read name: string }
type Bag<T> = { read __type: Tok, read __generics: { read Item: (T) -> T }, items: { T } }
type Hand = { read Fold: (<U>(bag: Bag<A>, init: U, fn: (U, A) -> U) -> U)?, read Map: <U>(bag: Bag<A>, fn: (A) -> U) -> { U } }
local function map<U>(_b: Bag<A>, _fn: (A) -> U): { U } return {} end
local negPinU: Hand = { Map = map,
	Fold = function(_b: Bag<A>, init: number, _fn: (number, A) -> number): number return init end } -- NEG 1
local negMapPin: Hand = {
	Map = function(_b: Bag<A>, _fn: (A) -> number): { number } return {} end } -- NEG 7
-- 정의 함수 모양 그대로(같은 모듈의 제네릭 함수 반환을 typeof 로)
local function def<Self, T>(of: Self)
	return table.freeze({
		Map = (nil :: any) :: <U>(bag: Self, fn: (T) -> U) -> { U },
	})
end
type Via = typeof(def<<Bag<A>, A>>(nil :: any))
local negVia: Via = {
	Map = function(_b: Bag<A>, _fn: (A) -> number): { number } return {} end } -- NEG 9
local canary: string = 1
return { negPinU, negMapPin, negVia, canary }
