--!strict
--[[
	`Trait.ImplWith` — 표 대신 **표를 만드는 함수**로 등록 (2026-10-14, 질문 AW).

	`Trait.ImplWith(트레이트, 토큰, function(deps) return { … } end)` 는 의존이 바뀌면 다시 불리는 등록입니다. 만드는 함수의
	타입은 `(deps) -> C` 라 **돌려주는 표가 `Trait.Impl` 의 표와 같은 검사**를 받아야 합니다.

	지키는 성질:
	- 돌려주는 표의 재정의 자리에 함수가 아닌 것 / 필수 함수가 빠짐 / 표가 아닌 것은 에러.
	- 만드는 함수 자리에 표를 넘기면 에러(그건 `Impl`).
	- 맞게 쓴 것은 통과.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 4 + CANARY 1 — "알려진 경계" 한 줄은 0건이어야 함)
]]
local stl = require("../../../../src")
local CircularDeque = stl.CircularDeque
local Trait, List, Stack, Deque = stl.Trait, stl.List, stl.Stack, stl.Deque

-- 맞게 쓴 것: 의존의 함수를 그대로 넘김
const History = Trait.New<<{ read Save: (any, any) -> any, read Load: (any) -> any }>>("History", {
	required = { "Save", "Load" },
	dependencies = { Stack },
})
Trait.ImplWith(History, CircularDeque.Token, function(deps)
	const stack = deps[Stack]
	return { Save = stack.Push, Load = stack.Pop }
end)
Trait.ImplWith(List, Trait.NewToken("Built"), function(_deps)
	return {
		Get = CircularDeque.Get,
		FirstIndex = CircularDeque.FirstIndex,
		LastIndex = CircularDeque.LastIndex,
		NextIndex = CircularDeque.NextIndex,
		PrevIndex = CircularDeque.PrevIndex,
	}
end)

-- NEG: 재정의 자리에 함수가 아닌 것
Trait.ImplWith(List, Trait.NewToken("BadOverride"), function(_deps)
	return {
		Get = CircularDeque.Get,
		FirstIndex = CircularDeque.FirstIndex,
		LastIndex = CircularDeque.LastIndex,
		NextIndex = CircularDeque.NextIndex,
		PrevIndex = CircularDeque.PrevIndex,
		Fold = "not a function",
	}
end)
-- NEG: 필수 함수가 빠짐(Load) — 값에 타입이 있을 때
local push: (any, any) -> any = CircularDeque.PushBack
Trait.ImplWith(History, Trait.NewToken("NoLoad"), function(_deps)
	return { Save = push }
end)
-- ⚠️ 알려진 경계(0건이어야 함): `deps` 는 `{ [any]: any }` 라 거기서 꺼낸 `any` 만 든 표는 빠진 필수 함수를 못 잡습니다
-- (`Trait.Impl` 에 같은 표를 넘기면 잡힘). 등록 때 런타임 검사가 사용자 줄로 알립니다(`spec.contracts` 20절).
Trait.ImplWith(History, Trait.NewToken("NoLoadAny"), function(deps)
	return { Save = deps[Stack].Push }
end)
-- NEG: 표가 아닌 것을 돌려줌
Trait.ImplWith(Deque, Trait.NewToken("Number"), function(_deps)
	return 5
end)
-- NEG: 만드는 함수 자리에 표
Trait.ImplWith(Deque, Trait.NewToken("Table"), {
	PushFront = CircularDeque.PushFront,
	PushBack = CircularDeque.PushBack,
	PopFront = CircularDeque.PopFront,
	PopBack = CircularDeque.PopBack,
	Front = CircularDeque.Front,
	Back = CircularDeque.Back,
})

local canary: string = 42

return { canary }
