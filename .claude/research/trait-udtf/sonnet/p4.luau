--!strict
type function Rebuild(f, mode)
	local m = mode:value()
	local ps = f:parameters()
	local rs = f:returns()
	local out: any = {}
	for k, v in rs.head[1]:properties() do
		local req = v.read:readproperty(types.singleton("required"))
		local fnty = v.read:readproperty(types.singleton("fn"))
		if m == "impl" and not (req:is("singleton") and req:value() == true) then
			out[k] = { read = types.optional(fnty) }
		else
			out[k] = { read = fnty }
		end
	end
	return types.newfunction({ head = ps.head }, { head = { types.newtable(out) } }, f:generics())
end
type Fn<F> = { required: true, fn: F }
type Def<F> = { required: false, fn: F }
-- 제네릭 팩, 그림자(안쪽 E), 중첩 제네릭 함수
local function def<Self, E, Args...>(of: Self | E)
	return {
		Call = (nil :: any) :: Fn<(self: Self, Args...) -> E>,
		Shadow = (nil :: any) :: Def<<E>(self: Self, x: E) -> E>,
		Nested = (nil :: any) :: Def<<U>(self: Self, f: <V>(U, V) -> (U, V)) -> U>,
		Outer = (nil :: any) :: Def<(self: Self, x: E) -> E>,
	}
end
type FullT = Rebuild<typeof(def), "full">
type ImplT = Rebuild<typeof(def), "impl">
local full: FullT = nil :: any
local impl: ImplT = nil :: any
local t1 = full(1 :: number)
local c: string = t1.Call(1 :: number, "x")   -- (Args = string)? 호출 팩
local s: string = t1.Shadow(1 :: number, "s") -- 안쪽 E 는 string
local o: string = t1.Outer(1 :: number, "s")  -- NEG 안쪽 가려진 바깥 E (number 여야)
local n: string = t1.Nested(1 :: number, function<V>(u: string, v: V): (string, V) return u, v end)
local z: number = {full, impl}
local canary: string = 1
return { c, s, o, n, z, canary }
