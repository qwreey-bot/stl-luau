--!strict
local stl = require("../src")
local Trait = stl.Trait

-- Test what Entries does to an indexer
local TestTrait = Trait.Trait("TestIndexer", function<Self, T>(of: Self & { read [number]: T, read n: number })
	return table.freeze({
		GetMap = Trait.Fn<<(self: Self) -> { read [string]: T }>>()
	})
end)

local function check(t: typeof(TestTrait.GetMap))
	local res = TestTrait.GetMap(nil :: any)
	res["foo"] = 123
end

return check
