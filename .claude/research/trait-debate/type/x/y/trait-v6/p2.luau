--!strict
local Trait = require("./Trait")
local stl = require("../../../src")
type A = Trait.A
type Arr<T> = stl.Arr<T>
const L = Trait.Trait("P2", function<Self, E>(of: (Self & Trait.ItemRead<E>) | Trait.AnyToken)
	return {
		Get = Trait.Fn<<(s: Self, i: number) -> E?>>(),
		Has = Trait.Default(function(ops: P2<Self, E>)
			const get = ops.Get
			return function(s: Self, x: E): boolean
				return get(s, 1) == x
			end
		end),
		Bad = Trait.Default(function(ops: P2<Self, E>)
			return function(s: Self, x: E): boolean
				return 5 -- NEG 몸통 반환
			end
		end),
	}
end)
export type P2<Self, E> = typeof(L.Of<<Self, E>>(nil :: any))
local function mk(): Arr<number> return nil :: any end
local arr = mk()
local tbl = L.Of(arr)
local r1: boolean = tbl.Has(arr, 3)
local r2: string = tbl.Has(arr, 3) -- NEG 같은 파일 반환
local r3: string = tbl.Bad(arr, 3) -- NEG
local r4 = tbl.Has(arr, "s") -- NEG
local canary: string = 1
return { r1, r2, r3, r4, canary }
