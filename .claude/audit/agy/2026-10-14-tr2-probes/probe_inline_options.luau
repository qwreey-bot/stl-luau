--!strict
-- probe_inline_options.luau: 등록 표를 작성하고 등록하는 다양한 방식 비교

type Stack<Self, T> = {
	Push: (Self, T) -> Self,
	Pop: (Self) -> T?,
}

type Arr<T> = { n: number, [number]: T }

-- 모듈의 제네릭 함수들
local function arrPush<T>(a: Arr<T>, x: T): Arr<T>
	return a
end
local function arrPop<T>(a: Arr<T>): T?
	return a[a.n]
end
local function strPush(a: Arr<string>, x: string): Arr<string>
	return a
end

-- 방식 1: v4 의 방식 (탐침 타입 주석 단 지역 변수)
type A = { read __probeA: true }
const arrStack1: Stack<Arr<A>, A> = {
	Push = arrPush,
	Pop = arrPop,
}

-- 방식 2: 제네릭 생성 함수 (Generic Helper)
-- 이 방식은 탐침 타입 A 없이도 완전한 제네릭 검사를 받음!
local function makeArrStack<T>(): Stack<Arr<T>, T>
	return {
		Push = arrPush,
		Pop = arrPop,
	}
end

-- 방식 2에서 잘못된 구현(예: string 전용 함수)이 들어오면 잡히는가?
local function makeBadArrStack<T>(): Stack<Arr<T>, T>
	return {
		Push = strPush, -- NEG: string 전용 함수가 T 자리에 들어감!
		Pop = arrPop,
	}
end

-- 방식 3: 등록 헬퍼 함수 호출 자리에 인라인
local function registerStack<Self, T>(token: string, impl: Stack<Self, T>)
	-- 런타임 등록 로직
end

-- 인라인 테이블 전달 시도:
-- registerStack<<Arr<A>, A>>("Arr", { Push = arrPush, Pop = arrPop })
-- 이게 되는지 안 되는지 확인:
local inlineOk = registerStack<<Arr<A>, A>>("Arr", {
	Push = arrPush,
	Pop = arrPop,
})

local canary: string = 1

return {
	arrStack1,
	makeArrStack,
	makeBadArrStack,
	inlineOk,
	canary,
}
