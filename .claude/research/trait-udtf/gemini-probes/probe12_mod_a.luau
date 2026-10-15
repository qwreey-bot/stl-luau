--!strict
-- probe12_mod_a: defines trait with type function

export type function FullOf(defTable: type): type
	local props: any = {}
	for name, prop in defTable:properties() do
		local entry = prop.read :: type
		local fnProp = entry:readproperty(types.singleton("fn")) :: type
		props[name] = { read = fnProp }
	end
	return types.newtable(props)
end

export type Req<F> = { read required: true, read fn: F }
export type Def<F> = { read required: false, read fn: F }

export type ProbeDef<Self, T> = {
	Get: Req<(Self) -> T>,
	Twice: Def<(Self) -> T>,
}

export type ProbeFull<Self, T> = FullOf<ProbeDef<Self, T>>

return {}
