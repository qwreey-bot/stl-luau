--!strict
local Arr = require("./Arr")
local a = Arr.Of(1, 2, 3)
local mapped = a:Map(function(v: number) return tostring(v) end)
local ok1: number = a:Len()
if (nil :: any) then
	local neg1: number = mapped[1]      -- string 인데
	local neg2 = a:NoSuchMethod()
	local neg3: string = a:Len()
	local canary: string = 42
	print(neg1, neg2, neg3, canary)
end
-- 쪼갠 파일이 Arr<T> 를 모르므로 반환이 ArrData<G> 다 → 체이닝이 되는가?
local chain = a:Map(function(v: number)
	return tostring(v)
end):Map(function(s: string)
	return #s
end)

print("mapped[1] =", tostring(mapped[1]), " len =", ok1)
print("chain =", tostring(chain[1]))
return true
