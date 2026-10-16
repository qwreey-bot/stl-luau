--!strict
export type function TestIndex(t)
	local tb = types.newtable()
	local pcall = pcall
	local ok, err = pcall(function()
		(tb :: any):setreadindexer(types.number, types.string)
	end)
	error("result: ok=" .. tostring(ok) .. ", err=" .. tostring(err))
end

type T = TestIndex<number>
