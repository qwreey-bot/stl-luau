--!strict
--[[
	Deque — 양끝에서 O(1) 로 넣고 빼는 리스트(링 버퍼). M5(2026-10-07).

	## 왜 따로 있는가

	`Arr.PopFront`/`PushFront` 는 뒤 원소를 전부 미는 O(n) 입니다. 큐(BFS)·작업 목록·미끄럼 창처럼
	**앞에서 빼는** 용도면 이것을 쓰세요. 앞에서 뺄 일이 없으면 `Arr` 이 모든 면에서 낫습니다(조회·
	순회가 한 단계 더 짧고 `table.move` 벌크 연산이 다 있음).

	## 표현 — 링 버퍼

	```lua
	{ head: number, size: number, cap: number, [1..cap]: T }
	```

	원소는 테이블 자신의 `1..cap` 칸에 감겨 있고, 논리 위치 `i`(1부터)는 물리 칸 `head + i` 입니다
	(`cap` 을 넘으면 `cap` 을 뺌 — `%` 대신 비교 하나). 차면 `cap` 을 두 배로 늘리며 감긴 앞부분을
	뒤로 펼칩니다(`table.move`). 줄이지는 않습니다(Rust `VecDeque` 와 같음 — 줄이려면 `Clone`).

	**두 인덱스 방식**(`first`/`last` 를 늘이고 줄이는 PIL 큐)보다 쟀을 때 낫습니다(perf 24절):
	길이가 유지되는 큐에서 키가 계속 커지면 배열 부분을 벗어나 해시로 가서 3배 느렸고, `PushFront`
	는 음수 키라 처음부터 해시였습니다.

	⚠️ 길이 필드 이름이 `n` 이 아니라 **`size`** 입니다 — `n` 을 두면 `{ n, [1..n] }` 리스트로
	잘못 읽히기 쉽습니다(물리 칸은 감겨 있음). 리스트 진입점(`Arr.FromTable` 등)은 타입 토큰이
	`Arr` 가 아니면 받지 않습니다(`Common.listLength`) — 넘기려면 `Deque.ToArr`.

	## 구멍

	`Arr` 처럼 `nil` 원소를 담을 수 있고 타입에 `T?` 로 드러납니다(`Deque.New<<number?>>()`).
	`PopFront`·`Front`·`At` 이 `nil` 을 돌려주면 비었는지 구멍인지는 `Len` 으로 가르세요.

	## 데이터는 엔티티, 함수는 서비스

	메타테이블 없는 평범한 테이블이고 연산은 이 모듈의 네임스페이스 함수입니다(질문 AB). 리스트
	트레이트(`Trait.List`)를 구현해 `Algorithm.IndexOf(d, x)` 가 됩니다.
]]
local Types = require("./Types")
local Common = require("./Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("./Trait")
local Arr = require("./Arr")

export type DequeData<T> = {
	head: number,
	size: number,
	cap: number,
	read __type: Trait.Token<"Deque">,
	read __list: T,
	read __listIndex: number,
	[number]: T,
}
export type Deque<T> = DequeData<T>
type Arr<T> = Arr.Arr<T>

-- 리터럴로 둡니다 — `Trait.TYPE_KEY` 를 받아 쓰면 상수 접기가 안 돼 생성이 느려졌습니다(perf 21절).
const TYPE_KEY = "__type"
const TOKEN = Trait.Types.Deque

-- 처음 칸 수. 0 이면 두 배로 늘릴 수 없어 바닥을 둡니다.
const MIN_CAPACITY = 4
-- `table.create` 의 한계(`Arr` 의 길이 정책과 같음).
const MAX_LENGTH = 2 ^ 26

--#region ----------- 내부 헬퍼 -----------

const function newBuffer<T>(cap: number): Deque<T>
	const d = table.create(cap) :: any
	d.head = 0
	d.size = 0
	d.cap = cap
	d[TYPE_KEY] = TOKEN
	return d
end

-- 칸 수 인자. 소수는 0 쪽으로, 음수·NaN·한계 초과는 에러(`Arr` 의 길이 정책).
const function checkCapacity(capacity: number): number
	const count = if capacity >= 0 then math.floor(capacity) else math.ceil(capacity)
	if not (count >= 0) or count > MAX_LENGTH then
		Common.raise(`Deque: capacity must be in [0, {MAX_LENGTH}] (got {capacity})`)
	end
	return if count < MIN_CAPACITY then MIN_CAPACITY else count
end

-- 꽉 찬 버퍼를 두 배로. 감긴 앞부분(물리 `1..head`)을 `cap + 1..` 로 옮기면 원소가
-- `head + 1 .. head + cap` 에 이어지고, 새 `cap`(두 배) 안에서는 감기지 않습니다.
const function grow<T>(self: DequeData<T>)
	const cap = self.cap
	const head = self.head
	if head > 0 then
		table.move(self :: any, 1, head, cap + 1)
		for idx = 1, head do
			self[idx] = nil :: any
		end
	end
	self.cap = cap * 2
end

-- 논리 위치(1..size)의 물리 칸.
const function slot<T>(self: DequeData<T>, idx: number): number
	const pos = self.head + idx
	return if pos > self.cap then pos - self.cap else pos
end

-- 논리 순서대로 `out` 의 `1..size` 에 복사합니다(감긴 두 조각을 `table.move` 둘로).
const function copyInto<T>(self: DequeData<T>, out: any)
	const size = self.size
	const head = self.head
	const firstLen = math.min(size, self.cap - head)
	table.move(self :: any, head + 1, head + firstLen, 1, out)
	if firstLen < size then
		table.move(self :: any, 1, size - firstLen, firstLen + 1, out)
	end
end

--#endregion

--#region ----------- 계약 구현 (Types.ListOps) -----------
-- 위치는 논리 위치(1..size). 알고리즘이 준 위치만 받는 자리라 검사하지 않습니다(`Arr` 과 같음).

const function Get<T>(self: DequeData<T>, idx: number): T?
	if idx < 1 or idx > self.size then
		return nil
	end
	return self[slot(self, idx)]
end
const function FirstIndex<T>(self: DequeData<T>): number?
	return if self.size > 0 then 1 else nil
end
const function LastIndex<T>(self: DequeData<T>): number?
	return if self.size > 0 then self.size else nil
end
const function NextIndex<T>(self: DequeData<T>, idx: number): number?
	return if idx < self.size then idx + 1 else nil
end
const function PrevIndex<T>(self: DequeData<T>, idx: number): number?
	return if idx > 1 then idx - 1 else nil
end

--#endregion

--#region ----------- 넣기·꺼내기 -----------

-- 맨 뒤에 넣습니다. 분할 상환 O(1). 자기 자신을 돌려줍니다(`Arr.PushBack` 과 같음).
const function PushBack<T>(self: DequeData<T>, item: T): Deque<T>
	const size = self.size
	if size == self.cap then
		grow(self)
	end
	local pos = self.head + size + 1
	if pos > self.cap then
		pos -= self.cap
	end
	self[pos] = item
	self.size = size + 1
	return self :: any
end

-- 맨 앞에 넣습니다. 분할 상환 O(1).
const function PushFront<T>(self: DequeData<T>, item: T): Deque<T>
	const size = self.size
	if size == self.cap then
		grow(self)
	end
	local head = self.head - 1
	if head < 0 then
		head += self.cap
	end
	self[head + 1] = item
	self.head = head
	self.size = size + 1
	return self :: any
end

-- 맨 앞을 꺼냅니다. 비었으면 `nil`(질문 AI — `Arr.PopFront` 와 같음). O(1).
const function PopFront<T>(self: DequeData<T>): T?
	const size = self.size
	if size == 0 then
		return nil
	end
	const pos = self.head + 1
	const item = self[pos]
	self[pos] = nil :: any
	self.head = if pos == self.cap then 0 else pos
	self.size = size - 1
	return item
end

-- 맨 뒤를 꺼냅니다. 비었으면 `nil`. O(1).
const function PopBack<T>(self: DequeData<T>): T?
	const size = self.size
	if size == 0 then
		return nil
	end
	const pos = slot(self, size)
	const item = self[pos]
	self[pos] = nil :: any
	self.size = size - 1
	return item
end

--#endregion

--#region ----------- 조회 -----------

-- 맨 앞 원소(꺼내지 않음). 비었으면 `nil`.
const function Front<T>(self: DequeData<T>): T?
	if self.size == 0 then
		return nil
	end
	return self[self.head + 1]
end

-- 맨 뒤 원소(꺼내지 않음). 비었으면 `nil`.
const function Back<T>(self: DequeData<T>): T?
	if self.size == 0 then
		return nil
	end
	return self[slot(self, self.size)]
end

-- 논리 위치의 원소. `Arr.At` 과 같은 규약 — 음수는 뒤에서(`-1` = 맨 뒤), 소수는 0 쪽으로,
-- NaN 은 에러, 범위 밖은 `nil`.
const function At<T>(self: DequeData<T>, idx: number): T?
	if idx ~= idx then
		Common.raise("Deque: At index is NaN")
	end
	const size = self.size
	const i = if idx >= 0 then math.floor(idx) else math.ceil(idx)
	const pos = if i < 0 then size + i + 1 else i
	if pos < 1 or pos > size then
		return nil
	end
	return self[slot(self, pos)]
end

const function Len<T>(self: DequeData<T>): number
	return self.size
end

const function Empty<T>(self: DequeData<T>): boolean
	return self.size == 0
end

-- `for i, v in Deque.Iter(d) do … end` — 앞에서 뒤로, `i` 는 논리 위치. `(number, T)` 비옵셔널
-- 선언은 `ipairs`·`Arr.Iter` 와 같은 이유. 도는 동안 넣거나 빼면 순서는 약속하지 않습니다.
const function iterStep<T>(self: DequeData<T>, idx: number): (number, T)
	const nextIdx = idx + 1
	if nextIdx > self.size then
		return nil :: any, nil :: any
	end
	return nextIdx, self[slot(self, nextIdx)]
end

const function Iter<T>(self: DequeData<T>): (typeof(iterStep), DequeData<T>, number)
	return iterStep, self, 0
end

-- 앞에서 뒤 순서의 새 `Arr`(구멍은 그대로, 길이는 `size`). 리스트 진입점에 넘길 때.
const function ToArr<T>(self: DequeData<T>): Arr<T>
	const size = self.size
	const raw = table.create(size) :: any
	copyInto(self, raw)
	raw.n = size
	return Arr.FromTable(raw)
end

--#endregion

--#region ----------- 변형 -----------

-- 비웁니다. 칸 수(`cap`)는 그대로입니다. 살아 있는 칸(감긴 두 구간)만 지워 **O(size)** — 처음엔
-- `1..cap` 을 다 지워, 크게 자랐던 덱을 재사용(BFS 마다 `Clear`)하면 원소 둘에도 O(cap) 이었습니다
-- (M5 리뷰 1라운드: cap 131072 에서 1000번 722ms). 살아 있지 않은 칸은 늘 비어 있습니다(꺼낼 때 지움).
const function Clear<T>(self: DequeData<T>): Deque<T>
	const size = self.size
	const head = self.head
	const firstLen = math.min(size, self.cap - head)
	for idx = head + 1, head + firstLen do
		self[idx] = nil :: any
	end
	for idx = 1, size - firstLen do
		self[idx] = nil :: any
	end
	self.head = 0
	self.size = 0
	return self :: any
end

-- 얕은 복사. 감긴 것을 펴서 앞에서부터 담습니다. 칸 수는 원소 수에 맞춥니다(최소 4) — 줄이는
-- 길이기도 합니다.
const function Clone<T>(self: DequeData<T>): Deque<T>
	const size = self.size
	const copy = newBuffer(if size < MIN_CAPACITY then MIN_CAPACITY else size)
	copyInto(self, copy)
	copy.size = size
	return copy :: any
end

--#endregion

--#region ----------- 생성자 -----------

-- ⚠️ 빈 덱은 원소 타입을 직접 알려줘야 합니다: `Deque.New<<number>>()`. `capacity` 는 미리 잡아 둘
-- 칸 수(선택, 최소 4).
const function New<T>(capacity: number?): Deque<T>
	return newBuffer(if capacity == nil then MIN_CAPACITY else checkCapacity(capacity))
end

-- 리스트에서 만듭니다(복사). 길이는 `Common.listLength` 규약(`n` 우선, `Arr` 이면 그 `n`, 아니면 `#`).
const function FromList<T>(list: { T }): Deque<T>
	const len = Common.listLength(list)
	const d = newBuffer(if len < MIN_CAPACITY then MIN_CAPACITY else len)
	table.move(list :: any, 1, len, 1, d :: any)
	d.size = len
	return d :: any
end

-- `Deque.Of(1, 2, 3)` — 인자 사이의 `nil` 도 보존(`Arr.Of` 와 같음).
const function Of<T>(...: T): Deque<T>
	const count = select("#", ...)
	const d = newBuffer(if count < MIN_CAPACITY then MIN_CAPACITY else count)
	for idx = 1, count do
		(d :: any)[idx] = select(idx, ...)
	end
	d.size = count
	return d :: any
end

const function isDeque(value: any): boolean
	return type(value) == "table" and rawget(value, TYPE_KEY) == TOKEN
end

--#endregion

-- stylua: ignore
const DequeModule = {
	New = New, FromList = FromList, Of = Of, isDeque = isDeque,

	-- ⭐ 모든 연산은 여기 네임스페이스 함수입니다(`Deque.X(d, …)`) — 콜론 호출은 없습니다(질문 AB).
	PushBack = PushBack, PushFront = PushFront, PopBack = PopBack, PopFront = PopFront,
	Front = Front, Back = Back, At = At, Len = Len, Empty = Empty, Iter = Iter, ToArr = ToArr,
	Clear = Clear, Clone = Clone,
	Get = Get, FirstIndex = FirstIndex, LastIndex = LastIndex, NextIndex = NextIndex, PrevIndex = PrevIndex,
}

-- 모듈 테이블이 그대로 리스트 트레이트의 구현체입니다.
Trait.Impl(Trait.List, TOKEN, DequeModule)

-- `Types` 는 계약 타입만 — 구현이 계약을 만족하는지 여기서 정적으로 확인합니다.
const _ops: Types.ListOps<Deque<any>, any, number> = DequeModule

return DequeModule
