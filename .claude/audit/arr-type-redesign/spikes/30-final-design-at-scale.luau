--!strict
-- 확정 검증: 실제 arr 규모(메소드 54 + 스태틱 9)로 최종 설계를 세운다.
--
-- 설계 3원칙 (전부 실측으로 고른 것 — 09-21):
--   1. 인스턴스 타입은 **교집합** `ArrData<T> & ArrIfce`.
--      setmetatable<> 은 메소드 30개에서 pending-expansion 1700여 건으로 죽는다.
--      한도 플래그 6종(quad 가 쓰는 3종 포함) 전부 무효 — 예산이 아니라 구조 문제.
--   2. ArrIfce 는 이름 붙은 top-level 함수들의 `typeof` 를 **명시 나열**(quad ③).
--      인라인 제네릭으로 쓰면 Map 이 Unifiable<Error> 로 샌다.
--   3. 콜백의 컨테이너 인자는 **ArrData<T>(데이터부)** — Arr<T> 를 넘기면
--      타입 변환 체이닝이 1단부터 ArrData<any> 로 죽는다 (quad ② 쪼개기).

export type ArrData<T> = { n: number, [number]: T }

local function Clear<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Clone<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Consume<T>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrData<T>) -> boolean): Arr<T>
	return nil :: any
end
local function Count<T>(self: Arr<T>): number
	return nil :: any
end
local function Each<T>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrData<T>) -> boolean): Arr<T>
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
local function Filter<T>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrData<T>) -> boolean): Arr<T>
	return nil :: any
end
local function FilterInplace<T>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrData<T>) -> boolean): Arr<T>
	return nil :: any
end
local function Find<T>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrData<T>) -> boolean): T?
	return nil :: any
end
local function Flat<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function FlatInplace<T>(self: Arr<T>, ...: any): Arr<T>
	return nil :: any
end
local function Flatmap<T, G>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrData<T>) -> G): Arr<G>
	return nil :: any
end
local function FlatmapInplace<T, G>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrData<T>) -> G): Arr<G>
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
local function Join<T>(self: Arr<T>, sep: string?): string
	return nil :: any
end
local function Len<T>(self: Arr<T>): number
	return nil :: any
end
local function Map<T, G>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrData<T>) -> G): Arr<G>
	return nil :: any
end
local function MapInplace<T, G>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrData<T>) -> G): Arr<G>
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
local function Some<T>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrData<T>) -> boolean): T?
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

-- 네임스페이스: 순수 테이블 (List.of 스타일)
local function NsOf<T>(...: T): Arr<T>
	return nil :: any
end
local function NsSized<T>(len: number, fill: T): Arr<T>
	return nil :: any
end
local function NsFromTable<T>(t: { T }): Arr<T>
	return nil :: any
end
local function NsIsArr(v: any): boolean
	return nil :: any
end
type ArrNs = { Of: typeof(NsOf), Sized: typeof(NsSized), FromTable: typeof(NsFromTable), IsArr: typeof(NsIsArr) }
local stl = (nil :: any) :: { Arr: ArrNs }

-- POS: 에러 없어야 함
local a = stl.Arr.Of(1, 2, 3)
local pos1: number = a.n
local pos2: number? = a[1]
local pos3: Arr<number> = a:Push(4)
local pos4: Arr<number> = stl.Arr.FromTable({ 1, 2 })

-- 타입 변환 체이닝 3단 (number -> string -> boolean -> number)
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

-- 깊은 동일타입 체이닝 12단
local deep = a:Push(1):Unshift(2):Clone():Reverse():Sorted():Slice(1, 2)
	:Erase(1, 1):Fill(0):Clear():Push(9):Rotate(1):ShuffleInplace()

-- 콜백에서 컨테이너 인자 쓰기 (읽기는 되어야 함)
local withArr = a:Map(function(el: number, idx: number, arr: ArrData<number>)
	return el + arr.n
end)

-- NEG: 전부 에러여야 함
local neg1: string = a[1]
local neg2: string = chained[1]
local neg3: string = deep[1]
local neg4: string = withArr[1]
local neg5 = a:NoSuchMethod()
local neg6 = stl.Arr.Off
local neg7: string = a:Reduce(function(acc: number, v: number) return acc + v end, 0)
local neg8: string = a:Len()
-- 캐비엇: 콜백 안에서 컨테이너 메소드 호출은 **안 되는 게 정상** (ArrData 엔 메소드 없음)
local caveat = a:Map(function(el: number, idx: number, arr: ArrData<number>)
	local _bad = arr:Push(1)
	return el
end)
-- 잔여 구멍 시험 (quad §1 ①: ③으로도 안 메워진다고 기록된 것)
--   그 줄 자체에 틀린 타입을 명시하면 잡히는가?
local wrongBind: Arr<boolean> = a:Map(function(el: number)
	return tostring(el) -- string 인데 Arr<boolean> 으로 받음
end)
--   그리고 그 뒤 다운스트림은 명시한 타입으로 정확히 바인딩되는가?
local downstream: string = wrongBind[1] -- boolean 으로 바인딩됐다면 에러여야 함

local canary: string = 42
return { a, wrongBind, downstream, pos1, pos2, pos3, pos4, chained, deep, withArr, neg1, neg2, neg3, neg4, neg5, neg6, neg7, neg8, caveat, canary }
