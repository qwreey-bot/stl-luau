--!nolint
-- 시제품의 값: 지금의 트레이트(`src`) 대 "다시 만들 수 있는 구현"(`Trait3`).
-- 실행: ( ulimit -v 1048576; timeout 300 luau -O2 .claude/research/trait-rebuild/bench.luau )
local stl = require("../../../src")
local Trait3 = require("./Trait3")
local T = require("./Traits")
local CircularDeque: any, LinkedDeque: any = stl.CircularDeque, stl.LinkedDeque
local Trait: any = stl.Trait

local function best(reps: number, fn: () -> ()): number
	local bestTime = math.huge
	for _ = 1, reps do
		local t = os.clock()
		fn()
		bestTime = math.min(bestTime, os.clock() - t)
	end
	return bestTime
end
local function row(label: string, ns: number, unit: string)
	print(string.format("  %-66s %7.1f %s", label, ns, unit))
end

--[[ A. Stack 에 넣고 꺼내는 한 쌍 — 같은 CircularDeque 값 ]]
do
	print("A. Stack 넣고 꺼내기 한 쌍 (CircularDeque, ns/쌍)")
	local N = 2000000
	local d = CircularDeque.Of(1, 2, 3)
	local function pair(label: string, push: any, pop: any)
		row(label, best(15, function()
			for i = 1, N do
				push(d, i)
				pop(d)
			end
		end) * 1e9 / N, "ns")
	end
	pair("직접: CircularDeque.PushBack + PopBack", CircularDeque.PushBack, CircularDeque.PopBack)
	pair("src   Deque 진입점", stl.Deque.PushBack, stl.Deque.PopBack)
	pair("src   Stack 진입점 (기본 구현이 감싸 부름)", stl.Stack.Push, stl.Stack.Pop)
	local srcImpl: any = Trait.ImplOf(stl.Stack, d)
	pair("src   └ 완성 표에서 미리 꺼내 둔 함수 (감싼 함수)", srcImpl.Push, srcImpl.Pop)
	pair("시제품 Stack 진입점 — 지금 모양 (표에 덱 함수 자체)", T.Entry.Push, T.Entry.Pop)
	pair("시제품 Stack 진입점 — 구현 찾기를 안에 펼침", T.Inline.Push, T.Inline.Pop)
	pair("시제품 Stack 진입점 — 함수별 표", T.ByFn.Push, T.ByFn.Pop)
	local protoImpl = Trait3.ImplOf(T.Stack, d)
	pair("시제품 └ 완성 표에서 미리 꺼내 둔 함수 (= 덱 함수)", protoImpl.Push, protoImpl.Pop)
	assert(protoImpl.Push == CircularDeque.PushBack)
end

--[[ A-2. 한 호출 자리가 두 종류를 번갈아 봄 ]]
do
	print("A-2. 두 종류를 번갈아 (CircularDeque·LinkedDeque 각각 한 쌍씩, ns/쌍)")
	local N = 1000000
	local a, b = CircularDeque.Of(1, 2, 3), LinkedDeque.Of(1, 2, 3)
	local function pair(label: string, push: any, pop: any)
		row(label, best(15, function()
			for i = 1, N do
				push(a, i)
				pop(a)
				push(b, i)
				pop(b)
			end
		end) * 1e9 / (N * 2), "ns")
	end
	local cPush, cPop, lPush, lPop =
		CircularDeque.PushBack, CircularDeque.PopBack, LinkedDeque.PushBack, LinkedDeque.PopBack
	row("직접 (각 모듈의 함수)", best(15, function()
		for i = 1, N do
			cPush(a, i)
			cPop(a)
			lPush(b, i)
			lPop(b)
		end
	end) * 1e9 / (N * 2), "ns")
	pair("src   Deque 진입점", stl.Deque.PushBack, stl.Deque.PopBack)
	pair("src   Stack 진입점 (감싼 것)", stl.Stack.Push, stl.Stack.Pop)
	pair("시제품 Stack 진입점 — 지금 모양", T.Entry.Push, T.Entry.Pop)
	pair("시제품 Stack 진입점 — 안에 펼침", T.Inline.Push, T.Inline.Pop)
	pair("시제품 Stack 진입점 — 함수별 표", T.ByFn.Push, T.ByFn.Pop)
end

