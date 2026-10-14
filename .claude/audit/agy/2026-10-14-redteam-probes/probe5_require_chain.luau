--!strict
-- probes/probe5_require_chain.luau
-- mod_consumer를 require하여 최종 사용하는 모듈

local consumer = require("./mod_consumer")

type Item<T> = { read __generics: { read Item: (T) -> T } }
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }

local a: Arr<number> = nil :: any
local ops = consumer.Stack.Of(a)

-- 1. consumer.Stack.Of(a).IsEmpty(a)가 boolean으로 잡히는가?
local ok_empty: boolean = ops.IsEmpty(a)
local bad_empty: string = ops.IsEmpty(a) -- NEG: boolean이어야 함!

-- 2. consumer.checkEmpty(ops, a)의 반환 타입 검사
local ok_check: boolean = consumer.checkEmpty(ops, a)
local bad_check: string = consumer.checkEmpty(ops, a) -- NEG: boolean이어야 함!

-- 3. 등록 표 검사
local function badPush(s: Arr<number>, item: string): Arr<number> return s end
local NEG_reg: consumer.StackImpl<Arr<number>, number> = {
	Push = badPush, -- NEG: item은 number여야 함
	Pop = function(s) return nil end,
}

local canary: string = 1
return { canary, ok_empty, bad_empty, ok_check, bad_check, NEG_reg }
