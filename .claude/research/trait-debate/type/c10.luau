--!strict
local function Fn<F>(): F return nil :: any end
local function listReq<S, E, I>()
	return { Get = Fn<<(l: S, i: I) -> E?>>(), First = Fn<<(l: S) -> I?>>(), Next = Fn<<(l: S, i: I) -> I?>>() }
end
-- 기본 구현은 ops(완성 표)를 받는 팩토리: 완성 표 타입이 자기 자신을 참조함
local function listDefaults<S, E, I>(ops: { Get: (S, I) -> E?, First: (S) -> I?, Next: (S, I) -> I? })
	return {
		Contains = function(l: S, x: E): boolean
			return ops.Get(l, ops.First(l) :: I) ~= nil
		end,
	}
end
export type List<S, E, I> = typeof(listReq<<S, E, I>>()) & typeof(listDefaults<<S, E, I>>(nil :: any))
local x: List<string, number, number> = nil :: any
local r: boolean = x.Contains("a", 1)
local r2: string = x.Contains("a", 1) -- NEG
local canary: string = 1
return { r, r2, canary }
