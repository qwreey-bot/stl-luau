--!strict
--[[
	Fut — 코루틴 래퍼. 프로미스와 같은 자리입니다(이름이 짧아서 `Fut`).

	```lua
	local fetch = Fut.Async(function(id: number): (string, number)
		local body = http:Get(id):Await()    -- 코루틴 안이라 기다릴 수 있음
		return body, #body
	end)
	fetch(1):AndThen(function(body: string, size: number) … end)
	```

	## ⭐ 스케줄러를 주입받습니다 (사용자 결정 2026-09-22)

	순수 luau 에는 `task.defer` 도 이벤트 루프도 없습니다. 그래서 "콜백을 언제
	부르나" 를 이 모듈이 정하지 않고 **주입받습니다**(quad 의 provider 계층과
	같은 방식).

	- **기본은 즉시 실행**입니다. 아무것도 안 해도 순수 luau 에서 돕니다.
	- provider 는 세 가지를 정합니다 — **언제 돌리나**(`schedule`), **이
	  스레드에서 기다려도 되나**(`canWait`), **기다리던 스레드를 어떻게
	  깨우나**(`resume`). 빠진 것은 기본값을 씁니다.
	- Roblox 라면 이렇게 꽂습니다(이 모듈은 환경에 중립이라 기본으로 넣지
	  않습니다 — 쓰는 곳에 맞추는 건 쓰는 쪽의 일입니다):

	  ```lua
	  Fut.UseProvider({
	      schedule = task.defer,           -- 예측 가능한 타이밍
	      canWait = coroutine.isyieldable, -- task.spawn 스레드에서도 Await
	      resume = task.spawn,             -- 깨운 스레드의 에러가 보고되도록
	  })
	  ```
	- 테스트는 큐 스케줄러를 꽂고 손으로 비워서 **결정적으로** 돌립니다.

	⚠️ **즉시 실행 스케줄러에서는 `Resolve` 를 부른 그 자리에서 콜백이 돕니다.**
	"때로는 동기, 때로는 비동기" 가 되는 고전적 함정이 있으니, 타이밍에
	기대는 코드는 스케줄러를 주입하세요.

	## 다중 반환

	결과가 여러 개일 수 있습니다(`Fut<T...>`). 타입 팩을 **팬텀 필드**
	(`_pack: (T...) -> ()`)에 얹어 들고 다닙니다 — 런타임엔 그 필드가 없습니다.
	tbox 의 튜플과 같은 기법이고, `type function` 없이 3단 체이닝까지 타입이
	삽니다(스파이크로 확인).

	## `AndThen` 과 `Chain` 을 가릅니다

	콜백이 **값**을 돌려주면 `AndThen`, **`Fut`** 을 돌려주면 `Chain`(펼침).
	JS 의 `then` 은 둘을 하나로 합치지만, Luau 타입으로는 "돌려준 게 Fut 이면
	펼친다" 를 표현할 수 없습니다. Rust 의 `map` / `and_then` 과 같은 구분입니다.

	## 취소는 아직 없습니다 (사용자 결정: 잠정 보류)

	Luau 의 `coroutine.close` 로 가능은 합니다. 나중에 확장으로 얹을 수 있도록
	상태(`Status`)를 닫힌 셋으로 못박지 않았습니다 — "Cancelled" 가 더해질 수
	있다고 보고 쓰세요.
]]

export type Status = "Pending" | "Resolved" | "Rejected"
export type Scheduler = (job: () -> ()) -> ()

-- 환경에 맞추는 세 갈래. 빠진 것은 기본값을 씁니다.
export type Provider = {
	-- 콜백을 언제 돌리나. 기본은 즉시 실행.
	schedule: Scheduler?,
	-- 지금 스레드에서 `Await` 가 기다려도 되나. 기본은 **`Fut` 이 만든
	-- 코루틴일 때만** 참(아래 `ownThreads` 참고).
	canWait: (() -> boolean)?,
	-- 기다리던 스레드를 깨우는 방법. 기본은 `coroutine.resume`.
	-- ⚠️ `coroutine.resume` 은 깨운 스레드의 에러를 **조용히 삼킵니다.**
	-- `Fut` 이 만든 코루틴은 본문 전체가 `pcall` 로 감싸져 있어 괜찮지만,
	-- `canWait` 를 넓혀 남의 스레드까지 기다리게 했다면 에러를 보고하는
	-- 방법(Roblox 의 `task.spawn`)을 주세요.
	resume: ((co: thread) -> ())?,
}

type Packed = { n: number, [number]: any }

export type FutData = {
	status: Status,
	values: Packed?,
	reason: any,
	listeners: { () -> () },
}

local Ifce: FutIfce

-- 즉시 실행. 순수 luau 의 기본값.
const function immediate(job: () -> ())
	job()
end

local scheduler: Scheduler = immediate

-- ⭐ **이 모듈이 만든 코루틴들.** `Await` 는 이 안에서만 기다립니다.
-- `coroutine.isyieldable()` 로는 못 가립니다 — luau CLI 의 메인 스레드도 참을
-- 돌려주고, 거기서 yield 하면 `pcall` 로도 못 잡는 크래시가 납니다(실측).
-- 약한 키라 끝난 코루틴은 GC 됩니다.
const ownThreads: { [thread]: true } = setmetatable({}, { __mode = "k" }) :: any

