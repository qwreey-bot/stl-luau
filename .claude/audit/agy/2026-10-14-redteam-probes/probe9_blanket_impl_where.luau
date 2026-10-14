--!strict
-- probes/probe9_blanket_impl_where.luau
-- B'에서 트레이트 간의 뭉텅이 구현(ImplWhere) 및
-- 한 트레이트의 기본 구현이 다른 트레이트의 기본 구현을 활용할 때의 타입 검사

type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
local function Fn<F>(): F return nil :: any end
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end

local function Trait<F, G>(
	name: string,
	def: (mode: "full") -> F,
	implDef: (mode: "impl") -> G
): { read Of: F, read ImplOf: G, read ImplWhere: (deps: { any }, build: (deps: { [any]: any }) -> any) -> () }
	return nil :: any
end

-- Deque 정의 (기본 구현 IsEmpty 포함)
local function dequeDef<M>(mode: M)
	return function<Self, T>(of: (Self & Item<T>) | Token)
		return {
			PushBack = Fn<<(s: Self, x: T) -> Self>>(),
			PopBack = Fn<<(s: Self) -> T?>>(),
			PeekBack = Fn<<(s: Self) -> T?>>(),
			IsEmpty = Default(mode, function(ops: any)
				return function(s: Self): boolean
					return ops.PeekBack(s) == nil
				end
			end),
		}
	end
end
const Deque = Trait("Deque", dequeDef<<"full">>, dequeDef<<"impl">>)
export type Deque<Self, T> = typeof(Deque.Of<<Self, T>>(nil :: any))
export type DequeImpl<Self, T> = typeof(Deque.ImplOf<<Self, T>>(nil :: any))

-- Stack 정의 (기본 구현 IsEmpty 포함)
local function stackDef<M>(mode: M)
	return function<Self, T>(of: (Self & Item<T>) | Token)
		return {
			Push = Fn<<(s: Self, x: T) -> Self>>(),
			Pop = Fn<<(s: Self) -> T?>>(),
			Peek = Fn<<(s: Self) -> T?>>(),
			IsEmpty = Default(mode, function(ops: any)
				return function(s: Self): boolean
					return ops.Peek(s) == nil
				end
			end),
		}
	end
end
const Stack = Trait("Stack", stackDef<<"full">>, stackDef<<"impl">>)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))

type A = { read __probeA: true }
type B = { read __probeB: true }

-- [1] 정상적인 blanket 변환 함수 (탐침 타입 사용)
local function stackFromDeque(d: Deque<A, B>): StackImpl<A, B>
	return {
		Push = d.PushBack,
		Pop = d.PopBack,
		Peek = d.PeekBack,
		IsEmpty = d.IsEmpty, -- Deque의 기본 구현을 연결
	}
end

-- [2] 잘못된 blanket 변환: Pop에 PushBack 연결
local function NEG_badBlanket(d: Deque<A, B>): StackImpl<A, B>
	return {
		Push = d.PushBack,
		Pop = d.PushBack, -- NEG: Pop은 () -> B? 인데 PushBack은 (B) -> A
		Peek = d.PeekBack,
	}
end

-- [3] 잘못된 blanket 변환: 원소를 못박은 변환
local function NEG_pinnedBlanket(d: Deque<A, B>): StackImpl<A, B>
	return {
		Push = function(s: A, x: B): A return s end,
		Pop = function(s: A): string? return nil end, -- NEG: B?여야 하는데 string?
		Peek = d.PeekBack,
	}
end

-- [4] 잘못된 blanket 변환: IsEmpty에 string 반환 함수 지정
local function NEG_emptyBlanket(d: Deque<A, B>): StackImpl<A, B>
	return {
		Push = d.PushBack,
		Pop = d.PopBack,
		Peek = d.PeekBack,
		IsEmpty = function(s: A): string return "wrong" end, -- NEG: boolean이어야 함
	}
end

local canary: string = 1
return { canary, stackFromDeque, NEG_badBlanket, NEG_pinnedBlanket, NEG_emptyBlanket }
