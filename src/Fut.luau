--!strict
--[[
	Fut — 코루틴 래퍼. 프로미스와 같은 자리입니다(이름이 짧아서 `Fut`).

	```lua
	local fetch = Fut.Async(function(id: number): (string, number)
		local body = Fut.Await(httpGet(id))   -- 코루틴 안이라 기다릴 수 있음
		return body, #body
	end)
	Fut.AndThen(fetch(1), function(body: string, size: number) … end)
	```

	⭐ **모든 연산은 네임스페이스 함수입니다**(`Fut.AndThen(f, fn)`) — 메소드도
	메타테이블도 없습니다(질문 AB). 모체인 `coroutine.resume(co)` 과 같은
	모양입니다(사용자: *"Fut 의 모체인 코루틴도 바깥함수야"*).

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
	tbox 의 튜플과 같은 기법이고, `type function` 없이 잇기를 세 번 중첩해도
	(`Fut.AndThen(Fut.AndThen(Fut.AndThen(f, …), …), …)`) 타입이 삽니다(스파이크로 확인).

	## `AndThen` 과 `Chain` 을 가릅니다

	콜백이 **값**을 돌려주면 `AndThen`, **`Fut`** 을 돌려주면 `Chain`(펼침).
	JS 의 `then` 은 둘을 하나로 합치지만, Luau 타입으로는 "돌려준 게 Fut 이면
	펼친다" 를 표현할 수 없습니다. Rust 의 `map` / `and_then` 과 같은 구분입니다.

	## 취소는 아직 없습니다 (사용자 결정: 잠정 보류)

	Luau 의 `coroutine.close` 로 가능은 합니다. 나중에 확장으로 얹을 수 있도록
	상태(`Status`)를 닫힌 셋으로 못박지 않았습니다 — "Cancelled" 가 더해질 수
	있다고 보고 쓰세요.
]]

const ArrModule = require("./Arr")
const Common = require("./Common")
Common.registerSource(debug.info(1, "s"))
type Arr<T> = ArrModule.Arr<T>

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
	-- 타입에만 드러난 태그(생성자가 붙이는 실제 필드) — 리터럴이 Fut 자리에 들어가는
	-- 것을 막습니다. 다른 컨테이너와 대칭(M0 3라운드).
	read __fut__: true,
	status: Status,
	values: Packed?,
	reason: any,
	listeners: { () -> () },
}

-- 인스턴스 판별용 태그. **메타테이블은 없습니다**(질문 AB).
const TAG = "__fut__"

-- 즉시 실행. 순수 luau 의 기본값.
--
-- ⭐ **재진입 가드가 있는 드레인 루프(트램펄린)입니다.** 처음 들어온 호출이
-- 큐를 끝까지 비우고, 그 사이에 들어온 호출은 큐에 넣기만 합니다. 그래서
-- 바깥에서 보면 여전히 동기적으로 끝나지만 **중첩이 쌓이지 않습니다.**
-- 그냥 `job()` 으로 부르던 판은 사슬마다 코루틴 안에서 또 `resume` 을 불러
-- **약 198단에서 "C stack overflow" 로 거짓 실패**했습니다(2026-09-30 리뷰).
--
-- 잡마다 `pcall` 로 격리합니다. 하나가 에러를 내도 나머지는 돌고, 다 비운
-- 뒤 **첫 에러를 다시 던집니다** — 조용히 삼키지 않습니다.
const queue: { () -> () } = {}
local queueHead, queueTail = 1, 0
local draining = false

const function immediate(job: () -> ())
	queueTail += 1
	queue[queueTail] = job
	if draining then
		return
	end
	draining = true
	local failed, firstError = false, nil :: any
	while queueHead <= queueTail do
		const nextJob = queue[queueHead]
		queue[queueHead] = nil :: any
		queueHead += 1
		const ok, err = pcall(nextJob)
		if not ok and not failed then
			failed, firstError = true, err
		end
	end
	queueHead, queueTail = 1, 0
	draining = false
	if failed then
		Common.rethrow(firstError)
	end
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