--[[ B. 리스트의 기본 구현 — 부를 때 꺼냄(src) 대 만들 때 붙잡음(시제품) ]]
do
	print("B. List 기본 구현 (진입점 경유)")
	local function add(acc: number, item: number): number
		return acc + item
	end
	for _, kind in { { "CircularDeque", CircularDeque }, { "LinkedDeque", LinkedDeque } } do
		for _, size in { 3, 1000 } do
			local d = kind[2].New()
			for i = 1, size do
				kind[2].PushBack(d, i * 10)
			end
			local last = size * 10
			local calls = if size == 3 then 1000000 else 4000
			local unit = if size == 3 then "ns/호출" else "ns/원소"
			local div = if size == 3 then calls else calls * size
			local function one(label: string, fn: () -> ())
				row(string.format("%-13s n=%-4d %s", kind[1], size, label), best(15, function()
					for _ = 1, calls do
						fn()
					end
				end) * 1e9 / div, unit)
			end
			local srcIndexOf, srcContains, srcFold = stl.List.IndexOf, stl.List.Contains, stl.List.Fold
			local pIndexOf, pContains, pFold = T.Entry.IndexOf, T.Entry.Contains, T.Entry.Fold
			one("IndexOf(끝)  src", function()
				srcIndexOf(d, last)
			end)
			one("IndexOf(끝)  시제품", function()
				pIndexOf(d, last)
			end)
			one("Contains(끝) src   (IndexOf 를 한 번 더 거침)", function()
				srcContains(d, last)
			end)
			one("Contains(끝) 시제품", function()
				pContains(d, last)
			end)
			one("Fold         src", function()
				srcFold(d, 0, add)
			end)
			one("Fold         시제품", function()
				pFold(d, 0, add)
			end)
		end
	end
end

--[[ C. 등록 시점의 값 — 종류 하나에 Deque 를 등록하고 Stack 이 따라오게, 그 위에 재정의 ]]
do
	print("C. 등록 비용 (종류 하나당, μs)")
	local KINDS = 20000
	local dequeNames = { "PushFront", "PushBack", "PopFront", "PopBack", "Front", "Back" }
	local function fn() end
	local function dequeTable(): { [string]: any }
		local t = {}
		for _, name in dequeNames do
			t[name] = fn
		end
		return t
	end
	-- 지금의 시스템: 같은 모양의 트레이트를 따로 만듦(내장 트레이트를 더럽히지 않게)
	local function srcRound(): (number, number, number)
		local SDeque = Trait.New("Deque", { required = dequeNames })
		local SStack = Trait.New("Stack", {
			dependencies = { SDeque },
			defaults = function(_ops: any, deps: any)
				local deque = deps[SDeque]
				return {
					Push = function(self: any, item: any): any
						return deque.PushBack(self, item)
					end,
					Pop = function(self: any): any
						return deque.PopBack(self)
					end,
					Peek = function(self: any): any
						return deque.Back(self)
					end,
				}
			end,
		})
		local tokens, values, tables = table.create(KINDS), table.create(KINDS), table.create(KINDS)
		for i = 1, KINDS do
			tokens[i] = Trait.NewToken("K")
			values[i] = { __type = tokens[i] }
			tables[i] = dequeTable()
		end
		local t0 = os.clock()
		for i = 1, KINDS do
			Trait.Impl(SDeque, tokens[i], tables[i])
		end
		local t1 = os.clock()
		for i = 1, KINDS do
			Trait.ImplOf(SStack, values[i])
		end
		local t2 = os.clock()
		for i = 1, KINDS do
			Trait.Impl(SStack, tokens[i], { Push = fn })
		end
		local t3 = os.clock()
		return t1 - t0, t2 - t1, t3 - t2
	end
	local function protoRound(dependents: number): (number, number, number)
		local PDeque = Trait3.New("Deque", { required = dequeNames })
		local PStack = Trait3.New("Stack", {
			dependencies = { PDeque },
			defaults = function(_ops: any, deps: any)
				local deque = deps[PDeque]
				return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
			end,
		})
		-- 스택에 의존하는 트레이트(연쇄의 값을 보려고)
		local uppers = {}
		for u = 1, dependents do
			uppers[u] = Trait3.New("Upper" .. u, {
				dependencies = { PStack },
				defaults = function(_ops: any, deps: any)
					local stack = deps[PStack]
					return { Save = stack.Push, Load = stack.Pop }
				end,
			})
		end
		local tokens, values, tables = table.create(KINDS), table.create(KINDS), table.create(KINDS)
		for i = 1, KINDS do
			tokens[i] = table.freeze({ name = "K" })
			values[i] = { __type = tokens[i] }
			tables[i] = dequeTable()
		end
		local t0 = os.clock()
		for i = 1, KINDS do
			Trait3.Impl(PDeque, tokens[i], tables[i])
		end
		local t1 = os.clock()
		for i = 1, KINDS do
			Trait3.ImplOf(PStack, values[i])
		end
		local t2 = os.clock()
		for u = 1, dependents do
			for i = 1, KINDS do
				Trait3.ImplOf(uppers[u], values[i])
			end
		end
		local t3 = os.clock()
		for i = 1, KINDS do
			Trait3.Impl(PStack, tokens[i], { Push = fn })
		end
		local t4 = os.clock()
		return t1 - t0, t2 - t1, t4 - t3
	end
	local function three(label: string, round: () -> (number, number, number))
		local a, b, c = math.huge, math.huge, math.huge
		for _ = 1, 7 do
			local x, y, z = round()
			a, b, c = math.min(a, x), math.min(b, y), math.min(c, z)
		end
		print(
			string.format(
				"  %-44s Deque 등록 %5.2f | Stack 따라오기 %5.2f | 그 위에 재정의 %5.2f",
				label,
				a * 1e6 / KINDS,
				b * 1e6 / KINDS,
				c * 1e6 / KINDS
			)
		)
	end
	three("src (재정의 = 제자리에서 키를 고침)", srcRound)
	three("시제품 (재정의 = 다시 만듦, 위에 의존 0)", function()
		return protoRound(0)
	end)
	three("시제품 (위에 의존하는 트레이트 1 — 연쇄)", function()
		return protoRound(1)
	end)
	three("시제품 (위에 의존하는 트레이트 4 — 연쇄)", function()
		return protoRound(4)
	end)
