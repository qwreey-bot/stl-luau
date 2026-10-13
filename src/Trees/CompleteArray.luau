--!strict
--[[
	CompleteArray — **배열에 담은 완전 이진 트리**(2층 트리부, 2026-10-13 사용자: *"완전이진 같은 경우는 배열식,
	노드식 둘을 제공하는 방향"*, *"heap 에서 그거 사용"*).

	## 칸 배치 (계약)

	평범한 배열 `list` 의 `1..count` 가 트리입니다 — 층별로 왼쪽부터 빈틈없이 채운 순서:

	`list[1]` 이 뿌리, `idx` 의 자식은 `2 * idx`(왼쪽)·`2 * idx + 1`(오른쪽), 부모는 `idx // 2`.

	노드 테이블이 없습니다 — 위치(번호)가 곧 구조라 메모리가 촘촘합니다. 길이는 배열이 아니라 **쓰는 쪽이 듭니다**
	(`count` 를 인자로 받음 — `BSearch` 와 같은 모양). 그래서 `Arr`·힙의 저장소·평범한 배열에 다 먹습니다.

	## 무엇이 여기 있는가

	- 자리 계산: `Parent`·`Left`·`Right`·`Height`.
	- **힙 순서**(부모가 자식보다 뒤서지 않음)를 지키는 도구: `SiftUp`·`SiftDown`·`Heapify`·`IsHeap`. 완전 이진
	  트리에서 "균형" 은 모양이 이미 해 주니, 고칠 것은 순서뿐입니다. `Heap`(3층)이 이것으로 조립되고, 힙 정렬도
	  이것으로 짭니다.

	비교는 불리언 `LessThan` 입니다 — `less(a, b)` 가 참이면 `a` 가 `b` 보다 **앞섭니다**(뿌리 쪽에 옴).

	## ⚠️ 인자를 검사하지 않습니다

	위치는 `1..count` 의 정수, `count` 는 배열에 실제로 든 개수여야 합니다. 조립하는 쪽이 준 값만 받는 자리라
	검사하지 않습니다(규약의 "계약 함수" 예외). `1..count` 사이에 구멍(`nil`)이 있으면 비교자가 `nil` 을 받습니다.
	비교자가 도중에 던지면 옮기던 원소가 제자리에 안 놓인 채 남습니다(관측 — 계약 아님).
]]
local Types = require("../Types")
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))

type LessThan<T> = Types.LessThan<T>

-- 부모의 위치. 뿌리(`1`)면 `nil`.
const function Parent(idx: number): number?
	if idx <= 1 then
		return nil
	end
	return idx // 2
end

-- 왼쪽 자식의 위치. 없으면(`count` 를 넘으면) `nil`.
const function Left(idx: number, count: number): number?
	const left = idx * 2
	return if left <= count then left else nil
end

-- 오른쪽 자식의 위치. 없으면 `nil`.
const function Right(idx: number, count: number): number?
	const right = idx * 2 + 1
	return if right <= count then right else nil
end

-- 층의 수(빈 트리는 0, 노드 하나는 1). `count` 개를 담은 완전 이진 트리의 높이는 `floor(log2(count)) + 1`.
const function Height(count: number): number
	local height = 0
	while count > 0 do
		height += 1
		count //= 2
	end
	return height
end

-- `idx` 의 원소를 **뿌리 쪽으로** 올립니다 — 부모보다 앞서는 동안. 맨 뒤에 새 원소를 놓은 뒤 부르는 자리.
-- 원소를 맞바꾸지 않고 "구멍" 을 밀어 올린 뒤 한 번 씁니다(쓰기가 걸음마다 하나).
const function SiftUp<T>(list: { T }, idx: number, less: LessThan<T>)
	const moving = list[idx]
	while idx > 1 do
		const parent = idx // 2
		if not less(moving, list[parent]) then
			break
		end
		list[idx] = list[parent]
		idx = parent
	end
	list[idx] = moving
end

-- `idx` 의 원소를 **잎 쪽으로** 내립니다 — 더 앞서는 자식이 있는 동안. 뿌리를 갈아 끼운 뒤 부르는 자리.
const function SiftDown<T>(list: { T }, count: number, idx: number, less: LessThan<T>)
	const moving = list[idx]
	while true do
		const left = idx * 2
		if left > count then
			break
		end
		-- 두 자식 중 더 앞서는 쪽을 고릅니다.
		local child = left
		const right = left + 1
		if right <= count and less(list[right], list[left]) then
			child = right
		end
		if not less(list[child], moving) then
			break
		end
		list[idx] = list[child]
		idx = child
	end
	list[idx] = moving
end

-- 아무 순서의 `1..count` 를 **한 번에** 힙 순서로 만듭니다(O(n)). 뒤쪽 절반은 이미 잎이라 건드릴 필요가 없어서,
-- 가운데부터 거꾸로 내려가며 내립니다. 하나씩 넣는 것(O(n log n))의 1.7배쯤 빠릅니다(`Heap.FromList` 실측).
const function Heapify<T>(list: { T }, count: number, less: LessThan<T>)
	for idx = count // 2, 1, -1 do
		SiftDown(list, count, idx, less)
	end
end

-- `1..count` 가 힙 순서인가(어느 자식도 부모보다 앞서지 않음). 빈 것·하나는 참. O(n) — 검사·디버깅용.
const function IsHeap<T>(list: { T }, count: number, less: LessThan<T>): boolean
	for idx = 2, count do
		if less(list[idx], list[idx // 2]) then
			return false
		end
	end
	return true
end

-- stylua: ignore
return {
	Parent = Parent, Left = Left, Right = Right, Height = Height,
	SiftUp = SiftUp, SiftDown = SiftDown, Heapify = Heapify, IsHeap = IsHeap,
}
