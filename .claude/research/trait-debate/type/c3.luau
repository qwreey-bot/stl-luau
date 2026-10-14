--!strict
local function Fn<F>(): F return nil :: any end
local function listReq<Self, E, I>()
	return { Get = Fn<<(l: Self, i: I) -> E?>>(), First = Fn<<(l: Self) -> I?>>(), Next = Fn<<(l: Self, i: I) -> I?>>() }
end
-- 기본 구현은 ops(완성 표)를 받는 팩토리: 완성 표 타입이 자기 자신을 참조함
local function listDefaults<Self, E, I>(ops: typeof(listReq<<Self, E, I>>()))
	return {
		IndexOf = function(l: Self, x: E): I?
			local i = ops.First(l)
			while i ~= nil do
				if ops.Get(l, i) == x then return i end
				i = ops.Next(l, i)
			end
			return nil
		end,
		Contains = function(l: Self, x: E): boolean
			return ops.Get(l, ops.First(l) :: I) ~= nil
		end,
	}
end
export type List<Self, E, I> = typeof(listReq<<Self, E, I>>()) & typeof(listDefaults<<Self, E, I>>(nil :: any))
local x: List<string, number, number> = nil :: any
local r: boolean = x.Contains("a", 1)
local r2: string = x.Contains("a", 1) -- NEG
local canary: string = 1
return { r, r2, canary }
