--!strict

type SelectFn = 
	(<A, B>(mode: "full", a: A, b: B) -> A) &
	(<A, B>(mode: "impl", a: A, b: B) -> B)

local select: SelectFn = (function(mode: string, a: any, b: any): any
	return if mode == "full" then a else b
end) :: any

type FullVal = { kind: "full", x: number }
type ImplVal = { kind: "impl", s: string }

local dummyA: FullVal = nil :: any
local dummyB: ImplVal = nil :: any

type ResFull = typeof(select("full", dummyA, dummyB))
type ResImpl = typeof(select("impl", dummyA, dummyB))

local rf: ResFull = { kind = "full", x = 123 }
local ri: ResImpl = { kind = "impl", s = "hello" }

-- NEG 1: wrong type for ResFull
local NEG_rf: ResFull = { kind = "impl", s = "hello" } -- NEG

-- NEG 2: wrong type for ResImpl
local NEG_ri: ResImpl = { kind = "full", x = 123 } -- NEG

local canary: string = 1
