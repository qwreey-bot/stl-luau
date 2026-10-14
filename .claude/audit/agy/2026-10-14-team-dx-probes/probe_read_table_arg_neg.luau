--!strict
-- probe_read_table_arg_neg.luau
type A = { read __probeA: true }
type Arr<T> = { n: number, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end

type ReadStackImpl<Self, T> = {
	read Push: (stack: Self, item: T) -> Self,
	read Pop: (stack: Self) -> T?,
}

local function takeRead<Self, T>(impl: ReadStackImpl<Self, T>) end

-- Test 3: read에 잘못된 표 리터럴 전달 (Pop에 pushBack 전달 - NEG 잡혀야 함)
takeRead<<Arr<A>, A>>({ Push = pushBack, Pop = pushBack }) -- NEG

local canary: string = 1
