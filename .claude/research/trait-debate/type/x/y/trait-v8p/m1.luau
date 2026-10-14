--!strict
local Trait = require("./Trait")
local function d1<M>(mode: M) return function<Self, T>(of: (Self & Trait.Item<T>) | Trait.AnyToken)
	return { Get = Trait.Fn<<(s: Self) -> T>>(), D = Trait.Default("full", function(ops: any) return function(s: Self): T return "x" :: any end end) }
end end
const L1 = Trait.Trait("M1", d1<<"full">>, d1<<"impl">>)
-- 모드 오타: 둘째 인자 자리에 "ful"
local function d2<M>(mode: M) return function<Self, T>(of: (Self & Trait.Item<T>) | Trait.AnyToken)
	return { Get = Trait.Fn<<(s: Self) -> T>>(), D = Trait.Default(mode, function(ops: any) return function(s: Self): T return "x" :: any end end) }
end end
const L2 = Trait.Trait("M2", d2<<"ful">>, d2<<"impl">>) -- NEG?
const L3 = Trait.Trait("M3", d2<<"impl">>, d2<<"full">>) -- NEG? 바뀜
const L4 = Trait.Trait("M4", d2<<"full">>) -- 둘째 생략
local canary: string = 1
return { L1, L2, L3, L4, canary }
