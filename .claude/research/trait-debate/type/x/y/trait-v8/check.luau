--!strict
-- 시제품 v8 의 동작 확인. 실행: ( ulimit -v 1048576; timeout 60 luau .claude/research/trait-v8/check.luau ) — -O2 도
local P = require("./Traits")
local stl = require("../../../src")
local Trait: any = P.Trait
local Kinds = P.Kinds
local where = 0
local function fails(fn: () -> (), needle: string)
	const ok, err = pcall(fn)
	assert(not ok and string.find(tostring(err), needle, 1, true), `wanted "{needle}", got {err}`)
	assert(string.find(tostring(err), `check.luau:{where}:`, 1, true), `사용자 줄: {err}`)
end
local function fnsOf(names: { string }, tag: string): { [string]: any }
	const t = {}
	for _, n in names do
		t[n] = function()
			return tag .. "." .. n
		end
	end
	return t
end
const DEQUE6 = { "PushFront", "PushBack", "PopFront", "PopBack", "Front", "Back" }
local function factory(fns: { [string]: any }): () -> { [string]: any }
	return function()
		return fns
	end
end

-- 1. 토큰: 이름 유일, 직렬화 뒤 되찾기
fails(function()
	where = debug.info(1, "l") + 1
	Trait.Token("Stl.Arr")
end, "a token named Stl.Arr already exists")
do
	const d = Kinds.tag(stl.CircularDeque.Of(1, 2), Kinds.CD)
	const copy = table.clone(d) :: any
	copy.__type = { name = "Stl.CircularDeque" }
	const stack: any = P.Stack
	fails(function()
		where = debug.info(1, "l") + 1
		stack.Push(copy, 3)
	end, "the value's type token Stl.CircularDeque is a copy (serialized?): Trait.Restore it")
	Trait.Restore({ inner = copy })
	stack.Push(copy, 3)
	assert(stack.Pop(copy) == 3)
end

-- 2. 함수 번호는 정렬한 이름 순, 완성 표는 덱 함수 그대로(뭉텅이 구현)
do
	const stack: any = P.Stack
	assert(stack.FnTok.Peek == 1 and stack.FnTok.Pop == 2 and stack.FnTok.Push == 3)
	const full = stack.Of(Kinds.CD)
	assert(full.Push == stl.CircularDeque.PushBack and full[3] == full.Push)
end

-- 3. 기본 구현 빌더: 형제를 붙잡음(재정의된 것), 안 적은 칸은 기본 구현, 고리, 함수가 아닌 것
do
	const Seq = Trait.Trait(
		"Seq",
		factory({
			Get = Trait.Fn(),
			Find = Trait.Default("full", function(ops: any)
				const get = ops.Get
				return function(s: any, x: any): number?
					for i = 1, s.n do
						if get(s, i) == x then
							return i
						end
					end
					return nil
				end
			end),
			Has = Trait.Default("full", function(ops: any)
				const find = ops.Find -- 형제(재정의됐으면 그것) — 빌드 순서와 무관
				return function(s: any, x: any): boolean
					return find(s, x) ~= nil
				end
			end),
		})
	)
	const plain = Trait.Token("Test.Plain")
	Seq.ImplFor(plain, {
		Get = function(s: any, i: number): any
			return s[i]
		end,
	})
	const v: any = { __type = plain, n = 3, "a", "b", "c" }
	assert(Seq.Has(v, "b") and not Seq.Has(v, "z"), "기본 구현 둘이 서로를 씀")
	local calls = 0
	const fast = Trait.Token("Test.Fast")
	Seq.ImplFor(fast, {
		Get = function(s: any, i: number): any
			return s[i]
		end,
		Find = function(s: any, x: any): number?
			calls += 1
			return table.find(s, x)
		end,
	})
	const w: any = { __type = fast, n = 2, "x", "y" }
	assert(Seq.Has(w, "y") and calls == 1, "Has 가 재정의된 Find 를 붙잡음")
	assert(getmetatable(Seq.Of(w)) == nil, "완성 표는 평범한 테이블")
	local loopLine = 0
	const Loop = Trait.Trait(
		"Loop",
		factory({
			A = Trait.Default("full", function(ops: any)
				const b = ops.B
				return b
			end),
			B = Trait.Default("full", function(ops: any)
				loopLine = debug.info(1, "l") + 1
				const a = ops.A
				return a
			end),
		})
	)
	-- 고리 에러는 고리를 닫는 빌더 줄을 가리킴(등록 줄이 아니라)
	const okLoop, errLoop = pcall(function()
		Loop.ImplFor(Trait.Token("Test.Loop"), {})
	end)
	assert(
		not okLoop
			and string.find(
				tostring(errLoop),
				"default implementations of Loop need each other while building",
				1,
				true
			)
	)
	assert(string.find(tostring(errLoop), `check.luau:{loopLine}:`, 1, true), `고리를 닫는 빌더 줄: {errLoop}`)
	const NotFn = Trait.Trait(
		"NotFn",
		factory({
			A = Trait.Default("full", function(_ops: any)
				return 5
			end),
		})
	)
	fails(function()
		where = debug.info(1, "l") + 1
		NotFn.ImplFor(Trait.Token("Test.NotFn"), {})
	end, "the default implementation of A in NotFn must build a function, got number")
	-- 등록 검사(런타임): 빠짐·모르는 이름·함수 아닌 값
	const tok = Trait.Token("Test.Bad")
	fails(function()
		where = debug.info(1, "l") + 1
		P.List.ImplFor(tok, { FirstIndex = print, LastIndex = print, NextIndex = print, PrevIndex = print })
	end, "Test.Bad is missing Get for List")
	const extra = fnsOf({ "PushFront", "PushBack", "PopFront", "PopBack", "Front", "Back", "Shove" }, "x")
	fails(function()
		where = debug.info(1, "l") + 1
		P.Deque.ImplFor(tok, extra)
	end, "Test.Bad gave Shove to Deque")
	const notFn = fnsOf(DEQUE6, "x")
	notFn.Back = 5 :: any
	fails(function()
		where = debug.info(1, "l") + 1
		P.Deque.ImplFor(tok, notFn)
	end, "Test.Bad gave a number as Back for Deque")
	fails(function()
		where = debug.info(1, "l") + 1
		Trait.Trait("Bad", factory({ Of = Trait.Fn() }))
	end, "Bad cannot have a function named Of")
	fails(function()
		where = debug.info(1, "l") + 1
		Trait.Trait("Bad2", factory({ ImplFor = Trait.Fn() }))
	end, "Bad2 cannot have a function named ImplFor")
