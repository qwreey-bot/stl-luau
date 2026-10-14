--!strict

type SelectFn = 
	(<A, B>(mode: "full", a: A, b: B) -> A) &
	(<A, B>(mode: "impl", a: A, b: B) -> B)

local select: SelectFn = (function(mode: string, a: any, b: any): any
	return if mode == "full" then a else b
end) :: any

local function test<M>(mode: M)
	local dummyA: number = 0
	local dummyB: string = ""
	local res = select(mode, dummyA, dummyB)
	return res
end

local canary: string = 1
