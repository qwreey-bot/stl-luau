--!strict
local stl = require("../src")
type Assoc<K, V> = { read Key: () -> K, read Value: () -> V, read Mut: (K, V) -> (K, V) }
type Value<K, V> = { read __type: stl.TraitToken<any>, read __traits: { read Tbl: Assoc<K, V> } }
type MyTbl<K, V> = { read __type: stl.TraitToken<"P5">, read __traits: { read Tbl: Assoc<K, V> } }
local function PutAll<Self, K, V>(t: Self & Value<K, V>, src: { read [K]: V }) end
local function PutAll2<K, V>(t: Value<K, V>, src: { read [K]: V }) end
local t: MyTbl<string, number> = nil :: any
PutAll(t, { a = "s" }) -- NEG
PutAll2(t, { a = "s" }) -- NEG
return nil
