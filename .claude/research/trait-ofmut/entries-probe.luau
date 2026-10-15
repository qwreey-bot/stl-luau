--!strict
local Trait = require("../../../src/Trait")
type Tag = { read __probeDeque: true }
type Box<T> = { read __type: Trait.Token<"P">, read __probeDeque: true, read __generics: { read Item: (T) -> T }, read __readGenerics: { read Item: () -> T }, items: { T } }
type BoxRead<T> = { read __type: Trait.Token<"P">, read __probeDeque: true, read __readGenerics: { read Item: () -> T }, read items: { read [number]: T } }
type Other<T> = { read __type: Trait.Token<"Q">, read __generics: { read Item: (T) -> T }, read __readGenerics: { read Item: () -> T } }
const D = Trait.Trait("Probe.D", function<Self, T>(of: (Self & Trait.ItemRead<T> & Tag) | Trait.AnyToken, ofMut: (Self & Trait.Item<T> & Tag) | Trait.AnyToken)
		return table.freeze({
			Push = Trait.FnMut<<(d: Self, item: T) -> Self>>(),
			Peek = Trait.Fn<<(d: Self) -> T?>>(),
		Has = Trait.Default(function(_ops: any): (d: Self, item: T) -> boolean
			return function(_d: Self, _item: T): boolean
				return false
			end
		end),
		Has2 = Trait.Fn<<(d: Self, item: T) -> boolean>>(),
			Fold = Trait.Default(function(_ops: any): <U>(d: Self, init: U, fn: (U, T) -> U) -> U
				return function<U>(_d: Self, init: U, _fn: (U, T) -> U): U
					return init
				end
			end),
		})
	end)
local b: Box<number> = nil :: any
local br: BoxRead<number> = b
local o: Other<number> = nil :: any
local p1: number? = D.Peek(br)
local p2: Box<number> = D.Push(b, 1)
local s: string = D.Fold(b, "", function(acc: string, x: number): string return acc .. x end)
local n1: string? = D.Peek(br) -- NEG 원소
local n2 = D.Push(br, 1) -- NEG 빌린 참조에 쓰기
local n3 = D.Push(b, "x") -- NEG 원소
local n4 = D.Peek(o) -- NEG 다른 종류(태그 없음)
local n5: number = D.Fold(b, "", function(acc: string, x: number): string return acc .. x end) -- NEG U
local function gen<C, T>(c: C & Trait.Item<T> & Tag, x: T): C
	return D.Push(c, x)
end
local g: Box<number> = gen(b, 2)
local n6 = gen(b, "y") -- NEG
local h1: boolean = D.Has(b, 1)
local h2: boolean = D.Has2(b, 1)
local canary: string = 1
return { p1, p2, s, n1, n2, n3, n4, n5, g, n6, canary }
