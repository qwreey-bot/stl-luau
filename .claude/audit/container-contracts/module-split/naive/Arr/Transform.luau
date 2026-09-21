--!strict
-- 변환 계열을 별도 파일로. Arr<T> 타입은 init 에 있으므로 여기선 못 쓴다 →
-- 데이터부만 참조하고 반환은 init 이 조립하게 한다.
local Types = require("../Types")
type ArrData<T> = Types.ArrData<T>

local exports = {}
function exports.Map<T, G>(self: ArrData<T>, fn: (el: T, idx: number) -> G): ArrData<G>
	local len = self.n
	local out = table.create(len)
	out.n = len
	for i = 1, len do out[i] = fn(self[i], i) end
	return out :: any
end
function exports.Len<T>(self: ArrData<T>): number
	return self.n
end
return exports
