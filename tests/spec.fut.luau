--!strict
--[[
	Fut 테스트.

	⭐ 비동기는 "언제 도는가" 가 눈에 안 보이는 버그를 만듭니다. 그래서 7절에서
	**큐 스케줄러를 꽂아** 콜백이 flush 전엔 안 돌고, flush 하면 순서대로 도는
	것까지 고정합니다. 전역 스케줄러를 바꾸므로 **절 끝에서 반드시 되돌립니다.**
]]
local stl = require("../src")
local Fut = stl.Fut

type Fut<T...> = stl.Fut<T...>

-- ⚠️ `(fn :: T)(…)` 처럼 **`(` 로 시작하는 문장을 쓰지 않습니다.** 앞 문장이
-- `const` 선언이면 stylua 2.5.2 가 모호함을 가르는 `;` 를 지워 파싱 에러가
-- 납니다(실측). 붙잡아 둔 resolve 를 부를 땐 이 도우미를 씁니다.
const function call(fn: ((number) -> ())?, value: number)
	const f = fn :: (number) -> ()
	f(value)
end

print("=== 1. 이미 정해진 Fut ===")
do
	const ok = Fut.Resolved(1, "a")
	assert(ok:Status() == "Resolved", "Resolved 상태")
	const n, s = ok:Await()
	assert(n == 1 and s == "a", "다중 반환 Await")
	const safeOk, sn, ss = ok:AwaitSafe()
	assert(safeOk == true and sn == 1 and ss == "a", "AwaitSafe 성공")

	const bad = Fut.Rejected<<(number)>>("이유")
	assert(bad:Status() == "Rejected", "Rejected 상태")
	const good, reason = bad:AwaitSafe()
	assert(good == false and reason == "이유", "AwaitSafe 실패")
	assert(not pcall(function()
		return bad:Await()
	end), "실패한 Fut 의 Await 는 에러")

	const empty = Fut.Resolved()
	assert(select("#", empty:Await()) == 0, "빈 팩")
	assert(stl.isFut(ok) and not stl.isFut({}) and not stl.isFut(nil), "isFut")
end
print("PASS")

print("=== 2. New — 한 번만 정해진다 ===")
do
	local resolveLater: ((number) -> ())? = nil
	const f = Fut.New(function(resolve: (number) -> (), _reject: (any) -> ())
		resolveLater = resolve
	end)
	assert(f:Status() == "Pending", "대기")
	call(resolveLater, 1)
	call(resolveLater, 2) -- 두 번째는 무시
	assert(f:Status() == "Resolved" and f:Await() == 1, "먼저 부른 것만 효력")

	const thrown = Fut.New(function()
		error("터짐")
	end)
	assert(thrown:Status() == "Rejected", "executor 에러는 실패")
	const _, why = thrown:AwaitSafe()
	assert(string.find(tostring(why), "터짐", 1, true), "이유가 보존됨")

	const rejected = Fut.New(function(_resolve: () -> (), reject: (any) -> ())
		reject({ code = 7 })
	end)
	const _, obj = rejected:AwaitSafe()
	assert(type(obj) == "table" and obj.code == 7, "문자열이 아닌 이유도 그대로")
end
print("PASS")

print("=== 3. AndThen ===")
do
	const chained = Fut.Resolved(2, 3)
		:AndThen(function(a: number, b: number): (number, string)
			return a * b, "x"
		end)
		:AndThen(function(n: number, s: string): string
			return s .. n
		end)
	assert(chained:Await() == "x6", "다중 반환이 체인을 지남")

	local called = false
	const passThrough = Fut.Rejected<<(number)>>("원래 이유"):AndThen(function(n: number): number
		called = true
		return n
	end)
	const _, why = passThrough:AwaitSafe()
	assert(not called and why == "원래 이유", "실패는 콜백 없이 그대로 흐름")

	const broken = Fut.Resolved(1):AndThen(function(_n: number): number
		error("콜백에서 터짐")
	end)
	assert(broken:Status() == "Rejected", "콜백 에러는 실패로")
end
print("PASS")

