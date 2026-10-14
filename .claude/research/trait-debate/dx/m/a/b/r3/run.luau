--!strict
-- D3 런타임: v8 런타임 그대로 도는지(기본 구현 채움, 재정의, 오타 등록 에러, 한 겹 트레이트)
local TG = require("../TraitG")
local Trait = require("../trait-v8/Trait")
const Fn, Default = TG.Fn, TG.Default
local function listDef<M>(mode: M)
	return function<Self, T>(of: Self?)
		return {
			Get = Fn<<(l: Self, i: number) -> T?>>(),
			Len = Fn<<(l: Self) -> number>>(),
			Contains = Default(mode, function(ops: any)
				const get, len = ops.Get, ops.Len
				return function(l: Self, x: T): boolean
					for i = 1, len(l) do
						if get(l, i) == x then
							return true
						end
					end
					return false
				end
			end),
		}
	end
end
const List = TG.Trait("ListRun", listDef(TG.FULL), listDef(TG.IMPL))
const Size = TG.Trait("SizeRun", function<Self>(of: Self?)
	return { Len = Fn<<(s: Self) -> number>>() }
end)
const T = Trait.Token("My.Arr3")
List.ImplFor(T, { Get = function(l: any, i: number) return l.items[i] end, Len = function(l: any) return #l.items end })
Size.ImplFor(T, { Len = function(l: any) return #l.items end })
const v: any = { items = { 10, 20 }, __type = T }
print("default Contains:", List.Of(v).Contains(v, 20), List.Contains(v, 99), "Size:", Size.Of(v).Len(v))
local ok, err = pcall(function()
	const T2 = Trait.Token("My.Arr4")
	List.ImplFor(T2, { Get = function() return nil end, Len = function() return 0 end, Contians = function() return true end } :: any)
end)
print("typo override:", ok, err)
