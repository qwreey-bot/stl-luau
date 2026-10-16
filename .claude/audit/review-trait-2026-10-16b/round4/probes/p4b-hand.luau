--!strict
local stl = require("../src")
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag4: AssocRead<T> } }
type MyBag<T> = { read __type: stl.TraitToken<"P4">, read __traits: { read Bag4: Assoc<T> } }
local function Choose<T>(bag: ValueRead<T>, weights: { read [number]: number }): T return nil :: any end
local function ToList<T>(bag: ValueRead<T>): { read [number]: T } return nil :: any end
local b: MyBag<number> = nil :: any
local c1: number = Choose(b, { 1 }) -- POS
local c2: string = Choose(b, { 1 }) -- NEG
return { c1, c2, ToList }
