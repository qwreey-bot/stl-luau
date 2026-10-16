--!strict
local stl = require("../src")
type AssocRead<K, V> = { read Item: () -> (K, V) }
type Assoc<K, V> = { read Item: () -> (K, V), read Mut: (K, V) -> (K, V) }
type ValueRead<K, V> = { read __type: stl.TraitToken<any>, read __traits: { read Multi: AssocRead<K, V> } }
type MyMulti<K, V> = { read __type: stl.TraitToken<"P1">, read __traits: { read Multi: Assoc<K, V> } }
local function GetAll<K, V>(m: ValueRead<K, V>, key: K): { [number]: V } return nil :: any end
local function GetAll2<K, V>(m: ValueRead<K, V>, key: K): { read [number]: V } return nil :: any end
local m: MyMulti<string, number> = nil :: any
GetAll(m, 1) -- NEG: 키 (손으로 쓴 서명)
GetAll2(m, 1) -- NEG
local s: string = GetAll(m, "x")[1] -- NEG: 값
return nil
