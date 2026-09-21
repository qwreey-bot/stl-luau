--!strict
-- ArrView<T>: 콜백이 받는 컨테이너 뷰.
--
-- 실측 규칙(bisect): **콜백 타입이 Arr<T>(전체 타입)를 어디에서도 언급하지
-- 않으면** 타입 변환 체이닝이 산다. 그래서 ArrView 의 자기폐쇄 재귀 메소드는
-- Arr<T> 가 아니라 ArrView<T> 를 반환한다. 반대로 Map 처럼 타입을 바꾸는
-- 메소드는 Arr<G> 를 낳아야 하므로 뷰에 넣을 수 없다 — 넣으면 체이닝이 죽는다.
--
-- | 콜백 arr 타입            | 3단 체이닝 | 콜백서 메소드 |
-- | ArrData<T>              |     O     |      X       |
-- | 비재귀 메소드 포함        |     O     |      O       |
-- | 자기폐쇄 재귀 -> View<T> |     O     |      O       |
-- | 재귀 반환이 Arr<T>       |     X     |      O       |
-- | 전체 Arr<T>             |     X     |      O       |

export type ArrData<T> = { n: number, [number]: T }

export type ArrView<T> = ArrData<T> & {
	Len: (self: ArrView<T>) -> number,
	Empty: (self: ArrView<T>) -> boolean,
	Count: (self: ArrView<T>, fn: (T) -> any) -> number,
	Find: (self: ArrView<T>, fn: (T) -> any) -> (T?, number?),
	Some: (self: ArrView<T>, fn: (T) -> any) -> boolean,
	Every: (self: ArrView<T>, fn: (T) -> boolean) -> boolean,
	Join: (self: ArrView<T>, sep: string?) -> string,
	Sum: (self: ArrView<T>) -> T,
	Prod: (self: ArrView<T>) -> T,
	Max: (self: ArrView<T>) -> T?,
	Min: (self: ArrView<T>) -> T?,
	Equal: (self: ArrView<T>, to: ArrView<T>) -> boolean,
	Unpack: (self: ArrView<T>) -> ...T,
	Slice: (self: ArrView<T>, ...any) -> ArrView<T>,
	Clone: (self: ArrView<T>, ...any) -> ArrView<T>,
	Reverse: (self: ArrView<T>, ...any) -> ArrView<T>,
	Sorted: (self: ArrView<T>, ...any) -> ArrView<T>,
	Rotate: (self: ArrView<T>, ...any) -> ArrView<T>,
	Filter: (self: ArrView<T>, ...any) -> ArrView<T>,
	Erase: (self: ArrView<T>, ...any) -> ArrView<T>,
	Flat: (self: ArrView<T>, ...any) -> ArrView<T>,
}

local function Clear<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Clone<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Consume<T>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrView<T>) -> boolean): Arr<T>
	return nil :: any
end
local function Count<T>(self: Arr<T>): number
	return nil :: any
end
local function Each<T>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrView<T>) -> boolean): Arr<T>
	return nil :: any
end
local function Empty<T>(self: Arr<T>, ...: any): boolean
	return nil :: any
end
local function Equal<T>(self: Arr<T>, ...: any): boolean
	return nil :: any
end
local function Erase<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function EraseInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Every<T>(self: Arr<T>, ...: any): boolean
	return nil :: any
end
local function Fill<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Filter<T>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrView<T>) -> boolean): Arr<T>
	return nil :: any
end
local function FilterInplace<T>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrView<T>) -> boolean): Arr<T>
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
local function Join<T>(self: Arr<T>, s: string?): string
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
local function Max<T>(self: Arr<T>): T?
	return nil :: any
end
local function MergeInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Min<T>(self: Arr<T>): T?
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
local function Reduce<T, U>(self: Arr<T>, fn: (acc: U, v: T) -> U, init: U): U
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
local function Unpack<T>(self: Arr<T>): ...T
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
export type Arr<T> = ArrData<T> & ArrIfce
local a = (nil :: any) :: Arr<number>

-- 3단 타입 변환 체이닝
local chained = a
	:Map(function(el: number)
		return tostring(el)
	end)
	:Map(function(s: string)
		return #s > 0
	end)
	:Map(function(b: boolean)
		return b and 1 or 0
	end)

-- 콜백 안에서: 읽기 + 조회 메소드 + 자기폐쇄 재귀 메소드
local rich = a:Map(function(el: number, idx: number, arr: ArrView<number>)
	local n = arr.n
	local l = arr:Len()
	local j = arr:Join(",")
	local s = arr:Slice(1, idx)
	local sl = s:Len()
	return el + n + l + #j + sl
end)

-- NEG
local neg1: string = chained[1]
local neg2: string = rich[1]
local neg3 = a:Map(function(el: number, idx: number, arr: ArrView<number>)
	return arr:NoSuchMethod()
end)
-- 뷰에서 타입 변환 메소드는 없어야 정상
local neg4 = a:Map(function(el: number, idx: number, arr: ArrView<number>)
	return arr:Map(function(x: number) return x end)
end)
local canary: string = 42
return { chained, rich, neg1, neg2, neg3, neg4, canary }
