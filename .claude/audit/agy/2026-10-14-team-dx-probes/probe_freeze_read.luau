--!strict
-- probe_freeze_read.luau
-- table.freeze({ ... })의 반환 타입이 read 필드로 추론되는가?

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

takeFrozen<<Arr<A>, A>>({
	Push = pushBack,
	Pop = popBack,
})

local canary: string = 1