end

--[[ D. 메모리 — 종류 하나당(Deque 등록 + Stack 따라옴) ]]
do
	print("D. 메모리 (종류 하나당 바이트 — Deque 등록 + Stack 이 따라옴, 토큰·넘긴 표 포함)")
	local KINDS = 20000
	local dequeNames = { "PushFront", "PushBack", "PopFront", "PopBack", "Front", "Back" }
	local function fn() end
	local function measure(label: string, build: (keep: { any }) -> ())
		collectgarbage("collect")
		local before = gcinfo()
		local keep = {}
		build(keep)
		collectgarbage("collect")
		local after = gcinfo()
		row(label, (after - before) * 1024 / KINDS, "B")
		return keep
	end
	local function dequeTable(): { [string]: any }
		local t = {}
		for _, name in dequeNames do
			t[name] = fn
		end
		return t
	end
	local k1 = measure("src", function(keep)
		local SDeque = Trait.New("Deque", { required = dequeNames })
		local SStack = Trait.New("Stack", {
			dependencies = { SDeque },
			defaults = function(_ops: any, deps: any)
				local deque = deps[SDeque]
				return {
					Push = function(self: any, item: any): any
						return deque.PushBack(self, item)
					end,
					Pop = function(self: any): any
						return deque.PopBack(self)
					end,
					Peek = function(self: any): any
						return deque.Back(self)
					end,
				}
			end,
		})
		keep[1], keep[2] = SDeque, SStack
		for i = 1, KINDS do
			local tok = Trait.NewToken("K")
			keep[i + 2] = tok
			Trait.Impl(SDeque, tok, dequeTable())
			Trait.ImplOf(SStack, { __type = tok })
		end
	end)
	local k2 = measure("시제품 (출처 기억 포함)", function(keep)
		local PDeque = Trait3.New("Deque", { required = dequeNames })
		local PStack = Trait3.New("Stack", {
			dependencies = { PDeque },
			defaults = function(_ops: any, deps: any)
				local deque = deps[PDeque]
				return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
			end,
		})
		keep[1], keep[2] = PDeque, PStack
		for i = 1, KINDS do
			local tok = table.freeze({ name = "K" })
			keep[i + 2] = tok
			Trait3.Impl(PDeque, tok, dequeTable())
			Trait3.ImplOf(PStack, { __type = tok })
		end
	end)
	local k3 = measure("시제품 + 함수별 표 둘(Push·Pop)", function(keep)
		local PDeque = Trait3.New("Deque", { required = dequeNames })
		local PStack = Trait3.New("Stack", {
			dependencies = { PDeque },
			defaults = function(_ops: any, deps: any)
				local deque = deps[PDeque]
				return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
			end,
		})
		keep[1], keep[2] = PDeque, PStack
		Trait3.FnTable(PStack, "Push")
		Trait3.FnTable(PStack, "Pop")
		for i = 1, KINDS do
			local tok = table.freeze({ name = "K" })
			keep[i + 2] = tok
			Trait3.Impl(PDeque, tok, dequeTable())
			Trait3.ImplOf(PStack, { __type = tok })
		end
	end)
	assert(#k1 > 0 and #k2 > 0 and #k3 > 0)
end
