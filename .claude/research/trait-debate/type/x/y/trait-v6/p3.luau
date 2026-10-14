--!strict
local P = require("./Traits")
local Trait = require("./Trait")
local stl = require("../../../src")
type A = Trait.A
type Arr<T> = stl.Arr<T>
const arrList: P.List<Arr<A>, A, number> = {
	Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex,
	IndexOf = stl.Arr.IndexOf, Contains = stl.Arr.Contains, Fodl = stl.Arr.Fold, -- NEG(A): 오타 + Fold 빠짐
}
const arrList2: P.List<Arr<A>, A, number> = {
	Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex,
	IndexOf = Trait.Inherit, Contains = Trait.Inherit, Fold = Trait.Inherit, Get = stl.Arr.Len, -- 중복키
}
local canary: string = 1
return { arrList, arrList2, canary }
