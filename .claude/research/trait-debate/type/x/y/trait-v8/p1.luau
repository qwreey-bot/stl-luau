--!strict
local Trait = require("./Trait")
local P = require("./Traits")
local stl = require("../../../src")
type A = Trait.A
type Arr<T> = stl.Arr<T>
-- P1: Default 에 mode 를 빼먹음 / 엉뚱한 값
const T1 = Trait.Trait("P1", function<M>(mode: M) return function<Self, T>(of: (Self & Trait.Item<T>) | Trait.AnyToken)
	return {
		Get = Trait.Fn<<(s: Self) -> T>>(),
		D1 = Trait.Default("full", function(ops: any) return function(s: Self): T return "bad" :: any end end), -- 모드 리터럴 박음
		D2 = Trait.Default(mode, function(ops: any) return function(s: Self): number return 1 end end), -- T 와 무관한 반환(옳은 타입)
	}
end end)
export type P1<Self, T> = typeof(T1.Of<<Self, T>>(nil :: any))
export type P1Impl<Self, T> = typeof(T1.ImplOf<<Self, T>>(nil :: any))
local function get(s: Arr<A>): A return s[1] end
-- D1 이 "full" 로 박혀 있으면 등록 보기에서 선택 칸이 아님 -> 필수가 됨?
const r1: P1Impl<Arr<A>, A> = { Get = get }
-- D2 반환 string 으로 덮어쓰기 (서명 불일치) 
const r2: P1Impl<Arr<A>, A> = { Get = get, D2 = function(s: Arr<A>): string return "x" end } -- NEG
-- Default 의 ops 를 any 로 받으면 몸통 검사 사라짐 (정의자 실수 — 타입 못 막음)
local canary: string = 1
return { r1, r2, canary }
