--!strict
--[[
	원소 타입이 **유니온**인 컨테이너 (2026-09-26).

	발견: `Arr<number?>` 처럼 원소가 유니온이면, `self: Arr<T>`(전체형)를 받는
	메소드가 전부 "No valid instantiation" 으로 무너졌다. 원인은 전체형에 섞인
	계약 조각(`ListCore<T, number>`) — 그 `Get` 이 `E?` 를 돌려주는데, `T`
	자체가 유니온이면 `self` 에서 `T` 를 역추론할 때 경계가 모순된다.
	**계약을 뺀 교집합에서는 멀쩡하다**(최소 재현으로 확인).

	해법: 메소드의 `self` 파라미터를 **데이터부(`ArrData<T>`)** 로 받고, 반환만
	전체형으로 한다. 체이닝과 음성 대조군은 그대로 산다.

	이 스파이크는 모든 컨테이너가 유니온 원소를 받아내는지를 고정한다.

	(2026-10-01, 질문 AB) 메타테이블·메소드를 걷어내 전체형이 데이터부 그 자체가
	되면서 위 원인(전체형에 섞인 계약 조각)은 **구조적으로 사라졌다.** 그래도
	유니온 원소가 네임스페이스 함수에서 무너지지 않는지는 계속 지킨다.

	기대 진단: 12건 (NEG 9 + CAVEAT 2 + CANARY 1 — 캐비엇은 지금 에러가 나는 한계 기록)
]]
local stl = require("../../../../src")
local Arr = stl.Arr
local Heap = stl.Heap
local HashSet = stl.HashSet
local HashMap = stl.HashMap
local TreeMap = stl.TreeMap
type Arr<T> = stl.Arr<T>
type ArrView<T> = stl.ArrView<T>

--[[ Arr<number?> — 가장 흔한 유니온 ]]
local maybe = stl.Arr.Of<<number?>>(1, nil, 3)
local okF = Arr.Filter(maybe, function(v: number?)
	return v ~= nil
end)
local okM: Arr<number> = Arr.Map(maybe, function(v: number?): number
	return v or 0
end)
local okC: number = Arr.Count(maybe, function(v: number?)
	return v == nil
end)
local okS = Arr.Sort(maybe)
local okP = Arr.PushBack(maybe, nil)
local okCl: Arr<number?> = Arr.Clone(maybe)
local okG: number? = Arr.Get(maybe, 1)
local okFold: number = Arr.Fold(maybe, 0, function(acc: number, v: number?)
	return acc + (v or 0)
end)
-- 3단 타입 변환 체이닝이 유니온을 지나서도 산다
local okChain: Arr<string> = Arr.Filter(Arr.Map(Arr.Map(maybe, function(v: number?): number
		return v or 0
	end), function(v: number): string
		return tostring(v)
	end), function(s: string)
		return #s > 0
	end)

--[[ Arr<number | string> ]]
local mixed = stl.Arr.Of<<number | string>>(1, "a")
local okMixed = Arr.Filter(mixed, function(v: number | string)
	return type(v) == "number"
end)

--[[ 다른 컨테이너들 ]]
local hs = stl.HashSet.Of<<number | string>>(1, "a")
local okHs: boolean = HashSet.Has(hs, "a")
local okHsU = HashSet.Union(hs, hs)
local hm = stl.HashMap.New<<string, number?>>()
HashMap.Set(hm, "a", nil :: any)
local okHm: number? = HashMap.GetOr(hm, "a", 0)
local tm = stl.TreeMap.New<<number, string | boolean>>(stl.Common.compareNumber)
TreeMap.Set(tm, 1, true)
local okTm = TreeMap.Get(tm, 1)
local hp = stl.Heap.New<<number | string>>(function(a: number | string, b: number | string)
	return tostring(a) < tostring(b)
end)
local okHp = Heap.Push(Heap.Push(hp, 1), "b")

--[[ NEG ]]
local neg1: string = okM[1]                      -- Map 결과는 number
local neg2: number = maybe[1]                    -- 원소는 number?
local neg3 = Arr.PushBack(maybe, "문자열")            -- 원소 타입이 다름
local neg4 = Arr.NoSuch(maybe)
local neg5: Arr<number> = okChain                -- 체인 결과는 Arr<string>
local neg6 = Arr.PushBack(mixed, true)                -- number | string 에 boolean
local neg7 = HashSet.Add(hs, true)
local neg8: number = TreeMap.GetOr(tm, 1, false)          -- 값은 string | boolean
local neg9 = Heap.Push(hp, true)
--[[ 캐비엇(한계 — 지금은 에러, M0 3라운드): 원소가 유니온이면 함수 묶음 계약에
	모듈을 담을 수 없습니다. 계약의 `Get: (C, I) -> E?` 에서 `E` 가 이미 `number?`
	면 `E?` 와 모듈 `Get` 의 `T?` 를 맞추는 역추론이 모순됩니다 — 옛 교집합 시절
	이 스파이크가 막던 원인이 함수 묶음 쪽에서 다시 나타난 것. 우회는 캐스트.
	Luau 가 좋아져 통과하기 시작하면 건수가 줄어 배터리가 알려줍니다. ]]
local caveat1: stl.ListOps<Arr<number?>, number?, number> = Arr
local caveat2: stl.MapOps<stl.HashMap<string, number?>, string, number?> = HashMap
local canary: string = 42

return {
	okF, okM, okC, okS, okP, okCl, okG, okFold, okChain, okMixed, okHs, okHsU, okHm, okTm, okHp,
	neg1, neg2, neg3, neg4, neg5, neg6, neg7, neg8, neg9, caveat1, caveat2, canary,
}
