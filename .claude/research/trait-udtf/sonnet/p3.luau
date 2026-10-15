--!strict
type function Rb(f, variant)
	local ps = f:parameters()
	local v = variant:value()
	if v == "1" then
		return types.newfunction({ head = ps.head, tail = ps.tail }, f:returns(), f:generics())
	elseif v == "2" then
		return types.newfunction({ head = ps.head }, { head = f:returns().head }, f:generics())
	elseif v == "3" then
		local c = types.copy(f)
		return c
	else
		print(ps.tail, 0)
		return types.newfunction({ head = ps.head }, { head = f:returns().head })
	end
end
local function g<S>(x: S) return 1 end
local a: Rb<typeof(g), "1"> = nil :: any
local b: Rb<typeof(g), "2"> = nil :: any
local c: Rb<typeof(g), "3"> = nil :: any
local d: Rb<typeof(g), "4"> = nil :: any
local z: number = {a,b,c,d}
