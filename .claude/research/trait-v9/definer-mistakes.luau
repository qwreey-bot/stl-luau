--!strict
-- 정의하는 사람의 실수 넷 — 전부 **에러가 나야** 함(조용하면 안 됨). 각 줄의 `-- MISTAKE` 마다 에러.
local Trait = require("./Trait")
type ItemIndexRead<E, I> = Trait.ItemIndexRead<E, I>
const Fn, Default = Trait.Fn, Trait.Default
local function def<M>(mode: M)
	return function<Self, E, I>(of: (Self & ItemIndexRead<E, I>) | Trait.AnyToken)
		return {
			Get = Fn<<(list: Self, idx: I) -> E?>>(),
			Has = Default(mode, function(ops: any)
				return function(list: Self, item: E): boolean
					return false
				end
			end),
		}
	end
end
const Swapped = Trait.Trait("Swapped", def(Trait.IMPL), def(Trait.FULL)) -- MISTAKE: 모드를 맞바꿈
const Literal = Trait.Trait("Literal", def("full"), def("impl")) -- MISTAKE: 상수 대신 글자(넓어져 string)
const Uncalled = Trait.Trait("Uncalled", def, def) -- MISTAKE: 부르지 않고 넘김
type SwappedFull<S, E, I> = typeof(Swapped.Of<<S, E, I>>(nil :: any))
type LiteralFull<S, E, I> = typeof(Literal.Of<<S, E, I>>(nil :: any))
type UncalledFull<S, E, I> = typeof(Uncalled.Of<<S, E, I>>(nil :: any))
local x: SwappedFull<{ n: number }, number, number> = nil :: any
local y: LiteralFull<{ n: number }, number, number> = nil :: any
local z: UncalledFull<{ n: number }, number, number> = nil :: any
const s1: boolean = x.Has(nil :: any, 1)
const s2: boolean = y.Has(nil :: any, 1)
const s3: boolean = z.Has(nil :: any, 1)
return { s1, s2, s3 }
