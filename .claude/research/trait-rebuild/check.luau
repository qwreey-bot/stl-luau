--!strict
-- 시제품의 동작 확인. 실행: ( ulimit -v 1048576; timeout 60 luau .claude/research/trait-rebuild/check.luau )
local Trait3 = require("./Trait3")
local T = require("./Traits")
local stl = require("../../../src")
local CircularDeque: any, LinkedDeque: any = stl.CircularDeque, stl.LinkedDeque
local Deque, Stack, Queue, List = T.Deque, T.Stack, T.Queue, T.List

local function token(name: string): any
	return table.freeze({ name = name })
end
local function fails(fn: () -> (), needle: string)
	local ok, err = pcall(fn)
	assert(not ok, "expected an error containing: " .. needle)
	assert(string.find(tostring(err), needle, 1, true), `wrong error: {tostring(err)} (wanted {needle})`)
end
-- 덱 여섯을 가진 가짜 종류(함수의 정체성만 봄)
local function fakeDeque(name: string): (any, { [string]: any })
	local tok = token(name)
	local fns = {}
	for _, fnName in { "PushFront", "PushBack", "PopFront", "PopBack", "Front", "Back" } do
		fns[fnName] = function()
			return name .. "." .. fnName
		end
	end
	Trait3.Impl(Deque, tok, fns)
	return tok, fns
end

-- 1. 스택은 덱에서 저절로 따라오고, 표에 든 것은 **덱의 함수 자체**
do
	local d = CircularDeque.Of(10, 20)
	local impl = Trait3.ImplOf(Stack, d)
	assert(
		impl.Push == CircularDeque.PushBack and impl.Pop == CircularDeque.PopBack and impl.Peek == CircularDeque.Back
	)
	local q = Trait3.ImplOf(Queue, d)
	assert(q.Push == CircularDeque.PushBack and q.Pop == CircularDeque.PopFront and q.Peek == CircularDeque.Front)
	assert(Trait3.ImplOf(Stack, d) == impl, "같은 표")
	assert(Stack.sources[CircularDeque.Token] == false, "저절로 따라옴")
end

-- 2. 의존을 못 갖췄으면: 저절로는 안 따라오고(nil), 등록은 "먼저 구현하라"
do
	local tok = token("NotADeque")
	assert(Trait3.ImplOf(Stack, { __type = tok }) == nil)
	fails(function()
		Trait3.Impl(Stack, tok, { Push = function() end })
	end, "NotADeque must implement Deque first to implement Stack")
	fails(function()
		T.Entry.Push({ __type = tok }, 1)
	end, "Stack: Push needs a Stack")
	-- 함수별 표의 빗나감도 같은 길
	fails(function()
		T.ByFn.Push({ __type = tok }, 1)
	end, "Stack: Push needs a Stack")
end

-- 3. ⭐ 연쇄: 덱(명시) → 스택(저절로) → 스택에 의존하는 트레이트(붙잡음). 스택에 빠른 판을 얹으면 위가 다시 만들어짐
do
	local builderRuns = 0
	local Undo = Trait3.New("Undo", {
		dependencies = { Stack },
		defaults = function(_ops: any, deps: any)
			builderRuns += 1
			local push = deps[Stack].Push -- 만들 때 붙잡음
			return {
				Record = function(self: any, item: any): any
					return push(self, item)
				end,
				Raw = push, -- 함수 자체
			}
		end,
	})
	local tok, fns = fakeDeque("K3")
	local value = { __type = tok }
	local stackImpl = Trait3.ImplOf(Stack, value)
	local undoImpl = Trait3.ImplOf(Undo, value)
	assert(builderRuns == 1)
	assert(undoImpl.Raw == fns.PushBack and undoImpl.Record(value, 1) == "K3.PushBack")
	local hoisted = undoImpl.Record -- 함수를 미리 꺼내 둔 쪽
	local pushOf = Trait3.FnTable(Stack, "Push")
	assert(pushOf[tok] == fns.PushBack)

	local function fastPush(): string
		return "fast"
	end
	Trait3.Impl(Stack, tok, { Push = fastPush })
	-- 스택의 표: 같은 테이블, Push 만 바뀌고 나머지는 다시 덱의 함수
	assert(Trait3.ImplOf(Stack, value) == stackImpl, "같은 테이블을 고침")
	assert(stackImpl.Push == fastPush and stackImpl.Pop == fns.PopBack and stackImpl.Peek == fns.Back)
	assert(Stack.sources[tok] ~= false, "이제 명시 등록")
	-- 위 트레이트: 같은 테이블, 다시 만들어져 새 함수를 붙잡음
	assert(builderRuns == 2, "의존이 바뀌어 다시 불림")
	assert(Trait3.ImplOf(Undo, value) == undoImpl and undoImpl.Raw == fastPush)
	assert(undoImpl.Record(value, 1) == "fast")
	-- 함수별 표도 맞춰짐
	assert(pushOf[tok] == fastPush)
	-- ⚠️ 등록 **전에** 함수를 꺼내 둔 쪽은 낡음(표를 쥔 쪽은 새 것을 봄) — 알려진 대가
	assert(hoisted(value, 1) == "K3.PushBack")
	-- 명시 등록의 재등록은 그대로 에러
	fails(function()
		Trait3.Impl(Stack, tok, { Push = fastPush })
	end, "K3 already implements Stack")
	-- 다른 종류는 건드리지 않음
	assert(Trait3.ImplOf(Stack, CircularDeque.New()).Push == CircularDeque.PushBack)
