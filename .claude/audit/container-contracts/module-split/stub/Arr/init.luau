--!strict
local Types = require("./Types")
local Transform = require("@self/Transform")
export type Arr<T> = Types.Arr<T>

local Ifce = {}
Ifce.__index = Ifce
function Ifce.PushBack<T>(self: Arr<T>, v: T): Arr<T>
	local n = self.n + 1
	self[n] = v
	self.n = n
	return self
end
function Ifce.Map<T, G>(self: Arr<T>, fn: (el: T, idx: number) -> G): Arr<G>
	return Transform.Map(self, fn, Ifce)
end
function Ifce.Len<T>(self: Arr<T>): number
	return self.n
end
local function Of<T>(...: T): Arr<T>
	return setmetatable(table.pack(...), Ifce) :: any
end
return { Of = Of }
