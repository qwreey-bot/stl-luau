--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }

local function fullMut<Self, T>(): Self & Item<T> return nil :: any end
local function implMut<Self, T>(): Self return nil :: any end

local function test<Self, T>()
	type MutType = typeof(fullMut<<Self, T>>())
	local x: MutType = nil :: any
	return x
end