end

-- 4. 종류 쪽의 "만드는 함수": Impl(trait, token, function(deps) … end) — 의존이 바뀌면 다시 불림
do
	local History = Trait3.New("History", { required = { "Save", "Load" }, dependencies = { Stack } })
	local tok, fns = fakeDeque("K4")
	local runs = 0
	Trait3.Impl(History, tok, function(deps: any)
		runs += 1
		local stack = deps[Stack]
		return { Save = stack.Push, Load = stack.Pop }
	end)
	local impl = Trait3.ImplOf(History, { __type = tok })
	assert(runs == 1 and impl.Save == fns.PushBack and impl.Load == fns.PopBack)
	local function fastPop(): string
		return "fastPop"
	end
	Trait3.Impl(Stack, tok, { Pop = fastPop })
	assert(runs == 2 and impl.Save == fns.PushBack and impl.Load == fastPop)
	-- 만드는 함수가 필수 함수를 빠뜨리면 등록 때 에러
	local tok2 = fakeDeque("K4b")
	fails(function()
		Trait3.Impl(History, tok2, function(deps: any)
			return { Save = deps[Stack].Push }
		end)
	end, "K4b is missing Load for History")
	assert(Trait3.ImplOf(History, { __type = tok2 }) == nil, "실패하면 아무것도 적용되지 않음")
end

-- 5. 마름모: E(명시) → D(저절로) → A·B(저절로) → C(A·B 에 의존). D 를 재정의하면 C 는 끝에 맞는 상태(두 번 다시 만들어짐)
do
	local E = Trait3.New("E", { required = { "Base" } })
	local D = Trait3.New("D", {
		dependencies = { E },
		defaults = function(_ops: any, deps: any)
			return { Core = deps[E].Base }
		end,
	})
	local function passThrough(name: string): any
		return Trait3.New(name, {
			dependencies = { D },
			defaults = function(_ops: any, deps: any)
				return { Get = deps[D].Core }
			end,
		})
	end
	local A, B = passThrough("A"), passThrough("B")
	local cRuns = 0
	local C = Trait3.New("C", {
		dependencies = { A, B },
		defaults = function(_ops: any, deps: any)
			cRuns += 1
			return { Left = deps[A].Get, Right = deps[B].Get }
		end,
	})
	local tok = token("K5")
	local function base(): string
		return "base"
	end
	local function better(): string
		return "better"
	end
	Trait3.Impl(E, tok, { Base = base })
	local value = { __type = tok }
	local c = Trait3.ImplOf(C, value)
	assert(c.Left == base and c.Right == base and cRuns == 1)
	Trait3.Impl(D, tok, { Core = better })
	assert(c.Left == better and c.Right == better, "끝 상태가 맞음")
	assert(cRuns == 3, "A 가 바뀔 때 한 번, B 가 바뀔 때 한 번 — 순서를 안 맞춰 두 번")
end

