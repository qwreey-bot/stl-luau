--!strict
local stl = require("../src")
local a = stl.Arr.Of(1, 2, 3)
local cd = stl.CircularDeque.Of(1, 2)
local s1: number = stl.List.Fold(a, 0, function(acc: number, v: number, _i: number): number return acc + v end)
local s2: string = stl.List.Fold(a, "", function(acc: string, v: number, _i: number): string return acc .. v end)
local s3: string = stl.List.Of(a).Fold(a, "", function(acc: string, v: number, _i: number, ...): string return acc end)
local s4: boolean = stl.List.Fold(cd, false, function(acc: boolean, v: number, _i: number): boolean return acc end)
local s5: number = stl.List.Fold(cd, "", function(acc: string, v: number, _i: number): string return acc end) -- NEG
local s6 = stl.List.Fold(a, 0, function(acc: number, v: string, _i: number): number return acc end) -- NEG
local canary: string = 1
return nil
