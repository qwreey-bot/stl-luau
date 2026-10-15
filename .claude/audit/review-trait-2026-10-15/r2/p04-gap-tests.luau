--!nocheck
-- 프로브 04: 생존한 돌연변이(mut-r2.log 의 R01·R02·R03·R04·R06·R07·R10)를 각각 잡는 시험 — 지금 src 에서는 전부 통과해야 함.
-- spec.traitrebuild 8절에 옮길 후보. 줄 단언은 생략(메시지만) — 옮길 땐 `where` 를 붙이세요.
local stl = require("../../../../src")
local T = stl.Trait
local function tr(name, fns)
	return T.Trait(name, function()
		return table.freeze(fns)
	end)
end
local function fails(fn, needle, label)
	local ok, err = pcall(fn)
	assert(not ok and string.find(tostring(err), needle, 1, true), `{label}: wanted "{needle}", got {err}`)
end

-- (a) R01: 뭉텅이의 빠뜨림이 **나중의 다시 짓기**에서 드러나도 뭉텅이를 탓함
do
	local Src = tr("P04.Src", { a = T.Fn() })
	local Dst = tr("P04.Dst", { run = T.Fn(), stop = T.Fn() })
	Dst.ImplWhere({ Src }, function(deps)
		return { run = deps[Src].a }
	end)
	fails(function()
		Src.ImplFor(T.NewToken("P04.K1"), { a = print })
	end, "Trait: a blanket implementation of P04.Dst (ImplWhere) for P04.K1 is missing stop for P04.Dst", "(a) 다시 짓기에서 드러난 빠뜨림")
end

-- (b) R02: 의존 목록의 **둘째**가 고리
do
	local A = tr("P04.bA", { a = T.Fn() })
	local B = tr("P04.bB", { b = T.Fn() })
	local X = tr("P04.bX", { x = T.Fn() })
	B.ImplWhere({ A }, function(deps) return { b = deps[A].a } end)
	fails(function()
		A.ImplWhere({ X, B }, function(deps) return { a = deps[X].x } end)
	end, "Trait: P04.bA.ImplWhere on P04.bB makes a cycle", "(b) 둘째 의존")
end

-- (c) R04: 고리가 의존 트레이트의 **둘째 뭉텅이**를 지나감
do
	local A = tr("P04.cA", { a = T.Fn() })
	local E = tr("P04.cE", { e = T.Fn() })
	local Y = tr("P04.cY", { y = T.Fn() })
	E.ImplWhere({ Y }, function(deps) return { e = deps[Y].y } end)
	E.ImplWhere({ A }, function(deps) return { e = deps[A].a } end)
	fails(function()
		A.ImplWhere({ E }, function(deps) return { a = deps[E].e } end)
	end, "Trait: P04.cA.ImplWhere on P04.cE makes a cycle", "(c) 둘째 뭉텅이")
end

-- (d) R03: 고리가 의존 트레이트의 뭉텅이 하나에 적힌 **둘째 의존**을 지나감
do
	local A = tr("P04.dA", { a = T.Fn() })
	local E = tr("P04.dE", { e = T.Fn() })
	local Y = tr("P04.dY", { y = T.Fn() })
	E.ImplWhere({ Y, A }, function(deps) return { e = deps[A].a } end)
	fails(function()
		A.ImplWhere({ E }, function(deps) return { a = deps[E].e } end)
	end, "Trait: P04.dA.ImplWhere on P04.dE makes a cycle", "(d) 뭉텅이의 둘째 의존")
end

-- (e) R06: 다이아몬드는 고리가 아님 — 스택이면서 큐인 것(둘 다 덱에서 따라옴)
do
	local Both = tr("P04.StackQueue", { Size = T.Fn() })
	Both.ImplWhere({ stl.Stack, stl.Queue }, function(deps)
		return { Size = function(x) return stl.Collection.Len(x) end }
	end)
	assert(Both.Size(stl.CircularDeque.Of(1, 2, 3)) == 3, "(e) 다이아몬드")
end

-- (f) R10: Restore 가 토큰 없는 중간 표(HashMap 의 data, 연결 노드)를 지나 안쪽 값까지
do
	local m = stl.HashMap.New()
	stl.HashMap.Set(m, "k", stl.Arr.Of(10, 20))
	local copy = { __type = { name = "Stl.HashMap" }, size = 1, data = { k = table.clone(m.data.k) } }
	copy.data.k.__type = { name = "Stl.Arr" }
	T.Restore(copy)
	assert(T.TokenOf(copy) == stl.HashMap.Token, "(f) 맵")
	assert(T.TokenOf(copy.data.k) == stl.Arr.Token, "(f) 맵 안의 data 를 지나 안쪽 Arr 까지")
end

-- (g) R07: 진입점은 값 **자신의** `__type` 만(메타테이블로 물려받은 토큰은 종류가 아님 — TokenOf 와 같게)
do
	local proto = { __type = stl.CircularDeque.Token }
	proto.__index = proto
	local obj = setmetatable({}, proto)
	assert(T.TokenOf(obj) == nil, "(g) TokenOf 는 raw")
	fails(function()
		stl.Stack.Push(obj, 1)
	end, "Stack: Push needs a Stack (got table without a type token)", "(g) 물려받은 __type 의 진입점")
end

print("p04 PASS")
