--!strict
-- 함수 번호를 타입에서는 문자열 필드 이름으로 보이게: Fn.Push 의 타입은 "Push"(런타임은 1)
type D = { read __type: number, n: number }
type Full = {
	read Push: (d: D, item: number) -> D,
	read Pop: (d: D) -> number?,
}
type Fn = { read Push: "Push", read Pop: "Pop" }
local Fn: Fn = { Push = 1, Pop = 2 } :: any
local Stack: { [number]: Full } = {} :: any

local d: D = { __type = 1, n = 0 }
local push = Stack[d.__type][Fn.Push] -- 기대: (D, number) -> D
local ok: D = push(d, 5)
local bad1: string = push(d, 5) -- NEG: 반환 타입
local bad2 = push(d, "x") -- NEG: 인자 타입
local pop = Stack[d.__type][Fn.Pop]
local bad3: string = pop(d) -- NEG: number? 는 string 이 아님
local nope = Stack[d.__type][Fn.Peek] -- NEG: Fn 에 없는 이름
return { ok, bad1, bad2, bad3, nope }
