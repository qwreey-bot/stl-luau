--!strict
--[[
	읽기만 하는 함수는 첫 인자가 공변 (2026-10-06, 질문 AC).

	읽기 함수는 `ArrRead<T>`(`read` 인덱서)를 받아 **더 좁은 원소의 배열**을 넓은 자리에 넘길 수
	있습니다(`Arr<number>` → `<<number?>>`, 하위 레코드 → 상위 레코드). 쓰는 함수는 `ArrData<T>`
	(불변)로 남아 넓어진 원소를 쓰지 못합니다. ⚠️ **두 배열을 합치는 함수**(`Concat`·`MergeSorted`)는
	`ArrData` 로 둡니다 — `ArrRead` 둘에서 `T` 를 풀면 솔버가 `number & string` 을 골라 결과 원소를
	`number` 에도 `string` 에도 넣을 수 있는 건전하지 않은 타입이 됐습니다(진단 0건, 실측).

	기대 진단: 10건 (NEG 9 + CANARY 1)
]]
local stl = require("../../../../src")
local Arr = stl.Arr
type Arr<T> = stl.Arr<T>
type Base = { name: string }
type Derived = { name: string, age: number }

local nums = Arr.Of(1, 2, 3)
local people: Arr<Derived> = Arr.Of({ name = "a", age = 1 }, { name = "b", age = 2 })

--[[ POS — 좁은 배열을 넓은 자리에(읽기) ]]
local maybe: Arr<number> = Arr.Map<<number?, number>>(nums, function(v)
	return v or 0
end)
local names: Arr<string> = Arr.Map<<Base, string>>(people, function(p)
	return p.name
end)
local found: Base? = Arr.Find<<Base>>(people, function(p)
	return p.name == "a"
end)
local sliced: Arr<Base> = Arr.Slice<<Base>>(people, 1, 1)
local counted: number = Arr.Count<<number?>>(nums)
local kept: Arr<Base> = Arr.Filter<<Base>>(people, function(p)
	return p.name ~= ""
end)
local sortedBase: Arr<Base> = Arr.Sort<<Base>>(people, function(a, b)
	return a.name < b.name
end)
local total: number = Arr.Fold<<Base, number>>(people, 0, function(acc, _p)
	return acc + 1
end)

--[[ NEG — 쓰는 함수는 불변으로 남음 ]]
local holed = Arr.Of<<number?>>(1, nil)
local neg1 = Arr.PushBack<<number?>>(nums, nil) -- Arr<number> 에 nil 을 쓰면 안 됨
local neg2 = Arr.Fill<<Base>>(people, { name = "z" }) -- Derived 배열에 Base 를 쓰면 안 됨
local neg3: Arr<number> = Arr.Map<<number?, number?>>(nums, function(v) -- 결과 타입은 그대로 검사
	return v
end)
local neg4 = Arr.Concat(nums, Arr.Of("x")) -- 합치는 함수는 불변(위 ⚠️) — 섞이면 에러
-- 읽기 전용 참조로는 소비형 제자리 변환을 못 함 — 넓혀 빌린 쪽이 원본에 넓은 원소를 쓰던 구멍(AC 리뷰)
local function borrow(list: stl.ArrRead<Base>)
	return Arr.CompactInplace(list)
end
-- 같은 종류의 다른 소비형 셋도(AC 2라운드 — MapInplace 를 ArrRead 로 바꿔도 아무것도 안 잡았음)
local function borrowMap(list: stl.ArrRead<number>)
	return Arr.MapInplace<<number, string>>(list, function(v)
		return tostring(v)
	end)
end
local function borrowFlat(list: stl.ArrRead<Arr<number>>)
	return Arr.FlatInplace<<number>>(list)
end
local function borrowFlatmap(list: stl.ArrRead<number>)
	return Arr.FlatmapInplace<<number, string>>(list, function(v)
		return tostring(v)
	end)
end
-- 읽기 함수도 토큰·마커를 요구(리터럴·table.pack 은 Arr 이 아님 — 2라운드 참고)
local negLiteral = Arr.Clone({ n = 2, 10, 20 })

local canary: string = 42

return {
	maybe,
	names,
	found,
	sliced,
	counted,
	kept,
	sortedBase,
	total,
	holed,
	neg1,
	neg2,
	neg3,
	neg4,
	borrow,
	borrowMap,
	borrowFlat,
	borrowFlatmap,
	negLiteral,
	canary,
}