-- 6. 같은 트레이트 안의 다른 기본 구현: 재정의한 IndexOf 를 Contains 가 씀(`ops.IndexOf or 내것`)
do
	local tok = token("K6")
	local calls = 0
	Trait3.Impl(List, tok, {
		Get = function(self: any, idx: number): any
			return self[idx]
		end,
		FirstIndex = function(self: any): number?
			return if self.n > 0 then 1 else nil
		end,
		LastIndex = function(self: any): number?
			return if self.n > 0 then self.n else nil
		end,
		NextIndex = function(self: any, idx: number): number?
			return if idx < self.n then idx + 1 else nil
		end,
		PrevIndex = function(self: any, idx: number): number?
			return if idx > 1 then idx - 1 else nil
		end,
		IndexOf = function(self: any, item: any): number?
			calls += 1
			return table.find(self, item)
		end,
	})
	local value = { __type = tok, n = 3, "x", "y", "z" }
	local impl = Trait3.ImplOf(List, value)
	assert(impl.Contains(value, "y") == true and impl.Contains(value, "q") == false and calls == 2)
	assert(impl.Fold(value, "", function(acc: string, item: string, idx: number): string
		return acc .. item .. idx
	end) == "x1y2z3")
	-- 모르는 이름·함수 아닌 값은 그대로 에러
	fails(function()
		Trait3.Impl(Deque, token("K6b"), { PushFront = 1 } :: any)
	end, "gave a number as PushFront")
	local tok3, _ = fakeDeque("K6c")
	fails(function()
		Trait3.Impl(Stack, tok3, { Shove = function() end })
	end, "gave Shove to Stack, which Stack does not have")
end

-- 7. 다시 만들다 만드는 함수가 던지면: 그 트레이트의 예전 표는 그대로(시제품의 경계 — 앞선 것은 이미 적용됨)
do
	local explode = false
	local Fragile = Trait3.New("Fragile", {
		dependencies = { Stack },
		defaults = function(_ops: any, deps: any)
			if explode then
				error("boom", 0)
			end
			return { Do = deps[Stack].Push }
		end,
	})
	local tok, fns = fakeDeque("K7")
	local impl = Trait3.ImplOf(Fragile, { __type = tok })
	explode = true
	fails(function()
		Trait3.Impl(Stack, tok, { Push = function() end })
	end, "boom")
	assert(impl.Do == fns.PushBack, "Fragile 의 표는 예전 그대로")
	assert(
		Trait3.ImplOf(Stack, { __type = tok }).Push ~= fns.PushBack,
		"⚠️ Stack 은 이미 바뀜 — 낡은 채 남는 쪽이 생김"
	)
end

-- 8. `src` 의 Stack·Queue·List 와 같은 결과(실제 덱 둘, 무작위)
do
	local seed = 12345
	local function rand(n: number): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed % n + 1
	end
	for _, module: any in { CircularDeque, LinkedDeque } do
		local mine, theirs = module.New(), module.New()
		local sImpl, qImpl, lImpl = Trait3.ImplOf(Stack, mine), Trait3.ImplOf(Queue, mine), Trait3.ImplOf(List, mine)
		for step = 1, 4000 do
			local op = rand(6)
			if op <= 2 then
				T.Entry.Push(mine, step)
				stl.Stack.Push(theirs, step)
			elseif op == 3 then
				assert(T.ByFn.Pop(mine) == stl.Stack.Pop(theirs))
			elseif op == 4 then
				assert(qImpl.Pop(mine) == stl.Queue.Pop(theirs))
			elseif op == 5 then
				assert(sImpl.Peek(mine) == stl.Stack.Peek(theirs) and qImpl.Peek(mine) == stl.Queue.Peek(theirs))
			else
				local probe = step - rand(8)
				assert(lImpl.Contains(mine, probe) == stl.List.Contains(theirs, probe))
				assert((lImpl.IndexOf(mine, probe) ~= nil) == (stl.List.IndexOf(theirs, probe) ~= nil))
				local function add(acc: number, item: number): number
					return acc + item
				end
				assert(T.Entry.Fold(mine, 0, add) == stl.List.Fold(theirs, 0, add))
				assert(T.Inline.Pop(mine) == stl.Stack.Pop(theirs))
			end
			assert(stl.Collection.Len(mine) == stl.Collection.Len(theirs))
		end
	end
end

print("PASS trait-rebuild 시제품 (표 만들기 " .. Trait3.Builds() .. "회)")
return true