-- 본문 시작을 트램펄린에 태웁니다. 바깥(드레인 중이 아닐 때)에서 부르면 **지금**
-- 돌고, 이미 도는 본문 안에서 부르면 그 본문이 기다리거나 끝난 뒤 이어서
-- 돕니다. 그래야 `Async` 가 자기 자신을 재귀로 부를 때 코루틴 `resume` 이
-- 한 겹씩 쌓이지 않습니다(깊이 약 198 에서 "C stack overflow" 였음).
-- ⚠️ `New` 의 executor 는 **이걸 안 거치고 즉시** 돕니다 — 안에서 받은
-- `resolve` 를 바로 쓰는 코드가 흔하기 때문입니다.
const function spawnOwnedTrampolined(body: () -> ())
	immediate(function()
		spawnOwned(body)
	end)
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
	const fut: any = {
		status = "Pending",
		values = nil,
		reason = nil,
		listeners = {},
	}
	fut[TAG] = true
	return fut
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
	-- 리스너마다 격리합니다. 스케줄러(주입받은 것일 수 있음)가 에러를 내도
	-- **나머지 리스너가 버려진 옛 테이블에 남아 영원히 대기하는 일**이 없게
	-- 끝까지 돌리고, 첫 에러는 다 돌린 뒤 다시 던집니다(2026-09-30 리뷰).
	local failed, firstError = false, nil :: any
	for _, listener in listeners do
		const ok, err = pcall(scheduler, listener)
		if not ok and not failed then
			failed, firstError = true, err
		end
	end
	if failed then
		Common.rethrow(firstError)
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
	spawnOwnedTrampolined(function()
		const result = table.pack(pcall(fn, table.unpack(args, 1, args.n)))
		if result[1] then
			settle(target, "Resolved", table.pack(table.unpack(result, 2, result.n)), nil)
		else
			settle(target, "Rejected", nil, result[2])
		end
	end)
end

