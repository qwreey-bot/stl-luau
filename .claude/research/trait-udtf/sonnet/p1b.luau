--!strict
type function Show(t) return t end
local function listDef<Self, E>(of: Self | E)
	return {
		Get = (nil :: any) :: (list: Self, i: number) -> E?,
		Fold = (nil :: any) :: <U>(list: Self, init: U, fn: (U, E) -> U) -> U,
	}
end
local v = listDef(1)
local z: number = listDef
return {z}
