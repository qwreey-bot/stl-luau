--!strict
-- probe_simpler_trait.luau: Inherit 없는 필수 구현 분리 및 타입 안전한 진입점 프로브

-- 1. 트레이트의 완성 타입 (Complete Ops)
export type List<Self, E, I> = {
	Get: (Self, I) -> E?,
	FirstIndex: (Self) -> I?,
	NextIndex: (Self, I) -> I?,
	-- 기본 구현 메서드들
	IndexOf: (Self, E) -> I?,
	Contains: (Self, E) -> boolean,
}

-- 2. 구현자가 적어야 하는 필수 타입 (Required Ops Only)
-- Inherit 를 적을 필요가 없음! 기본 구현 메서드는 여기에 아예 없음!
export type ListReq<Self, E, I> = {
	Get: (Self, I) -> E?,
	FirstIndex: (Self) -> I?,
	NextIndex: (Self, I) -> I?,
}

-- 3. 컨테이너 정의
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
type MyList<T> = {
	n: number,
	read __generics: { read Item: (T) -> T, read Index: (number) -> number },
	[number]: T,
}

-- 모듈 함수들
local function myGet<T>(l: MyList<T>, i: number): T?
	return l[i]
end
local function myFirst<T>(l: MyList<T>): number?
	return if l.n > 0 then 1 else nil
end
local function myNext<T>(l: MyList<T>, i: number): number?
	return if i < l.n then i + 1 else nil
end

-- 4. 구현 등록 (탐침 타입 A 를 써서 필수 메서드만 등록)
type A = { read __probeA: true }
const myReq: ListReq<MyList<A>, A, number> = {
	Get = myGet,
	FirstIndex = myFirst,
	NextIndex = myNext,
	-- IndexOf = ..., Contains = ... 를 적지 않아도 됨! Inherit 필요 없음!
}

-- 실수로 필수 메서드를 빼먹으면 잡히는가?
const NEG_missing_req: ListReq<MyList<A>, A, number> = {
	Get = myGet,
	-- FirstIndex 누락!
	NextIndex = myNext,
}

-- 5. 기본 구현을 합성하는 빌더 함수 (트레이트 런타임이 수행)
local function buildList<Self, E, I>(req: ListReq<Self, E, I>): List<Self, E, I>
	local indexOf = function(self: Self, item: E): I?
		local idx = req.FirstIndex(self)
		while idx ~= nil do
			if req.Get(self, idx) == item then
				return idx
			end
			idx = req.NextIndex(self, idx)
		end
		return nil
	end

	local contains = function(self: Self, item: E): boolean
		return indexOf(self, item) ~= nil
	end

	return {
		Get = req.Get,
		FirstIndex = req.FirstIndex,
		NextIndex = req.NextIndex,
		IndexOf = indexOf,
		Contains = contains,
	}
end

local completeList = buildList(myReq)

-- 6. 트레이트 모듈 진입점 타입
type ListModule = {
	Get: <Self, E, I>(list: Self & ItemIndex<E, I>, idx: I) -> E?,
	Contains: <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> boolean,
	IndexOf: <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I?,
}

local ListMod: ListModule = {
	Get = function(list: any, idx: any): any
		return nil
	end,
	Contains = function(list: any, item: any): any
		return false
	end,
	IndexOf = function(list: any, item: any): any
		return nil
	end,
}

local myList: MyList<number> = {
	n = 2,
	__generics = {
		Item = function(x: number) return x end,
		Index = function(i: number) return i end,
	},
	[1] = 10,
	[2] = 20,
}

-- 올바른 진입점 호출
local ok_contains = ListMod.Contains(myList, 10)
local ok_idx = ListMod.IndexOf(myList, 20)

-- 틀린 진입점 호출
local NEG_wrong_elem = ListMod.Contains(myList, "string") -- NEG
local NEG_wrong_idx = ListMod.Get(myList, "not an index") -- NEG

local canary: string = 1

return {
	myReq,
	NEG_missing_req,
	completeList,
	ok_contains,
	ok_idx,
	NEG_wrong_elem,
	NEG_wrong_idx,
	canary,
}
