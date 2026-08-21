local arr = require("@self/arr")

export type arr<T> = arr.Arr<T>

-- stylua: ignore start
local function run_test()
	local test = require("../libs/test-luau/lib")
	return test("stl-luau")(
		require("../tests/arr")()
	)
end
-- stylua: ignore end

return {
	arr = arr,
	run_test = run_test,
}
