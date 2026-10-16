--!strict
local stl = require("../src")
local List, Arr, LD, CD = stl.List, stl.Arr, stl.LinkedDeque, stl.CircularDeque
type NodeRead<T> = stl.DoubleNodeRead<T>
local a = Arr.Of(10, 20, 30)
local ld = LD.Of(10, 20)
local cd = CD.Of(10, 20)
local ar: stl.ArrRead<number?> = a
local cr: stl.CircularDequeRead<number?> = cd
local lr: stl.LinkedDequeRead<number> = ld

-- POS
local g1: number? = List.Get(a, 1)
local g2: number? = List.Get(ar, 1)
local g3: number? = List.Get(cr, 1)
local fi = List.FirstIndex(ld)
if fi then
	local g4: number? = List.Get(ld, fi)
	local g5: number? = List.Get(lr, fi)
	local nx: NodeRead<number>? = List.NextIndex(ld, fi)
end
local ins = LD.InsertAfter(ld, LD.FirstIndex(ld) :: NodeRead<number>, 15)
local g6: number? = List.Get(ld, ins)
local f1: number = List.Fold(ar, 0, function(acc: number, v: number?, _i: number): number return acc + (v or 0) end)
local f2: number = List.Fold(cr, 0, function(acc: number, v: number?, _i: number): number return acc + (v or 0) end)
local f3: number = List.Fold(lr, 0, function(acc: number, v: number, _i: NodeRead<number>): number return acc + v end)
local io1: number? = List.IndexOf(ar, nil)
local io2: NodeRead<number>? = List.IndexOf(lr, 10)
local c1: boolean = List.Contains(cr, 10)
local fd, fdi = List.Find(lr, function(v: number, _i: NodeRead<number>): boolean return v > 1 end)
local n1: number = List.Count(ar)
local s1: boolean = List.Some(cr, function(v: number?, _i: number) return v == 1 end)
-- generic user function over ListRead
local function firstOf<E, I>(l: stl.ListRead<E, I>): E?
	local i = List.FirstIndex(l)
	if i == nil then return nil end
	return List.Get(l, i)
end
local fo1: number? = firstOf(a)
local fo2: number? = firstOf(ld)
local fo3: number? = firstOf(ar)

-- NEG
local x1 = List.Get(ld, 123) -- NEG
local x2 = List.NextIndex(a, "x") -- NEG
local x3 = List.PrevIndex(cd, "x") -- NEG
local x4 = List.Get(lr, 1) -- NEG
local x5 = List.PrevIndex(ld, 1) -- NEG
local x6 = List.Get(ar, "1") -- NEG
local x7 = List.NextIndex(LD.Of("s"), fi :: NodeRead<number>) -- NEG? node of number deque into string deque
return { g1, g2, g3, g6, f1, f2, f3, io1, io2, c1, fd, fdi, n1, s1, fo1, fo2, fo3, x1, x2, x3, x4, x5, x6, x7 }
