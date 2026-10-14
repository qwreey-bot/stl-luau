--!strict
local stl = require("../src")
local Arr = stl.Arr
type Arr<T> = stl.Arr<T>
type ArrData<T> = stl.ArrData<T>
type ArrRead<T> = stl.ArrRead<T>
type Item<T> = { read __generics: { read Item: (T) -> T } }
type A = { read __probeA: true }

type StackExpected<Self, T> = {
	Push: (Self & Item<T>, T) -> Self,
	Pop: (Self & Item<T>) -> T?,
	Peek: (Self) -> T?,
}

local function arrPeek<T>(self: ArrRead<T>): T?
	return self[self.n]
end

const arrStack: StackExpected<Arr<A>, A> = {
	Push = Arr.PushBack,
	Pop = Arr.PopBack,
	Peek = arrPeek,
}

local canary: string = 1
