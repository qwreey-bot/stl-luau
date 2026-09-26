--!strict
--[[
	실제 `src/Fut.luau` 에 대한 음성 대조군.

	`Fut<T...>` 는 타입 팩을 **팬텀 필드**(`_pack: (T...) -> ()`)에 얹어 들고
	다닙니다. 팬텀이 무너지면 모든 `Fut<…>` 가 같아져 **결과 타입이 조용히
	사라지므로**, 다중 반환이 체이닝을 지나서도 정확한지를 봅니다.

	기대 진단: 10건 (NEG 9 + CANARY 1)
]]
local stl = require("../../../../src")
local Fut = stl.Fut
type Fut<T...> = stl.Fut<T...>

local pair: Fut<number, string> = Fut.Resolved(1, "a")

--[[ POS ]]
local okN: number, okS: string = pair:Await()
local okChain: Fut<string> = pair
	:AndThen(function(n: number, s: string): (number, string)
		return n + 1, s
	end)
	:AndThen(function(n: number, s: string): string
		return s .. n
	end)
local okFlat: Fut<number> = pair:Chain(function(n: number, _s: string): Fut<number>
	return Fut.Resolved(n)
end)
local okCatch: Fut<number, string> = pair:Catch(function(_reason: any): (number, string)
	return 0, ""
end)
local okAsync: (number) -> Fut<string> = Fut.Async(function(x: number): string
	return tostring(x)
end)
local okRejected: Fut<number> = Fut.Rejected<<(number)>>("이유")
local okSafe: boolean = pair:AwaitSafe()
local okStatus: stl.FutStatus = pair:Status()

--[[ NEG ]]
local neg1: string = pair:Await() -- 첫 결과는 number
local _, neg2: number = pair:Await() -- 둘째는 string
local neg3 = pair:AndThen(function(s: string) -- 콜백 인자 순서가 틀림
	return s
end)
local neg4: Fut<number> = okChain -- 체인 결과는 Fut<string>
local neg5: number = okChain:Await() -- 체인 결과는 string
local neg6: Fut<string> = okFlat -- 펼친 결과는 Fut<number>
local neg7 = pair:NoSuch()
local neg8 = Fut.Nope
local neg9: number = okAsync(1):Await() -- Async 결과는 string
local canary: string = 42

return {
	okN, okS, okChain, okFlat, okCatch, okAsync, okRejected, okSafe, okStatus,
	neg1, neg2, neg3, neg4, neg5, neg6, neg7, neg8, neg9, canary,
}
