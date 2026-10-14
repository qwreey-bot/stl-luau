--!nolint
-- 시제품 v2 진입점(시스템이 만든 가변인자 + 함수 번호, 테이블 토큰) 대 src. 실행: ( ulimit -v 1048576; timeout 300 luau -O2 bench.luau )
local P = require("./Traits")
local stl = require("../../../src")
local function best(fn: () -> ()): number
	local b = math.huge
	for _ = 1, 15 do
		local t = os.clock()
		fn()
		b = math.min(b, os.clock() - t)
	end
	return b
end
local N = 2000000
local src = stl.CircularDeque.Of(1, 2, 3)
local mine = P.Kinds.tag(stl.CircularDeque.Of(1, 2, 3), P.Kinds.CD)
local function pair(label: string, d: any, push: any, pop: any)
	print(string.format("  %-44s %6.1f ns/쌍", label, best(function()
		for i = 1, N do
			push(d, i)
			pop(d)
		end
	end) * 1e9 / N))
end
pair("직접", src, stl.CircularDeque.PushBack, stl.CircularDeque.PopBack)
pair("src Deque 진입점(손으로 펼침)", src, stl.Deque.PushBack, stl.Deque.PopBack)
pair("src Stack 진입점", src, stl.Stack.Push, stl.Stack.Pop)
pair("v2 Deque 진입점(시스템이 만듦)", mine, P.Deque.PushBack, P.Deque.PopBack)
pair("v2 Stack 진입점(시스템이 만듦)", mine, P.Stack.Push, P.Stack.Pop)
local full = P.Stack[P.Kinds.CD]
pair("v2 Stack[토큰].Push (종류를 앎)", mine, full.Push, full.Pop)
