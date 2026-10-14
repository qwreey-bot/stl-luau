--!strict
-- probes/probe_overload_variants.luau

type DefaultOverload =
	(<F>(mode: "full", build: (ops: any) -> F) -> F) &
	(<F>(mode: "impl", build: (ops: any) -> F) -> F?)

local Default: DefaultOverload = nil :: any

local dummyBuild = function(ops: any)
	return function(x: number): boolean return x > 0 end
end

-- 케이스 1: 순수 유니온 타입 "full" | "impl" 넘기기
local function testUnion(mode: "full" | "impl")
	return Default(mode, dummyBuild)
end

-- 케이스 2: 제네릭 M & "full"
local function testGenericFull<M>(mode: M & "full")
	return Default(mode, dummyBuild)
end

-- 케이스 3: 제네릭 M & "impl"
local function testGenericImpl<M>(mode: M & "impl")
	return Default(mode, dummyBuild)
end

-- 케이스 4: 제네릭 M (아무 제약 없음)
local function testGenericUnconstrained<M>(mode: M)
	return Default(mode, dummyBuild)
end

-- 케이스 5: 제네릭 M & ("full" | "impl")
local function testGenericUnion<M>(mode: M & ("full" | "impl"))
	return Default(mode, dummyBuild)
end

-- canary
local canary: string = 1
