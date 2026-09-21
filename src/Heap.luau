--!strict
--[[
	Heap — 이진 힙. 가장 앞서는 원소를 O(1) 로 보고 O(log n) 으로 꺼냅니다.

	## 표현

	```lua
	{ items: { T }, size: number, less: LessThan<T> }
	```

	평범한 배열에 완전이진트리를 담습니다 — 자식은 `2i`, `2i + 1`, 부모는
	`i // 2`. 노드 테이블이 없어 메모리가 촘촘하고 캐시에 친합니다.

	## 비교자는 **불리언** `LessThan` 입니다

	`less(a, b)` 가 참이면 `a` 가 `b` 보다 **앞섭니다**. 그래서 `Peek` 은
	"가장 앞서는 것" 을 돌려줍니다 — 기본적으로 **최소 힙**입니다.

	최대 힙이 필요하면 비교자를 뒤집으세요:

	```lua
	local maxHeap = Heap.New(function(a: number, b: number) return a > b end)
	```

	3방향 비교자를 쓰려면 `Common.lessFrom(cmp)` 로 감싸면 됩니다. 힙은
	같음을 판정할 일이 없어 불리언이 맞는 자리입니다
	(`src/Common.luau` 상단의 "비교의 통화가 둘인 이유").

	## ⚠️ 순회에 순서가 없습니다

	`Items()` 는 **힙 순서**(배열에 담긴 그대로)이지 정렬 순서가 아닙니다.
	정렬된 것이 필요하면 `Sorted()` 를 쓰세요 — 복사해서 전부 꺼내므로
	O(n log n) 입니다. 순회가 자주 필요하면 애초에 `TreeSet` 이 맞습니다.
]]
local Types = require("./Types")

type LessThan<T> = Types.LessThan<T>

export type HeapData<T> = { items: { T }, size: number, less: LessThan<T> }

local Ifce: HeapIfce

--#region ----------- 내부: 위아래로 밀어넣기 -----------

-- `start` 자리의 원소를 부모와 비교하며 위로 올립니다.
const function siftUp<T>(items: { T }, less: LessThan<T>, start: number)
	local idx = start
	const moving = items[idx]
	while idx > 1 do
		const parent = idx // 2
		if not less(moving, items[parent]) then
			break
		end
		items[idx] = items[parent]
		idx = parent
	end
	items[idx] = moving
end

-- `start` 자리의 원소를 자식과 비교하며 아래로 내립니다.
const function siftDown<T>(items: { T }, size: number, less: LessThan<T>, start: number)
	local idx = start
	const moving = items[idx]
	while true do
		const left = idx * 2
		if left > size then
			break
		end
		-- 두 자식 중 더 앞서는 쪽을 고릅니다.
		local child = left
		const right = left + 1
		if right <= size and less(items[right], items[left]) then
			child = right
		end
		if not less(items[child], moving) then
			break
		end
		items[idx] = items[child]
		idx = child
	end
	items[idx] = moving
end

--#endregion

--#region ----------- 조회 -----------

const function Len<T>(self: HeapData<T>): number
	return self.size
end

const function Empty<T>(self: HeapData<T>): boolean
	return self.size == 0
end

-- 가장 앞서는 원소. **꺼내지 않습니다.** 비어 있으면 `nil`.
const function Peek<T>(self: HeapData<T>): T?
	if self.size == 0 then
		return nil
	end
	return self.items[1]
end

-- ⚠️ **힙 순서**입니다. 정렬 순서가 아닙니다. 복사본이라 건드려도 안전합니다.
const function Items<T>(self: HeapData<T>): { T }
	const out = table.create(self.size) :: { T }
	table.move(self.items, 1, self.size, 1, out)
	return out
end

-- 정렬된 배열. **원본은 그대로입니다** — 복사해서 전부 꺼냅니다(O(n log n)).
const function Sorted<T>(self: HeapData<T>): { T }
	const size = self.size
	const work = table.create(size) :: { T }
	table.move(self.items, 1, size, 1, work)
	const less = self.less
	const out = table.create(size) :: { T }
	local remaining = size
	for idx = 1, size do
		out[idx] = work[1]
		work[1] = work[remaining]
		work[remaining] = nil :: any
		remaining -= 1
		if remaining > 1 then
			siftDown(work, remaining, less, 1)
		end
	end
	return out
end

--#endregion

--#region ----------- 변형 -----------

const function Push<T>(self: HeapData<T>, item: T): Heap<T>
	const size = self.size + 1
	self.items[size] = item
	self.size = size
	siftUp(self.items, self.less, size)
	return self :: any
end

