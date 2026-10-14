--!strict

type Mode<D> = {
	Default: D,
}

local modeFull: Mode<<F>(build: (ops: any) -> F) -> F> = {
	Default = function<F>(build: (ops: any) -> F): F return nil :: any end,
}

local modeImpl: Mode<<F>(build: (ops: any) -> F) -> F?> = {
	Default = function<F>(build: (ops: any) -> F): F? return nil :: any end,
}

local function stackDef<D>(mode: Mode<D>)
	return function<Self, T>()
		return {
			IsEmpty = (mode.Default :: any)(function(ops: any)
				return function(s: Self): boolean return true end
			end),
		}
	end
end
