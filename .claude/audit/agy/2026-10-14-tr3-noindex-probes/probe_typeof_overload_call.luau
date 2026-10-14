--!strict

type Overloaded = 
	((mode: "full") -> { read kind: "full_result", val: number }) &
	((mode: "impl") -> { read kind: "impl_result", val: string })

local fn: Overloaded = nil :: any

type ResFull = typeof(fn("full"))
type ResImpl = typeof(fn("impl"))

local rf: ResFull = { kind = "full_result", val = 123 }
local ri: ResImpl = { kind = "impl_result", val = "hello" }

-- NEG 1: wrong kind in rf
local NEG_rf: ResFull = { kind = "impl_result", val = 123 } -- NEG

-- NEG 2: wrong kind in ri
local NEG_ri: ResImpl = { kind = "full_result", val = "hello" } -- NEG

local canary: string = 1
