local NewCD = require("../src/Collections/CircularDeque")
local OldCD = require("./old_src/Collections/CircularDeque")

math.randomseed(54321)

local function assertEqual(cd_new, cd_old, op_name)
	if NewCD.Len(cd_new) ~= OldCD.Len(cd_old) then
		error(string.format("Mismatch in %s: len new=%d, old=%d", op_name, NewCD.Len(cd_new), OldCD.Len(cd_old)))
	end
	local n = NewCD.Len(cd_new)
	for i = 1, n do
		local v1 = NewCD.At(cd_new, i)
		local v2 = OldCD.At(cd_old, i)
		if v1 ~= v2 then
			error(string.format("Mismatch in %s at index %d: new=%s, old=%s", op_name, i, tostring(v1), tostring(v2)))
		end
	end
	if NewCD.Front(cd_new) ~= OldCD.Front(cd_old) then
		error("Front mismatch")
	end
	if NewCD.Back(cd_new) ~= OldCD.Back(cd_old) then
		error("Back mismatch")
	end
	if NewCD.Empty(cd_new) ~= OldCD.Empty(cd_old) then
		error("Empty mismatch")
	end
end

local cd_new = NewCD.New()
local cd_old = OldCD.New()

for step = 1, 10000 do
	local op = math.random(1, 8)
	if op == 1 then
		local v = math.random(1, 100)
		NewCD.PushBack(cd_new, v)
		OldCD.PushBack(cd_old, v)
		assertEqual(cd_new, cd_old, "PushBack")
	elseif op == 2 then
		local v = math.random(1, 100)
		NewCD.PushFront(cd_new, v)
		OldCD.PushFront(cd_old, v)
		assertEqual(cd_new, cd_old, "PushFront")
	elseif op == 3 then
		local r1 = NewCD.PopBack(cd_new)
		local r2 = OldCD.PopBack(cd_old)
		if r1 ~= r2 then error(string.format("PopBack mismatch: new=%s, old=%s", tostring(r1), tostring(r2))) end
		assertEqual(cd_new, cd_old, "PopBack")
	elseif op == 4 then
		local r1 = NewCD.PopFront(cd_new)
		local r2 = OldCD.PopFront(cd_old)
		if r1 ~= r2 then error(string.format("PopFront mismatch: new=%s, old=%s", tostring(r1), tostring(r2))) end
		assertEqual(cd_new, cd_old, "PopFront")
	elseif op == 5 and NewCD.Len(cd_new) > 0 then
		local idx = math.random(-NewCD.Len(cd_new) - 1, NewCD.Len(cd_new) + 2)
		local v1 = NewCD.At(cd_new, idx)
		local v2 = OldCD.At(cd_old, idx)
		if v1 ~= v2 then error(string.format("At mismatch at %d: new=%s, old=%s", idx, tostring(v1), tostring(v2))) end
	elseif op == 6 and NewCD.Len(cd_new) > 0 then
		local clone1 = NewCD.Clone(cd_new)
		local clone2 = OldCD.Clone(cd_old)
		assertEqual(clone1, clone2, "Clone")
	elseif op == 7 and NewCD.Len(cd_new) > 20 then
		NewCD.Clear(cd_new)
		OldCD.Clear(cd_old)
		assertEqual(cd_new, cd_old, "Clear")
	elseif op == 8 then
		local arr1 = NewCD.ToArr(cd_new)
		local arr2 = OldCD.ToArr(cd_old)
		if arr1.n ~= arr2.n then error("ToArr len mismatch") end
		for i = 1, arr1.n do
			if arr1[i] ~= arr2[i] then error("ToArr item mismatch") end
		end
	end
end

print("CircularDeque differential test: 10000 operations passed with 0 mismatches!")
