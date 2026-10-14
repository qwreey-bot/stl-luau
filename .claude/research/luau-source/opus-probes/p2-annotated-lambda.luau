--!strict
-- 몸통을 "주석 단 지역 + 제네릭 없는 람다" 로: 람다의 T 는 주석의 서명 스코프에 속하고, 람다 몸통은 그 스코프의 자손이 아님
const a: <T>(x: T) -> string = function(x)
	return x -- A: T -> string
end
const b: <T>(x: T) -> T = function(x)
	return 5 -- B: number -> T
end
const c: <T>(x: T) -> T? = function(x)
	return 123 -- C: number -> T?
end
const d: <T>(x: T, y: number?) -> T? = function(x, y)
	return y -- D: number? -> T?
end
const e: <T>(x: T) -> number = function(x)
	local y: number = x -- E
	return y
end
const f: <T>(x: T) -> () = function(x)
	local y: T = "s" -- F (주석에 T 를 못 씀 — 이름이 없으니 에러가 나야 정상: 아래 F2 로)
end
const g: <T, U>(x: T) -> U = function(x)
	return x -- G
end
const h: <T>(x: T) -> T | string = function(x)
	return 5 -- H
end
const i: <T>(x: T) -> { T } = function(x)
	return { 5 } -- I
end
-- 맞는 것(0건이어야 함)
const ok1: <T>(x: T) -> T? = function(x)
	return x
end
const ok2: <T>(x: T) -> { T } = function(x)
	return { x }
end
const ok3: <T>(x: T) -> T? = function(x)
	return nil
end
const ok4: <T>(x: { T }) -> T? = function(xs)
	return xs[1]
end
local function needsNumber(n: number) end
const callArg: <T>(x: T) -> () = function(x)
	needsNumber(x) -- J: T 를 number 인자로
end
local function idg<V>(v: V): V return v end
const callGen: <T>(x: T) -> T? = function(x)
	return idg(x) -- ok5: 제네릭 호출을 거쳐 그대로
end
const callGenBad: <T>(x: T) -> T? = function(x)
	return idg(5) -- K: 제네릭 호출로 number
end
return { a, b, c, d, e, f, g, h, i, ok1, ok2, ok3, ok4, callArg, callGen, callGenBad }
