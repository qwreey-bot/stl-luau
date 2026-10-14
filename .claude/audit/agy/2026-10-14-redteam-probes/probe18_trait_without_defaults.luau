--!strict
-- probes/probe18_trait_without_defaults.luau
-- 기본 구현이 전혀 없는 트레이트(예: Deque)를 정의할 때
-- B'의 Trait 함수에 비-모드 팩토리를 넘길 수 있는가?

type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
local function Fn<F>(): F return nil :: any end

local function Trait<F, G>(
	name: string,
	def: (mode: "full") -> F,
	implDef: ((mode: "impl") -> G)?
): { read Of: F, read ImplOf: G }
	return nil :: any
end

-- 순수 필수 메서드만 있는 팩토리 (mode 없음)
local function simpleDequeDef<Self, T>(of: (Self & Item<T>) | Token)
	return {
		Push = Fn<<(s: Self, x: T) -> Self>>(),
		Pop = Fn<<(s: Self) -> T?>>(),
	}
end

-- 시도 1: Trait("Deque", simpleDequeDef)
-- simpleDequeDef는 (mode: "full") 매개변수가 없으므로 타입 에러가 나는가?
const Deque1 = Trait("Deque", simpleDequeDef) -- NEG: 타입 불일치!

local canary: string = 1
return { canary, Deque1 }
