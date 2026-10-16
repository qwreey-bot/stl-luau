local stl = require("../src")
local Arr = stl.Arr

local a = Arr.Of(10, 20, 30)

-- 1. Normal set
Arr.Set(a, 1, 100)
Arr.Set(a, 2, 200)
Arr.Set(a, 3, 300)
print("Normal set:", a[1], a[2], a[3], "n:", a.n)

-- 2. Negative index (-1 is last, -3 is first)
Arr.Set(a, -1, 3000)
Arr.Set(a, -3, 1000)
print("Negative index set:", a[1], a[2], a[3], "n:", a.n)

-- 3. Float index (truncation towards 0)
Arr.Set(a, 1.9, 111)
Arr.Set(a, -1.9, 333)
print("Float index set:", a[1], a[2], a[3], "n:", a.n)

-- 4. Out of range errors
local function testErr(name, fn)
	local ok, err = pcall(fn)
	print(name, ":", ok, err)
end

testErr("Set(0)", function() Arr.Set(a, 0, 999) end)
testErr("Set(-0)", function() Arr.Set(a, -0, 999) end)
testErr("Set(4)", function() Arr.Set(a, 4, 999) end)
testErr("Set(-4)", function() Arr.Set(a, -4, 999) end)
testErr("Set(NaN)", function() Arr.Set(a, 0/0, 999) end)
testErr("Set(inf)", function() Arr.Set(a, math.huge, 999) end)
testErr("Set(-inf)", function() Arr.Set(a, -math.huge, 999) end)

-- 5. Empty array
local empty = Arr.Of()
testErr("Empty Set(1)", function() Arr.Set(empty, 1, 999) end)

-- 6. Setting nil (hole)
local a_opt = Arr.Of(1, 2, 3)
Arr.Set(a_opt :: any, 2, nil)
print("After setting nil at 2: a[2] =", a_opt[2], "n =", a_opt.n)
Arr.Set(a_opt :: any, 3, nil)
print("After setting nil at 3 (tail): a[3] =", a_opt[3], "n =", a_opt.n)

