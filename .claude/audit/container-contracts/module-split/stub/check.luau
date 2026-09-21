--!strict
local Arr = require("./Arr")
local a = Arr.Of(1, 2, 3)
local chain = a:Map(function(v: number)
	return tostring(v)
end):Map(function(s: string)
	return #s
end)
if (nil :: any) then
	local neg1: string = chain[1]
	local neg2 = a:NoSuchMethod()
	local canary: string = 42
	print(neg1, neg2, canary)
end
print("chain[1] =", chain[1], " n =", chain.n)
return true
