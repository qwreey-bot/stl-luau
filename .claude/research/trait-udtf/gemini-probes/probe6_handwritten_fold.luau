--!strict
-- probe6: Compare handwritten type vs type function output

type Arr<T> = { [number]: T }
type A = { read __probeA: true }

type ExpectedFold = <U>(list: Arr<A>, init: U, fn: (acc: U, item: A, idx: number) -> U) -> U

type HandWrittenTable = {
	read Fold: ExpectedFold?,
}

-- 1. 손으로 쓴 타입에 number 로 못박은 Fold 대입:
local _neg_handwritten: HandWrittenTable = {
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number
		return init
	end,
}

local canary: string = 1
