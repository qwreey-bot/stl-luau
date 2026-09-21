--!strict
local Types = require("./Types")
local Transform = require("@self/Transform")
type ArrData<T> = Types.ArrData<T>

-- ⭐ 핵심 시험: 다른 모듈의 함수를 typeof 로 가져올 수 있는가?
type ArrIfce = {
	Map: typeof(Transform.Map),
	Len: typeof(Transform.Len),
}
export type Arr<T> = ArrData<T> & ArrIfce

local Ifce = { Map = Transform.Map, Len = Transform.Len }
;(Ifce :: any).__index = Ifce
local function Of<T>(...: T): Arr<T>
	return setmetatable(table.pack(...), Ifce :: any) :: any
end
return { Of = Of }
