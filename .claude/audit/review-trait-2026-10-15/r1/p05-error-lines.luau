--!nocheck
-- 프로브 05: 트레이트 시스템의 raise 자리 전부가 사용자 줄을 가리키는가(-O0/-O1/-O2 로 돌림).
local stl = require("../../../../src")
local Trait = stl.Trait
local results = { ok = 0, bad = 0 }
local function check(label, where, err)
	local s = tostring(err)
	local want = ":" .. where .. ":"
	if string.find(s, "p05-error-lines.luau" .. want, 1, true) then
		results.ok += 1
	else
		results.bad += 1
		print("BAD", label, "want line", where, "got", s)
	end
end
local n = 0
local function uniq(p) n += 1; return "P05." .. p .. n end
local function tr(fns) return Trait.Trait(uniq("T"), function(of) return table.freeze(fns) end) end

local where, ok, err
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.NewToken(5) end); check("tokenName", where, err)
local t1 = Trait.NewToken(uniq("Tok"))
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.NewToken(t1.name) end); check("tokenTaken", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.Stamp({}, {}) end); check("notToken Stamp", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.Stamp(table.freeze({}), t1) end); check("stampBad", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.ImplOf({}, {}) end); check("notTrait ImplOf", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.Implements({}, {}) end); check("notTrait Implements", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.Expose({}, {}) end); check("notTrait Expose", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.Trait(5, function() return {} end) end); check("traitName", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.Trait(uniq("X"), 42) end); check("badFns notfn", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.Trait(uniq("X"), function() return 1 end) end); check("badFns nottable", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.Trait(uniq("X"), function() return { Raw = function() end } end) end); check("badFns mark", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.Trait(uniq("X"), function() return { [1] = Trait.Fn() } end) end); check("badFns key", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.Trait(uniq("X"), function() return { Of = Trait.Fn() } end) end); check("reserved", where, err)
local X = tr({ Len = Trait.Fn(), Twice = Trait.Default(function(ops) return function(v) return ops.Len(v) * 2 end end) })
ok, err = pcall(function() where = debug.info(1, "l") + 1
	X.ImplFor({}, {}) end); check("notToken ImplFor", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	X.ImplFor(t1, 5) end); check("implNotTable", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	X.ImplFor(t1, { Len = function() end, Nope = function() end }) end); check("unknownName", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	X.ImplFor(t1, { Len = 5 }) end); check("notFunction own", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	X.ImplFor(t1, setmetatable({}, { __index = { Len = 5 } })) end); check("notFunction inherited", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	X.ImplFor(t1, {}) end); check("missing", where, err)
X.ImplFor(t1, { Len = function() return 1 end })
ok, err = pcall(function() where = debug.info(1, "l") + 1
	X.ImplFor(t1, { Len = function() return 1 end }) end); check("already", where, err)
local Y = tr({ Get = Trait.Fn() })
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Y.ImplWhere(5, function() end) end); check("emptyWhere", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Y.ImplWhere({ X }, 5) end); check("builderNotFunction", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Y.ImplWhere({ X }, function() return 5 end) end); check("builderNotTable onWhere", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Y.ImplWhere({ {} }, function() return {} end) end); check("notTrait ImplWhere", where, err)
Y.ImplWhere({ X }, function(deps) return { Get = deps[X].Len } end)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Y.ImplWhere({ X }, function(deps) return { Get = deps[X].Len } end) end); check("overlap onWhere", where, err)
-- overlap 이 나중에 생기는 종류에서(sourceOf) — 서로 다른 의존 둘
local Z = tr({ Get = Trait.Fn() })
local W1 = tr({ A = Trait.Fn() })
local W2 = tr({ B = Trait.Fn() })
Z.ImplWhere({ W1 }, function(deps) return { Get = deps[W1].A } end)
Z.ImplWhere({ W2 }, function(deps) return { Get = deps[W2].B } end)
local t2 = Trait.NewToken(uniq("Tok"))
W1.ImplFor(t2, { A = function() end })
ok, err = pcall(function() where = debug.info(1, "l") + 1
	W2.ImplFor(t2, { B = function() end }) end); check("overlap sourceOf", where, err)
-- builderNotTable 이 나중 종류에서(sourceOf) — 계약 위반이지만 메시지는 사용자 줄이어야
-- defaultNotFunction / defaultCycle
local D = tr({ Len = Trait.Fn(), Bad = Trait.Default(function(ops) return 5 end) })
local t3 = Trait.NewToken(uniq("Tok"))
ok, err = pcall(function() where = debug.info(1, "l") + 1
	D.ImplFor(t3, { Len = function() end }) end); check("defaultNotFunction", where, err)
local C = tr({ Len = Trait.Fn(),
	P = Trait.Default(function(ops) local q = ops.Q; return function() return q() end end),
	Q = Trait.Default(function(ops) local p = ops.P; return function() return p() end end) })
ok, err = pcall(function() where = debug.info(1, "l") + 1
	C.ImplFor(t3, { Len = function() end }) end); check("defaultCycle", where, err)
-- Expose
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.Expose(X, 5) end); check("exposeNotTable", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.Expose(X, { Len = function() end }) end); check("exposeTaken", where, err)
-- 진입점·Of·ExpectImpl 의 셋
local t4 = Trait.NewToken(uniq("Tok"))
ok, err = pcall(function() where = debug.info(1, "l") + 1
	X.Of(t4) end); check("notImplemented Of(token)", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	X.Of(Trait.Stamp({}, t4)) end); check("entryMiss Of(value)", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	X.Len(Trait.Stamp({}, t4)) end); check("entryMiss entry known", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	X.Len({ __type = { name = "Ghost" } }) end); check("entryMiss entry foreign", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	X.Len(5) end); check("entryMiss entry none", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	Trait.ExpectImpl(X, {}, "Foo") end); check("ExpectImpl", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	stl.Map.Keys({}) end); check("Map.Keys miss", where, err)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	stl.Arr.GroupBy(stl.Arr.Of(1), function(x) return x end, {}) end); check("GroupBy miss", where, err)
-- 뭉텅이 대상 진입점(Stack)
ok, err = pcall(function() where = debug.info(1, "l") + 1
	stl.Stack.Push(stl.HashMap.New(), 1) end); check("Stack.Push on map", where, err)
print("ok", results.ok, "bad", results.bad)
