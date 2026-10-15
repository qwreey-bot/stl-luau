--!strict
--[[
	트레이트 시스템 — 토큰, 정의(필수·기본 구현), 등록(명시·뭉텅이), 미리 짓기와 다시 짓기, 진입점(2026-10-15 들임, 질문 AY).
	정본 설명은 `src/Trait/init.luau` 머리. 설계 시제품의 런타임 시험(`.claude/research/trait-v9/check.luau`)을 src 로 옮기고,
	옛 시스템의 시험 가운데 새 시스템에도 있는 성질(물려받은 구현, 다시 지어도 같은 표, 위로 번짐)을 더했습니다.

	`spec.contracts` 에 두지 않은 것은 그 파일이 타입 검사기의 한도("too complex")에 닿아서입니다.
]]
local stl = require("../src")
const T = stl.Trait

local where = 0
local function fails(fn: () -> (), needle: string, label: string)
	const ok, err = pcall(fn)
	assert(not ok and string.find(tostring(err), needle, 1, true), `{label}: wanted "{needle}", got {err}`)
	assert(string.find(tostring(err), `spec.traitrebuild.luau:{where}:`, 1, true), `{label} 사용자 줄: {err}`)
end
-- 이름들 → 그 이름을 돌려주는 함수들(배선 확인용)
local function fnsOf(names: { string }, tag: string): { [string]: any }
	const t = {}
	for _, n in names do
		t[n] = function()
			return tag .. "." .. n
		end
	end
	return t
end
-- 테스트용 트레이트(타입 없이 — 런타임 시험): 팩토리가 이름 표를 돌려줌
local function factory(fns: { [string]: any }): () -> { [string]: any }
	return function()
		return fns
	end
end
const DEQUE6 = { "PushFront", "PushBack", "PopFront", "PopBack", "Front", "Back" }

print("=== 1. 토큰 — 이름 유일, 직렬화 뒤 되찾기, TokenOf·Stamp ===")
do
	fails(function()
		where = debug.info(1, "l") + 1
		T.NewToken("Stl.Arr")
	end, "a token named Stl.Arr already exists", "같은 이름")
	fails(function()
		where = debug.info(1, "l") + 1
		T.NewToken(5 :: any)
	end, "Trait: NewToken needs a name string, got number", "이름이 아님")
	-- 직렬화로 복사된 값: 토큰 정체성을 잃어 진입점이 모름 → Restore 가 이름으로 되찾음(안쪽 값까지)
	const d = stl.CircularDeque.Of(1, 2)
	const copy = table.clone(d) :: any
	copy.__type = { name = "Stl.CircularDeque" }
	const outer = { inner = copy, self = nil :: any }
	outer.self = outer -- 돌아 물린 테이블도 됨
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Stack.Push(copy, 3)
	end, "got a Stl.CircularDeque this library does not know (deserialized? Trait.Restore it", "복사본")
	assert(T.TokenOf(copy) == nil, "복사본의 토큰은 이 사본의 것이 아님")
	T.Restore(outer)
	assert(T.TokenOf(copy) == stl.CircularDeque.Token, "Restore 가 진짜 토큰으로")
	stl.Stack.Push(copy, 3)
	assert(stl.Stack.Pop(copy) == 3, "되찾은 값은 스택")
	-- 이름이 이 사본에 없는 토큰은 그대로
	const stranger: any = { __type = { name = "Elsewhere.Thing" } }
	T.Restore(stranger)
	assert(stranger.__type.name == "Elsewhere.Thing" and T.TokenOf(stranger) == nil, "모르는 이름은 그대로")
	-- Stamp
	const tok = T.NewToken("Test.Rebuild.Stamped")
	const v = T.Stamp({}, tok)
	assert(T.TokenOf(v) == tok, "Stamp")
	fails(function()
		where = debug.info(1, "l") + 1
		T.Stamp(table.freeze({}), tok)
	end, "Trait: Stamp needs a table that is not frozen", "얼린 표")
	fails(function()
		where = debug.info(1, "l") + 1
		T.Stamp({}, { name = "x" } :: any)
	end, "Trait: Stamp needs a type token (from Trait.NewToken)", "토큰이 아님")
