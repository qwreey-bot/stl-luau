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
	assert(T.TokenOf(copy) == stl.Trait.TokenOf(stl.CircularDeque), "Restore 가 진짜 토큰으로")
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
	const full = stack.Of(stl.Trait.TokenOf(stl.CircularDeque))
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
		"Trait: Test.Rebuild.NotMark needs a definition function returning a table of Trait.Fn / Trait.Default",
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
	end, "needs a definition function returning a table", "표를 안 돌려줌")
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
			Find = T.Default(function(ops: any)
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
			Has = T.Default(function(ops: any)
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
			A = T.Default(function(ops: any)
				return ops.B
			end),
			B = T.Default(function(ops: any)
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
			A = T.Default(function(_ops: any)
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
		stl.Stack.OfMut(late).Push == lateFns.PushBack and stl.Queue.OfMut(late).Pop == lateFns.PopFront,
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
	const stackFull, undoFull = stl.Stack.OfMut(tok), Undo.Of(tok)
	assert(undoFull.Save == fns.PushBack, "덱 → 스택 → Undo")
	const before = runs
	const function fast(): string
		return "fast"
	end
	-- 명시 구현이 뭉텅이를 덮음: 같은 표를 다시 채우고(쥔 쪽이 새 함수를 봄), 그것을 의존으로 쓰는 표도 다시 지음
	stl.Stack.ImplFor(tok, { Push = fast, Pop = fns.PopBack, Peek = fns.Back })
	assert(stl.Stack.OfMut(tok) == stackFull and stackFull.Push == fast, "같은 표를 다시 채움")
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
	-- `Trait.Any` 는 모든 종류(기본 구현만 있는 트레이트를 모든 종류에)
	const Named: any = T.Trait(
		"Test.Rebuild.Named",
		factory({
			Describe = T.Default(function(_ops: any)
				return function(v: any): string
					return `kind {(T.TokenOf(v) :: any).name}`
				end
			end),
		})
	)
	Named.ImplWhere(T.Any, function()
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
	end, "Test.Rebuild.BadWhere.ImplWhere needs a non-empty list of traits", "목록이 아님")
	-- 빈 목록과 오타(= `{ nil }`, 길이 0)는 에러 — "모든 종류" 는 `Trait.Any` 로만(2026-10-15 사용자: 런타임 검사로)
	fails(
		function()
			where = debug.info(1, "l") + 1
			Bad.ImplWhere({}, function()
				return {}
			end)
		end,
		"Trait: Test.Rebuild.BadWhere.ImplWhere needs a non-empty list of traits (a misspelled trait name reads as nil) — use Trait.Any for every kind",
		"빈 목록"
	)
	const traitsByName = { Deque = stl.Deque } :: any
	fails(function()
		where = debug.info(1, "l") + 1
		Bad.ImplWhere({ traitsByName.Dequ }, function()
			return {}
		end)
	end, "use Trait.Any for every kind", "의존 이름의 오타")
	assert(not T.Implements(Bad, stl.HashMap.New()), "오타 난 뭉텅이는 모든 종류에 붙지 않음")
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
	assert(stl.Stack.OfMut(stl.Deque.AsStack(d)).Push == stl.CircularDeque.PushBack, "값으로 Of")
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
	-- `Trait.Impls`: 완성 표가 든 표(키는 토큰뿐), 트레이트가 아니면 에러
	assert(T.Impls(stl.Deque)[stl.Trait.TokenOf(stl.CircularDeque)] == stl.Deque.Of(d), "Impls")
	fails(function()
		where = debug.info(1, "l") + 1
		T.Impls({} :: any)
	end, "Trait: Impls needs a trait (from Trait.Trait)", "Impls 에 트레이트가 아님")
end
print("PASS")

print(
	"=== 8. 리뷰 1라운드(2026-10-15) — 문자열 __type, 의존 고리, 깊은 Restore, 겹침·사본·준 쪽 ==="
)
do
	-- (1) 문자열 `__type` 이 트레이트 객체의 필드 이름과 같아도 "토큰 없음"(예전엔 진입점 함수를 완성 표로 읽어 라이브러리 줄 에러)
	const bad = { __type = "Get" } :: any
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Map.Keys(bad)
	end, "Map: Keys needs a Map (got table without a type token)", "__type = Get 의 Keys")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Map.Of(bad)
	end, "Map: Of needs a Map (got table without a type token)", "__type = Get 의 Of")
	fails(function()
		where = debug.info(1, "l") + 1
		(stl.Map :: any).Get(bad, 1)
	end, "Map: Get needs a Map (got table without a type token)", "__type = Get 의 진입점")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Arr.GroupBy(stl.Arr.Of(1), tostring, bad)
	end, "Map: Arr.GroupBy needs a Map (got table without a type token)", "__type = Get 인 목적지")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Collection.Len({ __type = "Len" } :: any)
	end, "Collection: Len needs a Collection (got table without a type token)", "__type = Len")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Map.Values({ __type = "FnTok" } :: any)
	end, "Map: Values needs a Map (got table without a type token)", "__type = FnTok")
	assert(not T.Implements(stl.Map, bad) and T.ImplOf(stl.Map, bad) == nil, "Implements·ImplOf")
	fails(function()
		where = debug.info(1, "l") + 1
		T.ExpectImpl(stl.Map, { __type = "ImplFor" }, "Test.Rebuild.Expect")
	end, "Map: Test.Rebuild.Expect needs a Map (got table without a type token)", "__type = ImplFor 의 ExpectImpl")

	-- (2) 뭉텅이 의존의 고리는 등록 줄 에러(예전엔 다음 명시 등록에서 stack overflow, 반쯤 반영된 채)
	const LibA: any = T.Trait("Test.Rebuild.CycleA", factory({ Size = T.Fn() }))
	const LibB: any = T.Trait("Test.Rebuild.CycleB", factory({ Count = T.Fn() }))
	LibB.ImplWhere({ LibA }, function(deps: any)
		return { Count = deps[LibA].Size }
	end)
	fails(
		function()
			where = debug.info(1, "l") + 1
			LibA.ImplWhere({ LibB }, function(deps: any)
				return { Size = deps[LibB].Count }
			end)
		end,
		"Trait: Test.Rebuild.CycleA.ImplWhere on Test.Rebuild.CycleB makes a cycle — Test.Rebuild.CycleB already comes from Test.Rebuild.CycleA",
		"서로 의존"
	)
	const cyc = T.NewToken("Test.Rebuild.CycleKind")
	LibA.ImplFor(cyc, {
		Size = function()
			return 3
		end,
	})
	assert(LibB.Count(T.Stamp({}, cyc)) == 3, "거절된 뭉텅이는 남지 않음 — B 는 A 에서 따라옴")
	-- 세 단계 고리(C ← B ← A 인데 A 가 C 에 기대려 함)
	const LibC: any = T.Trait("Test.Rebuild.CycleC", factory({ Total = T.Fn() }))
	LibC.ImplWhere({ LibB }, function(deps: any)
		return { Total = deps[LibB].Count }
	end)
	fails(function()
		where = debug.info(1, "l") + 1
		LibA.ImplWhere({ LibC }, function(deps: any)
			return { Size = deps[LibC].Total }
		end)
	end, "Trait: Test.Rebuild.CycleA.ImplWhere on Test.Rebuild.CycleC makes a cycle", "세 단계 고리")
	-- 자기 자신
	const Self: any = T.Trait("Test.Rebuild.SelfDep", factory({ Run = T.Fn() }))
	fails(function()
		where = debug.info(1, "l") + 1
		Self.ImplWhere({ Self }, function(deps: any)
			return { Run = deps[Self].Run }
		end)
	end, "Trait: Test.Rebuild.SelfDep.ImplWhere cannot depend on Test.Rebuild.SelfDep itself", "자기 자신")
	Self.ImplFor(T.NewToken("Test.Rebuild.SelfKind"), { Run = print })

	-- (3) Restore 는 깊은 사슬도(예전엔 재귀라 5만 단계에서 stack overflow)
	const head = { __type = { name = "Stl.Arr" }, n = 0 } :: any
	local tail = head
	for _ = 1, 200000 do
		const node = { __type = { name = "Stl.Arr" }, n = 0, next = nil :: any }
		tail.next = node
		tail = node
	end
	T.Restore(head)
	assert(
		T.TokenOf(head) == stl.Trait.TokenOf(stl.Arr) and T.TokenOf(tail) == stl.Trait.TokenOf(stl.Arr),
		"깊은 사슬의 끝까지 되찾음"
	)
	-- 얼린 표는 건드리지 않음(에러 없이), 그 안은 그대로 걸음
	const frozenInner = { __type = { name = "Stl.Arr" }, n = 0 }
	const frozen = table.freeze({ __type = { name = "Stl.Arr" }, n = 0, inner = frozenInner }) :: any
	T.Restore({ frozen })
	assert(
		T.TokenOf(frozen) == nil and T.TokenOf(frozenInner) == stl.Trait.TokenOf(stl.Arr),
		"얼린 표는 건너뛰고 안쪽은 되찾음"
	)

	-- (4) 겹침이 **의존 등록 뒤에** 생김: 뭉텅이 둘을 먼저 걸고, 종류가 두 의존을 차례로 얻음
	const Z: any = T.Trait("Test.Rebuild.LateOverlap", factory({ Get = T.Fn() }))
	const W1: any = T.Trait("Test.Rebuild.LateW1", factory({ A = T.Fn() }))
	const W2: any = T.Trait("Test.Rebuild.LateW2", factory({ B = T.Fn() }))
	Z.ImplWhere({ W1 }, function(deps: any)
		return { Get = deps[W1].A }
	end)
	Z.ImplWhere({ W2 }, function(deps: any)
		return { Get = deps[W2].B }
	end)
	const both = T.NewToken("Test.Rebuild.LateBoth")
	W1.ImplFor(both, { A = print })
	fails(
		function()
			where = debug.info(1, "l") + 1
			W2.ImplFor(both, { B = print })
		end,
		"Trait: two blanket implementations of Test.Rebuild.LateOverlap apply to Test.Rebuild.LateBoth",
		"늦게 생긴 겹침"
	)
	-- 겹치는 뭉텅이 등록이 실패하면 아무것도 남지 않음 — 다른 종류(한쪽 의존만)에 그대로
	const Z2: any = T.Trait("Test.Rebuild.Overlap2", factory({ Get = T.Fn() }))
	const V1: any = T.Trait("Test.Rebuild.Overlap2V1", factory({ A = T.Fn() }))
	const V2: any = T.Trait("Test.Rebuild.Overlap2V2", factory({ B = T.Fn() }))
	Z2.ImplWhere({ V1 }, function(deps: any)
		return { Get = deps[V1].A }
	end)
	const both2 = T.NewToken("Test.Rebuild.Overlap2Both")
	V1.ImplFor(both2, { A = print })
	V2.ImplFor(both2, { B = print })
	fails(function()
		where = debug.info(1, "l") + 1
		Z2.ImplWhere({ V2 }, function(deps: any)
			return { Get = deps[V2].B }
		end)
	end, "Trait: two blanket implementations of Test.Rebuild.Overlap2 apply to", "겹치는 뭉텅이")
	const only2 = T.NewToken("Test.Rebuild.Overlap2Only")
	V2.ImplFor(only2, { B = print })
	assert(not T.Implements(Z2, T.Stamp({}, only2)), "거절된 뭉텅이는 남지 않음")
	-- 메시지가 권하는 길: 겹치는 종류에 명시 구현을 주면 두 번째 뭉텅이를 걸 수 있음
	const Z3: any = T.Trait("Test.Rebuild.Overlap3", factory({ Get = T.Fn() }))
	const U1: any = T.Trait("Test.Rebuild.Overlap3U1", factory({ A = T.Fn() }))
	const U2: any = T.Trait("Test.Rebuild.Overlap3U2", factory({ B = T.Fn() }))
	const both3 = T.NewToken("Test.Rebuild.Overlap3Both")
	U1.ImplFor(both3, { A = print })
	U2.ImplFor(both3, { B = print })
	Z3.ImplFor(both3, {
		Get = function()
			return "own"
		end,
	})
	Z3.ImplWhere({ U1 }, function(deps: any)
		return { Get = deps[U1].A }
	end)
	Z3.ImplWhere({ U2 }, function(deps: any)
		return { Get = deps[U2].B }
	end)
	assert(Z3.Get(T.Stamp({}, both3)) == "own", "명시 구현이 겹침을 풂")

	-- (5) 다시 지을 때는 넘긴 표의 **사본**(물려받은 함수 포함) — 넘긴 뒤 고친 표는 무시
	const base = {
		Push = function(s: any)
			return s
		end,
		Pop = function()
			return "base"
		end,
		Peek = print,
	}
	const inheritTok = T.NewToken("Test.Rebuild.InheritRebuild")
	const given = setmetatable({}, { __index = base }) :: any
	stl.Stack.ImplFor(inheritTok, given)
	given.Pop = 5
	stl.Deque.ImplFor(inheritTok, fnsOf(DEQUE6, "D")) -- 덱이 됨 → 스택의 표를 다시 지음(명시 사본으로)
	assert(stl.Stack.Pop(T.Stamp({}, inheritTok) :: any) == "base", "다시 지어도 사본의 물려받은 함수")

	-- (6) 칸이 Fn/Default 가 아닌 정의(맨 표)
	fails(
		function()
			where = debug.info(1, "l") + 1
			T.Trait("Test.Rebuild.PlainSlot", factory({ Len = T.Fn(), Sub = {} }))
		end,
		"Trait: Test.Rebuild.PlainSlot needs a definition function returning a table of Trait.Fn / Trait.Default",
		"맨 표 칸"
	)

	-- (7) 뭉텅이 구현이 준 표의 잘못은 "뭉텅이" 를 탓함(종류가 아니라)
	const Y: any = T.Trait("Test.Rebuild.BlanketGiver", factory({ Run = T.Fn() }))
	fails(
		function()
			where = debug.info(1, "l") + 1
			Y.ImplWhere({ stl.Map }, function(deps: any)
				return { Run = deps[stl.Map].Get, Extra = print }
			end)
		end,
		"Trait: a blanket implementation of Test.Rebuild.BlanketGiver (ImplWhere) for Stl.HashMap gave Extra",
		"뭉텅이가 모르는 이름"
	)
	fails(
		function()
			where = debug.info(1, "l") + 1
			Y.ImplWhere({ stl.Map }, function(_deps: any)
				return {}
			end)
		end,
		"Trait: a blanket implementation of Test.Rebuild.BlanketGiver (ImplWhere) for Stl.HashMap is missing Run",
		"뭉텅이가 빠뜨림"
	)
	fails(
		function()
			where = debug.info(1, "l") + 1
			Y.ImplWhere({ stl.Map }, function(_deps: any)
				return { Run = 5 }
			end)
		end,
		"Trait: a blanket implementation of Test.Rebuild.BlanketGiver (ImplWhere) for Stl.HashMap gave a number as Run",
		"뭉텅이가 함수 아닌 값"
	)
	-- 명시 구현은 그대로 종류를 댐
	fails(function()
		where = debug.info(1, "l") + 1
		Y.ImplFor(T.NewToken("Test.Rebuild.GiverKind"), { Run = print, Extra = print })
	end, "Trait: Test.Rebuild.GiverKind gave Extra to Test.Rebuild.BlanketGiver", "명시 구현이 모르는 이름")
	-- 뭉텅이를 걸 때 조건을 갖춘 종류가 없으면, 그 잘못은 **나중의 다시 짓기**(첫 종류의 등록 줄)에서 드러남 — 그때도 뭉텅이를 탓함(2라운드)
	const LateSrc: any = T.Trait("Test.Rebuild.LateSrc", factory({ A = T.Fn() }))
	const LateDst: any = T.Trait("Test.Rebuild.LateDst", factory({ Run = T.Fn(), Stop = T.Fn() }))
	LateDst.ImplWhere({ LateSrc }, function(deps: any)
		return { Run = deps[LateSrc].A }
	end)
	fails(
		function()
			where = debug.info(1, "l") + 1
			LateSrc.ImplFor(T.NewToken("Test.Rebuild.LateKind"), { A = print })
		end,
		"Trait: a blanket implementation of Test.Rebuild.LateDst (ImplWhere) for Test.Rebuild.LateKind is missing Stop",
		"다시 짓기에서 드러난 빠뜨림"
	)

	-- (8) 고리 검사의 갈래(2라운드): 의존 목록의 둘째, 의존 트레이트의 둘째 뭉텅이, 한 뭉텅이의 둘째 의존 — 그리고 다이아몬드는 고리가 아님
	const bA: any = T.Trait("Test.Rebuild.CycleB.A", factory({ A = T.Fn() }))
	const bB: any = T.Trait("Test.Rebuild.CycleB.B", factory({ B = T.Fn() }))
	const bX: any = T.Trait("Test.Rebuild.CycleB.X", factory({ X = T.Fn() }))
	bB.ImplWhere({ bA }, function(deps: any)
		return { B = deps[bA].A }
	end)
	fails(function()
		where = debug.info(1, "l") + 1
		bA.ImplWhere({ bX, bB }, function(deps: any)
			return { A = deps[bX].X }
		end)
	end, "Trait: Test.Rebuild.CycleB.A.ImplWhere on Test.Rebuild.CycleB.B makes a cycle", "의존 목록의 둘째")
	const cA: any = T.Trait("Test.Rebuild.CycleC.A", factory({ A = T.Fn() }))
	const cE: any = T.Trait("Test.Rebuild.CycleC.E", factory({ E = T.Fn() }))
	const cY: any = T.Trait("Test.Rebuild.CycleC.Y", factory({ Y = T.Fn() }))
	cE.ImplWhere({ cY }, function(deps: any)
		return { E = deps[cY].Y }
	end)
	cE.ImplWhere({ cA }, function(deps: any)
		return { E = deps[cA].A }
	end)
	fails(
		function()
			where = debug.info(1, "l") + 1
			cA.ImplWhere({ cE }, function(deps: any)
				return { A = deps[cE].E }
			end)
		end,
		"Trait: Test.Rebuild.CycleC.A.ImplWhere on Test.Rebuild.CycleC.E makes a cycle",
		"의존 트레이트의 둘째 뭉텅이"
	)
	const dA: any = T.Trait("Test.Rebuild.CycleD.A", factory({ A = T.Fn() }))
	const dE: any = T.Trait("Test.Rebuild.CycleD.E", factory({ E = T.Fn() }))
	const dY: any = T.Trait("Test.Rebuild.CycleD.Y", factory({ Y = T.Fn() }))
	dE.ImplWhere({ dY, dA }, function(deps: any)
		return { E = deps[dA].A }
	end)
	fails(function()
		where = debug.info(1, "l") + 1
		dA.ImplWhere({ dE }, function(deps: any)
			return { A = deps[dE].E }
		end)
	end, "Trait: Test.Rebuild.CycleD.A.ImplWhere on Test.Rebuild.CycleD.E makes a cycle", "뭉텅이의 둘째 의존")
	-- 다이아몬드: 스택이면서 큐인 것(둘 다 덱에서 따라옴) — 고리가 아님
	const Both: any = T.Trait("Test.Rebuild.StackQueue", factory({ Size = T.Fn() }))
	Both.ImplWhere({ stl.Stack, stl.Queue }, function(_deps: any)
		return {
			Size = function(x: any)
				return stl.Collection.Len(x)
			end,
		}
	end)
	assert(Both.Size(stl.CircularDeque.Of(1, 2, 3)) == 3, "다이아몬드")

	-- (9) Restore 는 토큰 없는 중간 표(HashMap 의 data, 연결 노드)를 지나 안쪽 값까지(2라운드), 걷기는 raw(`__iter` 를 부르지 않음)
	const m = stl.HashMap.New()
	stl.HashMap.Set(m, "k", stl.Arr.Of(10, 20))
	const mapCopy = { __type = { name = "Stl.HashMap" }, size = 1, data = { k = table.clone(m.data.k) :: any } } :: any
	mapCopy.data.k.__type = { name = "Stl.Arr" }
	T.Restore(mapCopy)
	assert(
		T.TokenOf(mapCopy) == stl.Trait.TokenOf(stl.HashMap) and T.TokenOf(mapCopy.data.k) == stl.Trait.TokenOf(stl.Arr),
		"맵 안의 data 를 지나 안쪽 Arr 까지"
	)
	const hidden = { __type = { name = "Stl.Arr" }, n = 0 }
	local iterCalls = 0
	const withIter = setmetatable({ inner = hidden }, {
		__iter = function(_t: any)
			iterCalls += 1
			return next, {}
		end,
	}) :: any
	T.Restore(withIter)
	assert(
		iterCalls == 0 and T.TokenOf(hidden) == stl.Trait.TokenOf(stl.Arr),
		"raw 로 걸음(__iter 를 안 부르고 숨긴 자식까지)"
	)

	-- (10) 진입점은 값 **자신의** `__type` 만 — 메타테이블로 물려받은 토큰은 종류가 아님(TokenOf 와 같게, 2라운드)
	const proto = { __type = stl.Trait.TokenOf(stl.CircularDeque) } :: any
	proto.__index = proto
	const obj = setmetatable({}, proto) :: any
	assert(T.TokenOf(obj) == nil, "TokenOf 는 raw")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Stack.Push(obj, 1)
	end, "Stack: Push needs a Stack (got table without a type token)", "물려받은 __type 의 진입점")

	-- (11) `Trait.Impls` 는 살아 있는 표 — 나중의 등록이 같은 표에 들어옴(`Map.luau` 가 로드 때 붙잡아 둠)
	const liveImpls = T.Impls(stl.Collection)
	const liveTok = T.NewToken("Test.Rebuild.LiveImpls")
	stl.Collection.ImplFor(liveTok, {
		Len = function()
			return 0
		end,
		Clear = function(c: any)
			return c
		end,
	})
	assert(T.Impls(stl.Collection) == liveImpls and liveImpls[liveTok] ~= nil, "살아 있는 표")

	-- (12) Any 뭉텅이와 다른 뭉텅이는 같은 트레이트에 함께 못 둠 — 어느 순서든 등록 줄 에러, 아무것도 남지 않음(3라운드: 예전엔 조건을
	-- 갖춘 첫 종류가 생길 때 무관한 줄에서 겹침이 났고, Any 의 번짐에서 드러나면 그 뒤 모든 NewToken 이 던졌음)
	const Printable: any = T.Trait("Test.Rebuild.Printable", factory({ Text = T.Fn() }))
	const ShowA: any = T.Trait("Test.Rebuild.ShowA", factory({ Show = T.Fn() }))
	ShowA.ImplWhere(T.Any, function(_deps: any)
		return {
			Show = function()
				return "default"
			end,
		}
	end)
	fails(
		function()
			where = debug.info(1, "l") + 1
			ShowA.ImplWhere({ Printable }, function(deps: any)
				return { Show = deps[Printable].Text }
			end)
		end,
		"Trait: Test.Rebuild.ShowA already has a blanket implementation for every kind (Trait.Any) — another ImplWhere would overlap it",
		"Any 뒤의 뭉텅이"
	)
	const doc = T.NewToken("Test.Rebuild.Doc")
	Printable.ImplFor(doc, {
		Text = function()
			return "printable"
		end,
	})
	assert(
		ShowA.Show(T.Stamp({}, doc)) == "default",
		"거절된 뭉텅이는 남지 않음 — 나중의 등록이 멀쩡함"
	)
	const ShowB: any = T.Trait("Test.Rebuild.ShowB", factory({ Show = T.Fn() }))
	ShowB.ImplWhere({ Printable }, function(deps: any)
		return { Show = deps[Printable].Text }
	end)
	fails(
		function()
			where = debug.info(1, "l") + 1
			ShowB.ImplWhere(T.Any, function(_deps: any)
				return { Show = print }
			end)
		end,
		"Trait: Test.Rebuild.ShowB.ImplWhere(Trait.Any) would overlap the blanket implementations Test.Rebuild.ShowB already has",
		"뭉텅이 뒤의 Any"
	)
	T.NewToken("Test.Rebuild.AfterAny") -- 거절된 Any 는 남지 않음 — 새 토큰이 던지지 않음
	assert(
		not T.Implements(ShowB, stl.HashMap.New()) and ShowB.Show(T.Stamp({}, doc)) == "printable",
		"Any 가 남지 않음"
	)

	-- (13) 등록은 묶음 — 던지면 그동안 바꾼 것(놓은 표·기록·토큰)을 전부 되돌림(리뷰 2~4라운드: 위로 번지는 다시 짓기에서 던지면 계기가 된
	-- 등록이 남아, 그 뒤 무관한 NewToken 마다 던지기도 했음). 에러 줄은 여전히 사용자 줄.
	-- (a) 번지는 다시 짓기의 실패: 계기가 된 명시 등록은 남지 않고, 놓였던 표는 **같은 테이블**에 옛 내용으로
	const TxQ: any = T.Trait("Test.Rebuild.TxQ", factory({ Get = T.Fn() }))
	const TxP: any = T.Trait("Test.Rebuild.TxP", factory({ Name = T.Fn() }))
	const TxX: any = T.Trait("Test.Rebuild.TxX", factory({ Run = T.Fn() }))
	local function blanketName()
		return "blanket"
	end
	TxP.ImplWhere({ TxQ }, function(_deps: any)
		return { Name = blanketName }
	end)
	TxX.ImplWhere({ TxP }, function(deps: any)
		const name = deps[TxP].Name
		return if name == blanketName then { Run = name } else {} -- 명시 구현의 이름이면 Run 을 빠뜨림(번지다 실패)
	end)
	const txKind = T.NewToken("Test.Rebuild.TxKind")
	TxQ.ImplFor(txKind, { Get = print })
	const held = TxP.Of(txKind)
	for _ = 1, 2 do -- 두 번째도 같은 에러(첫 실패가 "already implements" 를 남기지 않음)
		fails(
			function()
				where = debug.info(1, "l") + 1
				TxP.ImplFor(txKind, {
					Name = function()
						return "explicit"
					end,
				})
			end,
			"Trait: a blanket implementation of Test.Rebuild.TxX (ImplWhere) for Test.Rebuild.TxKind is missing Run",
			"번지다 실패"
		)
	end
	assert(TxP.Of(txKind) == held and held.Name == blanketName, "놓였던 표가 같은 테이블에 옛 내용으로")
	assert(
		TxP.Name(T.Stamp({}, txKind)) == "blanket" and TxX.Run(T.Stamp({}, txKind)) == "blanket",
		"진입점도 옛 구현"
	)
	-- (b) 간접 Any(4라운드): 목록 뭉텅이 둘 → 한쪽 의존에 Any 를 걸다 위에서 겹침 — Any 가 남지 않아 그 뒤 NewToken 이 멀쩡함
	const IA: any = T.Trait("Test.Rebuild.IndirectA", factory({ A = T.Fn() }))
	const IB: any = T.Trait("Test.Rebuild.IndirectB", factory({ B = T.Fn() }))
	const IShow: any = T.Trait("Test.Rebuild.IndirectShow", factory({ Show = T.Fn() }))
	IA.ImplWhere(T.Any, function(_deps: any)
		return { A = print }
	end)
	IShow.ImplWhere({ IA }, function(deps: any)
		return { Show = deps[IA].A }
	end)
	IShow.ImplWhere({ IB }, function(deps: any)
		return { Show = deps[IB].B }
	end)
	fails(function()
		where = debug.info(1, "l") + 1
		IB.ImplWhere(T.Any, function(_deps: any)
			return { B = print }
		end)
	end, "Trait: two blanket implementations of Test.Rebuild.IndirectShow apply to", "간접 Any 의 겹침")
	assert(not T.Implements(IB, stl.HashMap.New()), "실패한 Any 는 남지 않음")
	const afterIndirect = T.NewToken("Test.Rebuild.AfterIndirect") -- 예전엔 여기서 IndirectShow 의 겹침으로 던졌음
	assert(IShow.Of(afterIndirect).Show == print, "새 종류도 정상")
	-- (c) NewToken 이 던지면 토큰도 남지 않음(같은 이름으로 다시 만들 수 있음), 사용자 builder 의 에러는 **그 줄 그대로**
	local boom = false
	local boomLine = 0
	const Flaky: any = T.Trait("Test.Rebuild.Flaky", factory({ Run = T.Fn() }))
	Flaky.ImplWhere(T.Any, function(_deps: any)
		if boom then
			boomLine = debug.info(1, "l") + 1
			error("flaky builder")
		end
		return { Run = function() end }
	end)
	boom = true
	const okFlaky, errFlaky = pcall(T.NewToken, "Test.Rebuild.FlakyKind")
	assert(
		not okFlaky and string.find(tostring(errFlaky), `spec.traitrebuild.luau:{boomLine}: flaky builder`, 1, true),
		tostring(errFlaky)
	)
	boom = false
	const flakyKind = T.NewToken("Test.Rebuild.FlakyKind")
	assert(T.Implements(Flaky, T.Stamp({}, flakyKind)), "같은 이름으로 다시 만들고 Any 도 붙음")

	-- (14) 묶음의 경계(리뷰 5라운드)
	-- (a) 같은 표가 한 묶음에서 두 번 다시 지어진 뒤 실패해도 **가장 옛 내용**으로(일지를 거꾸로) — 마름모 A → B, A → C, {B, C} → D
	const DZ: any = T.Trait("Test.Rebuild.DiamondZ", factory({ Z = T.Fn() }))
	const DA: any = T.Trait("Test.Rebuild.DiamondA", factory({ A = T.Fn() }))
	const DB: any = T.Trait("Test.Rebuild.DiamondB", factory({ B = T.Fn() }))
	const DC: any = T.Trait("Test.Rebuild.DiamondC", factory({ C = T.Fn() }))
	const DD: any = T.Trait("Test.Rebuild.DiamondD", factory({ D = T.Fn() }))
	const DE: any = T.Trait("Test.Rebuild.DiamondE", factory({ E = T.Fn() }))
	local function tag(text: string): () -> string
		return function()
			return text
		end
	end
	DA.ImplWhere({ DZ }, function(_deps: any)
		return { A = tag("a-blanket") }
	end)
	DB.ImplWhere({ DA }, function(deps: any)
		return { B = tag("b<" .. deps[DA].A()) }
	end)
	DC.ImplWhere({ DA }, function(deps: any)
		return { C = tag("c<" .. deps[DA].A()) }
	end)
	DD.ImplWhere({ DB, DC }, function(deps: any)
		return { D = tag(`d<{deps[DB].B()},{deps[DC].C()}`) }
	end)
	DE.ImplWhere(
		{ DA },
		function(deps: any) -- A 가 뭉텅이일 때만 성공(B·C·D 를 다시 지은 다음에 실패)
			return if deps[DA].A() == "a-blanket" then { E = tag("e") } else {}
		end
	)
	const diamond = T.NewToken("Test.Rebuild.DiamondKind")
	DZ.ImplFor(diamond, { Z = print })
	const heldD = DD.Of(diamond)
	const dBefore = heldD.D()
	fails(
		function()
			where = debug.info(1, "l") + 1
			DA.ImplFor(diamond, { A = tag("a-explicit") })
		end,
		"Trait: a blanket implementation of Test.Rebuild.DiamondE (ImplWhere) for Test.Rebuild.DiamondKind is missing E",
		"마름모 위에서 실패"
	)
	assert(
		DD.Of(diamond) == heldD and heldD.D() == dBefore and dBefore == "d<b<a-blanket,c<a-blanket",
		"두 번 고친 표도 가장 옛 내용으로"
	)
	-- (b) builder 가 던진 **테이블** 에러는 같은 값 그대로(표식으로 오인하지 않음), 토큰도 남지 않음
	const errObject = { code = 7 }
	local throwObject = false
	const Obj: any = T.Trait("Test.Rebuild.ObjError", factory({ Run = T.Fn() }))
	Obj.ImplWhere(T.Any, function(_deps: any)
		if throwObject then
			error(errObject)
		end
		return { Run = function() end }
	end)
	throwObject = true
	const okObj, errObj = pcall(T.NewToken, "Test.Rebuild.ObjKind")
	assert(not okObj and errObj == errObject, "테이블 에러는 같은 값")
	throwObject = false
	T.NewToken("Test.Rebuild.ObjKind")
	-- (c) builder 안에서 라이브러리 함수를 `pcall` 로 부르면 평소처럼 문자열(예전엔 묶음의 표식 테이블이 샘)
	local innerErr: any = nil
	const Probe: any = T.Trait("Test.Rebuild.PcallInBuilder", factory({ Run = T.Fn() }))
	Probe.ImplWhere({ stl.Map }, function(_deps: any)
		local _ok
		_ok, innerErr = pcall(stl.Arr.At, stl.Arr.Of(1), 0 / 0)
		return { Run = function() end }
	end)
	assert(type(innerErr) == "string" and string.find(innerErr, "Arr: At index is NaN", 1, true), tostring(innerErr))
	-- (d) 일지는 스레드마다: 한 스레드의 등록이 builder 의 양보로 매달려 있어도(계약 밖 — 정의되지 않은 동작) 다른 스레드의 등록은 묶이고,
	-- 매달린 스레드를 버려도 표식이 새지 않음
	local yieldNow = false
	const Slow: any = T.Trait("Test.Rebuild.Slow", factory({ Run = T.Fn() }))
	Slow.ImplWhere(T.Any, function(_deps: any)
		if yieldNow then
			coroutine.yield()
		end
		return { Run = function() end }
	end)
	yieldNow = true
	const hung = coroutine.create(function()
		T.NewToken("Test.Rebuild.Hung")
	end)
	assert(coroutine.resume(hung) and coroutine.status(hung) == "suspended", "매달림")
	yieldNow = false
	const _, nanErr = pcall(stl.Arr.At, stl.Arr.Of(1), 0 / 0)
	assert(type(nanErr) == "string", "다른 스레드의 pcall 은 문자열")
	const otherHeld = TxP.Of(txKind)
	fails(function()
		where = debug.info(1, "l") + 1
		TxP.ImplFor(txKind, {
			Name = function()
				return "explicit"
			end,
		})
	end, "is missing Run", "매달린 동안 다른 스레드의 등록도 묶음")
	assert(TxP.Of(txKind) == otherHeld and otherHeld.Name == blanketName, "되돌림")
	coroutine.close(hung)
	const _, nanErr2 = pcall(stl.Arr.At, stl.Arr.Of(1), 0 / 0)
	assert(type(nanErr2) == "string", "버린 뒤에도 문자열")
