--!strict
-- quad 스타일: 네임스페이스 테이블 + PascalCase 생성자 **필드**
-- (`q.Source(0)` 처럼). __call 이 아니므로 순수 테이블이고, 필드는 평범한
-- 제네릭 함수라 타입 인자가 제대로 실린다 — 세 마리 토끼를 다 잡는지 본다.
type Data<T> = { n: number, [number]: T }

local function Map<T, G>(self: ArrT<T>, fn: (T) -> G): ArrT<G>
	return nil :: any
end
local function Push<T>(self: ArrT<T>, v: T): ArrT<T>
	return nil :: any
end
type ArrIfce = { Map: typeof(Map), Push: typeof(Push) }
type ArrT<T> = setmetatable<Data<T>, { __index: ArrIfce }>

-- 네임스페이스: 생성자는 PascalCase 필드
local function ArrCtor<T>(...: T): ArrT<T>
	return nil :: any
end
local function ArrSized<T>(len: number, fill: T): ArrT<T>
	return nil :: any
end
type Stl = { Arr: typeof(ArrCtor), ArrSized: typeof(ArrSized), IsArr: (any) -> boolean }
local stl = (nil :: any) :: Stl

-- A) 호출 + 원소 타입 추론
local a = stl.Arr(1, 2, 3)
local negA: string = a[1] -- 에러여야 함 (number)

-- B) 네임스페이스 오타
local negB = stl.Arrr -- 에러여야 함

-- C) 타입 바뀌는 체이닝
local chained = stl.Arr(1, 2):Map(function(x: number)
	return tostring(x)
end):Map(function(s: string)
	return #s > 0
end)
local negC: string = chained[1] -- 에러여야 함 (boolean)

-- D) 같은 타입 체이닝
local same = stl.Arr(1):Push(2)
local negD: string = same[1] -- 에러여야 함

-- E) 인스턴스 메소드 오타
local negE = a:NoSuch()

local canary: string = 42
return { a, negA, negB, chained, negC, same, negD, negE, canary }