end
print("PASS")

print("=== 2. 정의 — 필수(Fn)·기본 구현(Default), 예약 이름, 함수 번호 ===")
do
	-- 함수 번호는 정렬한 이름 순, 완성 표는 이름과 번호 둘 다
	const stack: any = stl.Stack
	assert(stack.FnTok.Peek == 1 and stack.FnTok.Pop == 2 and stack.FnTok.Push == 3, "함수 번호")
	const full = stack.Of(stl.CircularDeque.Token)
	assert(
		full.Push == stl.CircularDeque.PushBack and full[3] == full.Push,
		"완성 표: 덱 함수 그대로 + 번호 칸"
	)
	fails(function()
		where = debug.info(1, "l") + 1
		T.Trait("Test.Rebuild.BadOf", factory({ Of = T.Fn() }))
	end, "Test.Rebuild.BadOf cannot have a function named Of", "예약 이름 Of")
	fails(function()
		where = debug.info(1, "l") + 1
		T.Trait("Test.Rebuild.BadFor", factory({ ImplFor = T.Fn() }))
	end, "cannot have a function named ImplFor", "예약 이름 ImplFor")
	fails(
		function()
			where = debug.info(1, "l") + 1
			T.Trait("Test.Rebuild.NotMark", factory({ X = print }))
		end,
		"Trait: Test.Rebuild.NotMark needs a factory returning a table of Trait.Fn / Trait.Default",
		"표식이 아닌 칸"
	)
	fails(function()
		where = debug.info(1, "l") + 1
		T.Trait(
			"Test.Rebuild.NoTable",
			function()
				return 5
			end :: any
		)
	end, "needs a factory returning a table", "표를 안 돌려줌")
	fails(function()
		where = debug.info(1, "l") + 1
		T.Trait(5 :: any, factory({}))
	end, "Trait: Trait needs a name string, got number", "이름이 아님")
end
print("PASS")

