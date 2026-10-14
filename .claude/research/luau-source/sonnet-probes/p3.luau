--!strict
local function h<V>(v: V): number
	return v -- expected: error (V is not number)
end
local n: number = h("str")
print(n) -- prints "str" at runtime
local function mono(v: string): number
	return v -- control: error is reported for the non-generic function
end
