--!strict
type function Rebuild(f, mode)
	local m = mode:value()
	local ps = f:parameters()
	local rs = f:returns()
	local tbl = rs.head[1]
	local out: any = {}
	for k, v in tbl:properties() do
		local req = v.read:readproperty(types.singleton("required"))
		local fnty = v.read:readproperty(types.singleton("fn"))
		if m == "impl" and not (req:value() == true) then
			out[k] = { read = types.optional(fnty) }
		else
			out[k] = { read = fnty }
		end
	end
	return types.newfunction({ head = ps.head, tail = ps.tail }, { head = { types.newtable(out) } }, f:generics())
end
type Fn<F> = { required: true, fn: F }
type Def<F> = { required: false, fn: F }
local function listDef<Self, E>(of: Self | E)
	return {
		Get = (nil :: any) :: Fn<(list: Self, i: number) -> E?>,
		Fold = (nil :: any) :: Def<<U>(list: Self, init: U, fn: (U, E) -> U) -> U>,
	}
end
type Of = Rebuild<typeof(listDef), "full">
type ImplOf = Rebuild<typeof(listDef), "impl">
local of: Of = nil :: any
local iof: ImplOf = nil :: any
local d: number = of
local d2: number = iof
local canary: string = 1
return { d, d2, canary }
