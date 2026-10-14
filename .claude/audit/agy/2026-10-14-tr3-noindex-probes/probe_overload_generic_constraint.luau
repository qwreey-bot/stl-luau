--!strict

type DefaultFn =
	(<F>(mode: "full", build: (ops: any) -> F) -> F) &
	(<F>(mode: "impl", build: (ops: any) -> F) -> F?)

local Default: DefaultFn = (function(mode: string, build: any): any
	return nil
end) :: any

local function stackDef<M>(mode: M & ("full" | "impl"))
	return function<Self, T>()
		return {
			IsEmpty = Default(mode, function(ops: any)
				return function(s: Self): boolean return true end
			end),
		}
	end
end