print("=== 3. 기본 구현 빌더 — 형제(재정의된 것)를 붙잡음, 고리, 함수가 아닌 것 ===")
do
	const Seq = T.Trait(
		"Test.Rebuild.Seq",
		factory({
			Get = T.Fn(),
			Find = T.Default(T.FULL, function(ops: any)
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
			Has = T.Default(T.FULL, function(ops: any)
				const find = ops.Find -- 형제(재정의됐으면 그것) — 짓는 순서와 무관
				return function(s: any, x: any): boolean
					return find(s, x) ~= nil
				end
			end),
		})
	)
	const seq: any = Seq
	const plain = T.NewToken("Test.Rebuild.Plain")
	seq.ImplFor(plain, {
		Get = function(s: any, i: number): any
			return s[i]
		end,
	})
	const v: any = { __type = plain, n = 3, "a", "b", "c" }
	assert(seq.Has(v, "b") and not seq.Has(v, "z"), "기본 구현 둘이 서로를 씀")
	local calls = 0
	const fast = T.NewToken("Test.Rebuild.Fast")
	seq.ImplFor(fast, {
		Get = function(s: any, i: number): any
			return s[i]
		end,
		Find = function(s: any, x: any): number?
			calls += 1
			return table.find(s, x)
		end,
	})
	const w: any = { __type = fast, n = 2, "x", "y" }
	assert(seq.Has(w, "y") and calls == 1, "Has 가 재정의된 Find 를 붙잡음")
	assert(getmetatable(seq.Of(w)) == nil, "완성 표는 평범한 테이블(짓는 동안의 메타테이블을 뗌)")
	-- 고리: 고리를 닫는 빌더 줄을 가리킴
	local loopLine = 0
	const Loop: any = T.Trait(
		"Test.Rebuild.Loop",
		factory({
			A = T.Default(T.FULL, function(ops: any)
				return ops.B
			end),
			B = T.Default(T.FULL, function(ops: any)
				loopLine = debug.info(1, "l") + 1
				return ops.A
			end),
		})
	)
	const okLoop, errLoop = pcall(function()
		Loop.ImplFor(T.NewToken("Test.Rebuild.Loop"), {})
	end)
	assert(
		not okLoop
			and string.find(
				tostring(errLoop),
				"default implementations of Test.Rebuild.Loop need each other while building",
				1,
				true
			),
		`고리: {errLoop}`
	)
	assert(
		string.find(tostring(errLoop), `spec.traitrebuild.luau:{loopLine}:`, 1, true),
		`고리를 닫는 빌더 줄: {errLoop}`
	)
	const NotFn: any = T.Trait(
		"Test.Rebuild.NotFn",
		factory({
			A = T.Default(T.FULL, function(_ops: any)
				return 5
			end),
		})
	)
	fails(
		function()
			where = debug.info(1, "l") + 1
			NotFn.ImplFor(T.NewToken("Test.Rebuild.NotFnTok"), {})
		end,
		"the default implementation of A in Test.Rebuild.NotFn must build a function, got number",
		"함수가 아닌 기본 구현"
	)
end
print("PASS")

print(
	"=== 4. 등록 — 빠짐·모르는 이름·함수가 아닌 값·두 번, 실패하면 아무것도 남지 않음 ==="
)
do
	const tok = T.NewToken("Test.Rebuild.Bad")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.List.ImplFor(tok, { FirstIndex = print, LastIndex = print, NextIndex = print, PrevIndex = print })
	end, "Trait: Test.Rebuild.Bad is missing Get for List", "빠짐")
	fails(
		function()
			where = debug.info(1, "l") + 1
			stl.Deque.ImplFor(
				tok,
				fnsOf({ "PushFront", "PushBack", "PopFront", "PopBack", "Front", "Back", "Shove" }, "x")
			)
		end,
		"Trait: Test.Rebuild.Bad gave Shove to Deque, which Deque does not have — pass a table of only that trait's functions",
		"모르는 이름"
	)
	const notFn = fnsOf(DEQUE6, "x")
	notFn.Back = 5 :: any
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Deque.ImplFor(tok, notFn)
	end, "Trait: Test.Rebuild.Bad gave a number as Back for Deque — it must be a function", "함수가 아닌 값")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Deque.ImplFor(tok, 5 :: any)
	end, "Trait: Deque.ImplFor needs a table of functions, got number", "표가 아님")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Deque.ImplFor({ name = "x" } :: any, fnsOf(DEQUE6, "x"))
	end, "Trait: Deque.ImplFor needs a type token (from Trait.NewToken)", "토큰이 아님")
	-- 실패한 등록은 아무것도 남기지 않음: 그 뒤 제대로 등록할 수 있고, 덱이 아니었으니 스택도 아니었음
	assert(not T.Implements(stl.Stack, T.Stamp({}, tok)), "실패한 등록 뒤 스택도 아님")
	stl.Deque.ImplFor(tok, fnsOf(DEQUE6, "ok"))
	assert((stl.Stack.Of(tok) :: any).Push() == "ok.PushBack", "제대로 등록하면 스택이 따라옴")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Deque.ImplFor(tok, fnsOf(DEQUE6, "again"))
	end, "Trait: Test.Rebuild.Bad already implements Deque", "두 번")
end
print("PASS")