const function spawnOwned(body: () -> ())
	const co = coroutine.create(body)
	ownThreads[co] = true
	coroutine.resume(co)
end

const function ownThreadOnly(): boolean
	return ownThreads[coroutine.running()] == true
end
const function plainResume(co: thread)
	coroutine.resume(co)
end

local canWait: () -> boolean = ownThreadOnly
local resumeThread: (co: thread) -> () = plainResume

--#region ----------- 내부 -----------

const function newPending(): FutData
	return setmetatable(
		{
			status = "Pending",
			values = nil,
			reason = nil,
			listeners = {},
		} :: any,
		Ifce :: any
	) :: any
end

-- 한 번만 정해집니다. 이미 정해졌으면 아무것도 안 합니다(두 번째 resolve 무시).
const function settle(fut: FutData, status: Status, values: Packed?, reason: any)
	if fut.status ~= "Pending" then
		return
	end
	fut.status = status
	fut.values = values
	fut.reason = reason
	const listeners = fut.listeners
	fut.listeners = {}
	for _, listener in listeners do
		scheduler(listener)
	end
end

-- 정해지면 `listener` 를 부릅니다. 이미 정해졌으면 스케줄러로 바로 보냅니다.
const function onSettle(fut: FutData, listener: () -> ())
	if fut.status == "Pending" then
		table.insert(fut.listeners, listener)
	else
		scheduler(listener)
	end
end

-- `fn(...)` 을 **새 코루틴에서** 보호 실행합니다. 그래서 콜백 안에서도
-- `Await` 할 수 있습니다. 끝나면 결과로 `target` 을 정합니다.
const function runInto(target: FutData, fn: (...any) -> ...any, ...: any)
	const args = table.pack(...)
	spawnOwned(function()
		const result = table.pack(pcall(fn, table.unpack(args, 1, args.n)))
		if result[1] then
			settle(target, "Resolved", table.pack(table.unpack(result, 2, result.n)), nil)
		else
			settle(target, "Rejected", nil, result[2])
		end
	end)
end

-- `source` 가 정해지면 그 결과를 `target` 에 그대로 옮깁니다.
const function adopt(target: FutData, source: FutData)
	onSettle(source, function()
		settle(target, source.status, source.values, source.reason)
	end)
end

--#endregion

--#region ----------- 조회 -----------

const function Status<T...>(self: FutData): Status
	return self.status
end

-- 끝날 때까지 **현재 코루틴을 멈추고** 결과를 돌려줍니다. 실패했으면 에러.
-- ⚠️ **아직 안 끝났다면 기본으로는 `Fut` 이 만든 코루틴 안에서만 기다릴 수
-- 있습니다**(`Fut.Async` 의 본문, `Fut.New` 의 executor, `AndThen`/`Catch` 의
-- 콜백). 그 밖에서 부르면 에러입니다 — 이미 끝난 Fut 은 어디서든 됩니다.
-- 넓히려면 provider 의 `canWait` 를 주세요(`Fut.UseProvider`).
const function Await<T...>(self: Fut<T...>): T...
	const data = self :: FutData
	if data.status == "Pending" then
		if not canWait() then
			error("Fut: Await on a pending Fut outside a Fut coroutine (wrap it in Fut.Async)", 2)
		end
		const co = coroutine.running()
		onSettle(data, function()
			resumeThread(co)
		end)
		coroutine.yield()
	end
	if data.status == "Rejected" then
		error(data.reason, 2)
	end
	const values = data.values :: Packed
	return table.unpack(values, 1, values.n)
end

-- `Await` 와 같되 **에러를 던지지 않습니다.** `(true, 결과...)` 또는
-- `(false, 이유)`.
const function AwaitSafe<T...>(self: Fut<T...>): (boolean, ...any)
	const data = self :: FutData
	if data.status == "Pending" then
		if not canWait() then
			return false, "Fut: Await on a pending Fut outside a Fut coroutine (wrap it in Fut.Async)"
		end
		const co = coroutine.running()
		onSettle(data, function()
			resumeThread(co)
		end)
		coroutine.yield()
	end
	if data.status == "Rejected" then
		return false, data.reason
	end
	const values = data.values :: Packed
	return true, table.unpack(values, 1, values.n)
end

--#endregion

--#region ----------- 잇기 -----------

-- 성공하면 결과를 변환합니다. 실패는 그대로 흘려보냅니다.
-- 콜백이 에러를 내면 결과 Fut 이 실패합니다. 콜백은 새 코루틴에서 돌아
-- 그 안에서 `Await` 할 수 있습니다.
const function AndThen<T..., U...>(self: Fut<T...>, fn: (T...) -> U...): Fut<U...>
	const source = self :: FutData
	const target = newPending()
	onSettle(source, function()
		if source.status == "Resolved" then
			const values = source.values :: Packed
			runInto(target, fn :: any, table.unpack(values, 1, values.n))
		else
			settle(target, "Rejected", nil, source.reason)
		end
	end)
	return target :: any