end
print("PASS")

print(
	"=== 9. 중간자 Trait.Converter — 등록은 만들 때 한 번, 종류는 부를 때마다, 값은 그대로(질문 BA) ==="
)
do
	const kind = T.NewToken("Test.Rebuild.ConvKind")
	const other = T.NewToken("Test.Rebuild.ConvOther")
	const pushed = {}
	stl.Stack.ImplFor(kind, {
		Push = function(self: any, item: any): any
			table.insert(pushed, item)
			return self
		end,
		Pop = function(_self: any): any
			return table.remove(pushed)
		end,
		Peek = function(_self: any): any
			return pushed[#pushed]
		end,
	})
	-- (a) 만들 때: 트레이트가 아님 / 토큰이 아님 / 등록 안 됨 — 사용자 줄
	fails(function()
		where = debug.info(1, "l") + 1
		T.Converter({}, kind)
	end, "Trait: Converter", "트레이트가 아님")
	fails(function()
		where = debug.info(1, "l") + 1
		T.Converter(stl.Stack, "Test.Rebuild.ConvKind")
	end, "Stack.Converter", "토큰이 아님")
	fails(function()
		where = debug.info(1, "l") + 1
		T.Converter(stl.Stack, other)
	end, "Stack: Test.Rebuild.ConvOther does not implement Stack", "등록 안 된 종류")
	-- (b) 같은 테이블을 돌려주고, 위로·아래로 같은 함수
	const convert = T.Converter(stl.Stack, kind)
	const value = T.Stamp({}, kind)
	assert(rawequal(convert(value), value), "그대로 돌려줌")
	stl.Stack.Push(convert(value) :: any, 10)
	assert(pushed[1] == 10 and stl.Stack.Peek(convert(value) :: any) == 10, "바꾼 값으로 진입점")
	-- (c) 부를 때: 다른 종류·토큰 없는 테이블·테이블 아님 — 사용자 줄, 받은 것의 이름
	fails(function()
		where = debug.info(1, "l") + 1
		convert(stl.Arr.Of(1))
	end, "Stack: the converter for Test.Rebuild.ConvKind got Stl.Arr", "다른 종류")
	fails(
		function()
			where = debug.info(1, "l") + 1
			convert({ __type = { name = "Test.Rebuild.ConvKind" } })
		end,
		"Stack: the converter for Test.Rebuild.ConvKind got a Test.Rebuild.ConvKind this library does not know (deserialized? Trait.Restore it",
		'이름만 같은 가짜 토큰(되읽은 값 — Restore 를 권함, 리뷰 1라운드 R2: 예전엔 "for X got X")'
	)
	fails(function()
		where = debug.info(1, "l") + 1
		convert(42)
	end, "Stack: the converter for Test.Rebuild.ConvKind got number", "테이블 아님")
	-- (d) 뭉텅이로 따라온 구현도 등록으로 침(덱이면 스택)
	const fromDeque = T.Converter(stl.Stack, stl.Trait.TokenOf(stl.CircularDeque))
	const d = stl.CircularDeque.Of(1, 2)
	assert(rawequal(fromDeque(d), d), "뭉텅이 구현")
	-- (d′) 종류는 닫힌 트레이트(질문 BB): 바깥 종류도 `Trait.Struct` 로 — 종류 자리에 모듈을 넘기고(토큰 대신), 닫힌 트레이트로 바꾸면 "그 종류인가"
	const BagKind = T.Struct("Test.Rebuild.BagKind")
	const BAG = BagKind.Token
	const Bag = BagKind.Seal({
		New = function(): any
			return { __type = BAG, items = {} }
		end,
	})
	fails(function()
		where = debug.info(1, "l") + 1
		BagKind.Seal({})
	end, "Trait: Test.Rebuild.BagKind is already sealed", "두 번 봉인")
	fails(
		function()
			where = debug.info(1, "l") + 1
			T.Struct("Test.Rebuild.BagKind2").Seal(stl.Stack)
		end,
		"Trait: Test.Rebuild.BagKind2.Seal needs a module table that is not already a trait, a kind, a token or a value",
		"트레이트를 봉인"
	)
	-- 토큰·값도 거절(리뷰 1라운드 F8 — 받으면 `TokenOf(토큰)`·`TokenOf(그 값)` 이 엉뚱한 종류를 가리켰음)
	fails(function()
		where = debug.info(1, "l") + 1
		T.Struct("Test.Rebuild.BagKind3").Seal(T.NewToken("Test.Rebuild.BagKind3Tok") :: any)
	end, "Trait: Test.Rebuild.BagKind3.Seal needs a module table", "토큰을 봉인")
	fails(function()
		where = debug.info(1, "l") + 1
		T.Struct("Test.Rebuild.BagKind4").Seal(stl.Arr.Of(1) :: any)
	end, "Trait: Test.Rebuild.BagKind4.Seal needs a module table", "다른 종류의 값을 봉인")
	assert(T.TokenOf(stl.Arr.Of(1)) == T.TokenOf(stl.Arr), "거절된 봉인은 아무것도 바꾸지 않음")
	stl.Stack.ImplFor(Bag, {
		Push = function(b: any, x: any): any
			table.insert(b.items, x)
			return b
		end,
		Pop = function(b: any): any
			return table.remove(b.items)
		end,
		Peek = function(b: any): any
			return b.items[#b.items]
		end,
	})
	const bagToStack = T.Converter(stl.Stack, Bag)
	const stackToBag = T.Converter(Bag)
	const bag = Bag.New()
	stl.Stack.Push(bagToStack(bag), 8)
	assert(rawequal(stackToBag(bagToStack(bag)), bag) and stl.Stack.Peek(bagToStack(bag)) == 8, "위로·아래로")
	assert(
		T.Implements(Bag, bag) and not T.Implements(Bag, d) and T.ImplOf(Bag, bag) == Bag,
		"닫힌 트레이트의 조회"
	)
	assert(
		T.TokenOf(Bag) == T.TokenOf(bag) and T.TokenOf(stl.Arr) == T.TokenOf(stl.Arr.Of(1)),
		"종류의 토큰 = 값의 토큰"
	)
	assert(
		T.Implements(stl.Arr, stl.Arr.Of(1)) and not T.Implements(stl.Arr, d),
		"라이브러리 종류도 닫힌 트레이트"
	)
	fails(
		function()
			where = debug.info(1, "l") + 1
			stackToBag(d)
		end,
		"Test.Rebuild.BagKind: the converter needs a Test.Rebuild.BagKind — got Stl.CircularDeque",
		"아래로: 다른 종류"
	)
	-- (e) 토큰 없이 — 그 트레이트를 구현한 종류면 무엇이든(덱 쪽이 내주는 `Deque.AsStack`·`AsQueue` — 스택·큐는 덱을 모름)
	const ld = stl.LinkedDeque.Of(5)
	assert(rawequal(stl.Deque.AsStack(d), d) and rawequal(stl.Deque.AsQueue(ld), ld), "덱 두 종류")
	assert(rawequal(stl.Deque.AsStackRead(d), d) and rawequal(stl.Deque.AsQueueRead(ld), ld), "읽기 판")
	assert(
		stl.Stack.Pop(stl.Deque.AsStack(d)) == 2 and stl.Queue.Pop(stl.Deque.AsQueue(ld)) == 5,
		"바꾼 값으로 진입점"
	)
	const stamped = T.Stamp({}, kind)
	assert(
		rawequal(stl.Deque.AsStack(stamped :: any), stamped),
		"스택을 직접 구현한 종류도 받음(덱이 아니어도 — 보는 것은 스택 구현)"
	)
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Deque.AsStack(stl.Arr.Of(1) :: any)
	end, "Stack: the converter needs a Stack — got Stl.Arr", "스택이 아닌 종류")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Deque.AsQueue(nil :: any)
	end, "Queue: the converter needs a Queue — got nil", "테이블 아님")
	fails(
		function()
			where = debug.info(1, "l") + 1
			stl.Deque.AsStack({ __type = { name = "Stl.CircularDeque" } } :: any)
		end,
		"Stack: the converter needs a Stack — got a Stl.CircularDeque this library does not know (deserialized? Trait.Restore it",
		"되읽은 값(토큰 없는 변환자)"
	)
	-- (f) 종류 자리에 종류 모듈 — `X.Of`·`OfMut`·`ImplOf` 도(리뷰 1라운드 R1: `ImplFor`·`Converter`·`TokenOf` 는 받는데 `Of` 만 안 받았음)
	const arrFull = stl.List.Of(stl.Arr.Of(1))
	assert(rawequal(stl.List.Of(stl.Arr :: any), arrFull), "List.Of(stl.Arr)")
	assert(rawequal(stl.List.OfMut(stl.Arr :: any), arrFull), "List.OfMut(stl.Arr)")
	assert(
		rawequal(stl.Collection.Of(stl.HashMap :: any), stl.Collection.Of(stl.HashMap.New())),
		"Collection.Of(stl.HashMap)"
	)
	assert(rawequal(T.ImplOf(stl.List, stl.Arr), arrFull), "Trait.ImplOf(List, stl.Arr)")
	assert(T.Implements(stl.List, stl.Arr) and not T.Implements(stl.Map, stl.Arr), "Trait.Implements 에 종류")
	fails(function()
		where = debug.info(1, "l") + 1
		stl.Map.Of(stl.Arr :: any)
	end, "Map: Stl.Arr does not implement Map", "구현 안 한 종류 — 토큰과 같은 메시지")
end
print("PASS")

print()
print("=== ALL PASS (트레이트 시스템) ===")

return true
