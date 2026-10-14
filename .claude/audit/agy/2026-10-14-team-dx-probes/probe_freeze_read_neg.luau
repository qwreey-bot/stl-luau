--!strict
-- probe_freeze_read_neg.luau
-- table.freeze로 얻은 read 타입에서 NEG가 잡히는가?

type A = { read __probeA: true }
type Arr<T> = { n: number, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end

local function makeFrozenImpl<Self, T>()
	return table.freeze({
		Push = pushBack :: (Self, T) -> Self,
		Pop = popBack :: (Self) -> T?,
	})
end

type FrozenImpl<Self, T> = typeof(makeFrozenImpl<<Self, T>>())

local function takeFrozen<Self, T>(impl: FrozenImpl<Self, T>) end

-- NEG: Pop에 pushBack 전달
takeFrozen<<Arr<A>, A>>({
	Push = pushBack,
	Pop = pushBack, -- NEG
})

local canary: string = 1
