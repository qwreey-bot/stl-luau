--!nocheck
-- (벤치는 타입 검사 대상이 아닙니다 — 맨 람다를 일부러 씀)
-- 시제품의 속도 (papers/07): 기본 구현(프리미티브 경유) 대 직접 구현. `luau -O2`, 여러 번 재서 최소값.
local stl = require("../../../src")
local Trait2 = require("./Trait2")
local Traits = require("./Traits")
local C = require("./Containers")
local Algo = require("./Algo")
local Arr, Deque = stl.Arr, stl.Deque

local function best(f, reps)
	local m = math.huge
	for _ = 1, 21 do
		local t = os.clock()
		for _ = 1, reps do f() end
		t = os.clock() - t
		if t < m then m = t end
	end
	return m / reps
end
local add = function(acc, v) return acc + v end
local double = function(v) return v * 2 end

-- 구현을 인자로 받는 "일반" 기본 구현(등록 때 특수화하지 않는 모양) — 비교용
local function genericFold(ops, self, init, fn)
	local acc, idx = init, ops.FirstIndex(self)
	while idx ~= nil do
		acc = fn(acc, ops.Get(self, idx))
		idx = ops.NextIndex(self, idx)
	end
	return acc
end

for _, N in { 10, 1000, 100000 } do
	local arr, dq, ll = Arr.Of(), Deque.New(), C.LinkedList.New()
	for i = 1, N do
		Arr.PushBack(arr, i); Deque.PushBack(dq, i); C.LinkedList.PushBack(ll, i)
	end
	local reps = math.max(1, math.floor(400000 / N))
	-- 기본 구현만 받은 표(재정의 없는 Arr)를 따로 만들어 "Arr 의 기본 구현" 을 잼
	local PlainArr = stl.Trait.NewType("PlainArr")
	Trait2.Impl(Traits.List, PlainArr, {
		Get = Arr.Get, FirstIndex = Arr.FirstIndex, LastIndex = Arr.LastIndex,
		NextIndex = Arr.NextIndex, PrevIndex = Arr.PrevIndex,
	})
	Trait2.Impl(Traits.Build, PlainArr, { New = function() return Arr.Of() end, PushBack = Arr.PushBack })
	local arrDefault, arrSeqDefault = Traits.List.impls[PlainArr], Trait2.ImplOf(Traits.Seq, { __type = PlainArr })
	local dqOps, llOps = Trait2.ImplOf(Traits.List, dq), Trait2.ImplOf(Traits.List, ll)
	local dqSeq, llSeq = Trait2.ImplOf(Traits.Seq, dq), Trait2.ImplOf(Traits.Seq, ll)

	local direct = best(function() return Arr.Fold(arr, 0, add) end, reps)
	local viaAlgo = best(function() return Algo.Fold(arr, 0, add) end, reps)
	local arrDef = best(function() return arrDefault.Fold(arr, 0, add) end, reps)
	local arrGen = best(function() return genericFold(arrDefault, arr, 0, add) end, reps)
	local dqDef = best(function() return dqOps.Fold(dq, 0, add) end, reps)
	local dqHand = best(function() local acc = 0; for _, v in Deque.Iter(dq) do acc = add(acc, v) end; return acc end, reps)
	local llDef = best(function() return llOps.Fold(ll, 0, add) end, reps)
	local llHand = best(function() local acc, node = 0, ll.head; while node do acc = add(acc, node.value); node = node.next end; return acc end, reps)
	print(string.format("Fold N=%-6d Arr 직접 %8.2fus | Algo 경유(Arr 재정의) %8.2fus (%.2f) | Arr 기본 %8.2fus (%.2f) | Arr 일반형 %8.2fus (%.2f) || Deque 기본 %8.2fus, 손으로 %8.2fus (%.2f) || LinkedList 기본 %8.2fus, 손으로 %8.2fus (%.2f)",
		N, direct * 1e6, viaAlgo * 1e6, viaAlgo / direct, arrDef * 1e6, arrDef / direct, arrGen * 1e6, arrGen / direct,
		dqDef * 1e6, dqHand * 1e6, dqDef / dqHand, llDef * 1e6, llHand * 1e6, llDef / llHand))

	local mDirect = best(function() return Arr.Map(arr, double) end, reps)
	local mArrDef = best(function() return arrSeqDefault.Map(arr, double) end, reps)
	local mDq = best(function() return dqSeq.Map(dq, double) end, reps)
	local mDqHand = best(function() local out = Deque.New(); for _, v in Deque.Iter(dq) do Deque.PushBack(out, double(v)) end; return out end, reps)
	local mLl = best(function() return llSeq.Map(ll, double) end, reps)
	print(string.format("Map  N=%-6d Arr 직접 %8.2fus | Arr 기본 %8.2fus (%.2f) || Deque 기본 %8.2fus, 손으로 %8.2fus (%.2f) || LinkedList 기본 %8.2fus",
		N, mDirect * 1e6, mArrDef * 1e6, mArrDef / mDirect, mDq * 1e6, mDqHand * 1e6, mDq / mDqHand, mLl * 1e6))
end
-- 저절로 따라오는 구현의 조회 비용: 처음 한 번(만들기) 대 그 뒤(캐시)
do
	local token = stl.Trait.NewType("Fresh")
	Trait2.Impl(Traits.List, token, { Get = Arr.Get, FirstIndex = Arr.FirstIndex, LastIndex = Arr.LastIndex, NextIndex = Arr.NextIndex, PrevIndex = Arr.PrevIndex })
	Trait2.Impl(Traits.Build, token, { New = function() return Arr.Of() end, PushBack = Arr.PushBack })
	local value = { __type = token }
	local t = os.clock(); Trait2.ImplOf(Traits.Seq, value); local first = os.clock() - t
	local R = 1000000
	local cached = best(function() for _ = 1, R do Trait2.ImplOf(Traits.Seq, value) end end, 1)
	local direct = best(function() for _ = 1, R do local _ = Traits.Seq.impls[token] end end, 1)
	print(string.format("저절로 따라오는 구현: 처음 %.1fus(만들기), 그 뒤 호출당 %.0fns (표 직접 조회 %.0fns)", first * 1e6, cached / R * 1e9, direct / R * 1e9))
end