-- 가장 앞서는 원소를 꺼내 돌려줍니다. 비어 있으면 `nil`.
const function Pop<T>(self: HeapData<T>): T?
	const size = self.size
	if size == 0 then
		return nil
	end
	const items = self.items
	const top = items[1]
	items[1] = items[size]
	items[size] = nil :: any
	self.size = size - 1
	if self.size > 1 then
		siftDown(items, self.size, self.less, 1)
	end
	return top
end

-- 넣고 바로 꺼냅니다. **`Push` 후 `Pop` 보다 1.78배 쌉니다**(실측) — 힙을
-- 한 번만 흔듭니다. 넣으려는 것이 이미 가장 앞서면 그대로 돌려주고 힙은
-- 아예 안 건드립니다. 상위 k 개를 고르는 자리에서 특히 값집니다.
const function PushPop<T>(self: HeapData<T>, item: T): T
	const size = self.size
	if size == 0 or self.less(item, self.items[1]) then
		return item
	end
	const items = self.items
	const top = items[1]
	items[1] = item
	siftDown(items, size, self.less, 1)
	return top
end

-- 꼭대기를 새 원소로 **갈아 끼우고** 원래 꼭대기를 돌려줍니다.
-- 비어 있으면 그냥 넣고 `nil` 을 돌려줍니다.
const function Replace<T>(self: HeapData<T>, item: T): T?
	const size = self.size
	if size == 0 then
		Push(self, item)
		return nil
	end
	const items = self.items
	const top = items[1]
	items[1] = item
	siftDown(items, size, self.less, 1)
	return top
end

const function Clear<T>(self: HeapData<T>): ()
	table.clear(self.items)
	self.size = 0
end

const function Clone<T>(self: HeapData<T>): Heap<T>
	const items = table.create(self.size) :: { T }
	table.move(self.items, 1, self.size, 1, items)
	return setmetatable({ items = items, size = self.size, less = self.less } :: any, Ifce :: any) :: any
end

--#endregion

--#region ----------- 타입 조립 -----------
-- 힙은 `Types` 의 계약 중 어느 것도 만족하지 않습니다. 순차도 맵도 셋도
-- 아니고, "가장 앞서는 것 하나" 만 의미가 있는 구조라 억지로 끼우면 계약이
-- 거짓말을 하게 됩니다.

type HeapIfce = {
	Len: typeof(Len),
	Empty: typeof(Empty),
	Peek: typeof(Peek),
	Items: typeof(Items),
	Sorted: typeof(Sorted),
	Push: typeof(Push),
	Pop: typeof(Pop),
	PushPop: typeof(PushPop),
	Replace: typeof(Replace),
	Clear: typeof(Clear),
	Clone: typeof(Clone),
}

export type Heap<T> = HeapData<T> & HeapIfce

Ifce = {
	Len = Len, Empty = Empty, Peek = Peek, Items = Items, Sorted = Sorted,
	Push = Push, Pop = Pop, PushPop = PushPop, Replace = Replace,
	Clear = Clear, Clone = Clone,
} :: any
;(Ifce :: any).__index = Ifce

--#endregion

--#region ----------- 생성자 -----------

const function New<T>(less: LessThan<T>): Heap<T>
	return setmetatable({ items = {} :: { T }, size = 0, less = less } :: any, Ifce :: any) :: any
end

-- 배열에서 만듭니다. **한 번에 힙으로 만듭니다** — 뒤쪽 절반은 이미 잎이라
-- 건드릴 필요가 없어서, 가운데부터 거꾸로 내려가며 밀어넣습니다.
--
-- 차수로는 O(n) 대 `Push` 반복의 O(n log n) 인데, **실측에서는 그 격차가
-- N 에 따라 벌어지지 않습니다** — 1.7배 안팎으로 거의 일정합니다:
--
--     N=10000    1.86배    N=100000   1.68배    N=500000   1.74배
--
-- 무작위 입력에서는 `Push` 의 평균 밀어올림 깊이가 상수라서 그렇습니다
-- (새 원소는 거의 항상 아래쪽에 자리잡습니다). **그래도 1.7배는 1.7배이니
-- 한 번에 담을 수 있으면 이쪽을 쓰세요.**
const function FromList<T>(list: { T }, less: LessThan<T>): Heap<T>
	const size = #list
	const items = table.create(size) :: { T }
	table.move(list, 1, size, 1, items)
	for idx = size // 2, 1, -1 do
		siftDown(items, size, less, idx)
	end
	return setmetatable({ items = items, size = size, less = less } :: any, Ifce :: any) :: any
end

const function isHeap(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Ifce
end

--#endregion

return {
	New = New,
	FromList = FromList,
	isHeap = isHeap,
}
