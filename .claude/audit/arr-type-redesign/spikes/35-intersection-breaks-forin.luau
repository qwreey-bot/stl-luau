--!strict
-- 최소 재현: 교집합 타입은 for-in 루프 변수의 타입을 잃는다.
-- (__iter 와 무관하다 — 인덱서만 있으면 되는데 교집합이면 못 본다)

type Plain = { n: number, [number]: number }
type Inter = { n: number, [number]: number } & { Len: (self: any) -> number }
type Meta = setmetatable<{ n: number, [number]: number }, { __index: { Len: (self: any) -> number } }>

local p = (nil :: any) :: Plain
local i = (nil :: any) :: Inter
local m = (nil :: any) :: Meta

-- 직접 인덱싱은 셋 다 되는가?
local pIdx: string = p[1] -- 에러여야 함
local iIdx: string = i[1] -- 에러여야 함
local mIdx: string = m[1] -- 에러여야 함

-- for-in 은?
for _, v in p do
	local pv: string = v -- 에러여야 함
end
for _, v in i do
	local iv: string = v -- 에러여야 함
end
for _, v in m do
	local mv: string = v -- 에러여야 함
end

local canary: string = 42
return { canary }