const function isFutRaw(value: any): boolean
	if type(value) ~= "table" or rawget(value, TAG) ~= true then
		return false
	end
	-- 위조 태그(`{ __fut__ = true }`)를 입양하면 상태가 셋 중 어느 것도 아닌 Fut 이
	-- 생겨 "던지지 않는" `AwaitSafe` 가 던졌습니다(M0 리뷰). 모양까지 봅니다.
	-- 이행된 것은 값 팩까지 — `{ status = "Resolved" }` 만 그럴듯하게 위조하면
	-- 값을 읽다 던졌습니다(M0 2라운드). `Pending` 위조가 영원히 대기하는 것은
	-- 막을 수 없는 한계입니다(태그는 라이브러리 예약어).
	const status = rawget(value, "status")
	if status == "Resolved" then
		-- 값 팩의 `n` 까지 — `values = { n = "x" }` 위조가 unpack 에서 던졌습니다(M0 4라운드).
		-- 경계: 그보다 깊은 위조(거대한 `n` 등)는 계약 밖입니다(태그는 예약어).
		const values: any = rawget(value, "values")
		if type(values) ~= "table" then
			return false
		end
		const n = rawget(values, "n")
		return type(n) == "number"
			and n >= 0
			and n == math.floor(n)
			and n < math.huge
			and type(rawget(value, "listeners")) == "table"
	end
	return (status == "Pending" or status == "Rejected") and type(rawget(value, "listeners")) == "table"
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
			Common.raise("Fut: Await on a pending Fut outside a Fut coroutine (wrap it in Fut.Async)")
		end
		const co = coroutine.running()
		onSettle(data, function()
			resumeThread(co)
		end)
		coroutine.yield()
	end
	if data.status == "Rejected" then
		-- 위치를 덧붙이지 않음 — 문자열 이유에 홉마다 쌓였음
		Common.rethrow(data.reason)
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
--
-- 콜백은 `AndThen` 과 같이 **새 코루틴에서** 돕니다. 리스너가 도는 스레드에서
-- 바로 부르던 판은 콜백 안의 `Await` 가 **resolve 를 부른 쪽의 코루틴을
-- 가로채** 그 호출이 돌아오지 않았습니다(2026-09-30 리뷰).
-- 콜백이 Fut 이 아닌 것을 돌려주면(비-strict 호출자) 실패로 정해집니다.
const function Chain<T..., U...>(self: Fut<T...>, fn: (T...) -> Fut<U...>): Fut<U...>
	const source = self :: FutData
	const target = newPending()
	onSettle(source, function()
		if source.status ~= "Resolved" then
			settle(target, "Rejected", nil, source.reason)
			return
		end
		const values = source.values :: Packed
		spawnOwnedTrampolined(function()
			const ok, inner = pcall(fn :: any, table.unpack(values, 1, values.n))
			if not ok then
				settle(target, "Rejected", nil, inner)
			elseif not isFutRaw(inner) then
				settle(target, "Rejected", nil, "Fut: Chain callback must return a Fut")
			elseif inner == target then
				-- 결과 Fut 자신을 돌려주면 자기를 기다리며 영원히 Pending 이었습니다
				-- (2026-10-02 Gemini 사냥, Promise/A+ 2.3.1 과 같게 거절). 더 긴 순환
				-- (A → B → A)은 잡지 않습니다 — JS 프로미스도 같습니다.
				settle(target, "Rejected", nil, "Fut: Chain callback returned the chained Fut itself (cycle)")
			else
				adopt(target, inner)
			end
		end)
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

--#region ----------- 타입 -----------

-- ⭐ `_pack` 은 **팬텀 필드**입니다. 런타임엔 없고, 타입 팩 `T...` 를 들고
-- 다니기 위해서만 있습니다. 이게 없으면 모든 `Fut<…>` 가 구조적으로 같아져
-- 결과 타입이 사라집니다. 읽지 마세요. 함수는 타입 바깥(네임스페이스)에
-- 있으니 메소드 교집합은 없습니다(질문 AB).
export type Fut<T...> = FutData & { _pack: (T...) -> () }

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

-- 전부 성공하면 결과를 **입력 순서대로** 담은 `Arr` 로 성공합니다.
-- 하나라도 실패하면 **그 즉시** 그 이유로 실패합니다(나머지를 기다리지 않음).
-- 빈 목록이면 빈 `Arr` 로 곧바로 성공합니다.
--
-- `Arr<Fut<T>>` 를 넘겨도 됩니다(`n` 을 봅니다). 목록에 Fut 이 아닌 것이나
-- 구멍이 있으면 **곧바로 실패**합니다 — 영원히 기다리지 않습니다.
--
-- ⚠️ 각 Fut 은 **값 하나**여야 합니다 — 목록 타입이 `{ Fut<T> }` 라 다중 반환
-- Fut 은 타입에서 걸립니다. 여럿을 모으고 싶으면 `AndThen` 으로 먼저 하나로
-- 묶으세요.
--
-- 결과가 `Arr` 인 게 이 모듈을 컨테이너 저장소 안에 두는 값어치입니다 —
-- 받은 뒤 바로 `Arr.Map` / `Arr.Sum` 으로 이어집니다.
const function All<T>(futs: { Fut<T> }): Fut<Arr<T>>
	-- `n` 을 먼저 봅니다 — `Arr` 를 넘기면 `for … in` 이 `n` 과 태그 키까지 돌아
	-- 터졌습니다(타입 검사는 통과했음, 2026-09-30 리뷰). 그리고 숫자 루프로
	-- 돕니다 — `#` 와 `for … in` 이 구멍에서 서로 다른 걸 셌습니다.
	-- 길이는 다른 진입점과 같은 `Common.listLength` 규약 — 일반 조회의 `.n` 이면
	-- 소수 `n` 에서 영원히 Pending, 음수·NaN 에서 던졌습니다(M0 4라운드).
	const count = Common.listLength(futs)
	const target = newPending()
	for idx = 1, count do
		if not isFutRaw(futs[idx]) then
			settle(target, "Rejected", nil, `Fut: All expects a Fut at index {idx}`)
			return target :: any
		end
	end
	-- 비어서 시작하지만 **전부 이행돼야** 밖으로 나가므로(fail-fast) 받는 쪽에서
	-- 구멍을 볼 일이 없습니다 — 그래서 `Arr<T?>` 로 드러내지 않고 `nil` 을
	-- `T` 자리에 단언합니다. 원천이 `nil` 로 이행한 칸은 `T` 자체가 `nil` 을
	-- 품으니(`Fut<number?>`) 역시 정직합니다.
	-- ⚠️ 다만 그런 목록을 **만들기**가 번거롭습니다: `Fut._pack` 이 불변이라
	-- `{ Fut.Resolved(1), Fut.Resolved(nil :: number?) }` 는 첫 원소가
	-- `Fut<number>` 로 잡혀 에러이고, `<<number?>>` 나 `{ Fut<number?> }` 주석으로도
	-- 안 풀립니다. 원소마다 값을 넓혀서 만드세요: `Fut.Resolved(1 :: number?)`.
	const results = ArrModule.Sized<<T>>(count, nil :: any)
	if count == 0 then
		settle(target, "Resolved", table.pack(results), nil)
		return target :: any
	end
	local remaining = count
	for idx = 1, count do
		const source = (futs[idx] :: any) :: FutData
		onSettle(source, function()
			if target.status ~= "Pending" then
				return -- 이미 다른 하나가 실패시켰음
			end
			if source.status == "Resolved" then
				results[idx] = (source.values :: Packed)[1]
				remaining -= 1
				if remaining == 0 then
					settle(target, "Resolved", table.pack(results), nil)
				end
			else
				settle(target, "Rejected", nil, source.reason)
			end
		end)
	end
	return target :: any
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

-- 내부 판별과 **같은 함수**입니다 — 두 벌로 두면 하나만 고치는 일이 생깁니다.
const function isFut(value: any): boolean
	return isFutRaw(value)
end

--#endregion

-- stylua: ignore
return {
	New = New,
	Async = Async,
	Resolved = Resolved,
	Rejected = Rejected,
	All = All,
	UseProvider = UseProvider,
	isFut = isFut,

	-- ⭐ 모든 연산은 여기 네임스페이스 함수입니다(`Fut.X(f, …)`) — 콜론 호출은
	-- 없습니다(질문 AB).
	Status = Status, Await = Await, AwaitSafe = AwaitSafe, AndThen = AndThen, Chain = Chain,
	Catch = Catch,
}
