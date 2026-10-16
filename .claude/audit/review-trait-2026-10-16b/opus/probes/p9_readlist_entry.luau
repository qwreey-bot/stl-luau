--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
export type AssocRead<T> = { read Item: () -> T }
export type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
export type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag: AssocRead<T> } }
export type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("P9.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			-- 규약대로 리스트를 읽기만 하는 인자는 `{ read [number]: T }`(conventions "칸과 길이는 읽기만 공개")
			AddAll = Trait.FnMut<<(bag: Self, items: { read [number]: T }) -> ()>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"P9">, read __traits: { read Bag: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2, 3)
Bag.AddAll(b, arr) -- 맞는 코드: Arr 은 읽기 전용 리스트
Bag.OfMut(b).AddAll(b, arr) -- 같은 호출을 완성 표로(대조)
local canary: string = 1
return nil
