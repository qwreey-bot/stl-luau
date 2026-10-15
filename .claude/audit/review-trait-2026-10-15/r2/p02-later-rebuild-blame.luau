--!nocheck
-- 프로브 02: 뭉텅이의 잘못이 **나중의 다시 짓기**(다른 등록이 일으킴)에서 드러날 때의 문구·줄
-- 뭉텅이를 건 때에는 조건을 갖춘 종류가 없어(의존 트레이트가 막 정의됨) 선검사가 아무것도 짓지 않음 → 첫 종류의 등록에서 드러남.
local stl = require("../../../../src")
local T = stl.Trait
local function tr(name, fns)
	return T.Trait(name, function()
		return table.freeze(fns)
	end)
end
local function try(label, fn)
	local ok, err = pcall(fn)
	print(label, ok, if ok then "" else tostring(err))
end

local Src = tr("P02.Src", { a = T.Fn() })
local Dst = tr("P02.Dst", { run = T.Fn(), stop = T.Fn() })
-- 빠뜨림(stop 이 없음) — 지금은 Src 를 구현한 종류가 없어 선검사가 못 봄
Dst.ImplWhere({ Src }, function(deps)
	return { run = deps[Src].a }
end)
print("ImplWhere 통과(조건 갖춘 종류 없음)")
-- (a) onFor → commit → refresh(Dst) 경로
try("Src.ImplFor (빠뜨림이 여기서 드러남)", function()
	Src.ImplFor(T.NewToken("P02.K1"), { a = print })
end)

-- (b) onToken 경로: {} 뭉텅이가 모르는 이름을 돌려주는 경우가 **나중 토큰에서만** 생김(builder 가 deps 를 보고 고름 — 여기선 호출 횟수)
local Every = tr("P02.Every", { go = T.Fn() })
local calls = 0
Every.ImplWhere({}, function()
	calls += 1
	if calls == 30 then
		return { go = print, extra = print }
	end
	return { go = print }
end)
print("{} 뭉텅이 통과, 지은 횟수", calls)
for i = 1, 20 do
	local ok, err = pcall(T.NewToken, "P02.Tok" .. i)
	if not ok then
		print("NewToken", i, tostring(err))
		break
	end
end

-- (c) 겹침이 위로 번지는 다시 짓기에서 남기는 상태: Stack 에 뭉텅이 {MyRing} 을 먼저, 그다음 Deque 에 뭉텅이 {MyRing}
local MyRing = tr("P02.MyRing", { Put = T.Fn(), Take = T.Fn(), Look = T.Fn() })
local function ringImpl()
	local store = {}
	return {
		Put = function(s, v) table.insert(store, v) return s end,
		Take = function() return table.remove(store) end,
		Look = function() return store[#store] end,
	}
end
local r1, r2 = T.NewToken("P02.Ring1"), T.NewToken("P02.Ring2")
MyRing.ImplFor(r1, ringImpl())
MyRing.ImplFor(r2, ringImpl())
stl.Stack.ImplWhere({ MyRing }, function(deps)
	local r = deps[MyRing]
	return { Push = r.Put, Pop = r.Take, Peek = r.Look }
end)
try("Deque.ImplWhere({MyRing}) — Stack 이 두 뭉텅이로 겹침", function()
	stl.Deque.ImplWhere({ MyRing }, function(deps)
		local r = deps[MyRing]
		return { PushFront = r.Put, PushBack = r.Put, PopFront = r.Take, PopBack = r.Take, Front = r.Look, Back = r.Look }
	end)
end)
print("실패한 뒤: Deque 구현? r1", T.Implements(stl.Deque, T.Stamp({}, r1)), "r2", T.Implements(stl.Deque, T.Stamp({}, r2)))
print("실패한 뒤: Queue 구현? r1", T.Implements(stl.Queue, T.Stamp({}, r1)), "r2", T.Implements(stl.Queue, T.Stamp({}, r2)))
-- 메시지가 권하는 길: Stack 을 그 종류에 직접 구현 → 그다음 다시 Deque 뭉텅이
stl.Stack.ImplFor(r1, { Push = function(s) return s end, Pop = print, Peek = print })
stl.Stack.ImplFor(r2, { Push = function(s) return s end, Pop = print, Peek = print })
try("권하는 길을 따른 뒤 Deque.ImplWhere({MyRing}) 다시", function()
	stl.Deque.ImplWhere({ MyRing }, function(deps)
		local r = deps[MyRing]
		return { PushFront = r.Put, PushBack = r.Put, PopFront = r.Take, PopBack = r.Take, Front = r.Look, Back = r.Look }
	end)
end)
print("그 뒤: Deque 구현? r1", T.Implements(stl.Deque, T.Stamp({}, r1)), "r2", T.Implements(stl.Deque, T.Stamp({}, r2)))
local r3 = T.NewToken("P02.Ring3")
try("새 종류 r3 를 MyRing 으로", function()
	MyRing.ImplFor(r3, ringImpl())
end)
print("r3: Deque", T.Implements(stl.Deque, T.Stamp({}, r3)), "Stack", T.Implements(stl.Stack, T.Stamp({}, r3)))
