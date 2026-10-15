--!nocheck
-- 프로브 01: 등록(묶음) 안에서 도는 사용자 코드(뭉텅이 builder)가 라이브러리 함수를 `pcall(lib.fn, …)` 로 바로 부르면
-- 그 raise 의 첫 비라이브러리 프레임이 builder 의 pcall(C)이라 미룸이 걸려 **표식 테이블**이 builder 에게 샘.
local stl = require("../../../../src")
local T = stl.Trait
local Arr = stl.Arr
local function tr(name, fns)
	return T.Trait(name, function()
		return table.freeze(fns)
	end)
end
local a = Arr.Of(10, 20, 30)
-- 비교: 등록 밖에서의 같은 호출
local ok0, err0 = pcall(Arr.At, a, 0 / 0)
print("밖:", ok0, type(err0), tostring(err0))
local ok0b, err0b = pcall(function() Arr.At(a, 0 / 0) end)
print("밖(클로저):", ok0b, type(err0b), tostring(err0b))

local seen = {}
local Probe = tr("P01.Probe", { Run = T.Fn() })
Probe.ImplWhere(T.Every, function(_deps)
	local ok, err = pcall(Arr.At, a, 0 / 0)
	table.insert(seen, { ok, type(err), tostring(err), if type(err) == "table" then next(err) else nil })
	local ok2, err2 = pcall(Arr.Range, 1, 10, 0) -- step 0
	table.insert(seen, { ok2, type(err2), tostring(err2) })
	-- 흔한 쓰임: 메시지를 보고 가름
	local ok3, err3 = pcall(function()
		local _, e = pcall(Arr.At, a, 0 / 0)
		return string.find(e, "NaN")
	end)
	table.insert(seen, { "string.find on err:", ok3, tostring(err3) })
	return { Run = function() end }
end)
local tok = T.NewToken("P01.Kind")
print("builder 호출 수(행/3):", #seen // 3)
for at = 1, 3 do
	print("builder 안:", table.unpack(seen[at]))
end
