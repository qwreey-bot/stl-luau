--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }

type ViewHelper = {
	Default: <F>(build: (any) -> F) -> any,
	Mut: <Self, T>() -> any,
}

local function stackDef(h: ViewHelper)
	return function<Self, T>()
		type MutType = typeof(h.Mut<<Self, T>>())
		local x: MutType = nil :: any
		return x
	end
end