print("=== 5. 물려받은 구현(`__index` 가 테이블인 사슬) — 등록 때 한 번 읽음 ===")
do
	-- 클래스처럼 물려받은 모듈: 필수·재정의를 사슬에서 찾음, 함수가 아닌 것은 에러, 함수 `__index` 는 안 따라감
	const base = fnsOf(DEQUE6, "base")
	const derived = setmetatable({
		Back = function()
			return "derived.Back"
		end,
	}, { __index = base })
	const tok = T.NewToken("Test.Rebuild.Inherit")
	stl.Deque.ImplFor(tok, derived)
	const full: any = stl.Deque.Of(tok)
	assert(full.PushFront() == "base.PushFront" and full.Back() == "derived.Back", "사슬로 물려받음")
	-- 등록 때 읽은 사본: 나중에 넘긴 표를 고쳐도 그대로(다시 지어져도)
	base.PushFront = function()
		return "changed"
	end
	assert((stl.Deque.Of(tok) :: any).PushFront() == "base.PushFront", "넘긴 표를 나중에 고쳐도 그대로")
	-- 물려받은 재정의가 기본 구현의 형제로 보임(옛 시스템 2라운드 리뷰의 시나리오 — 이제 빌더가 짓는 표에서 읽음)
	local found = 0
	const parentList = {
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
		PrevIndex = function(_s: any, i: number): number?
			return if i > 1 then i - 1 else nil
		end,
		IndexOf = function(s: any, x: any): number?
			found += 1
			return table.find(s, x)
		end,
	}
	const listTok = T.NewToken("Test.Rebuild.InheritList")
	stl.List.ImplFor(listTok, setmetatable({}, { __index = parentList }))
	const lv: any = { __type = listTok, n = 3, 10, 20, 30 }
	assert(stl.List.Contains(lv, 20) and found == 1, "기본 구현 Contains 가 물려받은 IndexOf 를 붙잡음")
	-- 물려받은 값이 함수가 아니면 에러
	const badParent = fnsOf(DEQUE6, "p")
	badParent.Front = 7 :: any
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Deque.ImplFor(T.NewToken("Test.Rebuild.InheritBad"), setmetatable({}, { __index = badParent }))
	end, "gave a number as Front for Deque", "물려받은 값이 함수가 아님")
	-- `__index` 가 함수인 표(없는 멤버를 읽으면 던지는 엄격한 모듈)는 자기 키만 봄 — 등록이 됨
	const strict = setmetatable(fnsOf(DEQUE6, "strict"), {
		__index = function(_: any, key: any)
			error(`no member {key}`)
		end,
	})
	stl.Deque.ImplFor(T.NewToken("Test.Rebuild.Strict"), strict)
end
print("PASS")

