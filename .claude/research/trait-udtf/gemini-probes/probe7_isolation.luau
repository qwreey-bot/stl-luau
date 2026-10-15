--!strict
-- probe7: Pinpointing why ImplOf bypasses the check

export type function Identity(t: type): type
	return t
end

export type function TableOf(t: type): type
	local props: any = {}
	for name, prop in t:properties() do
		props[name] = { read = prop.read }
	end
	return types.newtable(props)
end

type Arr<T> = { [number]: T }
type A = { read __probeA: true }

type FoldSig = <U>(list: Arr<A>, init: U, fn: (acc: U, item: A, idx: number) -> U) -> U

type Case1_Direct = { read Fold: FoldSig? }
type Case2_Identity = Identity<Case1_Direct>
type Case3_TableOf = TableOf<Case1_Direct>

-- Case 1: 직접 작성 (잡힘)
local _case1: Case1_Direct = {
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number
		return init
	end,
}

-- Case 2: Identity 타입 함수 통과 (잡히는가?)
local _case2: Case2_Identity = {
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number
		return init
	end,
}

-- Case 3: TableOf 로 types.newtable 재구축 (잡히는가?)
local _case3: Case3_TableOf = {
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number
		return init
	end,
}

local canary: string = 1
