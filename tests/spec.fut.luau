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
	assert(f:Status() == "Pending", "대기");
	(resolveLater :: (number) -> ())(1);
	(resolveLater :: (number) -> ())(2) -- 두 번째는 무시
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
	assert(result:Status() == "Pending", "gate 가 열리기 전엔 대기");
	(release :: (number) -> ())(100)
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
			(table.remove(queue, 1) :: () -> ())()
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
		assert(got == nil and coroutine.status(co) == "suspended", "gate 전엔 멈춰 있음");
		(release :: (number) -> ())(42)
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
	(release :: (number) -> ())(5)
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
	assert(why == "먼저 실패", "실패 이유 그대로");
	(release :: (number) -> ())(1) -- 뒤늦게 끝나도 결과가 안 바뀜
	assert(failing:Status() == "Rejected", "뒤늦은 성공은 무시")

	-- 두 번째 실패는 첫 번째 이유를 덮지 않음
	const twice = Fut.All({ Fut.Rejected<<(number)>>("첫째"), Fut.Rejected<<(number)>>("둘째") })
	const _, firstWhy = twice:AwaitSafe()
	assert(firstWhy == "첫째", "첫 실패 이유가 남음")
end
print("PASS")

print()
print("=== ALL PASS (Fut) ===")

return true
