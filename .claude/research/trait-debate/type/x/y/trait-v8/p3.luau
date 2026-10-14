--!strict
local P = require("./Traits")
local Trait = require("./Trait")
local stl = require("../../../src")
type A = Trait.A
type Arr<T> = stl.Arr<T>
const arrList: P.ListImpl<Arr<A>, A, number> = {
	Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex,
	IndexOf = stl.Arr.IndexOf, Contains = stl.Arr.Contains, Fodl = stl.Arr.Fold, -- 오타: 타입이 못 잡음?
}
local canary: string = 1
return { arrList, canary }