print(
	"=== 6. 뭉텅이 구현 — 덱이면 스택·큐(나중에 생긴 종류도), 명시가 덮고 위로 번짐, 겹치면 에러 ==="
)
do
	-- 나중에 생긴 덱도 스택·큐
	const late = T.NewToken("Test.Rebuild.LateDeque")
	const lateFns = fnsOf(DEQUE6, "late")
	stl.Deque.ImplFor(late, lateFns)
	assert(
		stl.Stack.Of(late).Push == lateFns.PushBack and stl.Queue.Of(late).Pop == lateFns.PopFront,
		"나중에 생긴 덱"
	)
	-- 사용자 트레이트를 스택 위에 뭉텅이로: 스택이 다시 지어지면 위로 번짐
	local runs = 0
	const Undo: any = T.Trait("Test.Rebuild.Undo", factory({ Save = T.Fn() }))
	Undo.ImplWhere({ stl.Stack }, function(deps: any)
		runs += 1
		return { Save = deps[stl.Stack].Push }
	end)
	const tok = T.NewToken("Test.Rebuild.Pile")
	const fns = fnsOf(DEQUE6, "pile")
	stl.Deque.ImplFor(tok, fns)
	const stackFull, undoFull = stl.Stack.Of(tok), Undo.Of(tok)
	assert(undoFull.Save == fns.PushBack, "덱 → 스택 → Undo")
	const before = runs
	const function fast(): string
		return "fast"
	end
	-- 명시 구현이 뭉텅이를 덮음: 같은 표를 다시 채우고(쥔 쪽이 새 함수를 봄), 그것을 의존으로 쓰는 표도 다시 지음
	stl.Stack.ImplFor(tok, { Push = fast, Pop = fns.PopBack, Peek = fns.Back })
	assert(stl.Stack.Of(tok) == stackFull and stackFull.Push == fast, "같은 표를 다시 채움")
	assert(Undo.Of(tok) == undoFull and undoFull.Save == fast and runs == before + 1, "위로 번짐")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Stack.ImplFor(tok, { Push = fast, Pop = fast, Peek = fast })
	end, "Trait: Test.Rebuild.Pile already implements Stack", "명시 위에 명시")
	-- 뭉텅이끼리 겹치면 에러(그 종류에 명시 구현이 없을 때)
	const TA: any = T.Trait("Test.Rebuild.TA", factory({ X = T.Fn() }))
	const TB: any = T.Trait("Test.Rebuild.TB", factory({ X = T.Fn() }))
	const Len: any = T.Trait("Test.Rebuild.Len", factory({ Len = T.Fn() }))
	Len.ImplWhere({ TA }, function()
		return { Len = print }
	end)
	const both = T.NewToken("Test.Rebuild.Both")
	TA.ImplFor(both, { X = print })
	TB.ImplFor(both, { X = print })
	fails(function()
		where = debug.info(1, "l") + 1
		Len.ImplWhere({ TB }, function()
			return { Len = print }
		end)
	end, "two blanket implementations of Test.Rebuild.Len apply to Test.Rebuild.Both", "겹침")
	-- `{}` 는 모든 종류(기본 구현만 있는 트레이트를 모든 종류에)
	const Named: any = T.Trait(
		"Test.Rebuild.Named",
		factory({
			Describe = T.Default(T.FULL, function(_ops: any)
				return function(v: any): string
					return `kind {(T.TokenOf(v) :: any).name}`
				end
			end),
		})
	)
	Named.ImplWhere({}, function()
		return {}
	end)
	assert(Named.Describe(stl.Arr.Of(1)) == "kind Stl.Arr", "이미 있던 종류")
	const fresh = T.NewToken("Test.Rebuild.Fresh")
	assert(Named.Describe(T.Stamp({}, fresh)) == "kind Test.Rebuild.Fresh", "토큰이 생길 때 지어짐")
	-- 만드는 함수가 표를 안 돌려줌 / 함수가 아님 / 의존 목록이 아님
	const Bad: any = T.Trait("Test.Rebuild.BadWhere", factory({ Y = T.Fn() }))
	fails(function()
		where = debug.info(1, "l") + 1
		Bad.ImplWhere({ stl.Deque }, function()
			return 5
		end)
	end, "the builder given to Test.Rebuild.BadWhere.ImplWhere must return a table, got number", "표를 안 돌려줌")
	fails(function()
		where = debug.info(1, "l") + 1
		Bad.ImplWhere({ stl.Deque }, 5 :: any)
	end, "Test.Rebuild.BadWhere.ImplWhere needs a function that builds the implementation", "함수가 아님")
	fails(
		function()
			where = debug.info(1, "l") + 1
			Bad.ImplWhere({ stl.Deque, 5 } :: any, function()
				return {}
			end)
		end,
		"Trait: Test.Rebuild.BadWhere.ImplWhere needs a trait (from Trait.Trait), got number",
		"의존이 트레이트가 아님"
	)
	fails(function()
		where = debug.info(1, "l") + 1
		Bad.ImplWhere(nil :: any, function()
			return {}
		end)
	end, "Test.Rebuild.BadWhere.ImplWhere needs a list of traits", "목록이 아님")
	-- 실패한 뭉텅이 등록은 아무것도 남기지 않음: 그 뒤 조건(덱)을 채우는 무관한 등록이 멀쩡히 되고, 실패한 트레이트엔 표가 없음
	-- (기록부터 하고 짓던 때는 남은 뭉텅이가 뒤의 덱 등록마다 엉뚱한 줄에서 던졌음 — 이관 중 재현)
	const laterDeque = T.NewToken("Test.Rebuild.AfterBadWhere")
	stl.Deque.ImplFor(laterDeque, fnsOf(DEQUE6, "after"))
	assert(T.ImplOf(Bad, T.Stamp({}, laterDeque)) == nil, "실패한 뭉텅이는 나중 종류에도 안 붙음")
	-- 빠진 필수 함수도 먼저 지어 보다 걸림 — 일부 종류에만 붙은 채 남지 않음
	const Half: any = T.Trait("Test.Rebuild.Half", factory({ P = T.Fn(), Q = T.Fn() }))
	fails(function()
		where = debug.info(1, "l") + 1
		Half.ImplWhere({ stl.Deque }, function()
			return { P = print }
		end)
	end, "is missing Q for Test.Rebuild.Half", "뭉텅이의 빠진 필수 함수")
	assert(T.ImplOf(Half, stl.CircularDeque.Of(1)) == nil, "어느 종류에도 안 붙음")
