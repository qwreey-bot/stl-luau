--!strict
local function h<V>(v: V): number
	return v
end
local function call<T>(fn: (T) -> T)
	fn(nil)
end
call(function(x: number) return x + 1 end)
local function plain(t: { [string]: number }): number return t.x end
local n: number = plain({ x = "bad" })
