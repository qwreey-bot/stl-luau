--!strict
-- Verification of the fundamental subtyping leak rules inside generic bodies

local function leakRules<T>(val_T: T, opt_T: T?)
	-- Rule 1: T <: Concrete (assignment)
	local as_str: string = val_T -- LEAKS: T treated as string

	-- Rule 2: T <: Concrete (argument to concrete function)
	local function takesNum(n: number) end
	takesNum(val_T) -- LEAKS: T treated as number

	-- Rule 3: Concrete <: T (assignment from concrete)
	-- Wait, does `local t: T = "str"` leak or get caught?
	local from_str: T = "str"

	-- Rule 4: Concrete <: T? (assignment to union T?)
	local from_str_opt: T? = "str" -- LEAKS

	-- Rule 5: Concrete <: T in return position
	local function retT(): T
		return "str" -- CAUGHT?
	end

	local function retOptT(): T?
		return "str" -- LEAKS
	end

	-- Rule 6: Two distinct generics T and U
	local function twoGenerics<U>(val_U: U)
		local t_as_u: U = val_T -- Can T be assigned to U?
		takesNum(val_U)
	end
end

local canary: string = 1
return { leakRules, canary }
