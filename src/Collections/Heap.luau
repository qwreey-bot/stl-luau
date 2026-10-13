--!strict
--[[
	Heap — 이진 힙. 가장 앞서는 원소를 O(1) 로 보고 O(log n) 으로 꺼냅니다.

	## 표현

	```lua
	{ items: { T }, size: number, less: LessThan<T> }
	```

	평범한 배열에 완전이진트리를 담습니다 — 자식은 `2i`, `2i + 1`, 부모는
	`i // 2`. 노드 테이블이 없어 메모리가 촘촘하고 캐시에 친합니다.
	그 배치와 순서를 지키는 도구(올리기·내리기·한 번에 짓기)는 `Trees/CompleteArray` 의 것이고,
	이 모듈은 그것을 조립합니다(3층).

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
	O(n log n) 입니다. 순회가 자주 필요하면 애초에 `FlatSet` 이 맞습니다.
]]
local Types = require("../Types")
local Common = require("../Common")
local Trait = require("../Trait")
local Collection = require("../Traits/Collection")
local CompleteArray = require("../Trees/CompleteArray")
Common.registerSource(debug.info(1, "s"))

type LessThan<T> = Types.LessThan<T>

export type HeapData<T> = {
	items: { T },
	size: number,
	less: LessThan<T>,
	read __type: Trait.Token<"Heap">,
	-- 바꾸는 컬렉션 알고리즘용 팬텀(`Collection.MarkerMut`, 2026-10-12) — 타입에만 있습니다.
	read __collectionMut: true,
}

-- 인스턴스 판별용 태그. **메타테이블은 없습니다**(질문 AB) — 데이터는 평범한
-- 테이블(엔티티), 연산은 이 모듈의 네임스페이스 함수(서비스)입니다.
-- 리터럴로 둡니다 — `Trait.TYPE_KEY` 를 받아 쓰면 상수 접기가 안 돼 생성이 7~11% 느려졌습니다(perf 21절).
const TYPE_KEY = "__type"
const TOKEN = Trait.NewToken("Heap") :: Trait.Token<"Heap">

-- 날 테이블에 태그를 붙입니다. 생성자들이 공유합니다.
const function tagged(raw: any): any
	raw[TYPE_KEY] = TOKEN
	return raw
end

--#region ----------- 내부: 위아래로 밀어넣기 -----------

-- 올리기·내리기는 **배열에 담은 완전 이진 트리**의 것입니다(`Trees/CompleteArray` — 2층 트리부). 힙은 그 위에
-- 크기·비교자·타입 토큰을 얹은 조립입니다(2026-10-13 사용자: *"완전이진의 노드형/배열형 만들고 heap 에서 그거 사용"*).
-- 지역으로 받아 두어 호출은 예전의 지역 함수와 같은 값입니다(perf 41절).
const siftUp, siftDown, heapify = CompleteArray.SiftUp, CompleteArray.SiftDown, CompleteArray.Heapify

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
			siftDown(work, remaining, 1, less)
		end
	end
	return out
end

--#endregion

--#region ----------- 변형 -----------

-- ⚠️ 비교자가 도중에 에러를 내면 원소는 **이미 들어간 채** 힙 성질이 깨질 수
-- 있습니다(먼저 담고 밀어올리므로). 대부분의 라이브러리가 그렇고, 비교자는
-- 던지지 않는 것이 계약입니다(2026-09-30 리뷰 — 문서로 둠).
const function Push<T>(self: HeapData<T>, item: T): Heap<T>
	const size = self.size + 1
	self.items[size] = item
	self.size = size
	siftUp(self.items, size, self.less)
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
		siftDown(items, self.size, 1, self.less)
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
	siftDown(items, size, 1, self.less)
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
	siftDown(items, size, 1, self.less)
	return top
end

-- 비우고 **자기 자신을 돌려줍니다**(2026-10-12 사용자 결정, 질문 AM — 일곱 컨테이너가 같게. 반환은 공짜였음).
const function Clear<T>(self: HeapData<T>): Heap<T>
	table.clear(self.items)
	self.size = 0
	return self
end

const function Clone<T>(self: HeapData<T>): Heap<T>
	const items = table.create(self.size) :: { T }
	table.move(self.items, 1, self.size, 1, items)
	return tagged({ items = items, size = self.size, less = self.less })
end

--#endregion

--#region ----------- 타입 -----------
-- 함수가 타입 바깥(네임스페이스)에 있으니 전체형은 데이터부 그 자체입니다(질문 AB).
export type Heap<T> = HeapData<T>

--#endregion

--#region ----------- 생성자 -----------

const function New<T>(less: LessThan<T>): Heap<T>
	return tagged({ items = {} :: { T }, size = 0, less = less })
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
	-- 길이는 `Common.listLength` 규약(`n` 우선, 구멍은 건너뜀, M0 3라운드). 조밀한
	-- 사본이 곧 힙 저장소입니다.
	const items, size = Common.denseList(list)
	heapify(items, size, less)
	return tagged({ items = items, size = size, less = less })
end

const function isHeap(value: any): boolean
	-- 타입 토큰 하나만 봅니다(2026-10-06 — 위조는 막지 않음, `Trait.luau` 머리).
	return type(value) == "table" and rawget(value, TYPE_KEY) == TOKEN
end

--#endregion

-- stylua: ignore
const HeapModule = {
	New = New,
	FromList = FromList,
	isHeap = isHeap,
	-- 이 종류의 타입 토큰(값의 `__type`) — 바깥 트레이트를 이 종류에 붙일 때: `Trait.Impl(MyTrait, Heap.Token, impl)`
	Token = TOKEN,

	-- ⭐ 모든 연산은 여기 네임스페이스 함수입니다(`Heap.X(v, …)`) — 콜론 호출은
	-- 없습니다(질문 AB). `local` 로 받아 부르면 더 빠릅니다(perf 14·16절).
	Len = Len, Empty = Empty, Peek = Peek, Items = Items, Sorted = Sorted, Push = Push, Pop = Pop,
	PushPop = PushPop, Replace = Replace, Clear = Clear, Clone = Clone,
}

-- 리스트·맵·셋 계약은 만족하지 않지만(순서가 힙 순서) 크기와 비우기는 됩니다(2026-10-12).
Trait.Impl(Collection, TOKEN, HeapModule)

return HeapModule
