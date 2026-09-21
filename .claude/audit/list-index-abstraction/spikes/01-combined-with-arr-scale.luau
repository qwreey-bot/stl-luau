--!strict
-- 합산 규모 시험: 위치 타입 제네릭(ListCore<E,I>) + 54개 메소드 Arr<T> 를
-- **한 파일에서** 같이 세우면 버티는가?
--   * arr-type-redesign: 교집합 필수(setmetatable 은 30개에서 붕괴)
--   * list-index-abstraction: ListCore<E,I> 는 단독으로는 성립
-- 따로는 확인했지만 합쳐서는 안 재봤다.

export type ArrData<T> = { n: number, [number]: T }
type Node<E> = { value: E, next: Node<E>?, prev: Node<E>? }

-- 위치 타입 제네릭 코어
export type ListCore<E, I> = {
	Get: (self: ListCore<E, I>, idx: I) -> E?,
	FirstIndex: (self: ListCore<E, I>) -> I?,
	LastIndex: (self: ListCore<E, I>) -> I?,
	NextIndex: (self: ListCore<E, I>, idx: I) -> I?,
	PrevIndex: (self: ListCore<E, I>, idx: I) -> I?,
}

-- 조회기 위의 공용 알고리즘 (한 번만 존재)
local function IndexOf<E, I>(self: ListCore<E, I>, item: E): I?
	local idx = self:FirstIndex()
	while idx ~= nil do
		if self:Get(idx) == item then return idx end
		idx = self:NextIndex(idx)
	end
	return nil
end
local function CountOf<E, I>(self: ListCore<E, I>): number
	local total, idx = 0, self:FirstIndex()
	while idx ~= nil do total += 1; idx = self:NextIndex(idx) end
	return total
end

-- ArrView: 콜백이 받는 뷰 (Arr<T> 를 언급하지 않음)
export type ArrView<T> = ArrData<T> & {
	Len: (self: ArrView<T>) -> number,
	Join: (self: ArrView<T>, sep: string?) -> string,
	Slice: (self: ArrView<T>, a: number?, b: number?) -> ArrView<T>,
}

local function Clear<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Clone<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Consume<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Count<T>(self: Arr<T>): number
	return nil :: any
end
local function Each<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Empty<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Equal<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Erase<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function EraseInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Every<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Fill<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Filter<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function FilterInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Find<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Flat<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function FlatInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Flatmap<T, G>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrView<T>) -> G): Arr<G>
	return nil :: any
end
local function FlatmapInplace<T, G>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrView<T>) -> G): Arr<G>
	return nil :: any
end
local function Insert<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function InsertArray<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function InsertMany<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Iter<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Join<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Len<T>(self: Arr<T>): number
	return nil :: any
end
local function Map<T, G>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrView<T>) -> G): Arr<G>
	return nil :: any
end
local function MapInplace<T, G>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrView<T>) -> G): Arr<G>
	return nil :: any
end
local function Max<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function MergeInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Min<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Prod<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Push<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function PushArray<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function PushMany<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Rangeflat<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function RangeflatInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Reduce<T, U>(self: Arr<T>, fn: (U, T) -> U, i: U): U
	return nil :: any
end
local function Replace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function ReplaceInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Reverse<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function ReverseInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Rotate<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function RotateInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Shuffle<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function ShuffleInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Slice<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function SliceInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Some<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function SortInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Sorted<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Sum<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Unpack<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Unshift<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function UnshiftArray<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function UnshiftMany<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end

type ArrIfce = {
	Clear: typeof(Clear),
	Clone: typeof(Clone),
	Consume: typeof(Consume),
	Count: typeof(Count),
	Each: typeof(Each),
	Empty: typeof(Empty),
	Equal: typeof(Equal),
	Erase: typeof(Erase),
	EraseInplace: typeof(EraseInplace),
	Every: typeof(Every),
	Fill: typeof(Fill),
	Filter: typeof(Filter),
	FilterInplace: typeof(FilterInplace),
	Find: typeof(Find),
	Flat: typeof(Flat),
	FlatInplace: typeof(FlatInplace),
	Flatmap: typeof(Flatmap),
	FlatmapInplace: typeof(FlatmapInplace),
	Insert: typeof(Insert),
	InsertArray: typeof(InsertArray),
	InsertMany: typeof(InsertMany),
	Iter: typeof(Iter),
	Join: typeof(Join),
	Len: typeof(Len),
	Map: typeof(Map),
	MapInplace: typeof(MapInplace),
	Max: typeof(Max),
	MergeInplace: typeof(MergeInplace),
	Min: typeof(Min),
	Prod: typeof(Prod),
	Push: typeof(Push),
	PushArray: typeof(PushArray),
	PushMany: typeof(PushMany),
	Rangeflat: typeof(Rangeflat),
	RangeflatInplace: typeof(RangeflatInplace),
	Reduce: typeof(Reduce),
	Replace: typeof(Replace),
	ReplaceInplace: typeof(ReplaceInplace),
	Reverse: typeof(Reverse),
	ReverseInplace: typeof(ReverseInplace),
	Rotate: typeof(Rotate),
	RotateInplace: typeof(RotateInplace),
	Shuffle: typeof(Shuffle),
	ShuffleInplace: typeof(ShuffleInplace),
	Slice: typeof(Slice),
	SliceInplace: typeof(SliceInplace),
	Some: typeof(Some),
	SortInplace: typeof(SortInplace),
	Sorted: typeof(Sorted),
	Sum: typeof(Sum),
	Unpack: typeof(Unpack),
	Unshift: typeof(Unshift),
	UnshiftArray: typeof(UnshiftArray),
	UnshiftMany: typeof(UnshiftMany),
}
-- Arr 은 전체 인터페이스 + 위치 타입이 number 인 ListCore 를 **둘 다** 만족
export type Arr<T> = ArrData<T> & ArrIfce & ListCore<T, number>
export type LinkedList<E> = ListCore<E, Node<E>> & { PushBack: (self: LinkedList<E>, v: E) -> () }

local a = (nil :: any) :: Arr<number>
local ll = (nil :: any) :: LinkedList<string>

-- POS: 공용 알고리즘이 Arr 과 LinkedList 양쪽에
local p1: number? = IndexOf(a, 5)
local p2: Node<string>? = IndexOf(ll, "x")
local p3: number = CountOf(a)
local p4: number = CountOf(ll)

-- POS: Arr 의 타입 변환 체이닝이 여전히 사는가 (핵심)
local chained = a
	:Map(function(el: number)
		return tostring(el)
	end)
	:Map(function(s: string)
		return #s > 0
	end)

-- NEG: 전부 에러여야 함
local n1: string = chained[1]
local n2: Node<string>? = IndexOf(a, 5)
local n3 = a:Get(ll:FirstIndex())
local n4 = a:NoSuchMethod()
local canary: string = 42
return { p1, p2, p3, p4, chained, n1, n2, n3, n4, canary }
