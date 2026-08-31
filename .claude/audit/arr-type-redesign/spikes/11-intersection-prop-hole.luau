--!strict
-- 함수 타입과 테이블 타입의 교집합에서, 없는 속성 접근이 잡히는가?
type S = { a: number }

local table_only = (nil :: any) :: S
local fn_and_table = (nil :: any) :: (<T>(...T) -> T) & S

local ok1: number = table_only.a
local ok2: number = fn_and_table.a

local neg1 = table_only.nope -- 반드시 에러
local neg2 = fn_and_table.nope -- 반드시 에러여야 하는데?

local canary: string = 42
return { ok1, ok2, neg1, neg2, canary }
