--!strict
type Stack<Self, T> = {
	Push: (Self, T) -> Self,
	Pop: (Self) -> T?,
}
type Arr<T> = { n: number, [number]: T }

local function strPush(a: Arr<string>, x: string): Arr<string>
	return a
end
local function arrPop<T>(a: Arr<T>): T?
	return a[a.n]
end

local function makeBadArrStack<T>(): Stack<Arr<T>, T>
	return {
		Push = strPush, -- NEG: string 전용 함수가 T 자리에 들어감!
		Pop = arrPop,
	}
end

local canary: string = 1

return { makeBadArrStack, canary }
