--!strict
-- 시제품 v3 의 동작 확인(v2 의 것 + Of·For). 실행: ( ulimit -v 1048576; timeout 60 luau .claude/research/trait-v3/check.luau )
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

-- 1. 토큰: 이름 유일, 직렬화 뒤 되찾기
fails(function()
	where = debug.info(1, "l") + 1
	Trait.Token("Stl.CircularDeque")
end, "a token named Stl.CircularDeque already exists")
do
	const d = Kinds.tag(stl.CircularDeque.Of(1, 2), Kinds.CD)
	const copy = table.clone(d) :: any
	copy.__type = { name = "Stl.CircularDeque" } -- 복사된 토큰(정체성 없음)
	fails(function()
		where = debug.info(1, "l") + 1
		P.Stack.Push(copy, 3)
	end, "Stl.CircularDeque does not implement Stack (or the value was copied: Trait.Restore it)")
	const nested = { inner = copy, list = { copy } }
	Trait.Restore(nested)
	assert(rawget(copy, "__type") == Kinds.CD, "되찾음")
	P.Stack.Push(copy, 3)
	assert(P.Stack.Pop(copy) == 3)
end

-- 2. 함수 번호는 정렬한 이름 순, 완성 표는 번호와 이름을 둘 다
do
	assert(P.Stack.FnTok.Peek == 1 and P.Stack.FnTok.Pop == 2 and P.Stack.FnTok.Push == 3)
	const full = (P.Stack :: any)[Kinds.CD]
	assert(full.Push == stl.CircularDeque.PushBack and full[3] == full.Push, "덱 함수 그대로, 번호로도")
end

-- 3. 필수와 기본 구현: Default 로 적은 것만 기본 구현이 채움
do
	fails(function()
		where = debug.info(1, "l") + 1
		Trait.Trait("Bad1", { A = Trait.Fn(), B = Trait.Default() }, function()
			return {}
		end)
	end, "Bad1 declares B with Trait.Default but its defaults do not provide it")
	fails(function()
		where = debug.info(1, "l") + 1
		Trait.Trait("Bad2", { A = Trait.Fn() }, function()
			return { A = print }
		end)
	end, "defaults of Bad2 gave A, which Bad2 does not declare with Trait.Default")
	const tok = Trait.Token("Test.NoGet")
	fails(function()
		where = debug.info(1, "l") + 1
		Trait.Impl(P.List):For(tok)({ FirstIndex = print, LastIndex = print, NextIndex = print, PrevIndex = print })
	end, "Test.NoGet is missing Get for List")
	assert(P.List[tok] == nil, "실패한 등록은 남지 않음")
	const withShove = fnsOf({ "PushFront", "PushBack", "PopFront", "PopBack", "Front", "Back", "Shove" }, "x")
	fails(function()
		where = debug.info(1, "l") + 1
		Trait.Impl(P.Deque):For(tok)(withShove)
	end, "Test.NoGet gave Shove to Deque, which Deque does not have")
	fails(function()
		const t = fnsOf(DEQUE6, "x")
		t.Back = 5 :: any
		where = debug.info(1, "l") + 1
		Trait.Impl(P.Deque):For(tok)(t)
	end, "Test.NoGet gave a number as Back for Deque")
	-- 기본 구현은 재정의를 붙잡음(ops.IndexOf or 내것)
	local calls = 0
	const tok2 = Trait.Token("Test.Seq")
	Trait.Impl(P.List):For(tok2)({
		Get = function(s: any, i: number): any
			return s[i]
		end,
		FirstIndex = function(s: any): number?
			return if s.n > 0 then 1 else nil
		end,
		LastIndex = function(s: any): number?
			return if s.n > 0 then s.n else nil
		end,
		NextIndex = function(s: any, i: number): number?
			return if i < s.n then i + 1 else nil
		end,
		PrevIndex = function(s: any, i: number): number?
			return if i > 1 then i - 1 else nil
		end,
		IndexOf = function(s: any, x: any): number?
			calls += 1
			return table.find(s, x)
		end,
	})
	const v: any = { __type = tok2, n = 3, "a", "b", "c" }
	assert(P.List.Contains(v, "b") and not P.List.Contains(v, "z") and calls == 2)
	assert(P.List.Fold(v, "", function(acc: string, x: string, i: number): string
		return acc .. x .. i
	end) == "a1b2c3")
end

-- 4. 뭉텅이 구현(Where): 덱이면 스택·큐가 따라옴 — 나중에 생긴 종류도
do
	const tok = Trait.Token("Test.LateDeque")
	assert(P.Stack[tok] == nil)
	const fns = fnsOf(DEQUE6, "late")
	Trait.Impl(P.Deque):For(tok)(fns)
	assert(P.Stack[tok].Push == fns.PushBack and P.Queue[tok].Pop == fns.PopFront, "의존이 채워질 때 따라옴")
