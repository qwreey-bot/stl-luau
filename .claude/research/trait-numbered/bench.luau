--!nolint
-- 숫자 토큰·배열 트레이트 시제품의 값. 실행: ( ulimit -v 1048576; timeout 300 luau -O2 bench.luau )
local stl = require("../../../src")
local P = require("./Traits")
local CircularDeque, LinkedDeque = stl.CircularDeque :: any, stl.LinkedDeque :: any
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
-- 같은 덱 함수를 부르는 값 둘: 테이블 토큰(src 그대로) / 숫자 토큰(같은 자료에 `__type` 만 바꿈)
local dt = CircularDeque.Of(1, 2, 3)
local dn = CircularDeque.Of(1, 2, 3); dn.__type = P.CD
local lt = LinkedDeque.Of(1, 2, 3)
local ln = LinkedDeque.Of(1, 2, 3); ln.__type = P.LD
local dh = CircularDeque.Of(1, 2, 3); dh.__type = P.Hybrid.CD
local lh = LinkedDeque.Of(1, 2, 3); lh.__type = P.Hybrid.LD
local function pair(label: string, d: any, push: any, pop: any)
	print(string.format("  %-58s %6.1f ns/쌍", label, best(function()
		for i = 1, N do
			push(d, i)
			pop(d)
		end
	end) * 1e9 / N))
end
local function mixed(label: string, a: any, b: any, push: any, pop: any)
	print(string.format("  %-58s %6.1f ns/쌍", label, best(function()
		for i = 1, N // 2 do
			push(a, i)
			pop(a)
			push(b, i)
			pop(b)
		end
	end) * 1e9 / N))
end
print("A. CircularDeque 넣고 꺼내기 한 쌍")
pair("직접 호출", dt, CircularDeque.PushBack, CircularDeque.PopBack)
pair("src 지금(테이블 토큰·약한 키·이름 필드, 손으로 펼친 진입점)", dt, stl.Deque.PushBack, stl.Deque.PopBack)
pair("테이블 토큰·약한 키·함수 번호", dt, P.WeakKey.PushBack, P.WeakKey.PopBack)
pair("테이블 토큰·약한 키, 시스템이 만든 가변인자 진입점", dt, P.AutoTable.PushBack, P.AutoTable.PopBack)
pair("테이블 토큰·약한 키 없음·함수 번호", dt, P.TableKey.PushBack, P.TableKey.PopBack)
pair("절충: 테이블 토큰의 번호로 배열 + 정체성 확인, 손으로", dh, P.Hybrid.PushBack, P.Hybrid.PopBack)
pair("숫자 토큰(배열)·이름 필드, 손으로", dn, P.Hand.PushBackName, P.Hand.PopBackName)
pair("숫자 토큰(배열)·함수 번호, 손으로", dn, P.Hand.PushBackNum, P.Hand.PopBackNum)
pair("숫자 토큰·함수 번호, 시스템이 만든 고정 인자 진입점", dn, P.Auto.PushBack2, P.Auto.PopBack1)
pair("숫자 토큰·함수 번호, 시스템이 만든 가변인자 진입점", dn, P.Auto.PushBack, P.Auto.PopBack)
pair("숫자 토큰·이름 문자열(상수 아님), 가변인자 진입점", dn, P.Auto.PushBackByName, P.Auto.PopBackByName)
local impl = P.Deque[P.CD]
pair("숫자 토큰 표에서 미리 꺼낸 함수(Deque[tok][Fn.PushBack])", dn, impl[P.Deque.Fn.PushBack], impl[P.Deque.Fn.PopBack])
print("A-2. 두 종류를 번갈아(CircularDeque·LinkedDeque)")
mixed("src 지금", dt, lt, stl.Deque.PushBack, stl.Deque.PopBack)
mixed("테이블 토큰, 시스템이 만든 가변인자 진입점", dt, lt, P.AutoTable.PushBack, P.AutoTable.PopBack)
mixed("테이블 토큰·약한 키 없음·함수 번호", dt, lt, P.TableKey.PushBack, P.TableKey.PopBack)
mixed("절충: 번호로 배열 + 정체성 확인", dh, lh, P.Hybrid.PushBack, P.Hybrid.PopBack)
mixed("숫자 토큰·함수 번호, 손으로", dn, ln, P.Hand.PushBackNum, P.Hand.PopBackNum)
mixed("숫자 토큰·가변인자 진입점", dn, ln, P.Auto.PushBack, P.Auto.PopBack)
print("B. 인자 수가 다른 것 — Len(인자 하나), Fold(인자 셋, 덱 3개)")
local function one(label: string, fn: () -> ())
	print(string.format("  %-58s %6.1f ns/호출", label, best(function()
		for _ = 1, N do
			fn()
		end
	end) * 1e9 / N))
end
local srcLen, autoLen, autoLen1 = stl.Collection.Len, P.Auto.Len, P.Auto.Len1
one("src Collection.Len", function() srcLen(dt) end)
one("숫자 토큰 Len, 고정 인자", function() autoLen1(dn) end)
one("숫자 토큰 Len, 가변인자", function() autoLen(dn) end)
local function add(acc: number, x: number): number return acc + x end
local srcFold, autoFold = stl.List.Fold, P.Auto.Fold
one("src List.Fold(덱 3개)", function() srcFold(dt, 0, add) end)
one("숫자 토큰 Fold, 가변인자(덱 3개)", function() autoFold(dn, 0, add) end)
