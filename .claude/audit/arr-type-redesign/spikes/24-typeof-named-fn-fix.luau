--!strict
-- quad typing-limits §1 ③: 재귀 메소드를 인라인 제네릭 시그니처로 쓰지 말고
-- **이름 붙은 top-level 함수 + typeof(그함수)** 로 선언하면 반환 타입이 산다.
-- arr 의 map 모양(Arr<T> -> Arr<G>)에 그대로 적용해 재현되는지 본다.
--
-- **결과 (2026-09-21 실측, luau 0.734)**
--   A 인라인: 선언 자체가 "Recursive type being used with different parameters",
--             a_mapped 가 Unifiable<Error> — quad §1 이 말한 그 누수.
--   B typeof: b_mapped = Data<string>, b_chain = Data<boolean> — **타입 인자가
--             정확히 실리고 3단 체이닝까지 보존됨.** NEG 도 전부 검출.
--
-- 핵심: IfceB 는 **제네릭이 아닙니다**(`{ map: typeof(Map), push: typeof(Push) }`).
-- 제네릭성은 이름 붙은 함수 쪽에 있습니다. 이게 재귀 파라미터 충돌을 없앱니다.
--
-- 기대 진단 5건: (15) A 선언 실패, (16) A 파생 실패, (36)(42) B 의 NEG, (45) canary.

type Data<T> = { n: number, [number]: T }

--#region A. 인라인 선언 (지금 stl-luau 방식)
type IfceA<T> = {
	map: <G>(self: any, fn: (T) -> G) -> ArrA<G>,
	push: (self: any, v: T) -> ArrA<T>,
}
type ArrA<T> = setmetatable<Data<T>, { __index: IfceA<T> }>

local a = (nil :: any) :: ArrA<number>
local a_mapped = a:map(function(x: number)
	return tostring(x)
end)
local a_neg: number = a_mapped[1] -- 에러여야 함 (string 인데)
--#endregion

--#region B. quad ③: 이름 붙은 함수 + typeof
local function Map<T, G>(self: ArrB<T>, fn: (T) -> G): ArrB<G>
	return nil :: any
end
local function Push<T>(self: ArrB<T>, v: T): ArrB<T>
	return nil :: any
end
type IfceB = { map: typeof(Map), push: typeof(Push) }
type ArrB<T> = setmetatable<Data<T>, { __index: IfceB }>

local b = (nil :: any) :: ArrB<number>
local b_mapped = b:map(function(x: number)
	return tostring(x)
end)
local b_neg: number = b_mapped[1] -- 에러여야 함
local b_chain = b:map(function(x: number)
	return tostring(x)
end):map(function(s: string)
	return #s > 0
end)
local b_neg2: string = b_chain[1] -- 에러여야 함 (boolean 인데)
--#endregion

local canary: string = 42
return { a_mapped, a_neg, b_mapped, b_neg, b_chain, b_neg2, canary }
