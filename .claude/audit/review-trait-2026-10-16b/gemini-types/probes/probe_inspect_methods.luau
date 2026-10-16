--!strict
local stl = require("../src")
local Trait = stl.Trait

export type function InspectTable(t)
	local mt = getmetatable(t)
	local methods = {}
	if mt and mt.__index then
		for k, v in mt.__index do
			table.insert(methods, tostring(k))
		end
	end
	error("Table methods: " .. table.concat(methods, ", "))
end

type X = InspectTable<typeof(stl.Arr.Of(1))>
