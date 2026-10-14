--!strict
local function f_str<T>(): T?
	return "hello"
end

local function f_num<T>(): T?
	return 123
end

local function f_tbl<T>(): T?
	return { x = 1 }
end

local canary: string = 1
return { f_str, f_num, f_tbl, canary }
