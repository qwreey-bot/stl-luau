--!strict
local function Map2<T, G>(xs: { T }, f: (T) -> G): { G }
	local out: { G } = {}
	for i, x in xs do
		out[i] = f(x)
	end
	return out
end
local leaked: { string } = Map2({ 1, 2 }, function(v) return v end) -- expected: error ({number} is not {string})
print(leaked[1]) -- prints 1 (a number) at runtime
local control: { string } = Map2({ 1, 2 }, function(v: number) return v end) -- control: error is reported
