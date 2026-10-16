--!strict
type AssocReadTest<E, I> = { read Item: () -> E, read Index: (I) -> I }
type ValueReadTest<E, I> = { read __traits: { read List: AssocReadTest<E, I> } }

local function testGet<E, I>(list: ValueReadTest<E, I>, idx: I): E?
	return nil
end

local myArr: ValueReadTest<number, number> = {
	__traits = {
		List = {
			Item = function() return 1 end,
			Index = function(x: number) return x end,
		}
	}
}

-- Covariant element reading: can we read as number?
local function readCovariant(list: ValueReadTest<number?, number>)
	local val: number?? = testGet(list, 1)
end
readCovariant(myArr) -- Passes! Covariant in Item!

-- Can we pass string as index?
local negIndex = testGet(myArr, "wrong") -- Should FAIL!