end

-- 5. For 가 뭉텅이를 덮음 + 위로 번짐(Stack 을 Where 로 쓰는 트레이트가 다시 지어짐)
do
	local upperRuns = 0
	const Undo = Trait.Trait("Undo", { Save = Trait.Fn() })
	Trait.Impl(Undo):Where({ P.Stack })(function(deps: any)
		upperRuns += 1
		return { Save = deps[P.Stack].Push }
	end)
	const tok = Trait.Token("Test.Pile")
	const fns = fnsOf(DEQUE6, "pile")
	Trait.Impl(P.Deque):For(tok)(fns)
	const stackFull, undoFull = P.Stack[tok], Undo[tok]
	assert(undoFull.Save == fns.PushBack)
	const before = upperRuns
	const function fast(): string
		return "fast"
	end
	Trait.Impl(P.Stack):For(tok)({ Push = fast, Pop = fns.PopBack, Peek = fns.Back })
	assert(P.Stack[tok] == stackFull and stackFull.Push == fast, "같은 표를 다시 채움")
	assert(Undo[tok] == undoFull and undoFull.Save == fast and upperRuns == before + 1, "위로 번짐")
	fails(function()
		where = debug.info(1, "l") + 1
		Trait.Impl(P.Stack):For(tok)({ Push = fast, Pop = fast, Peek = fast })
	end, "Test.Pile already implements Stack")
	-- Arr 는 덱이 아니어도 For 로 스택
	const a = Kinds.tag(stl.Arr.Of(1, 2), Kinds.ARR)
	P.Stack.Push(a, 3)
	assert(P.Stack.Peek(a) == 3 and P.Stack.Pop(a) == 3 and a.n == 2)
end

-- 6. 뭉텅이 구현이 겹치면 에러(두 Where 가 같은 종류에 맞음) — 등록 때 / 나중에 의존이 채워질 때
do
	const A = Trait.Trait("TA", { X = Trait.Fn() })
	const B = Trait.Trait("TB", { X = Trait.Fn() })
	const Len = Trait.Trait("Len", { Len = Trait.Fn() })
	Trait.Impl(Len):Where({ A })(function()
		return {
			Len = function(): string
				return "viaA"
			end,
		}
	end)
	const both = Trait.Token("Test.Both")
	Trait.Impl(A):For(both)({ X = print })
	Trait.Impl(B):For(both)({ X = print })
	fails(function()
		where = debug.info(1, "l") + 1
		Trait.Impl(Len):Where({ B })(function()
			return { Len = print }
		end)
	end, "two blanket implementations of Len apply to Test.Both")
	-- 같은 상황이라도 그 종류를 For 로 직접 구현해 두면 겹침이 아님(For 가 이김)
	const Len2 = Trait.Trait("Len2", { Len = Trait.Fn() })
	Trait.Impl(Len2):Where({ A })(function()
		return {
			Len = function(): string
				return "viaA"
			end,
		}
	end)
	const function own(): string
		return "own"
	end
	Trait.Impl(Len2):For(both)({ Len = own })
	Trait.Impl(Len2):Where({ B })(function()
		return {
			Len = function(): string
				return "viaB"
			end,
		}
	end)
	assert(Len2[both].Len == own, "For 가 이김")
	-- 나중에 의존이 채워지며 겹치게 되면 그 등록에서 에러
	const later = Trait.Token("Test.Later")
	Trait.Impl(A):For(later)({ X = print })
	assert(Len2[later].Len() == "viaA")
	fails(function()
		where = debug.info(1, "l") + 1
		Trait.Impl(B):For(later)({ X = print })
	end, "two blanket implementations of Len2 apply to Test.Later")
end

-- 7. Of·For — 동적 경로로 완성 표 꺼내기, 없으면 사용자 줄 에러
do
	const d = Kinds.tag(stl.CircularDeque.Of(1, 2), Kinds.CD)
	assert((P.Stack :: any).Of(d).Push == stl.CircularDeque.PushBack, "Of 는 완성 표")
	assert((P.Stack :: any).For(Kinds.ARR).Push == stl.Arr.PushBack, "For 는 토큰으로")
	const plain = Trait.Token("Test.Plain")
	const stack: any = P.Stack
	fails(function()
		where = debug.info(1, "l") + 1
		stack.For(plain)
	end, "Stack: Test.Plain does not implement Stack")
	fails(function()
		where = debug.info(1, "l") + 1
		stack.Of({ __type = plain })
	end, "Stack: Of needs a Stack")
end

print("PASS trait-v3 시제품")
return true
