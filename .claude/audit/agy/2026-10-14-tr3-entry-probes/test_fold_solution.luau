--!strict
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }

local function Fn<F>(): F
	return nil :: any
end

-- Fold 의 진입점 타입:
type FoldEntry = <Self, E, I, U>(list: Self & ItemIndex<E, I>, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U) -> U

-- Fold 의 완성 표 타입 (Self, E, I 가 바깥에서 주어짐):
type FoldOp<Self, E, I> = <U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U) -> U

-- 만약 ListEntries 에 FoldOp 를 반환하는 팩토리나 헬퍼를 둔다면?
-- 또는 ListEntries.Fold 가 진입점 타입일 때,
-- FoldOp 를 FoldEntry 로부터 유도할 수 있는가?
-- 아니면 FoldEntry 를 FoldOp 로부터 유도할 수 있는가?

local canary: string = 1
