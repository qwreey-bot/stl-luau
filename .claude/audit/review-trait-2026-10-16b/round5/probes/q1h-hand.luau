--!strict
-- 손으로 쓴 같은 서명(경계 판정용)
local stl = require("../src")
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q1: AssocRead<T> } }
type MyBag<T> = { read __type: stl.TraitToken<"Q1">, read __traits: { read Q1: Assoc<T> } }
local FindOpt: <T>(bag: ValueRead<T>, pool: { read [number]: T }) -> T? = nil :: any
local Pick: <T>(bag: ValueRead<T>, pool: { read [number]: T }) -> T = nil :: any
local AddAll: <T>(bag: ValueRead<T>, pool: { read [number]: T }) -> () = nil :: any
local b: MyBag<number> = nil :: any
FindOpt(b, { "s" }) -- NEG
local h1 = FindOpt(b, { "s" }) -- NEG
local h2: number? = FindOpt(b, { "s" }) -- NEG
Pick(b, { "s" }) -- NEG
AddAll(b, { "s" }) -- NEG
return { h1, h2 }
