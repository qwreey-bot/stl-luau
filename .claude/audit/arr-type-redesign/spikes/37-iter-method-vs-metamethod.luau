--!strict
-- 교집합 타입에서 for-in 루프 변수 타입이 죽는 문제(35번)의 우회로.
--   `__iter` 메타메소드 대신 **메소드가 이터레이터 삼중항을 돌려주면** 어떤가?
-- for-in 이 컨테이너의 인덱서가 아니라 함수의 반환 타입을 보게 되므로 산다.
--
-- 두 변형을 비교한다:
--   A 정직한 선언 `(number?, T?)` — 끝에서 nil 을 돌려주는 것을 타입에 드러냄
--   B ipairs 식 선언 `(number, T)` — 끝의 nil 을 타입에서 숨김
--
-- 기대 진단: 5건 (NEG 4 + CANARY 1)

type Data<T> = { n: number, [number]: T }

--[[ A: 정직한 선언 ]]
local function stepA<T>(self: Data<T>, idx: number): (number?, T?)
	local nextIdx = idx + 1
	if nextIdx > self.n then
		return nil, nil
	end
	return nextIdx, self[nextIdx]
end
local function IterA<T>(self: Data<T>): (typeof(stepA), Data<T>, number)
	return stepA, self, 0
end

--[[ B: ipairs 식 선언. 끝에서 nil 을 돌려주지만 타입엔 안 드러낸다.
	Luau 자신의 ipairs 도 루프 변수가 옵셔널이 아니도록 이렇게 되어 있다. ]]
local function stepB<T>(self: Data<T>, idx: number): (number, T)
	local nextIdx = idx + 1
	if nextIdx > self.n then
		return nil :: any, nil :: any
	end
	return nextIdx, self[nextIdx]
end
local function IterB<T>(self: Data<T>): (typeof(stepB), Data<T>, number)
	return stepB, self, 0
end

local function Len<T>(self: Data<T>): number
	return self.n
end

type Ifce = {
	IterA: typeof(IterA),
	IterB: typeof(IterB),
	Len: typeof(Len),
}

type Arr<T> = Data<T> & Ifce

local a: Arr<number> = nil :: any

-- POS A: 옵셔널이라 산술에 바로 못 쓴다 (nil 검사를 강요함)
local sumA = 0
for _, v in a:IterA() do
	if v ~= nil then
		sumA += v
	end
end

-- POS B: 비옵셔널이라 그대로 쓸 수 있어야 한다 — 여기서 에러가 나면 B 는 실패다
local sumB = 0
for i, v in a:IterB() do
	sumB += i + v
end

-- NEG 1: A 의 값 타입이 살아있는가
for _, v in a:IterA() do
	local bad: string = v
	print(bad)
end

-- NEG 2: B 의 값 타입이 살아있는가
for _, v in a:IterB() do
	local bad: string = v
	print(bad)
end

-- NEG 3: B 의 인덱스 타입이 살아있는가
for i, _ in a:IterB() do
	local bad: string = i
	print(bad)
end

-- NEG 4: 없는 메소드
local nope = a:NoSuchMethod()

local canary: string = 42
return { sumA, sumB, nope, canary }
