--!strict
-- 제네릭 팩을 가진 정의 <Self, A...> + 인덱서 칸 여럿
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<A...> = { read Item: (A...) -> () }
type ValueRead<A...> = { read __type: stl.TraitToken<any>, read __traits: { read Sig7: AssocRead<A...> } }
local Sig
do
	Sig = Trait.Trait("P7.Sig", function<Self, A...>(of: (Self & ValueRead<A...>) | AnyToken)
		return table.freeze({
			Fire = Trait.Fn<<(s: Self, A...) -> ()>>(), -- 꼬리가 맨 팩
			Listeners = Trait.Fn<<(s: Self) -> { read [number]: (A...) -> () }>>(), -- 인덱서
			Connect = Trait.Fn<<(s: Self, fns: { read [number]: (A...) -> () }) -> ()>>(), -- 인덱서
			FireAll = Trait.Fn<<(s: Self, tags: { read [number]: string }, A...) -> ()>>(), -- 인덱서 + 맨 팩 꼬리
		})
	end)
end
type MySig<A...> = { read __type: stl.TraitToken<"P7">, read __traits: { read Sig7: AssocRead<A...> } }
local s: MySig<number, string> = nil :: any
Sig.Fire(s, 1, "x") -- POS
Sig.Fire(s, "x", 1) -- NEG
local ls = Sig.Listeners(s) -- POS
Sig.Connect(s, { function(a: number, b: string) end }) -- POS
Sig.Connect(s, { function(a: string, b: string) end }) -- NEG
Sig.FireAll(s, { "t" }, 1, "x") -- POS
Sig.FireAll(s, { "t" }, "x", 1) -- NEG
ls[1] = function(a: number, b: string) end -- NEG
return nil
