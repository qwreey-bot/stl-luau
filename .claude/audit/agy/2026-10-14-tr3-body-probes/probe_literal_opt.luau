--!strict
local function f_non_opt<T>(): T
	return 123
end

local function f_opt<T>(): T?
	return 123
end

local canary: string = 1
return { f_non_opt, f_opt, canary }
