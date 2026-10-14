--!strict
local stl = require("../src")
local Arr = stl.Arr
type Arr<T> = stl.Arr<T>
type ArrData<T> = stl.ArrData<T>
type Item<T> = { read __generics: { read Item: (T) -> T } }
type A = { read __probeA: true }

-- Let's inspect Arr.PushBack vs our pushBack
local function ourPushBack<T>(a: Arr<T>, v: T): Arr<T> return a end

type Target<Self, T> = {
	Push: (Self & Item<T>, T) -> Self,
}

-- Test 1: ourPushBack
local t1: Target<Arr<A>, A> = { Push = ourPushBack }

-- Test 2: Arr.PushBack
local t2: Target<Arr<A>, A> = { Push = Arr.PushBack }

local canary: string = 1
