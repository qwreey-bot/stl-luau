--!strict
-- 손으로 쓴 서명이면 같은 호출이 잡히는가(읽기 공변 첫 인자 + 읽기 리스트) — Tfield/Ttwo 의 0건이 Entries 탓인지 Luau 추론 탓인지
local stl = require("../src")
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read H: AssocRead<T> } }
type MyBag<T> = { read __type: stl.TraitToken<"Hx">, read __traits: { read H: Assoc<T> } }
local Zip: <T>(bag: ValueRead<T>, a: { read [number]: T }, c: { read [number]: T }) -> () = nil :: any
local Conf: <T>(bag: ValueRead<T>, opts: { read x: T, read list: { read [number]: T } }) -> () = nil :: any
local b: MyBag<number> = nil :: any
Zip(b, { 1 }, { "s" }) -- NEG
Conf(b, { x = "s", list = { 2 } }) -- NEG
Conf(b, { x = 1, list = { "s" } }) -- NEG
return nil
