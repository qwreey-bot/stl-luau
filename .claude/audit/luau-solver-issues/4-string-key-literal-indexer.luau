--!strict
local function plain(t: { [string]: number }): number
	return t.x
end
local n: number = plain({ x = "bad" }) -- expected: error (string is not number)
print(n) -- prints "bad" at runtime
local control = plain({ "bad" }) -- control: an array-style literal is reported
local t: { [string]: number } = { x = "bad" } -- control: assignment to an annotated local
