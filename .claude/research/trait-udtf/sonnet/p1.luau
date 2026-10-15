--!strict
-- 레코드 매핑 최소: 제네릭 함수 타입 속 Fn 레코드를 완성/등록 표로
type function FullOf(t)
	local out: any = {}
	for k, v in t:properties() do
		local fnty = v.read:readproperty(types.singleton("fn"))
		out[k] = { read = fnty }
	end
	return types.newtable(out)
end
type function ImplOf(t)
	local out: any = {}
	for k, v in t:properties() do
		local req = v.read:readproperty(types.singleton("required"))
		local fnty = v.read:readproperty(types.singleton("fn"))
		if req:is("singleton") and req:value() == true then
			out[k] = { read = fnty }
		else
			out[k] = { read = types.optional(fnty) }
		end
	end
	return types.newtable(out)
end
type Fn<F> = { required: true, fn: F }
type Def<F> = { required: false, fn: F }
local function listDef<Self, E>(of: Self | E)
	return {
		Get = (nil :: any) :: Fn<(list: Self, i: number) -> E?>,
		Fold = (nil :: any) :: Def<<U>(list: Self, init: U, fn: (U, E) -> U) -> U>,
	}
end
type DefT = typeof(listDef)
local x: FullOf<typeof(listDef(nil :: any))> = nil :: any
local y: ImplOf<typeof(listDef(nil :: any))> = nil :: any
local canary: string = 1
return { x, y, canary }
