--!strict
-- ArrStatic 이 실제로 쓰이는 스태틱을 다 담았는지 / 무엇이 좁아졌는지 확인.
local arr = require("../../../../src/arr")

-- POS: 스태틱으로 남긴 것들 — 전부 통과해야 함
local p1 = arr.sized(3, 0)
local p2 = arr.from_table({ 1, 2, 3 })
local p3 = arr.clone_from_table({ 1, 2, 3 })
local p4 = arr.pack(1, 2, 3)
local p5 = arr.range(5, 2, 4)
local p6 = arr.is_arr(p1)
local p7 = arr.merge(p1, p2)
local p8 = arr.from_func(3, function(i: number)
	return i
end)

-- NARROW: 인스턴스 메소드의 점 호출. 이전에는 타입이 잡혔고 지금은 안 잡힙니다.
local n1 = arr.push(p1, 1)
local n2 = arr.push_many(p1, 1, 2)
local n3 = arr.erase_inplace(p1, 1, 2)

-- NEG: 아예 존재하지 않는 스태틱. 반드시 에러여야 함
local neg = arr.definitely_not_a_real_static

-- CANARY
local canary: string = 42

return { p1, p2, p3, p4, p5, p6, p7, p8, n1, n2, n3, neg, canary }
