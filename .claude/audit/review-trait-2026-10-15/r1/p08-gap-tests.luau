--!nocheck
-- 프로브 08: 돌연변이 M04·M05·M16·M23·M37·M38 이 살아남은 자리를 잡는 시험(원본에서 전부 PASS 여야 함).
local stl = require("../../../../src")
local T = stl.Trait
local fails = 0
local function check(label, cond) if not cond then fails += 1; print("FAIL", label) end end
local function tr(name, fns) return T.Trait(name, function() return table.freeze(fns) end) end
-- (M04) 겹침이 의존 등록 **뒤에** 생김: 뭉텅이 둘을 먼저 걸고, 종류가 두 의존을 차례로 얻음
do
	local Z = tr("P08.Z", { Get = T.Fn() })
	local W1 = tr("P08.W1", { A = T.Fn() })
	local W2 = tr("P08.W2", { B = T.Fn() })
	Z.ImplWhere({ W1 }, function(deps) return { Get = deps[W1].A } end)
	Z.ImplWhere({ W2 }, function(deps) return { Get = deps[W2].B } end)
	local t = T.NewToken("P08.Both")
	W1.ImplFor(t, { A = function() return "a" end })
	local ok, err = pcall(W2.ImplFor, t, { B = function() return "b" end })
	check("M04 later overlap errors", not ok and string.find(tostring(err), "two blanket implementations of P08.Z", 1, true))
end
-- (M05) 겹치는 뭉텅이 등록이 실패하면 아무것도 남지 않음: 그 뒤 다른 종류(한쪽 의존만)에 원래 뭉텅이 그대로
do
	local Z = tr("P08.Z2", { Get = T.Fn() })
	local W1 = tr("P08.W12", { A = T.Fn() })
	local W2 = tr("P08.W22", { B = T.Fn() })
	Z.ImplWhere({ W1 }, function(deps) return { Get = deps[W1].A } end)
	local both = T.NewToken("P08.Both2")
	W1.ImplFor(both, { A = function() return "a" end })
	W2.ImplFor(both, { B = function() return "b" end })
	local ok = pcall(Z.ImplWhere, { W2 }, function(deps) return { Get = deps[W2].B } end)
	check("M05 overlap rejected", not ok)
	local only2 = T.NewToken("P08.Only2")
	local ok2 = pcall(W2.ImplFor, only2, { B = function() return "b" end })
	check("M05 rejected blanket left nothing behind", ok2 and not T.Implements(Z, T.Stamp({}, only2)))
end
-- (M38) 명시 구현으로 겹침을 푼 종류에는 두 번째 뭉텅이를 걸 수 있음(에러 메시지가 권하는 길)
do
	local Z = tr("P08.Z3", { Get = T.Fn() })
	local W1 = tr("P08.W13", { A = T.Fn() })
	local W2 = tr("P08.W23", { B = T.Fn() })
	local both = T.NewToken("P08.Both3")
	W1.ImplFor(both, { A = function() return "a" end })
	W2.ImplFor(both, { B = function() return "b" end })
	Z.ImplFor(both, { Get = function() return "own" end })
	Z.ImplWhere({ W1 }, function(deps) return { Get = deps[W1].A } end)
	local ok, err = pcall(Z.ImplWhere, { W2 }, function(deps) return { Get = deps[W2].B } end)
	check("M38 explicit resolves overlap", ok and Z.Get(T.Stamp({}, both)) == "own")
end
-- (M16) 명시 등록은 넘긴 표의 **사본**으로 다시 지음: 물려받은(`__index`) 함수, 나중에 고친 표
do
	local Base = { Push = function(s, x) return s end, Pop = function() return "base" end, Peek = function() return nil end }
	local t = T.NewToken("P08.Inherit")
	local given = setmetatable({}, { __index = Base })
	stl.Stack.ImplFor(t, given) -- 명시(뭉텅이를 덮음)
	given.Pop = 5 -- 넘긴 뒤에 고침(무시돼야)
	-- 다시 짓기를 부름: 이 종류가 덱이 됨 → Stack 의 표를 다시 지음(명시 사본으로)
	local ok, err = pcall(stl.Deque.ImplFor, t, {
		PushFront = function(s) return s end, PushBack = function(s) return s end,
		PopFront = function() end, PopBack = function() end, Front = function() end, Back = function() end,
	})
	check("M16 rebuild uses snapshot", ok and stl.Stack.Pop(T.Stamp({}, t)) == "base")
	if not ok then print("  ", err) end
end
-- (M23) 얼린 표는 Restore 가 건드리지 않음(에러 없이)
do
	local frozen = table.freeze({ __type = { name = "Stl.Arr" }, n = 0 })
	local ok = pcall(T.Restore, { inner = frozen })
	check("M23 frozen node skipped", ok)
end
-- (M37) 칸이 Fn/Default 가 아닌 표면 정의 에러
do
	local ok = pcall(T.Trait, "P08.Bad", function() return { Len = T.Fn(), Sub = {} } end)
	check("M37 plain table slot rejected", not ok)
end
-- (M34) 문자열 __type 이 트레이트 함수 이름과 같은 값은 구현이 아님
check("M34 string __type", not T.Implements(stl.Map, { __type = "Get" }))
print("fails", fails)
