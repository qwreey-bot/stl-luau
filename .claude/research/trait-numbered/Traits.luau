--!strict
-- 시제품 트레이트: Deque(여섯) 와 List 의 Fold(인자 셋) — 같은 덱 함수를 숫자 토큰으로 등록.
-- 진입점은 손으로 쓴 고정 인자판(이름 상수 / 번호)도 같이 둠(견주기).
local N = require("./TraitNum")
local stl = require("../../../src")
local CircularDeque: any, LinkedDeque: any = stl.CircularDeque, stl.LinkedDeque

const Deque = N.New("Deque", { "PushFront", "PushBack", "PopFront", "PopBack", "Front", "Back", "Fold", "Len" })
const CD = N.NewToken("CircularDeque")
const LD = N.NewToken("LinkedDeque")
for _, pair in { { CD, CircularDeque }, { LD, LinkedDeque } } do
	const m: any = pair[2]
	N.Impl(Deque, pair[1], {
		PushFront = m.PushFront,
		PushBack = m.PushBack,
		PopFront = m.PopFront,
		PopBack = m.PopBack,
		Front = m.Front,
		Back = m.Back,
		Fold = (stl.Trait.ImplOf(stl.List, m.New()) :: any).Fold,
		Len = m.Len,
	})
end

const PUSH_BACK, POP_BACK = Deque.Fn.PushBack, Deque.Fn.PopBack

-- 견주기: **테이블 토큰**을 키로 쓰는 트레이트 객체(직렬화에 안전한 쪽) — 같은 완성 표를 해시 칸에.
-- 약한 키 없음(버린 종류가 안 수거됨 — 숫자 판과 같은 조건) / 약한 키 있음(지금 src 와 같은 조건)
const DequeT: any = { name = "Deque", Fn = Deque.Fn }
DequeT[CircularDeque.Token] = Deque[CD]
DequeT[LinkedDeque.Token] = Deque[LD]
const DequeW: any = setmetatable({ name = "Deque", Fn = Deque.Fn }, { __mode = "k" })
DequeW[CircularDeque.Token] = Deque[CD]
DequeW[LinkedDeque.Token] = Deque[LD]
local function tableEntries(trait: any): (any, any)
	return function(self: any, item: any): any
		const impl = if type(self) == "table" then trait[rawget(self, "__type")] else nil
		if not impl then
			return error("miss", 0)
		end
		return impl[PUSH_BACK](self, item)
	end, function(self: any): any
		const impl = if type(self) == "table" then trait[rawget(self, "__type")] else nil
		if not impl then
			return error("miss", 0)
		end
		return impl[POP_BACK](self)
	end
end
const tablePush, tablePop = tableEntries(DequeT)
-- 테이블 토큰 + 시스템이 만든 가변인자 진입점(함수 번호)
local function autoTable(trait: any, fnName: string): (...any) -> ...any
	const fnNum = trait.Fn[fnName]
	return function(self: any, ...: any): ...any
		const impl = if type(self) == "table" then trait[rawget(self, "__type")] else nil
		if not impl then
			return error("miss", 0)
		end
		return impl[fnNum](self, ...)
	end
end
const autoTablePush, autoTablePop = autoTable(DequeW, "PushBack"), autoTable(DequeW, "PopBack")

-- 견주기: **절충** — 값에는 테이블 토큰(직렬화에 안전), 토큰이 자기 번호(`id`)를 듦. 트레이트는 번호로 배열을 찾고,
-- 찾은 표가 그 토큰의 것인지 정체성으로 확인(복사된 토큰은 번호가 같아도 정체성이 달라 "모르는 종류").
const HYB_CD = table.freeze({ name = "CircularDeque", id = CD })
const HYB_LD = table.freeze({ name = "LinkedDeque", id = LD })
const DequeH: any = { name = "Deque", Fn = Deque.Fn }
for _, pair in { { HYB_CD, Deque[CD] }, { HYB_LD, Deque[LD] } } do
	const full = table.clone(pair[2])
	full.__token = pair[1]
	DequeH[pair[1].id] = full
end
const hybridPush = function(self: any, item: any): any
	const tok = if type(self) == "table" then rawget(self, "__type") else nil
	const impl = if type(tok) == "table" then DequeH[tok.id] else nil
	if not impl or impl.__token ~= tok then
		return error("miss", 0)
	end
	return impl[PUSH_BACK](self, item)
end
const hybridPop = function(self: any): any
	const tok = if type(self) == "table" then rawget(self, "__type") else nil
	const impl = if type(tok) == "table" then DequeH[tok.id] else nil
	if not impl or impl.__token ~= tok then
		return error("miss", 0)
	end
	return impl[POP_BACK](self)
end
const weakPush, weakPop = tableEntries(DequeW)
const Hand = {
	-- 지금 src 와 같은 모양(이름 상수 필드)
	PushBackName = function(self: any, item: any): any
		const impl = if type(self) == "table" then Deque[rawget(self, "__type")] else nil
		if not impl then
			return error("miss", 0)
		end
		return impl.PushBack(self, item)
	end,
	PopBackName = function(self: any): any
		const impl = if type(self) == "table" then Deque[rawget(self, "__type")] else nil
		if not impl then
			return error("miss", 0)
		end
		return impl.PopBack(self)
	end,
	-- 번호(지역 상수)
	PushBackNum = function(self: any, item: any): any
		const impl = if type(self) == "table" then Deque[rawget(self, "__type")] else nil
		if not impl then
			return error("miss", 0)
		end
		return impl[PUSH_BACK](self, item)
	end,
	PopBackNum = function(self: any): any
		const impl = if type(self) == "table" then Deque[rawget(self, "__type")] else nil
		if not impl then
			return error("miss", 0)
		end
		return impl[POP_BACK](self)
	end,
}

const Auto = {
	PushBack = N.Entry(Deque, "PushBack"),
	PopBack = N.Entry(Deque, "PopBack"),
	Fold = N.Entry(Deque, "Fold"),
	Len = N.Entry(Deque, "Len"),
	PushBack2 = N.Entry2(Deque, "PushBack"),
	PopBack1 = N.Entry1(Deque, "PopBack"),
	Len1 = N.Entry1(Deque, "Len"),
	PushBackByName = N.EntryByName(Deque, "PushBack"),
	PopBackByName = N.EntryByName(Deque, "PopBack"),
}

-- stylua: ignore
return { Deque = Deque, CD = CD, LD = LD, Hand = Hand, Auto = Auto,
	TableKey = { PushBack = tablePush, PopBack = tablePop },
	AutoTable = { PushBack = autoTablePush, PopBack = autoTablePop },
	Hybrid = { PushBack = hybridPush, PopBack = hybridPop, CD = HYB_CD, LD = HYB_LD }, WeakKey = { PushBack = weakPush, PopBack = weakPop } }
