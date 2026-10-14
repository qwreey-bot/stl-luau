--!strict
type Deque<Self, T> = {
	PushFront: (deque: Self, item: T) -> Self,
	PushBack: (deque: Self, item: T) -> Self,
	PopFront: (deque: Self) -> T?,
	PopBack: (deque: Self) -> T?,
	Front: (deque: Self) -> T?,
	Back: (deque: Self) -> T?,
	IsEmpty: (deque: Self) -> boolean,
}

type Stack<Self, T> = {
	Push: (stack: Self, item: T) -> Self,
	Pop: (stack: Self) -> T?,
	Peek: (stack: Self) -> T?,
}

type ProbeC = { read __probeC: true }
type ProbeT = { read __probeT: true }

-- Pattern A1: Monomorphic blanket body using probe types directly!
local function stackFromDeque(deque: Deque<ProbeC, ProbeT>): Stack<ProbeC, ProbeT>
	return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
end

-- What if someone puts mistakes into stackFromDeque?
local function bad_pinnedPop(deque: Deque<ProbeC, ProbeT>): Stack<ProbeC, ProbeT>
	return {
		Push = deque.PushBack,
		Pop = function(c: ProbeC): string? return nil end, -- NEG: string? vs ProbeT?
		Peek = deque.Back,
	}
end

local function bad_pinnedPush(deque: Deque<ProbeC, ProbeT>): Stack<ProbeC, ProbeT>
	return {
		Push = function(c: ProbeC, x: number): ProbeC return c end, -- NEG: number vs ProbeT
		Pop = deque.PopBack,
		Peek = deque.Back,
	}
end

local function bad_siblingReturn(deque: Deque<ProbeC, ProbeT>): Stack<ProbeC, ProbeT>
	return {
		Push = deque.PushBack,
		Pop = deque.IsEmpty, -- NEG: boolean vs ProbeT?
		Peek = deque.Back,
	}
end

local canary: string = 1
return { stackFromDeque, bad_pinnedPop, bad_pinnedPush, bad_siblingReturn, canary }
