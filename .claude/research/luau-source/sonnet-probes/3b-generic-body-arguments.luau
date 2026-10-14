--!strict
local function needsNumber(n: number): number
	return n
end
local function g<V>(v: V): number
	return needsNumber(v) -- V passed where number is required
end
local function store<K, V>(t: { [K]: V }, k: K, v: V)
	t[k] = v
end
local function wrap<K, V>(t: { [K]: V }, k: K)
	store(t, k, "bad") -- "bad" passed where V is required
end
local nums: { [string]: number } = {}
wrap(nums, "x")
print(g("str"), nums.x)
