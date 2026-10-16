local Trait = require("../src/Trait")
local stl = require("../src")

print("--- 1. Closed trait in ImplWhere deps ---")
local T1 = Trait.Trait("T1", function(of)
	return table.freeze({
		Foo = Trait.Fn<<() -> ()>>(),
	})
end)

local ok, err = pcall(function()
	T1.ImplWhere({ stl.Arr }, function(deps)
		return {
			Foo = function() end,
		}
	end)
end)
print("ImplWhere with stl.Arr in deps:", ok, err)
if ok then
	print("Trait.Implements(T1, stl.Arr.Of()):", Trait.Implements(T1, stl.Arr.Of()))
	print("Trait.Implements(T1, stl.CircularDeque.New()):", Trait.Implements(T1, stl.CircularDeque.New()))
end

print("--- 2. Closed trait passed to Trait.Any / ImplWhere ---")
print("stl.Arr.ImplWhere:", (stl.Arr :: any).ImplWhere)

print("--- 3. Closed trait passed to Trait.ImplOf, Implements, ExpectImpl, Impls ---")
print("Trait.ImplOf(stl.Arr, stl.Arr.Of()) == stl.Arr:", Trait.ImplOf(stl.Arr, stl.Arr.Of()) == stl.Arr)
print("Trait.Implements(stl.Arr, stl.Arr.Of()):", Trait.Implements(stl.Arr, stl.Arr.Of()))
print("Trait.Implements(stl.Arr, stl.CircularDeque.New()):", Trait.Implements(stl.Arr, stl.CircularDeque.New()))
print("Trait.Impls(stl.Arr) ~= nil:", Trait.Impls(stl.Arr) ~= nil)

local ok_exp, res_exp = pcall(function()
	return Trait.ExpectImpl(stl.Arr, stl.Arr.Of(), "test")
end)
print("Trait.ExpectImpl(stl.Arr, arr):", ok_exp, res_exp == stl.Arr)

local ok_exp2, err_exp2 = pcall(function()
	return Trait.ExpectImpl(stl.Arr, stl.Arr, "test")
end)
print("Trait.ExpectImpl(stl.Arr, stl.Arr):", ok_exp2, err_exp2)

print("--- 4. Restore with stl.Arr ---")
local restored = Trait.Restore(stl.Arr)
print("Trait.Restore(stl.Arr) == stl.Arr:", restored == stl.Arr)

