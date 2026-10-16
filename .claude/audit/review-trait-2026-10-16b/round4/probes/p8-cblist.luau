--!strict
-- 인덱서 안의 함수 타입 속 T (콜백 목록) — 유지 칸 둘
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Ev8: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Ev8: Assoc<T> } }
local Ev
do
	Ev = Trait.Trait("P8.Ev", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			Listeners = Trait.Fn<<(e: Self) -> { read [number]: (T) -> () }>>(),
			Connect = Trait.FnMut<<(e: Self, fns: { read [number]: (T) -> () }) -> ()>>(),
			ConnectMap = Trait.FnMut<<(e: Self, fns: { read [string]: (T) -> boolean }) -> ()>>(),
			Snapshot = Trait.Fn<<(e: Self) -> { read [number]: { read value: T } }>>(),
			Load = Trait.FnMut<<(e: Self, rows: { read [number]: { read value: T } }) -> ()>>(),
		})
	end)
end
type MyEv<T> = { read __type: stl.TraitToken<"P8">, read __traits: { read Ev8: Assoc<T> } }
local e: MyEv<number> = nil :: any
local ls = Ev.Listeners(e) -- POS
Ev.Connect(e, { function(x: number) end }) -- POS
Ev.Connect(e, { function(x: string) end }) -- NEG
Ev.ConnectMap(e, { a = function(x: number): boolean return true end }) -- POS
Ev.ConnectMap(e, { a = function(x: string): boolean return true end }) -- NEG
local sn = Ev.Snapshot(e) -- POS
local sv: number? = if sn[1] then sn[1].value else nil -- POS
Ev.Load(e, { { value = 1 } }) -- POS
Ev.Load(e, { { value = "s" } }) -- NEG
return { ls, sv }