print("=== 4. Catch ===")
do
	const recovered = Fut.Rejected<<(string)>>("x"):Catch(function(reason: any): string
		return "복구:" .. tostring(reason)
	end)
	assert(recovered:Await() == "복구:x", "Catch 로 복구")

	local called = false
	const untouched = Fut.Resolved("그대로"):Catch(function(_reason: any): string
		called = true
		return "안 불려야 함"
	end)
	assert(untouched:Await() == "그대로" and not called, "성공은 Catch 를 지나침")
end
print("PASS")

print("=== 5. Chain — Fut 을 돌려주면 펼친다 ===")
do
	const flat = Fut.Resolved(2):Chain(function(n: number): Fut<number>
		return Fut.Resolved(n * 10)
	end)
	assert(flat:Await() == 20, "펼침")

	const innerFail = Fut.Resolved(1):Chain(function(_n: number): Fut<number>
		return Fut.Rejected<<(number)>>("안쪽 실패")
	end)
	const _, why = innerFail:AwaitSafe()
	assert(why == "안쪽 실패", "안쪽 실패를 따름")

	const cbFail = Fut.Resolved(1):Chain(function(_n: number): Fut<number>
		error("콜백 실패")
	end)
	assert(cbFail:Status() == "Rejected", "Chain 콜백 에러")
end
print("PASS")

print("=== 6. Async / Await ===")
do
	local release: ((number) -> ())? = nil
	const gate = Fut.New(function(resolve: (number) -> (), _reject: (any) -> ())
		release = resolve
	end)
	const add = Fut.Async(function(x: number, y: number): number
		return x + y + gate:Await()
	end)
	const result = add(1, 2)
	assert(result:Status() == "Pending", "gate 가 열리기 전엔 대기")
	call(release, 100)
	assert(result:Status() == "Resolved" and result:Await() == 103, "gate 가 열리면 이어서 끝남")

	-- 콜백 안에서도 Await 할 수 있음
	const nested = Fut.Resolved(1):AndThen(function(n: number): number
		return n + Fut.Resolved(10):Await()
	end)
	assert(nested:Await() == 11, "AndThen 콜백 안의 Await")

	-- Fut 이 만든 코루틴 밖에서 대기 중인 것을 Await 하면 크래시가 아니라 에러
	const pending = Fut.New(function() end)
	const ok, err = pcall(function()
		return pending:Await()
	end)
	assert(not ok and string.find(tostring(err), "outside a Fut coroutine", 1, true), "밖에서의 Await")
	const safeOk = pending:AwaitSafe()
	assert(safeOk == false, "밖에서의 AwaitSafe 는 false")

	-- Async 본문의 에러
	const failing = Fut.Async(function(): number
		error("본문 실패")
	end)()
	assert(failing:Status() == "Rejected", "Async 본문 에러")
end
print("PASS")

