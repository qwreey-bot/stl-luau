--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
export type AssocRead<T> = { read Item: () -> T }
export type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
export type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag: AssocRead<T> } }
export type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag: Assoc<T> } }
local Bag
do Bag =  Trait.Trait("P6.do", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
	return table.freeze({
		Put = Trait.FnMut<<(bag: Self, item: T) -> ()>>(),
		Peek = Trait.Fn<<(bag: Self) -> T?>>(),
		Fold = Trait.Default(function(_ops: any): <U>(bag: Self, init: U, f: (U, T) -> U) -> U
			return nil :: any
		end),
	})
end)
end
type MyBag<T> = { read __type: stl.TraitToken<"P6">, read __traits: { read Bag: Assoc<T> } }
local b: MyBag<number> = nil :: any
Bag.Put(b, "x") -- 기대: 에러(원소)
local s: string? = Bag.Peek(b) -- 기대: 에러
local f: string = Bag.Fold(b, 0, function(acc: number, v: number): number return acc + v end) -- 기대: 에러(반환)
Bag.Fold(b, 0, function(acc: number, v: string): number return acc end) -- 기대: 에러(콜백 원소)
local canary: string = 1
return nil
