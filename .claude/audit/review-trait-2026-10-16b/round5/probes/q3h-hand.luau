--!strict
local stl = require("../src")
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q3: Assoc<T> } }
type MyBag<T> = { read __type: stl.TraitToken<"Q3">, read __traits: { read Q3: Assoc<T> } }
local AddOrList: <T>(bag: Value<T>, x: T | { read [number]: T }) -> () = nil :: any
local EachM: <T>(bag: Value<T>, pool: { read [number]: T }, f: (T) -> ()) -> () = nil :: any
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
AddOrList(b, 1) -- POS
AddOrList(b, { 1 }) -- POS
AddOrList(b, arr) -- POS
AddOrList(b, "s") -- NEG
EachM(b, { 1 }, function(x) local y: string = x end) -- NEG
return nil
