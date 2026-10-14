--!strict
-- 런타임 문구: B 의 오타 재정의, A 의 필수 칸 Inherit, A 의 Inherit 생략(런타임은 받음?)
local B = require("./trait-v8/Traits")
local A6 = require("./trait-v6/Traits")
local TraitA = require("./trait-v6/Trait")
local TraitB = require("./trait-v8/Trait")
local function get(l: any, i: any) return l.items[i] end
local function first(l: any) return 1 end
local function nxt(l: any, i: any) return nil end
local function run(label: string, f: () -> ())
	local ok, err = pcall(f)
	print(label, ok, err)
end
run("B typo", function()
	const T = TraitB.Token("My.ListB1")
	B.List.ImplFor(T, { Get = get, FirstIndex = first, LastIndex = first, NextIndex = nxt, PrevIndex = nxt, IndexOff = get } :: any)
end)
run("A Inherit in required", function()
	const T = TraitA.Token("My.ListA1")
	A6.List.ImplFor(T, { Get = get, FirstIndex = TraitA.Inherit, LastIndex = first, NextIndex = nxt, PrevIndex = nxt, IndexOf = TraitA.Inherit, Contains = TraitA.Inherit, Fold = TraitA.Inherit } :: any)
end)
run("A omit defaults (runtime)", function()
	const T = TraitA.Token("My.ListA2")
	A6.List.ImplFor(T, { Get = get, FirstIndex = first, LastIndex = first, NextIndex = nxt, PrevIndex = nxt } :: any)
	const v = { items = { 10, 20 }, __type = T }
	print("  A contains via default:", A6.List.Of(v :: any).Contains(v :: any, 10))
end)
run("B missing required", function()
	const T = TraitB.Token("My.ListB2")
	B.List.ImplFor(T, { Get = get, FirstIndex = first } :: any)
end)
