--!strict
-- quad typing-limits §1-2(a): setmetatable + "콜백이 self 핸들을 받는" 재귀 제네릭
-- 조합에서 Luau 0.733 솔버 버그(모순된 진단 2개)를 만났다고 기록돼 있다.
-- stl-luau 의 CallBack 은 3번째 인자로 컨테이너 자신을 받으므로 **정확히 그 모양**이다.
-- 어디까지가 안전한 경계인지 잰다. (luau 0.734)
type Data<T> = { n: number, [number]: T }

--#region 경계 1: 콜백이 원소만 받음 (self 핸들 없음)
local function MapEl<T, G>(self: A1<T>, fn: (T) -> G): A1<G>
	return nil :: any
end
type I1 = { Map: typeof(MapEl) }
type A1<T> = setmetatable<Data<T>, { __index: I1 }>

local x1 = (nil :: any) :: A1<number>
local r1 = x1:Map(function(v: number)
	return tostring(v)
end)
local neg1: number = r1[1] -- 에러여야 함 (string)
--#endregion

--#region 경계 2: 콜백이 self 핸들을 받음 (quad 가 깨진다고 한 모양)
local function MapSelf<T, G>(self: A2<T>, fn: (el: T, idx: number, arr: A2<T>) -> G): A2<G>
	return nil :: any
end
type I2 = { Map: typeof(MapSelf) }
type A2<T> = setmetatable<Data<T>, { __index: I2 }>

local x2 = (nil :: any) :: A2<number>
local r2 = x2:Map(function(el: number, idx: number, arr: A2<number>)
	return tostring(el)
end)
local neg2: number = r2[1] -- 에러여야 함 (string)

-- 콜백 안에서 self 를 다시 호출하는 중첩 (quad 실사용 계약)
local nested = x2:Map(function(el: number, idx: number, arr: A2<number>)
	local inner = arr:Map(function(e2: number, i2: number, a2: A2<number>)
		return e2 > 0
	end)
	local _innerEl: boolean? = inner[1]
	return tostring(el)
end)
local neg3: number = nested[1] -- 에러여야 함 (string)
--#endregion

--#region 경계 3: 교집합(&) 버전 — 대조군 (선언 순서 주의: 함수가 먼저)
local function MapSelf3<T, G>(self: A3<T>, fn: (el: T, idx: number, arr: A3<T>) -> G): A3<G>
	return nil :: any
end
type I3 = { Map: typeof(MapSelf3) }
type A3<T> = Data<T> & I3
local x3 = (nil :: any) :: A3<number>
local r3 = x3:Map(function(el: number, idx: number, arr: A3<number>)
	return tostring(el)
end)
local neg4: number = r3[1] -- 에러여야 함
--#endregion

local canary: string = 42
return { r1, neg1, r2, neg2, nested, neg3, r3, neg4, canary }
