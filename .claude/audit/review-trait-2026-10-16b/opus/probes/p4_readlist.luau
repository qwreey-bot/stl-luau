--!strict
local stl = require("../src")
local cd = stl.CircularDeque.Of(1, 2)
local ld = stl.LinkedDeque.Of(1, 2)
local hm = stl.HashMap.New<<number, number>>()
local h = stl.Heap.New(function(a: number, b: number) return a < b end)
local x1 = stl.HashSet.FromList(cd) -- 기대: 에러(원형 덱은 리스트 진입점 X)
local x2 = stl.HashSet.FromList(ld) -- 기대: 에러
local x3 = stl.HashSet.FromList(hm) -- 기대: 에러
local x4 = stl.HashSet.FromList(h) -- 기대: 에러
local x5 = stl.Arr.FromTable(cd) -- 기대: 에러
local x6 = stl.HashSet.FromList({ __type = 1 }) -- ?
local canary: string = 1
return nil
