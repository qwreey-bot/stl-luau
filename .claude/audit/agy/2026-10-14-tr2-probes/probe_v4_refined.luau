--!strict
-- probe_v4_refined.luau: v4 한 걸음 물러서기 종합 제안 프로브
-- 1. 진입점 정적 타입 복원
-- 2. Inherit 폐지 및 필수(Req)/완성(Ops) 타입 분리
-- 3. Of -> Ops 이름 변경
-- 4. 공변 읽기 참조의 타입 지원

-- [A] 연관 타입 마커 (읽기/쓰기 분리)
export type Item<T> = { read __generics: { read Item: (T) -> T } }
export type ItemRead<T> = { read __genericsRead: { read Item: () -> T } }
export type AnyToken = { read name: string }

-- [B] 트레이트 정의: Stack
-- 1. 완성 연산 표 (Consumer & Blanket 용)
export type StackOps<Self, T> = {
	Push: (Self, T) -> Self,
	Pop: (Self) -> T?,
	Peek: (Self) -> T?,
}

-- 2. 구현자가 등록해야 하는 필수 표 (Inherit 불필요!)
export type StackReq<Self, T> = {
	Push: (Self, T) -> Self,
	Pop: (Self) -> T?,
	-- Peek 은 기본 구현이 있으므로 필수가 아님!
}

-- 3. 트레이트 모듈 진입점 타입 (Push/Pop/Peek 에 정적 타입 부여!)
export type StackModule = {
	-- 정적 타입이 살아있는 편한 진입점
	Push: <Self, T>(stack: Self & Item<T>, item: T) -> Self,
	Pop: <Self, T>(stack: Self & Item<T>) -> T?,
	Peek: <Self, T>(stack: Self & Item<T>) -> T?,
	-- 연산 표 꺼내기 (Of 대신 Ops) - 합집합 단일 매개변수로 ambiguous 해결
	Ops: <Self, T>(of: (Self & Item<T>) | AnyToken) -> StackOps<Self, T>,
}

-- [C] 컨테이너 모의 구현: Arr
type Arr<T> = {
	n: number,
	read __generics: { read Item: (T) -> T },
	read __genericsRead: { read Item: () -> T },
	[number]: T,
}

local ArrMod = {}
function ArrMod.PushBack<T>(a: Arr<T>, x: T): Arr<T>
	a.n += 1
	a[a.n] = x
	return a
end
function ArrMod.PopBack<T>(a: Arr<T>): T?
	if a.n == 0 then return nil end
	local v = a[a.n]
	a[a.n] = nil :: any
	a.n -= 1
	return v
end

-- [D] 트레이트 모듈 런타임 구현 모의
local Stack: StackModule = {
	Push = function(s: any, item: any): any
		return ArrMod.PushBack(s, item)
	end,
	Pop = function(s: any): any
		return ArrMod.PopBack(s)
	end,
	Peek = function(s: any): any
		return s[s.n]
	end,
	Ops = function(x: any): any
		return {
			Push = ArrMod.PushBack,
			Pop = ArrMod.PopBack,
			Peek = function(s: any) return s[s.n] end,
		}
	end,
}

-- [E] 구현 등록 검증
type A = { read __probeA: true }

-- 1. 필수만 적은 등록 표 (Inherit 없이 깔끔함!)
const arrStackReq: StackReq<Arr<A>, A> = {
	Push = ArrMod.PushBack,
	Pop = ArrMod.PopBack,
}

-- 2. 필수 누락 시 타입 에러 검증
const NEG_missing_pop: StackReq<Arr<A>, A> = {
	Push = ArrMod.PushBack,
	-- Pop 누락!
}

-- 3. 원소 타입 못박은 함수 등록 시 타입 에러 검증
local function strPush(a: Arr<string>, x: string): Arr<string>
	return a
end
const NEG_pinned_type: StackReq<Arr<A>, A> = {
	Push = strPush, -- NEG: string 전용 함수 거절됨!
	Pop = ArrMod.PopBack,
}

-- [F] 사용 자리 검증
local a: Arr<number> = {
	n = 2,
	__generics = { Item = function(x: number) return x end },
	__genericsRead = { Item = function() return 0 end },
	[1] = 10,
	[2] = 20,
}

-- 1. 편한 진입점의 완벽한 정적 타입 검증!
local ok_push = Stack.Push(a, 30)
local ok_pop: number? = Stack.Pop(a)
local NEG_push_wrong = Stack.Push(a, "not_number") -- NEG: number 에 string 넣음!
local NEG_pop_wrong: string? = Stack.Pop(a) -- NEG: number? 를 string? 에 대입!

-- 2. Ops(Of 대안) 검증
local ops = Stack.Ops(a)
local ok_ops_push = ops.Push(a, 40)
local NEG_ops_wrong = ops.Push(a, "bad") -- NEG

local canary: string = 1

return {
	arrStackReq,
	NEG_missing_pop,
	NEG_pinned_type,
	ok_push,
	ok_pop,
	NEG_push_wrong,
	NEG_pop_wrong,
	ops,
	ok_ops_push,
	NEG_ops_wrong,
	canary,
}
