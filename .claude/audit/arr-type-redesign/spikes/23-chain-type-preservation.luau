--!strict
-- quad typing-limits §1: "Foo<T> 안에서 -> Foo<U> 를 반환" 하면 타입 안전성이
-- **조용히** 사라진다. arr 의 map/flatmap/reduce 가 정확히 그 모양이다.
-- 여기서 실제로 새는지, 체이닝 깊이에 따라 어떤지 잰다.
local arr = require("../../../../src-old/arr")

-- 1) 타입이 바뀌는 단일 map: Arr<number> -> Arr<string>
local strs = arr(1, 2, 3):map(function(x: number)
	return tostring(x)
end)
local neg1: number = strs[1] -- 에러여야 함 (string 인데 number 에 대입)

-- 2) 타입이 바뀌는 체이닝 3단: number -> string -> boolean -> number
local chained = arr(1, 2, 3)
	:map(function(x: number)
		return tostring(x)
	end)
	:map(function(s: string)
		return #s > 0
	end)
	:map(function(b: boolean)
		return b and 1 or 0
	end)
local neg2: string = chained[1] -- 에러여야 함 (number 인데 string 에 대입)

-- 3) 체이닝 후 없는 메소드
local neg3 = strs:no_such_method()

-- 4) 같은 타입으로만 도는 체이닝(push 는 Arr<T> -> Arr<T>) — 이건 안전해야 함
local same = arr(1, 2):push(3):push(4)
local neg4: string = same[1] -- 에러여야 함

-- 5) reduce 의 누적 타입
local total = arr(1, 2, 3):reduce(function(acc: number, v: number)
	return acc + v
end, 0)
local neg5: string = total -- 에러여야 함

local canary: string = 42
return { strs, neg1, chained, neg2, neg3, same, neg4, total, neg5, canary }
