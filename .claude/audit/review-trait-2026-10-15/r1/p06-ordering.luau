--!nocheck
-- 프로브 06: 등록 순서 — 토큰이 뭉텅이 뒤에 생김, 명시가 뭉텅이 뒤, 뭉텅이 위의 뭉텅이, Restore 뒤 진입점.
local stl = require("../../../../src")
local Trait = stl.Trait
local fails = 0
local function expect(label, got, want)
	if got ~= want then fails += 1; print("FAIL", label, got, want) end
end
-- 뭉텅이 위의 뭉텅이: Top 은 Stack 이면(= 덱이면) 따라옴
local Top = Trait.Trait("P06.Top", function(of) return table.freeze({ TopOf = Trait.Fn() }) end)
Top.ImplWhere({ stl.Stack }, function(deps) return { TopOf = deps[stl.Stack].Peek } end)
local d = stl.CircularDeque.Of(1, 2, 3)
expect("Top on existing deque", Top.TopOf(d), 3)
-- 새 바깥 덱(토큰을 나중에 만듦)
local T = Trait.NewToken("P06.MyDeque")
local function new() return Trait.Stamp({ items = {} }, T) end
local impl = {
	PushFront = function(s, x) table.insert(s.items, 1, x); return s end,
	PushBack = function(s, x) table.insert(s.items, x); return s end,
	PopFront = function(s) return table.remove(s.items, 1) end,
	PopBack = function(s) return table.remove(s.items) end,
	Front = function(s) return s.items[1] end,
	Back = function(s) return s.items[#s.items] end,
}
expect("before Deque impl, Stack?", Trait.Implements(stl.Stack, new()), false)
stl.Deque.ImplFor(T, impl)
local m = new()
stl.Stack.Push(m, 10); stl.Queue.Push(m, 20)
expect("Stack.Peek", stl.Stack.Peek(m), 20)
expect("Queue.Peek", stl.Queue.Peek(m), 10)
expect("Top.TopOf (blanket on blanket, new token)", Top.TopOf(m), 20)
-- 명시가 뭉텅이를 덮음: 쥐고 있던 완성 표가 새 함수를 봄
local held = stl.Stack.Of(m)
local heldTop = Top.Of(m)
stl.Stack.ImplFor(T, { Push = impl.PushFront, Pop = impl.PopFront, Peek = impl.Front })
expect("held Stack table sees explicit", held.Peek(m), 10)
expect("Top rebuilt from explicit Stack", heldTop.TopOf(m), 10)
expect("entry uses explicit", stl.Stack.Peek(m), 10)
-- {} 뭉텅이 뒤에 생긴 토큰
local Any = Trait.Trait("P06.Any", function(of) return table.freeze({ Hello = Trait.Fn() }) end)
Any.ImplWhere({}, function() return { Hello = function() return "hi" end } end)
local T2 = Trait.NewToken("P06.Later")
expect("{} after token", Any.Hello(Trait.Stamp({}, T2)), "hi")
-- {} 뭉텅이 위의 뭉텅이, 토큰이 나중에
local OnAny = Trait.Trait("P06.OnAny", function(of) return table.freeze({ Hello2 = Trait.Fn() }) end)
OnAny.ImplWhere({ Any }, function(deps) return { Hello2 = deps[Any].Hello } end)
local T3 = Trait.NewToken("P06.Later2")
expect("blanket on {} blanket, later token", OnAny.Hello2(Trait.Stamp({}, T3)), "hi")
-- 명시가 {} 뭉텅이 뒤 — 위로 번짐
Any.ImplFor(T3, { Hello = function() return "own" end })
expect("explicit over {} propagates", OnAny.Hello2(Trait.Stamp({}, T3)), "own")
-- Restore 한 값으로 진입점
local copy = { items = { 1, 2 }, __type = { name = "P06.MyDeque" } }
Trait.Restore(copy)
expect("restored entry", stl.Deque.Back(copy), 2)
-- 기본 구현의 형제 재정의가 위로(List): 바깥 리스트가 IndexOf 만 재정의하면 Contains 가 그것을 씀
local LT = Trait.NewToken("P06.List")
local calls = 0
stl.List.ImplFor(LT, {
	Get = function(s, i) return s.items[i] end,
	FirstIndex = function(s) return if #s.items > 0 then 1 else nil end,
	LastIndex = function(s) return if #s.items > 0 then #s.items else nil end,
	NextIndex = function(s, i) return if i < #s.items then i + 1 else nil end,
	PrevIndex = function(s, i) return if i > 1 then i - 1 else nil end,
	IndexOf = function(s, x) calls += 1; return table.find(s.items, x) end,
})
local lv = Trait.Stamp({ items = { 5, 6 } }, LT)
expect("Contains via overridden IndexOf", stl.List.Contains(lv, 6), true)
expect("override called", calls, 1)
print("fails", fails)
