--!strict
local stl = require("../src")
local Arr = stl.Arr
type Arr<T> = stl.Arr<T>
type ArrData<T> = stl.ArrData<T>
type A = { read __probeA: true }

-- Case 1: Item exactly matching ArrData's __generics
type ExactItem<T> = { read __generics: { read Item: (T) -> T, read Index: (number) -> number } }
type TargetExact<Self, T> = {
	Push: (Self & ExactItem<T>, T) -> Self,
}
local t1: TargetExact<Arr<A>, A> = { Push = Arr.PushBack }

-- Case 2: What if Target just expects Self?
type TargetSelf<Self, T> = {
	Push: (Self, T) -> Self,
}
local t2: TargetSelf<Arr<A>, A> = { Push = Arr.PushBack }

local canary: string = 1