print("=== 7. ⭐ 스케줄러 주입 ===")
do
	const queue: { () -> () } = {}
	const previous = Fut.UseProvider({
		schedule = function(job: () -> ())
			table.insert(queue, job)
		end,
	})
	const function flush()
		while #queue > 0 do
			const job = table.remove(queue, 1) :: () -> ()
			job()
		end
	end

	local order: { string } = {}
	const source = Fut.Resolved(1)
	source:AndThen(function(_n: number): ()
		table.insert(order, "a")
	end)
	source:AndThen(function(_n: number): ()
		table.insert(order, "b")
	end)
	assert(#order == 0, "flush 전엔 콜백이 안 돎")
	flush()
	assert(table.concat(order) == "ab", "flush 하면 등록 순서대로")

	-- 체인도 한 칸씩 밀린다
	local final = 0
	Fut.Resolved(1)
		:AndThen(function(n: number): number
			return n + 1
		end)
		:AndThen(function(n: number): ()
			final = n
		end)
	assert(final == 0, "체인도 flush 전엔 안 돎")
	flush()
	assert(final == 2, "flush 로 끝까지")

	-- 되돌리기 — 다음 테스트가 즉시 실행을 기대합니다
	Fut.UseProvider(previous)
	local immediate = false
	Fut.Resolved(1):AndThen(function(_n: number): ()
		immediate = true
	end)
	assert(immediate, "되돌린 뒤엔 즉시 실행")
end
print("PASS")

print("=== 8. provider — 남의 스레드에서 기다리기 ===")
do
	-- Fut 이 만들지 않은 코루틴(Roblox 의 task.spawn 스레드에 해당)
	local release: ((number) -> ())? = nil
	const function makeGate(): Fut<number>
		return Fut.New(function(resolve: (number) -> (), _reject: (any) -> ())
			release = resolve
		end)
	end

	-- (a) 기본값: 남의 스레드에서는 대기 중인 Fut 을 못 기다림
	do
		const gate = makeGate()
		local outcome: string? = nil
		const co = coroutine.create(function()
			const ok = pcall(function()
				return gate:Await()
			end)
			outcome = if ok then "기다림" else "거절"
		end)
		coroutine.resume(co)
		assert(outcome == "거절", "기본값은 남의 스레드를 거절")
	end

	-- (b) canWait 를 넓히고 resume 을 주면 기다렸다가 깨어남
	do
		const resumed: { thread } = {}
		const previous = Fut.UseProvider({
			canWait = function(): boolean
				return coroutine.running() ~= nil
			end,
			resume = function(co: thread)
				table.insert(resumed, co)
				coroutine.resume(co)
			end,
		})
		const gate = makeGate()
		local got: number? = nil
		const co = coroutine.create(function()
			got = gate:Await()
		end)
		coroutine.resume(co)
		assert(got == nil and coroutine.status(co) == "suspended", "gate 전엔 멈춰 있음")
		call(release, 42)
		assert(got == 42, "gate 가 열리면 깨어나 값을 받음")
		assert(#resumed == 1 and resumed[1] == co, "주입한 resume 으로 깨움")
		Fut.UseProvider(previous)
	end

	-- (c) 되돌린 뒤엔 다시 거절
	do
		const gate = makeGate()
		local outcome: string? = nil
		const co = coroutine.create(function()
			outcome = if pcall(function()
					return gate:Await()
				end)
				then "기다림"
				else "거절"
		end)
		coroutine.resume(co)
		assert(outcome == "거절", "provider 를 되돌리면 기본값")
	end
end
print("PASS")

print("=== 9. ⭐ immutable — 이어 붙여도 원래 Fut 은 안 바뀐다 ===")
do
	-- JS 의 then 처럼 "껍데기가 통째로 바뀌는" 일이 없어야 합니다. 모든 잇기는
	-- 새 Fut 을 만들고, 원래 Fut 을 여러 곳이 공유해도 서로 영향이 없습니다.
	const source = Fut.Resolved(1)
	const a = source:AndThen(function(n: number): number
		return n + 10
	end)
	const b = source:AndThen(function(n: number): number
		return n + 100
	end)
	const c = source:Chain(function(n: number): Fut<number>
		return Fut.Resolved(n * 1000)
	end)
	assert(a ~= source and b ~= source and c ~= source, "잇기는 새 Fut")
	assert(source:Await() == 1, "원래 Fut 의 값은 그대로")
	assert(a:Await() == 11 and b:Await() == 101 and c:Await() == 1000, "갈래마다 제 값")

	-- 실패도 공유된다 — 한쪽에서 Catch 해도 원래 Fut 은 여전히 실패
	const failed = Fut.Rejected<<(number)>>("이유")
	const recovered = failed:Catch(function(_reason: any): number
		return 0
	end)
	assert(recovered:Await() == 0, "갈래는 복구됨")
	assert(failed:Status() == "Rejected", "원래 Fut 은 여전히 실패")

	-- 대기 중인 원래 Fut 에 여러 갈래가 매달려도 정해질 때 전부 한 번씩
	local release: ((number) -> ())? = nil
	const pending = Fut.New(function(resolve: (number) -> (), _reject: (any) -> ())
		release = resolve
	end)
	local hits = 0
	for _ = 1, 3 do
		pending:AndThen(function(_n: number): ()
			hits += 1
		end)
	end
	call(release, 5)
	assert(hits == 3, "매달린 갈래마다 한 번씩")
end
print("PASS")

print("=== 10. All ===")
do
	-- 끝나는 순서를 뒤섞어도 결과는 입력 순서
	const resolvers: { (number) -> () } = {}
	const futs: { Fut<number> } = {}
	for idx = 1, 3 do
		futs[idx] = Fut.New(function(resolve: (number) -> (), _reject: (any) -> ())
			resolvers[idx] = resolve
		end)
	end
	const all = Fut.All(futs)
	resolvers[3](30)
	resolvers[1](10)
	assert(all:Status() == "Pending", "하나라도 남으면 대기")
	resolvers[2](20)
	const ok, result = all:AwaitSafe()
	assert(ok and stl.isArr(result), "결과는 Arr")
	assert(result.n == 3 and result[1] == 10 and result[2] == 20 and result[3] == 30, "입력 순서대로")
	assert(stl.Arr.Sum(result) == 60, "받은 뒤 바로 Arr 함수로 이어짐")

	-- 빈 목록은 빈 Arr 로 곧바로
	const empty = Fut.All({} :: { Fut<number> })
	const emptyOk, emptyResult = empty:AwaitSafe()
	assert(emptyOk and emptyResult.n == 0, "빈 목록")

	-- 실패는 그 즉시, 나머지를 기다리지 않음
	local release: ((number) -> ())? = nil
	const slow = Fut.New(function(resolve: (number) -> (), _reject: (any) -> ())
		release = resolve
	end)
	const failing = Fut.All({ slow, Fut.Rejected<<(number)>>("먼저 실패") })
	assert(failing:Status() == "Rejected", "느린 것을 안 기다리고 바로 실패")
	const _, why = failing:AwaitSafe()
	assert(why == "먼저 실패", "실패 이유 그대로")
	call(release, 1) -- 뒤늦게 끝나도 결과가 안 바뀜
	assert(failing:Status() == "Rejected", "뒤늦은 성공은 무시")

	-- 두 번째 실패는 첫 번째 이유를 덮지 않음
	const twice = Fut.All({ Fut.Rejected<<(number)>>("첫째"), Fut.Rejected<<(number)>>("둘째") })
	const _, firstWhy = twice:AwaitSafe()
	assert(firstWhy == "첫째", "첫 실패 이유가 남음")
end
print("PASS")

print("=== 11. 회귀 — 2026-09-30 리뷰가 재현한 버그들 ===")
do
	-- (1) 리스너 하나가 에러를 내도 나머지는 돌아야 한다
	local res: ((number) -> ())? = nil
	const src = Fut.New(function(resolve: (number) -> (), _reject: (any) -> ())
		res = resolve
	end)
	const notFut = src:Chain(function(_n: number): Fut<number>
		return nil :: any -- Fut 이 아닌 것을 돌려줌(비-strict 호출자 흉내)
	end)
	const tableNotFut = src:Chain(function(_n: number): Fut<number>
		return { x = 1 } :: any
	end)
	const other = src:AndThen(function(_n: number): string
		return "other"
	end)
	call(res, 1)
	assert(notFut:Status() == "Rejected", `Chain 이 nil 을 받으면 실패해야 함: {tostring(notFut:Status())}`)
	assert(tableNotFut:Status() == "Rejected", "Chain 이 Fut 아닌 테이블을 받으면 실패")
	assert(other:Status() == "Resolved", "무관한 리스너는 돌아야 함")

	-- (1b) provider 의 schedule 이 에러를 내도 다른 리스너는 유실되지 않는다
	do
		local calls = 0
		const previous = Fut.UseProvider({
			schedule = function(job: () -> ())
				calls += 1
				if calls == 1 then
					error("sched fail")
				end
				job()
			end,
		})
		local r2: ((number) -> ())? = nil
		const s2 = Fut.New(function(resolve: (number) -> (), _reject: (any) -> ())
			r2 = resolve
		end)
		const a = s2:AndThen(function(n: number): number
			return n
		end)
		const b = s2:AndThen(function(n: number): number
			return n
		end)
		const ok = pcall(r2 :: (number) -> (), 1)
		Fut.UseProvider(previous)
		assert(not ok, "schedule 의 에러는 resolve 쪽으로 드러남")
		assert(a:Status() == "Pending" and b:Status() == "Resolved", "실패한 한 건만 빠지고 나머지는 돎")
	end

	-- (2) Chain 콜백 안의 Await 가 resolve 한 쪽의 코루틴을 가로채지 않는다
	do
		local gres: ((number) -> ())? = nil
		const gate = Fut.New(function(resolve: (number) -> (), _reject: (any) -> ())
			gres = resolve
		end)
		local r3: ((number) -> ())? = nil
		const s3 = Fut.New(function(resolve: (number) -> (), _reject: (any) -> ())
			r3 = resolve
		end)
		const chained = s3:Chain(function(_n: number): Fut<string>
			gate:Await()
			return Fut.Resolved("chain")
		end)
		const sibling = s3:AndThen(function(_n: number): string
			return "sibling"
		end)
		local producerReturned = false
		const producer = Fut.Async(function(): ()
			const release3 = r3 :: (number) -> ()
			release3(1)
			producerReturned = true
		end)()
		assert(
			producerReturned and producer:Status() == "Resolved",
			"resolve 를 부른 쪽이 바로 돌아와야 함"
		)
		assert(sibling:Status() == "Resolved", "형제 리스너는 gate 와 무관하게 바로")
		assert(chained:Status() == "Pending", "Chain 은 gate 를 기다림")
		call(gres, 0)
		assert(chained:Status() == "Resolved" and chained:Await() == "chain", "gate 가 열리면 Chain 도 끝남")

		-- main 에서 resolve 해도 AndThen 과 똑같이 기다릴 수 있어야 함
		local gres2: ((number) -> ())? = nil
		const gate2 = Fut.New(function(resolve: (number) -> (), _reject: (any) -> ())
			gres2 = resolve
		end)
		const c2 = Fut.Resolved(1):Chain(function(_n: number): Fut<number>
			return Fut.Resolved(gate2:Await())
		end)
		assert(c2:Status() == "Pending", "main 에서도 Chain 콜백이 기다릴 수 있음")
		call(gres2, 9)
		assert(c2:Await() == 9, "gate2 로 이어짐")
	end

	-- (3) 긴 사슬이 C stack 에 걸리지 않는다
	do
		local r4: ((number) -> ())? = nil
		local f: Fut<number> = Fut.New(function(resolve: (number) -> (), _reject: (any) -> ())
			r4 = resolve
		end)
		for _ = 1, 1000 do
			f = f:AndThen(function(x: number): number
				return x + 1
			end)
		end
		call(r4, 0)
		const ok, v = f:AwaitSafe()
		assert(ok and v == 1000, `1000단 사슬: {tostring(ok)} {tostring(v)}`)

		-- 재귀 Async 깊이 500
		local depthFn: (number) -> Fut<number>
		depthFn = Fut.Async(function(d: number): number
			if d == 0 then
				return 0
			end
			return depthFn(d - 1):Await() + 1
		end)
		const deep = depthFn(500)
		const dok, dv = deep:AwaitSafe()
		assert(dok and dv == 500, `재귀 Async 500: {tostring(dok)} {tostring(dv)}`)
	end

	-- (4) Await 가 이유를 고쳐 쓰지 않는다 (홉마다 위치가 쌓이면 안 됨)
	do
		const f1 = Fut.Async(function(): number
			return Fut.Rejected<<(number)>>("boom"):Await()
		end)()
		const f2 = Fut.Async(function(): number
			return f1:Await()
		end)()
		const _, why = f2:AwaitSafe()
		assert(why == "boom", `이유가 그대로여야 함: {tostring(why)}`)
	end

	-- (5) All 에 Arr 를 줘도 된다 (가장 자연스러운 입력)
	do
		const fromArr = Fut.All(stl.Arr.Of(Fut.Resolved(1), Fut.Resolved(2)))
		const ok, result = fromArr:AwaitSafe()
		assert(ok and result.n == 2 and result[1] == 1 and result[2] == 2, "All(Arr)")
	end

	-- (6) All 에 구멍 있는 목록을 주면 영원히 기다리지 않고 실패한다
	do
		const holed = Fut.All({ Fut.Resolved(1), nil :: any, Fut.Resolved(3) } :: { Fut<number> })
		assert(holed:Status() == "Rejected", `구멍 있는 목록은 실패: {tostring(holed:Status())}`)
	end
end
print("PASS")

print()
print("=== ALL PASS (Fut) ===")

return true
