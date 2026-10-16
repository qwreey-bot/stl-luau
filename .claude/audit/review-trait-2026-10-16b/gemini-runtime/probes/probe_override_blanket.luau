local Trait = require("../src/Trait")
local stl = require("../src")

local T1 = Trait.Trait("T1", function(of)
	return table.freeze({
		Foo = Trait.Fn<<() -> string>>(),
	})
end)

T1.ImplWhere({ stl.Arr }, function(deps)
	return {
		Foo = function() return "from blanket" end,
	}
end)

local arr = stl.Arr.Of(1, 2, 3)
print("Before ImplFor:", T1.Of(arr).Foo())

-- Now explicit ImplFor on stl.Arr
local ok, err = pcall(function()
	T1.ImplFor(stl.Arr, {
		Foo = function() return "from explicit" end,
	})
end)
print("ImplFor on stl.Arr:", ok, err)
if ok then
	print("After ImplFor:", T1.Of(arr).Foo())
end
