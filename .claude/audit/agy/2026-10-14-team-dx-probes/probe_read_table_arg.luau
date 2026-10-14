--!strict
-- probe_read_table_arg.luau
type A = { read __probeA: true }
type Arr<T> = { n: number, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end

type ReadStackImpl<Self, T> = {
	read Push: (stack: Self, item: T) -> Self,
	read Pop: (stack: Self) -> T?,
}

local function takeRead<Self, T>(impl: ReadStackImpl<Self, T>) end

-- Test 2: read에 표 리터럴 직접 전달 (캐시 오염 없는 단독 실행)
takeRead<<Arr<A>, A>>({ Push = pushBack, Pop = popBack })

local canary: string = 1
