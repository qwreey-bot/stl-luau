--!strict
local stl = require("../src")
local arr = stl.Arr.Of(1, 2, 3)

-- Test List.Fold generics
-- Can we call Fold without explicit generics?
local sum1 = stl.List.Fold(arr, 0, function(acc: number, v: number, _i: number)
	return acc + v
end)

-- What if we pass explicit type argument <<number>>?
-- If generics are <E, I, U>, <<number>> binds E to number, and I and U are missing or error?
-- If generics are <U>, <<number>> binds U to number!
-- Let's test what generics List.Fold actually has!
local sum2 = stl.List.Fold<<number, number, number>>(arr, 0, function(acc: number, v: number, _i: number)
	return acc + v
end)

local sum3 = stl.List.Fold<<number>>(arr, 0, function(acc: number, v: number, _i: number)
	return acc + v
end)

print(sum1, sum2)
