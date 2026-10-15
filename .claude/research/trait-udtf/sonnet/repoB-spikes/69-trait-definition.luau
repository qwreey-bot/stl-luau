--!strict
--[[
	트레이트 시스템(2026-10-15, 질문 AY — `src/Trait/`)의 타입 — 정의·등록·쓰기 세 자리와, 판정자 둘이 들일 조건으로 건 것.

	- 같은 모듈의 기본 구현 반환: 모드를 추론에 맡기는 정의는 정의한 모듈 안에서 기본 구현 칸의 반환이 `never` 가 되어
	  검사가 사라졌음(덜 줄어든 `index<>` — `.claude/research/luau-source/README.md`). 모드를 **값**으로 넘기는 지금 모양에서
	  잡히는지 — 이 배터리가 그 동작의 유일한 경보입니다(상류가 줄이는 방식을 바꾸면 여기서 드러남).
	- 정의자의 실수(모드 맞바꿈·글자 리터럴·부르지 않고 넘김)는 **에러여야** 함(조용하면 안 됨).
	- 성장: 기본 구현을 더해도 필수만 적은 등록 표가 그대로 통과(POS — 바깥 구현이 깨지지 않음).
	- 등록 표의 탐침 타입 검사, 뭉텅이 몸통의 탐침 타입 검사, 빌린 참조는 읽기 트레이트만.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 줄마다 + CANARY 1). `-- 경계` 줄은 0건이어야(알려진 한계).
]]
local stl = require("../src")
local Trait = stl.Trait
type A = { read __probeA: true }
type B = { read __probeB: true }
type Arr<T> = stl.Arr<T>
type CircularDeque<T> = stl.CircularDeque<T>

--[[ 쓰는 자리 ]]
local d = stl.CircularDeque.Of(1, 2, 3)
-- 값으로 꺼낸 완성 표: 원소 타입이 섬
local s = stl.Stack.Of(d)
local pushed: CircularDeque<number> = s.Push(d, 4)
local popped: number? = s.Pop(d)
local negPush = s.Push(d, "x") -- NEG
local negPop: string? = s.Pop(d) -- NEG
-- 진입점(서명은 트레이트 파일이 입힘)
local entryPushed: CircularDeque<number> = stl.Stack.Push(d, 5)
local negEntry = stl.Stack.Push(d, "x") -- NEG
-- 리스트: 위치 타입도 값에서, 기본 구현 칸의 반환도
local l = stl.List.Of(d)
local where: number? = l.IndexOf(d, 2)
local has: boolean = l.Contains(d, 3)
local total: number = l.Fold(d, 0, function(acc: number, x: number, _i: number): number
	return acc + x
end)
local negWhere: string? = l.IndexOf(d, 2) -- NEG
local negContains: string = l.Contains(d, 3) -- NEG
-- 빌린 참조: 읽기 트레이트(List)는 됨, 쓰는 트레이트(Stack·Deque)는 못 얻음
local borrowed: stl.CircularDequeRead<number> = d
local found: number? = stl.List.Of(borrowed).IndexOf(borrowed, 2)
local negBorrowStack = stl.Stack.Of(borrowed) -- NEG
local negBorrowDeque = stl.Deque.Of(borrowed) -- NEG
-- 객체 타입에 인덱서가 없어 없는 이름은 에러
local negNoSuch = stl.Stack.NoSuch -- NEG

--[[ 등록하는 자리 — 탐침 타입으로 주석 단 지역 ]]
local function strPush(self: Arr<string>, _item: string): Arr<string>
	return self
end
local function arrPeek<T>(self: stl.ArrRead<T>): T?
	return self[self.n]
