--!strict
--[[
	트레이트 — 표를 **미리 만들고**, 의존이 바뀌면 **다시 만든다**(2026-10-14 사용자 결정, 질문 AW).

	- 언제 만드는가: 트레이트가 생길 때(그때 의존을 갖춘 종류) / 토큰이 생길 때(아무것도 요구하지 않는 트레이트) /
	  등록이 마지막 의존을 채울 때. **조회는 만들지 않습니다.**
	- 저절로 따라온 표 위에 재정의가 얹히면 같은 테이블을 다시 짓고, 그것을 의존으로 쓰는 표들(기본 구현, `ImplWith`)을
	  다시 짓습니다 — 그래서 기본 구현이 의존의 함수를 만들 때 붙잡거나 그대로 돌려줘도 됩니다(`Stack`·`Queue`).

	`spec.contracts` 에 두지 않은 것은 그 파일이 타입 검사기의 한도("too complex")에 닿아서입니다.
]]
local stl = require("../src")

print(
	"=== 1. ⭐ 표를 미리 만들고, 의존이 바뀌면 다시 만든다 — 언제 만드는가, 연쇄, ImplWith ==="
)
do
	const T = stl.Trait
	local where = 0
	local function fails(fn: () -> (), needle: string, label: string)
		const ok, err = pcall(fn)
		assert(not ok and string.find(tostring(err), needle, 1, true), `{label}: {err}`)
		assert(string.find(tostring(err), `spec.traitrebuild.luau:{where}:`, 1, true), `{label} 사용자 줄: {err}`)
	end
	local function getter(n: number): (any) -> number
		return function(_v: any): number
			return n
		end
	end

	-- (1) 트레이트가 생길 때: 이미 의존을 갖춘 종류는 그 자리에서 만들어짐(아무도 묻지 않아도)
	const Base = T.New<<{ read Get: (v: any) -> number }>>("Base20", { required = { "Get" } })
	const Early = T.NewToken("Early20")
	T.Impl(Base, Early, { Get = getter(1) })
	local builds = 0
	const Show = T.New<<{ read Show: (v: any) -> string }>>("Show20", {
		dependencies = { Base },
		defaults = function(_ops: any, deps: any)
			builds += 1
			const get = deps[Base].Get -- 만들 때 붙잡음
			return {
				Show = function(v: any): string
					return `<{get(v)}>`
				end,
			}
		end,
	})
	assert((Show.impls :: any)[Early] ~= nil and (Show :: any).derived[Early], "New 에서 만들어짐")
	assert(builds == 1, `한 번: {builds}`)
	-- (2) 조회는 만들지 않음 — 몇 번을 물어도 만드는 함수는 다시 안 불림
	const early = { __type = Early }
	for _ = 1, 5 do
		assert((T.ImplOf(Show, early) :: any).Show(early) == "<1>" and T.Implements(Show, early))
	end
	assert(builds == 1, `조회는 만들지 않음: {builds}`)
	-- (3) 등록이 의존을 채울 때: 의존이 둘이면 **마지막** 것이 채워질 때 만들어짐
	const Other = T.New<<{ read Name: (v: any) -> string }>>("Other20", { required = { "Name" } })
	const Both = T.New<<{ read Both: (v: any) -> string }>>("Both20", {
		dependencies = { Base, Other },
		defaults = function(_ops: any, deps: any)
			const get, name = deps[Base].Get, deps[Other].Name
			return {
				Both = function(v: any): string
					return `{name(v)}={get(v)}`
				end,
			}
		end,
	})
	const Late = T.NewToken("Late20")
	assert((Both.impls :: any)[Late] == nil)
	T.Impl(Other, Late, {
		Name = function(_v: any): string
			return "late"
		end,
	})
	assert((Both.impls :: any)[Late] == nil, "의존 하나만으로는 안 만들어짐")
	assert((Show.impls :: any)[Late] == nil, "Show 는 Base 만 요구 — 아직")
	T.Impl(Base, Late, { Get = getter(2) })
	assert(
		(Both.impls :: any)[Late] ~= nil and (Show.impls :: any)[Late] ~= nil,
		"마지막 의존이 채워질 때 만들어짐"
	)
	assert((T.ImplOf(Both, { __type = Late }) :: any).Both({ __type = Late }) == "late=2")
	-- (4) 토큰이 생길 때: 아무것도 요구하지 않는 트레이트(기본 구현만)는 새 종류에 바로
	const Hello = T.New<<{ read Hello: () -> string }>>("Hello20", {
		defaults = function()
			return {
				Hello = function(): string
					return "hi"
				end,
			}
		end,
	})
	const Fresh = T.NewToken("Fresh20")
	assert(
		(Hello.impls :: any)[Fresh] ~= nil and (Hello.impls :: any)[Early] ~= nil,
		"새 토큰·있던 토큰 모두"
	)

	-- (5) ⭐ 재정의가 위로 번짐: 덱 → Stack(저절로, 덱 함수 그대로) → Stack 에 의존하는 기본 구현·ImplWith 구현
	const Kind = T.NewToken("Pile20")
	const calls: { string } = {}
	local function tagged(name: string): (...any) -> string
		return function(): string
			table.insert(calls, name)
			return name
		end
	end
	const dequeFns = {
		PushFront = tagged("PushFront"),
		PushBack = tagged("PushBack"),
		PopFront = tagged("PopFront"),
		PopBack = tagged("PopBack"),
		Front = tagged("Front"),
		Back = tagged("Back"),
	}
	T.Impl(stl.Deque, Kind, dequeFns :: any)
	const value = { __type = Kind }
	const stackImpl: any = T.ImplOf(stl.Stack, value)
	assert(
		stackImpl.Push == dequeFns.PushBack and stackImpl.Pop == dequeFns.PopBack and stackImpl.Peek == dequeFns.Back,
		"Stack 의 표에는 덱 함수 그대로"
	)
	local upperRuns, histRuns = 0, 0
	const Upper = T.New<<{ read Save: (v: any) -> any }>>("Upper20", {
		dependencies = { stl.Stack :: any },
		defaults = function(_ops: any, deps: any)
			upperRuns += 1
			return { Save = deps[stl.Stack].Push }
		end,
	})
	const History = T.New<<{ read Undo: (v: any) -> any }>>("History20", {
		required = { "Undo" },
		dependencies = { stl.Stack :: any },
	})
	T.ImplWith(History, Kind, function(deps: any)
		histRuns += 1
		return { Undo = deps[stl.Stack].Pop }
	end)
	-- (Upper 는 만들 때 이미 스택인 **모든** 종류 — 내장 덱 포함 — 에 만들어지므로 횟수는 차이로 셉니다)
	const upperImpl: any = T.ImplOf(Upper, value)
	const histImpl: any = T.ImplOf(History, value)
	assert(upperRuns >= 3 and histRuns == 1, `Upper 는 종류마다(내장 덱 둘 + Pile20): {upperRuns}`)
	assert(upperImpl.Save == dequeFns.PushBack and histImpl.Undo == dequeFns.PopBack)
	const upperBuilt = upperRuns
	const hoisted = upperImpl.Save -- 함수를 미리 꺼내 둔 쪽
	const function fastPush(): string
		table.insert(calls, "fast")
		return "fast"
	end
	T.Impl(stl.Stack, Kind, { Push = fastPush } :: any)
	assert(rawequal(T.ImplOf(stl.Stack, value), stackImpl), "같은 표")
	assert(stackImpl.Push == fastPush and stackImpl.Pop == dequeFns.PopBack, "재정의한 것만 바뀜")
	assert(not (stl.Stack :: any).derived[Kind], "명시 등록이 됨")
	assert(
		upperRuns == upperBuilt + 1 and rawequal(T.ImplOf(Upper, value), upperImpl) and upperImpl.Save == fastPush,
		"기본 구현이 다시 불림"
	)
	assert(
		histRuns == 2 and rawequal(T.ImplOf(History, value), histImpl) and histImpl.Undo == dequeFns.PopBack,
		"ImplWith 도 다시 불림"
	)
	stl.Stack.Push(value :: any, 1)
	assert(calls[#calls] == "fast", "진입점은 새 함수")
	-- 관측(계약 아님 — 알려진 대가): **함수를** 미리 꺼내 둔 쪽은 그 뒤의 등록을 못 봄. 캐싱은 `ImplWith` 로.
	assert(hoisted == dequeFns.PushBack, "꺼내 둔 함수는 그대로")
	-- 명시 등록의 재등록은 그대로 에러
	fails(function()
		where = debug.info(1, "l") + 1
		T.Impl(stl.Stack, Kind, { Pop = fastPush } :: any)
	end, "Pile20 already implements Stack", "재등록")

	-- (6) 실패한 재정의는 아무것도 바꾸지 않고 위로 번지지도 않음
	const Kind2 = T.NewToken("Pile20b")
	T.Impl(stl.Deque, Kind2, dequeFns :: any)
	const upperBefore = upperRuns
	fails(function()
		where = debug.info(1, "l") + 1
		T.Impl(stl.Stack, Kind2, { Push = fastPush, Shove = fastPush } :: any)
	end, "Pile20b gave Shove to Stack", "모르는 이름")
	fails(function()
		where = debug.info(1, "l") + 1
		T.Impl(stl.Stack, Kind2, { Pop = 5 } :: any)
	end, "Pile20b gave a number as Pop for Stack", "함수 아닌 재정의")
	assert(
		(stl.Stack :: any).derived[Kind2] and (T.ImplOf(stl.Stack, { __type = Kind2 }) :: any).Push == dequeFns.PushBack
	)
	assert(upperRuns == upperBefore, "위로 번지지 않음")

	-- (7) ImplWith 의 에러(사용자 줄, 아무것도 남지 않음)
	const Kind3 = T.NewToken("Pile20c")
	T.Impl(stl.Deque, Kind3, dequeFns :: any)
	fails(function()
		where = debug.info(1, "l") + 1
		T.ImplWith(History, Kind3, { Undo = fastPush } :: any)
	end, "ImplWith needs a function that builds the implementation of History20, got table", "표를 넘김")
	fails(function()
		where = debug.info(1, "l") + 1
		T.ImplWith(History, Kind3, function(_deps: any): any
			return 5
		end)
	end, "the builder Pile20c gave for History20 must return a table, got number", "표가 아닌 것을 돌려줌")
	fails(function()
		where = debug.info(1, "l") + 1
		T.ImplWith(History, Kind3, function(_deps: any): any
			return {}
		end)
	end, "Pile20c is missing Undo for History20", "필수가 빠짐")
	fails(function()
		where = debug.info(1, "l") + 1
		T.ImplWith(History, T.NewToken("NoDeque20"), function(_deps: any): any
			return { Undo = fastPush }
		end)
	end, "NoDeque20 must implement Stack to implement History20", "의존을 못 갖춤")
	assert((History.impls :: any)[Kind3] == nil and (History :: any).sources[Kind3] == nil, "남는 것 없음")

	-- (8) 내장 덱: Stack·Queue 의 표가 덱 함수 그 자체(미리 꺼내 두면 직접 호출과 같음 — perf 52절)
	for _, module: any in { stl.CircularDeque, stl.LinkedDeque } do
		const d = module.New()
		const s: any, q: any = T.ImplOf(stl.Stack, d), T.ImplOf(stl.Queue, d)
		assert(s.Push == module.PushBack and s.Pop == module.PopBack and s.Peek == module.Back, "Stack")
		assert(q.Push == module.PushBack and q.Pop == module.PopFront and q.Peek == module.Front, "Queue")
	end

	-- (9) 마름모: D 가 바뀌면 C(A·B 에 의존)는 두 번 다시 지어지지만 끝 상태는 맞음
	const Root = T.New<<{ read Base: () -> string }>>("Root20", { required = { "Base" } })
	const D = T.New<<{ read Core: () -> string }>>("D20", {
		dependencies = { Root },
		defaults = function(_ops: any, deps: any)
			return { Core = deps[Root].Base }
		end,
	})
	local function through(name: string): any
		return T.New(name, {
			dependencies = { D :: any },
			defaults = function(_ops: any, deps: any)
				return { Get = deps[D].Core }
			end,
		})
	end
	const A, B = through("A20"), through("B20")
	local cRuns = 0
	const C = T.New<<{ read Left: () -> string, read Right: () -> string }>>("C20", {
		dependencies = { A, B },
		defaults = function(_ops: any, deps: any)
			cRuns += 1
			return { Left = deps[A].Get, Right = deps[B].Get }
		end,
	})
	const Diamond = T.NewToken("Diamond20")
	const function base(): string
		return "base"
	end
	const function better(): string
		return "better"
	end
	T.Impl(Root, Diamond, { Base = base })
	const c: any = T.ImplOf(C, { __type = Diamond })
	assert(c.Left == base and c.Right == base and cRuns == 1)
	T.Impl(D, Diamond, { Core = better } :: any)
	assert(c.Left == better and c.Right == better, "끝 상태가 맞음")
	assert(cRuns == 3, `관측: A 때 한 번, B 때 한 번 — {cRuns}`)
end
print("PASS")

print()
print("=== ALL PASS (트레이트 다시 만들기) ===")

return true
