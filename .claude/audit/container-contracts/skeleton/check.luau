--!strict
--[[
	스캐폴딩 가설 검증.

	타입: `luau-analyze .claude/audit/container-contracts/skeleton/check.luau`
	      → **정확히 6건** (NEG 5 + CANARY 1)
	런타임: `luau .claude/audit/container-contracts/skeleton/check.luau`
	      → 4줄 출력, 에러 없음

	확인하는 것:
	  (a) 공용 알고리즘이 구현을 모른 채 동작하는가
	  (b) 계약을 별도 모듈에서 require 하면 선언 순서 누수가 사라지는가
	  (c) 타입 변환 체이닝이 사는가
	  (d) 같은 설계가 런타임에서도 실제로 도는가
]]
local Arr = require("./Arr")
local Algorithm = require("./Algorithm")

local a = Arr.Of(1, 2, 3)

--#region POS — 에러가 나면 안 됨
local idx: number? = Algorithm.IndexOf(a, 2)
local cnt: number = Algorithm.Count(a)
local chained = a:Map(function(v: number)
	return tostring(v)
end):Map(function(s: string)
	return #s > 0
end)
local first: number? = a[1]
local n: number = a.n
--#endregion

--#region NEG — 전부 에러여야 함. 런타임에는 실행하지 않는다.
if (nil :: any) then
	local neg1: string = a[1]
	local neg2: string = chained[1]
	local neg3 = a:NoSuchMethod()
	local neg4: string = Algorithm.Count(a)
	local neg5 = a:PushBack("문자열")
	local canary: string = 42
	print(neg1, neg2, neg3, neg4, neg5, canary)
end
--#endregion

print("IndexOf(a, 2) =", idx)
print("Count(a)      =", cnt)
print("chained       =", tostring(chained[1]) .. "," .. tostring(chained[2]) .. "  n=" .. chained.n)
print("a:Len()       =", a:Len(), " a[1] =", first, " a.n =", n)
return true