end
local okStack: stl.StackProvided<Arr<A>, A> = { Push = stl.Arr.PushBack, Pop = stl.Arr.PopBack, Peek = arrPeek }
local negPinned: stl.StackProvided<Arr<A>, A> = { Push = strPush, Pop = stl.Arr.PopBack, Peek = arrPeek } -- NEG
local negMissing: stl.DequeProvided<CircularDeque<A>, A> = { PushBack = stl.CircularDeque.PushBack } -- NEG
local negFoldLen: stl.ListProvided<Arr<A>, A, number> = {
	Get = stl.Arr.Get,
	FirstIndex = stl.Arr.FirstIndex,
	LastIndex = stl.Arr.LastIndex,
	NextIndex = stl.Arr.NextIndex,
	PrevIndex = stl.Arr.PrevIndex,
	Fold = stl.Arr.Len, -- NEG
}
-- 경계: 오타 칸(남는 필드)은 타입이 못 잡음 — 런타임 `ImplFor` 가 등록 줄에서 잡음
local extraField: stl.StackProvided<Arr<A>, A> = { Push = stl.Arr.PushBack, Pop = stl.Arr.PopBack, Peek = arrPeek, Pek = arrPeek }
-- 경계: 표 리터럴을 `ImplFor` 에 바로 넘기면 검사가 안 됨(주석 단 지역에 적어 넘길 것)
local function literalRegistration()
	stl.Stack.ImplFor(Trait.NewToken("Spike69.Literal"), { Push = strPush, Pop = 5, Peek = 5 })
end

--[[ 정의하는 자리 — 이 모듈에서 정의하고 이 모듈에서 씀 ]]
type Box = { read __type: stl.TraitToken<string>, read __generics: { read Item: (number) -> number }, value: number }
local function sizedDef<Self>(of: Self | stl.TraitToken<string>)
	return table.freeze({
		Len = Trait.Fn<<(v: Self) -> number>>(),
		IsEmpty = Trait.Default(function(ops: any): (v: Self) -> boolean
			return function(v: Self): boolean
				return ops.Len(v) == 0
			end
		end),
	})
end
local Sized = Trait.Trait("Spike69.Sized", sizedDef)
type SizedImpl = typeof(Sized.ImplOf<<Box>>(nil :: any))
-- 성장 POS: 기본 구현(IsEmpty)이 있어도 필수만 적은 등록 표가 통과
local boxSized: SizedImpl = {
	Len = function(_v: Box): number
		return 1
	end,
}
Sized.ImplFor(Trait.NewToken("Spike69.Box"), boxSized)
local box: Box = nil :: any
local empty: boolean = Sized.Of(box).IsEmpty(box)
local negSameModule: string = Sized.Of(box).IsEmpty(box) -- NEG: 같은 모듈의 기본 구현 반환(`never` 경보)
local negOverride: SizedImpl = {
	Len = function(_v: Box): number
		return 1
	end,
	IsEmpty = function(_v: Box): number -- NEG: 재정의의 반환 타입
		return 0
	end,
}
-- 정의자의 실수 — 전부 에러여야 함
-- (모드가 없는 안: 정의자 실수 NEG 해당 없음) 
-- (모드가 없는 안: 정의자 실수 NEG 해당 없음) 
-- (모드가 없는 안: 정의자 실수 NEG 해당 없음) 
-- (모드가 없는 안: 정의자 실수 NEG 해당 없음) 

--[[ 뭉텅이 구현의 몸통 — 탐침 타입으로 짜면 원소를 못박은 함수까지 잡힘 ]]
local function okBody(deque: stl.DequeFull<A, B>): stl.StackProvided<A, B>
	return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
end
local function negBody(deque: stl.DequeFull<A, B>): stl.StackProvided<A, B>
	return {
		Push = deque.PushBack,
		Pop = function(_c: A): string? -- NEG
			return nil
		end,
		Peek = deque.Back,
	}
end

local canary: string = 42

return {
	pushed,
	popped,
	negPush,
	negPop,
	entryPushed,
	negEntry,
	where,
	has,
	total,
	negWhere,
	negContains,
	found,
	negBorrowStack,
	negBorrowDeque,
	negNoSuch,
	okStack,
	negPinned,
	negMissing,
	negFoldLen,
	extraField,
	literalRegistration,
	empty,
	negSameModule,
	negOverride,
-- (모드가 없는 안: 정의자 실수 NEG 해당 없음) 
	okBody,
	negBody,
	canary,
}