end
print("PASS")

print("=== 7. 진입점·Of·조회 — 값이나 토큰, 못 찾으면 사용자 줄 에러(셋으로 가름) ===")
do
	const d = stl.CircularDeque.Of(1, 2)
	assert(stl.Stack.Of(d).Push == stl.CircularDeque.PushBack, "값으로 Of")
	const plain = T.NewToken("Test.Rebuild.NoStack")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Stack.Of(plain)
	end, "Stack: Test.Rebuild.NoStack does not implement Stack", "토큰으로 Of — 구현 없음")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Stack.Of({ __type = plain } :: any)
	end, "Stack: Of needs a Stack — Test.Rebuild.NoStack does not implement Stack", "값으로 Of — 구현 없음")
	-- 진입점: 진짜 토큰이면 Restore 를 권하지 않음, 토큰 없음, 테이블이 아님
	const okNo, errNo = pcall(stl.Stack.Push :: any, { __type = plain }, 1)
	assert(not okNo and not string.find(tostring(errNo), "Restore", 1, true), tostring(errNo))
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Stack.Push({} :: any, 1)
	end, "Stack: Push needs a Stack (got table without a type token)", "토큰 없음")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Deque.Front(5 :: any)
	end, "Deque: Front needs a Deque (got number without a type token)", "숫자")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Collection.Len(nil :: any)
	end, "Collection: Len needs a Collection (got nil without a type token)", "nil")
	-- ImplOf·Implements·ExpectImpl
	assert(T.ImplOf(stl.Deque, d) == stl.Deque.Of(d) and T.ImplOf(stl.Deque, stl.Arr.Of(1)) == nil, "ImplOf")
	assert(T.Implements(stl.Queue, d) and not T.Implements(stl.Queue, 5), "Implements")
	fails(function()
		where = debug.info(1, "l") + 1
		T.ImplOf({} :: any, d)
	end, "Trait: ImplOf needs a trait (from Trait.Trait)", "트레이트가 아님")
	fails(function()
		where = debug.info(1, "l") + 1
		T.ExpectImpl(stl.Map, d, "Arr.GroupBy")
	end, "Map: Arr.GroupBy needs a Map — Stl.CircularDeque does not implement Map", "ExpectImpl")
	-- Expose: 트레이트 함수·시스템 이름과 겹치면 에러, 아무것도 얹지 않음
	const E: any = T.Trait("Test.Rebuild.Exposed", factory({ Run = T.Fn() }))
	fails(
		function()
			where = debug.info(1, "l") + 1
			T.Expose(E, { Extra = print, Run = print })
		end,
		"Trait: Expose got an entry named Run, which Test.Rebuild.Exposed already has",
		"트레이트 함수와 겹침"
	)
	assert(rawget(E, "Extra") == nil, "실패하면 아무것도 안 얹음")
	fails(function()
		where = debug.info(1, "l") + 1
		T.Expose(E, { ImplFor = print })
	end, "Expose got an entry named ImplFor", "시스템 이름과 겹침")
	T.Expose(E, { Extra = print })
	assert(E.Extra == print, "얹음")
end
print("PASS")

print()
print("=== ALL PASS (트레이트 시스템) ===")

return true