end

-- 성공하면 **Fut 을 돌려주는** 콜백을 부르고 그 Fut 의 결과를 따릅니다(펼침).
const function Chain<T..., U...>(self: Fut<T...>, fn: (T...) -> Fut<U...>): Fut<U...>
	const source = self :: FutData
	const target = newPending()
	onSettle(source, function()
		if source.status ~= "Resolved" then
			settle(target, "Rejected", nil, source.reason)
			return
		end
		const values = source.values :: Packed
		const ok, inner = pcall(fn :: any, table.unpack(values, 1, values.n))
		if ok then
			adopt(target, inner :: any)
		else
			settle(target, "Rejected", nil, inner)
		end
	end)
	return target :: any
end

-- 실패하면 이유를 받아 **복구**합니다. 성공은 그대로 흘려보냅니다.
const function Catch<T...>(self: Fut<T...>, fn: (reason: any) -> T...): Fut<T...>
	const source = self :: FutData
	const target = newPending()
	onSettle(source, function()
		if source.status == "Rejected" then
			runInto(target, fn :: any, source.reason)
		else
			settle(target, "Resolved", source.values, nil)
		end
	end)
	return target :: any
end

--#endregion

--#region ----------- 타입 조립 -----------

type FutIfce = {
	Status: typeof(Status),
	Await: typeof(Await),
	AwaitSafe: typeof(AwaitSafe),
	AndThen: typeof(AndThen),
	Chain: typeof(Chain),
	Catch: typeof(Catch),
}

-- ⭐ `_pack` 은 **팬텀 필드**입니다. 런타임엔 없고, 타입 팩 `T...` 를 들고
-- 다니기 위해서만 있습니다. 이게 없으면 모든 `Fut<…>` 가 구조적으로 같아져
-- 결과 타입이 사라집니다. 읽지 마세요.
export type Fut<T...> = FutData & { _pack: (T...) -> () } & FutIfce

-- stylua: ignore
Ifce = {
	Status = Status, Await = Await, AwaitSafe = AwaitSafe,
	AndThen = AndThen, Chain = Chain, Catch = Catch,
} :: any
(Ifce :: any).__index = Ifce

--#endregion

--#region ----------- 생성자 -----------

-- `executor(resolve, reject)` 를 **새 코루틴에서 바로** 돌립니다. executor 가
-- 에러를 내면 실패합니다. 먼저 부른 쪽 하나만 효력이 있습니다.
const function New<T...>(executor: (resolve: (T...) -> (), reject: (reason: any) -> ()) -> ()): Fut<T...>
	const fut = newPending()
	const function resolve(...: any)
		settle(fut, "Resolved", table.pack(...), nil)
	end
	const function reject(reason: any)
		settle(fut, "Rejected", nil, reason)
	end
	spawnOwned(function()
		const ok, err = pcall(executor :: any, resolve, reject)
		if not ok then
			reject(err)
		end
	end)
	return fut :: any
end

-- 함수를 **부를 때마다 Fut 을 돌려주는 함수**로 바꿉니다. 함수는 새 코루틴에서
-- 돌므로 안에서 다른 Fut 을 `Await` 할 수 있습니다 — async/await 모양.
const function Async<A..., R...>(fn: (A...) -> R...): (A...) -> Fut<R...>
	return function(...: A...): Fut<R...>
		const fut = newPending()
		runInto(fut, fn :: any, ...)
		return fut :: any
	end
end

-- 이미 성공한 Fut.
const function Resolved<T...>(...: T...): Fut<T...>
	const fut = newPending()
	settle(fut, "Resolved", (table.pack :: any)(...), nil)
	return fut :: any
end

-- 이미 실패한 Fut. 결과 타입은 호출자가 정합니다: `Fut.Rejected<<(number)>>(e)`.
-- ⚠️ 가변 팩 자리의 명시적 타입 인자는 **괄호로 감쌉니다** — `<<number>>` 는
-- "타입 인자가 너무 많다" 가 나고 `<<(number)>>` 가 맞습니다(실측).
const function Rejected<T...>(reason: any): Fut<T...>
	const fut = newPending()
	settle(fut, "Rejected", nil, reason)
	return fut :: any
end

-- ⭐ provider. **전역**입니다 — 한 번 꽂으면 그 뒤로 모든 Fut 이 이걸 씁니다.
-- 빠진 갈래는 기본값으로 돌아갑니다. **이전 provider 를 돌려주니** 테스트에서
-- 되돌리세요. `nil` 을 주면 전부 기본값입니다.
const function UseProvider(provider: Provider?): Provider
	const previous: Provider = { schedule = scheduler, canWait = canWait, resume = resumeThread }
	const given: Provider = provider or {}
	scheduler = given.schedule or immediate
	canWait = given.canWait or ownThreadOnly
	resumeThread = given.resume or plainResume
	return previous
end

const function isFut(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Ifce
end

--#endregion

return {
	New = New,
	Async = Async,
	Resolved = Resolved,
	Rejected = Rejected,
	UseProvider = UseProvider,
	isFut = isFut,
}
