local NewArr = require("../src/Collections/Arr")
local OldArr = require("./old_src/Collections/Arr")

math.randomseed(12345)

local function assertEqual(a_new, a_old, op_name)
	if a_new.n ~= a_old.n then
		error(string.format("Mismatch in %s: len new=%d, old=%d", op_name, a_new.n, a_old.n))
	end
	for i = 1, a_new.n do
		if a_new[i] ~= a_old[i] then
			error(string.format("Mismatch in %s at index %d: new=%s, old=%s", op_name, i, tostring(a_new[i]), tostring(a_old[i])))
		end
	end
end

local a_new = NewArr.Of()
local a_old = OldArr.Of()

for step = 1, 10000 do
	local op = math.random(1, 18)
	if op == 1 then
		local v = math.random(1, 100)
		NewArr.PushBack(a_new, v)
		OldArr.PushBack(a_old, v)
		assertEqual(a_new, a_old, "PushBack")
	elseif op == 2 then
		local v = math.random(1, 100)
		NewArr.PushFront(a_new, v)
		OldArr.PushFront(a_old, v)
		assertEqual(a_new, a_old, "PushFront")
	elseif op == 3 then
		local r1 = NewArr.PopBack(a_new)
		local r2 = OldArr.PopBack(a_old)
		if r1 ~= r2 then error(string.format("PopBack mismatch: new=%s, old=%s", tostring(r1), tostring(r2))) end
		assertEqual(a_new, a_old, "PopBack")
	elseif op == 4 then
		local r1 = NewArr.PopFront(a_new)
		local r2 = OldArr.PopFront(a_old)
		if r1 ~= r2 then error(string.format("PopFront mismatch: new=%s, old=%s", tostring(r1), tostring(r2))) end
		assertEqual(a_new, a_old, "PopFront")
	elseif op == 5 and a_new.n > 0 then
		local idx = math.random(1, a_new.n)
		local r1 = NewArr.SwapRemove(a_new, idx)
		local r2 = OldArr.SwapRemove(a_old, idx)
		if r1 ~= r2 then error("SwapRemove mismatch") end
		assertEqual(a_new, a_old, "SwapRemove")
	elseif op == 6 and a_new.n > 0 then
		local s = math.random(-2, a_new.n + 2)
		local l = math.random(-2, a_new.n + 2)
		NewArr.ReverseInplace(a_new, s, l)
		OldArr.ReverseInplace(a_old, s, l)
		assertEqual(a_new, a_old, "ReverseInplace")
	elseif op == 7 and a_new.n > 0 then
		local shift = math.random(-5, 5)
		local s = math.random(-2, a_new.n + 2)
		local l = math.random(-2, a_new.n + 2)
		NewArr.RotateInplace(a_new, shift, s, l)
		OldArr.RotateInplace(a_old, shift, s, l)
		assertEqual(a_new, a_old, "RotateInplace")
	elseif op == 8 and a_new.n > 0 then
		local at = math.random(1, a_new.n + 1)
		local v = math.random(1, 100)
		NewArr.Insert(a_new, at, v)
		OldArr.Insert(a_old, at, v)
		assertEqual(a_new, a_old, "Insert")
	elseif op == 9 and a_new.n > 0 then
		local s = math.random(-2, a_new.n + 2)
		local l = math.random(-2, a_new.n + 2)
		local to1 = NewArr.Of(999)
		local to2 = OldArr.Of(999)
		local res1 = NewArr.Slice(a_new, s, l, to1)
		local res2 = OldArr.Slice(a_old, s, l, to2)
		assertEqual(res1, res2, "Slice with to")
	elseif op == 10 and a_new.n > 0 then
		local to1 = NewArr.Of(999)
		local to2 = OldArr.Of(999)
		local res1 = NewArr.Map(a_new, function(x) return x * 2 end, to1)
		local res2 = OldArr.Map(a_old, function(x) return x * 2 end, to2)
		assertEqual(res1, res2, "Map with to")
	elseif op == 11 and a_new.n > 0 then
		local to1 = NewArr.Of(999)
		local to2 = OldArr.Of(999)
		local res1 = NewArr.Filter(a_new, function(x) return x % 2 == 0 end, to1)
		local res2 = OldArr.Filter(a_old, function(x) return x % 2 == 0 end, to2)
		assertEqual(res1, res2, "Filter with to")
	elseif op == 12 and a_new.n > 0 then
		local to1 = NewArr.Of(999)
		local to2 = OldArr.Of(999)
		local res1 = NewArr.Flatmap(a_new, function(x) return x, x + 1 end, to1)
		local res2 = OldArr.Flatmap(a_old, function(x) return x, x + 1 end, to2)
		assertEqual(res1, res2, "Flatmap with to")
	elseif op == 13 and a_new.n > 0 then
		NewArr.SortInplace(a_new)
		OldArr.SortInplace(a_old)
		assertEqual(a_new, a_old, "SortInplace")
	elseif op == 14 and a_new.n > 0 then
		NewArr.DedupInplace(a_new)
		OldArr.DedupInplace(a_old)
		assertEqual(a_new, a_old, "DedupInplace")
	elseif op == 15 and a_new.n > 0 then
		NewArr.Retain(a_new, function(x) return x % 3 ~= 0 end)
		OldArr.Retain(a_old, function(x) return x % 3 ~= 0 end)
		assertEqual(a_new, a_old, "Retain")
	elseif op == 16 and a_new.n > 0 then
		local s = math.random(1, a_new.n)
		local l = math.random(s, a_new.n)
		NewArr.SliceInplace(a_new, s, l)
		OldArr.SliceInplace(a_old, s, l)
		assertEqual(a_new, a_old, "SliceInplace")
	elseif op == 17 and a_new.n > 0 then
		local s = math.random(1, a_new.n)
		local l = math.random(s, a_new.n)
		NewArr.EraseInplace(a_new, s, l)
		OldArr.EraseInplace(a_old, s, l)
		assertEqual(a_new, a_old, "EraseInplace")
	elseif op == 18 and a_new.n > 0 then
		local extra = { math.random(1, 50), math.random(1, 50) }
		NewArr.ConcatInplace(a_new, NewArr.Adopt(table.clone(extra)))
		OldArr.ConcatInplace(a_old, OldArr.Adopt(table.clone(extra)))
		assertEqual(a_new, a_old, "ConcatInplace")
	end
end

print("Arr differential test: 10000 operations passed with 0 mismatches!")
