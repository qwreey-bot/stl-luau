--!strict
-- 분할된 구현 파일. Types 에서 Arr<T> 를 가져오므로 **컨테이너 타입을 반환할 수 있다.**
local Types = require("../Types")
type Arr<T> = Types.Arr<T>

local exports = {}
function exports.Map<T, G>(self: Arr<T>, fn: (el: T, idx: number) -> G, ifce: any): Arr<G>
	local len = self.n
	local out = table.create(len)
	out.n = len
	for i = 1, len do out[i] = fn(self[i], i) end
	return setmetatable(out, ifce) :: any
end
return exports