end

-- 4. 뭉텅이 구현: 덱이면 스택·큐 — 나중에 생긴 종류도
do
	const tok = Trait.Token("Test.LateDeque")
	const fns = fnsOf(DEQUE6, "late")
	P.Deque.ImplFor(tok, fns)
	assert((P.Stack :: any).Of(tok).Push == fns.PushBack and (P.Queue :: any).Of(tok).Pop == fns.PopFront)
end

-- 5. For 가 뭉텅이를 덮고 위로 번짐
do
	local runs = 0
	const Undo = Trait.Trait("Undo", factory({ Save = Trait.Fn() }))
	Undo.ImplWhere({ P.Stack }, function(deps: any)
		runs += 1
		return { Save = deps[P.Stack].Push }
	end)
	const tok = Trait.Token("Test.Pile")
	const fns = fnsOf(DEQUE6, "pile")
	P.Deque.ImplFor(tok, fns)
	const stackFull, undoFull = (P.Stack :: any).Of(tok), Undo.Of(tok)
	assert(undoFull.Save == fns.PushBack)
	const before = runs
	const function fast(): string
		return "fast"
	end
	P.Stack.ImplFor(tok, { Push = fast, Pop = fns.PopBack, Peek = fns.Back })
	assert((P.Stack :: any).Of(tok) == stackFull and stackFull.Push == fast, "같은 표를 다시 채움")
	assert(Undo.Of(tok) == undoFull and undoFull.Save == fast and runs == before + 1, "위로 번짐")
	fails(function()
		where = debug.info(1, "l") + 1
		P.Stack.ImplFor(tok, { Push = fast, Pop = fast, Peek = fast })
	end, "Test.Pile already implements Stack")
end

-- 6. 뭉텅이 구현끼리 겹치면 에러
do
	const TA = Trait.Trait("TA", factory({ X = Trait.Fn() }))
	const TB = Trait.Trait("TB", factory({ X = Trait.Fn() }))
	const Len = Trait.Trait("Len", factory({ Len = Trait.Fn() }))
	Len.ImplWhere({ TA }, function()
		return { Len = print }
	end)
	const both = Trait.Token("Test.Both")
	TA.ImplFor(both, { X = print })
	TB.ImplFor(both, { X = print })
	fails(function()
		where = debug.info(1, "l") + 1
		Len.ImplWhere({ TB }, function()
			return { Len = print }
		end)
	end, "two blanket implementations of Len apply to Test.Both")
end

-- 7. Of — 값·토큰, 없으면 사용자 줄 에러
do
	const stack: any = P.Stack
	const d = Kinds.tag(stl.CircularDeque.Of(1, 2), Kinds.CD)
	assert(stack.Of(d).Push == stl.CircularDeque.PushBack and stack.Of(Kinds.ARR).Push == stl.Arr.PushBack)
	const plain = Trait.Token("Test.NoStack")
	fails(function()
		where = debug.info(1, "l") + 1
		stack.Of(plain)
	end, "Stack: Test.NoStack does not implement Stack")
	fails(function()
		where = debug.info(1, "l") + 1
		stack.Of({ __type = plain })
	end, "Stack: Of needs a Stack — Test.NoStack does not implement Stack")
	-- 진짜 토큰인데 구현이 없으면 Restore 를 권하지 않음(v4 는 늘 붙여 오해를 부름)
	const okNo, errNo = pcall(stack.Push, { __type = plain }, 1)
	assert(not okNo and not string.find(tostring(errNo), "Restore", 1, true), tostring(errNo))
	-- Arr 스택(덱이 아니어도), Into
	const a = Kinds.tag(stl.Arr.Of(1, 2), Kinds.ARR)
	stack.Push(a, 3)
	assert(P.Into.ArrStack(a).Peek(a) == 3 and stack.Pop(a) == 3 and a.n == 2)
end

print("PASS trait-v8 시제품")
return true
