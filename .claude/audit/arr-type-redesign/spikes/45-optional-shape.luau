--!strict
--[[
	Optional 착수 전 스파이크 (2026-09-26). 결론:

	1. ✅ 평범한 태그 유니온 + 네임스페이스 함수 — 좁히기, 제네릭 추론 모두 됨.
	2. ❌ 유니온 & 메소드 교집합(컨테이너들과 같은 방식) — 메소드의 `T` 가
	   `number | nil` 로 잡혀 "No valid instantiation" 으로 무너짐.
	   유니온 두 갈래(value: T / value: nil)에서 각각 T 를 뽑아버리는 것으로 보임.
	3. ⚠️ **같은 스코프에서 좁히기 전에 `o.value` 를 한 번이라도 읽으면**
	   (print 만 해도) 그 뒤 `if o.isPresent then o.value` 가 `number?` 로 굳어
	   **좁혀지지 않음.** 새 지역 별칭으로 좁히거나, 읽기가 다른 함수 안이거나,
	   태그만 먼저 읽는 것은 괜찮음.

	그래서 Optional 은 1번 모양으로 가고, 사용자가 `.value` 를 직접 읽을 일을
	줄이도록 `UnwrapOr` 같은 네임스페이스 함수를 줍니다.

	기대 진단: 9건 (NEG 5 + 캐비엇 3 + CANARY 1)
]]
local stl = require("../../../../src")

type Opt<T> = { isPresent: true, value: T } | { isPresent: false, value: nil }

local function Present<T>(v: T): Opt<T>
	return { isPresent = true, value = v }
end
local function UnwrapOr<T>(o: Opt<T>, fallback: T): T
	return if o.isPresent then o.value else fallback
end

--[[ 1. 평범한 태그 유니온 ]]
local a: Opt<number> = Present(3)
if a.isPresent then
	local okNarrow: number = a.value
	print(okNarrow)
end
local okUnwrap: number = UnwrapOr(a, 0)
-- 유니온 원소 배열은 명시적 타입 인자로
local list = stl.Arr.Of<<Opt<number>>>(Present(1), { isPresent = false, value = nil }, Present(3))
local okChain: stl.Arr<number> = list
	:Filter(function(o: Opt<number>)
		return o.isPresent
	end)
	:Map(function(o: Opt<number>): number
		return UnwrapOr(o, 0)
	end)

-- NEG 1: 좁힌 뒤 타입이 틀리면 잡혀야 한다
if a.isPresent then
	local neg1: string = a.value
	print(neg1)
end
-- NEG 2: UnwrapOr 의 fallback 타입이 다르면
local neg2 = UnwrapOr(a, "문자열")
-- NEG 3: 체이닝 결과 원소 타입
local neg3: string = okChain[1]
-- NEG 4: 좁히지 않은 value 를 number 로
local c: Opt<number> = Present(1)
local neg4: number = c.value
-- NEG 5: 콜백 안에서 좁히지 않고 value 를 number 로 돌려줌
local neg5 = list:Map(function(o: Opt<number>): number
	return o.value
end)

--[[ 2. 캐비엇 — 유니온 & 메소드 교집합은 T 를 못 푼다 ]]
type BIfce = { UnwrapOr: typeof(UnwrapOr) }
local b: Opt<number> & BIfce = nil :: any
local caveat1 = b:UnwrapOr(0) -- "No valid instantiation" (T 가 number | nil)

--[[ 3. 캐비엇 — 좁히기 전에 value 를 읽으면 그 스코프에서 좁히기가 죽는다 ]]
local p: Opt<number> = Present(2)
print(p.value) -- 합법적인 읽기. 그런데 이 줄 때문에:
if p.isPresent then
	local caveat2: number = p.value -- ⚠️ 여기서 number? 로 남아 에러 (좁혀졌으면 통과해야 함)
	print(caveat2)
end
-- 우회: 새 지역 별칭으로 좁히면 산다
local p2 = p
if p2.isPresent then
	local okAlias: number = p2.value
	print(okAlias)
end
-- 파라미터도 같은 함정
local function f(o: Opt<number>)
	print(o.value)
	if o.isPresent then
		local caveat3: number = o.value -- ⚠️ 같은 이유로 에러
		print(caveat3)
	end
end

local canary: string = 42
return { okUnwrap, okChain, neg2, neg3, neg4, neg5, caveat1, f, canary }
