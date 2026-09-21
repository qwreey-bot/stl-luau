--!strict
-- 예전 C++ 과제(MyList.h)의 설계를 Luau 타입으로 옮길 수 있는가?
--   template <typename Element, typename Index> class List
--   ArrayList  : List<Element, int>
--   LinkedList : List<Element, ListNode<Element>*>
-- 최소 primitive 5개만 구현하면 공통 알고리즘을 한 번만 짜서 공유하는 구조.
--
-- 검사: (a) Index 가 타입 파라미터로 서는가 (b) 공통 알고리즘이 양쪽에
--       재사용되는가 (c) 두 구현의 Index 가 섞이면 잡히는가

-- 최소 primitive 5개 (구현체가 제공)
export type ListCore<E, I> = {
	Get: (self: ListCore<E, I>, idx: I) -> E?,
	FirstIndex: (self: ListCore<E, I>) -> I?,
	LastIndex: (self: ListCore<E, I>) -> I?,
	NextIndex: (self: ListCore<E, I>, idx: I) -> I?,
	PrevIndex: (self: ListCore<E, I>, idx: I) -> I?,
}

-- 공통 알고리즘: primitive 만으로 짜고 **한 번만** 존재한다
local function IndexOf<E, I>(self: ListCore<E, I>, item: E): I?
	local idx = self:FirstIndex()
	while idx ~= nil do
		if self:Get(idx) == item then
			return idx
		end
		idx = self:NextIndex(idx)
	end
	return nil
end
local function Contains<E, I>(self: ListCore<E, I>, item: E): boolean
	return IndexOf(self, item) ~= nil
end
local function Count<E, I>(self: ListCore<E, I>): number
	local total, idx = 0, self:FirstIndex()
	while idx ~= nil do
		total += 1
		idx = self:NextIndex(idx)
	end
	return total
end

-- 구현 1: 배열 기반 — Index 는 number
type ArrayList<E> = ListCore<E, number> & { PushBack: (self: ArrayList<E>, v: E) -> () }
-- 구현 2: 연결 기반 — Index 는 노드
type Node<E> = { value: E, next: Node<E>?, prev: Node<E>? }
type LinkedList<E> = ListCore<E, Node<E>> & { PushBack: (self: LinkedList<E>, v: E) -> () }

local al = (nil :: any) :: ArrayList<string>
local ll = (nil :: any) :: LinkedList<string>

-- POS: 같은 공통 알고리즘이 양쪽에 쓰인다
local p1: number? = IndexOf(al, "a")
local p2: Node<string>? = IndexOf(ll, "a")
local p3: boolean = Contains(al, "a")
local p4: boolean = Contains(ll, "a")
local p5: number = Count(ll)

-- NEG: 전부 에러여야 함
local n1: Node<string>? = IndexOf(al, "a") -- 배열의 Index 는 number
local n2: number? = IndexOf(ll, "a") -- 연결의 Index 는 Node
local n3 = IndexOf(al, 42) -- 원소 타입이 string 인데 number
local n4 = al:Get(ll:FirstIndex()) -- 다른 구현의 Index 를 섞음
local n5: string = Count(al) -- number 인데

local canary: string = 42
return { p1, p2, p3, p4, p5, n1, n2, n3, n4, n5, canary }
