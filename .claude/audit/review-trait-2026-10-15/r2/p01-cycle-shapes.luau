--!nocheck
-- 프로브 01: ImplWhere 고리 검사의 모양들 — 놓치는 고리 / 거절하는 정상 그래프
-- 실행: ( ulimit -v 1048576; timeout 60 luau p01-cycle-shapes.luau )
local stl = require("../../../../src")
local T = stl.Trait
local function tr(name, fns)
	return T.Trait(name, function()
		return table.freeze(fns)
	end)
end
local function try(label, fn)
	local ok, err = pcall(fn)
	print(label, ok, if ok then "" else string.sub(tostring(err), 1, 220))
end

-- 1. 다이아몬드(고리 아님): A ← B, A ← C, D ← {B, C}
local A = tr("P01.A", { a = T.Fn() })
local B = tr("P01.B", { b = T.Fn() })
local C = tr("P01.C", { c = T.Fn() })
local D = tr("P01.D", { d = T.Fn() })
B.ImplWhere({ A }, function(deps) return { b = deps[A].a } end)
C.ImplWhere({ A }, function(deps) return { c = deps[A].a } end)
try("다이아몬드 D<-{B,C}", function()
	D.ImplWhere({ B, C }, function(deps) return { d = deps[B].b } end)
end)
local k = T.NewToken("P01.Kind")
A.ImplFor(k, { a = function() return "A" end })
print("D.d", D.d(T.Stamp({}, k)))

-- 2. 의존 목록의 둘째가 고리를 만듦: A.ImplWhere({ X, D }) — D 는 A 에서 따라옴
local X = tr("P01.X", { x = T.Fn() })
try("둘째 의존이 고리", function()
	A.ImplWhere({ X, D }, function(deps) return { a = deps[X].x } end)
end)

-- 3. 고리가 둘째 뭉텅이를 지나감: E 에 뭉텅이 둘({Y}, {A}) — A.ImplWhere({E}) 는 고리
local E = tr("P01.E", { e = T.Fn() })
local Y = tr("P01.Y", { y = T.Fn() })
E.ImplWhere({ Y }, function(deps) return { e = deps[Y].y } end)
E.ImplWhere({ A }, function(deps) return { e = deps[A].a } end)
try("둘째 뭉텅이를 지나는 고리", function()
	A.ImplWhere({ E }, function(deps) return { a = deps[E].e } end)
end)

-- 4. 라이브러리 트레이트: Deque 가 Stack 에서 따라오게(Stack 은 Deque 에서 따라옴) — 고리
try("Deque <- Stack", function()
	stl.Deque.ImplWhere({ stl.Stack }, function(deps)
		local s = deps[stl.Stack]
		return { PushFront = s.Push, PushBack = s.Push, PopFront = s.Pop, PopBack = s.Pop, Front = s.Peek, Back = s.Peek }
	end)
end)

-- 5. 이미 다른 트레이트의 의존인 트레이트(Deque)에 뭉텅이를 더함(고리 아님): Deque <- MyRing
local MyRing = tr("P01.MyRing", { Put = T.Fn(), Take = T.Fn(), Look = T.Fn() })
try("Deque <- MyRing", function()
	stl.Deque.ImplWhere({ MyRing }, function(deps)
		local r = deps[MyRing]
		return { PushFront = r.Put, PushBack = r.Put, PopFront = r.Take, PopBack = r.Take, Front = r.Look, Back = r.Look }
	end)
end)
local rk = T.NewToken("P01.Ring")
local store = {}
MyRing.ImplFor(rk, {
	Put = function(s, v) table.insert(store, v) return s end,
	Take = function() return table.remove(store) end,
	Look = function() return store[#store] end,
})
local ring = T.Stamp({}, rk)
stl.Stack.Push(ring, 10)
stl.Queue.Push(ring, 20)
print("Stack.Pop/Queue.Peek via Deque<-MyRing", stl.Stack.Pop(ring), stl.Queue.Peek(ring))

-- 6. 같은 의존을 두 번 적은 목록(고리 아님)
local F = tr("P01.F", { f = T.Fn() })
try("의존 중복 {A, A}", function()
	F.ImplWhere({ A, A }, function(deps) return { f = deps[A].a } end)
end)
print("F.f", F.f(T.Stamp({}, k)))

-- 7. 고리가 거절된 뒤에도 같은 쌍의 반대 방향은 그대로 동작(거절이 남기는 것 없음): A 의 뭉텅이 수
-- (테스트 8절 (2) 와 같은 성질 — 여기서는 둘째 의존 경로)
local k2 = T.NewToken("P01.Kind2")
X.ImplFor(k2, { x = function() return "X" end })
print("거절된 A<-{X,D} 가 k2 에 남지 않음 (Implements A)", T.Implements(A, T.Stamp({}, k2)))
