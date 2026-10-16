--!strict
local stl = require("../src")
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read U1: Assoc<T> } }
type MyBag<T> = { read __type: stl.TraitToken<"U1x">, read __traits: { read U1: Assoc<T> } }
local PushOr: <T>(bag: Value<T>, x: T | string, rest: { read [number]: T }) -> () = nil :: any
local PushOrW: <T>(bag: Value<T>, x: T | string, rest: { T }) -> () = nil :: any
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
PushOr(b, "s", arr) -- POS
PushOr(b, "s", { 1 }) -- POS
PushOrW(b, "s", { 1 }) -- POS
return nil
