--!strict
-- probes/probe19_borrowed_ref_rejection.luau
-- B'에서 of 조건으로 빌린 읽기 참조(ItemRead)를 거절/수용하는 동작 시험

type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemRead<T> = { read __readGenerics: { read Item: () -> T } }

local function Fn<F>(): F return nil :: any end
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end

local function Trait<F, G>(
	name: string,
	def: (mode: "full") -> F,
	implDef: (mode: "impl") -> G
): { read Of: F, read ImplOf: G }
	return nil :: any
end

-- 쓰기 트레이트: Item<T> 요구
local function stackDef<M>(mode: M)
	return function<Self, T>(of: (Self & Item<T>) | Token)
		return {
			Push = Fn<<(stack: Self, item: T) -> Self>>(),
			Pop = Fn<<(stack: Self) -> T?>>(),
			IsEmpty = Default(mode, function(ops: any) return function(s: Self): boolean return true end end),
		}
	end
end
const Stack = Trait("Stack", stackDef<<"full">>, stackDef<<"impl">>)

-- 읽기 전용 트레이트: ItemRead<T> 허용
local function listDef<M>(mode: M)
	return function<Self, T>(of: (Self & ItemRead<T>) | Token)
		return {
			Get = Fn<<(list: Self, idx: number) -> T?>>(),
			Contains = Default(mode, function(ops: any) return function(list: Self, x: T): boolean return true end end),
		}
	end
end
const List = Trait("List", listDef<<"full">>, listDef<<"impl">>)

-- 컨테이너 정의: Full 타입과 Read 타입
type MyDeque<T> = {
	n: number,
	read __generics: { read Item: (T) -> T },
	read __readGenerics: { read Item: () -> T },
}
type MyDequeRead<T> = {
	n: number,
	read __readGenerics: { read Item: () -> T },
}

local d: MyDeque<number> = nil :: any
local borrowed: MyDequeRead<number> = d

-- [1] 쓰기 트레이트 Stack에 full 넘김: 정상
local s1 = Stack.Of(d)
-- [2] 쓰기 트레이트 Stack에 borrowed 넘김: 거절되어야 함!
local NEG_borrowedStack = Stack.Of(borrowed) -- NEG: Item<T>가 없으므로 거절!

-- [3] 읽기 트레이트 List에 borrowed 넘김: 정상 통과
local l1 = List.Of(borrowed)
local got: number? = l1.Get(borrowed, 1)
local has: boolean = l1.Contains(borrowed, 10)

-- [4] 읽기 트레이트라도 반환값 타입 검사는 정상이어야 함
local NEG_got: string? = l1.Get(borrowed, 1) -- NEG: number? 여야 함

local canary: string = 1
return { canary, s1, NEG_borrowedStack, l1, got, has, NEG_got }
