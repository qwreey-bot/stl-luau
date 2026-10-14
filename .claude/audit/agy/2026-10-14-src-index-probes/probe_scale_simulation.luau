--!strict
-- probes/probe_scale_simulation.luau
-- 트레이트 4종(Collection, Deque, Stack, Queue)과 컨테이너 2종(Arr, CircularDeque) 모의 스케일 프로브

type AnyToken = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemRead<T> = { read __readGenerics: { read Item: () -> T } }

export type Mut<Self, T, M> = index<{ full: Self & Item<T>, impl: Self }, M>
export type DefaultRet<F, M> = index<{ full: F, impl: F? }, M>

local function Fn<F>(): F
	return nil :: any
end

local function Default<F, M>(_mode: M, _build: (ops: any) -> F): DefaultRet<F, M>
	return nil :: any
end

type Object<F, G> = {
	read Of: F,
	read ImplOf: G,
	read ImplFor: (token: AnyToken, impl: any) -> (),
	read ImplWhere: (deps: { any }, build: (deps: { [any]: any }) -> any) -> (),
}

const function MakeTrait<F, G>(name: string, _def: (mode: "full") -> F, _implDef: ((mode: "impl") -> G)?): Object<F, G>
	return {
		Of = nil :: any,
		ImplOf = nil :: any,
		ImplFor = function(_tok, _impl) end,
		ImplWhere = function(_deps, _build) end,
	}
end

-- 1. Collection 트레이트
local function collectionDef<M>(mode: M)
	return function<Self, T>(of: (Self & ItemRead<T>) | AnyToken)
		return {
			Len = Fn<<(self: Self) -> number>>(),
			IsEmpty = Default(mode, function(ops)
				return function(self: Self): boolean
					return ops.Len(self) == 0
				end
			end),
			Clear = Fn<<(self: Mut<Self, T, M>) -> ()>>(),
		}
	end
end
local Collection = MakeTrait("Collection", collectionDef, collectionDef)
type Collection<Self, T> = typeof(Collection.Of<<Self, T>>(nil :: any))
type CollectionImpl<Self, T> = typeof(Collection.ImplOf<<Self, T>>(nil :: any))

-- 2. Deque 트레이트
local function dequeDef<M>(mode: M)
	return function<Self, T>(of: (Self & ItemRead<T>) | AnyToken)
		return {
			PushBack = Fn<<(self: Mut<Self, T, M>, item: T) -> Self>>(),
			PushFront = Fn<<(self: Mut<Self, T, M>, item: T) -> Self>>(),
			PopBack = Fn<<(self: Mut<Self, T, M>) -> T?>>(),
			PopFront = Fn<<(self: Mut<Self, T, M>) -> T?>>(),
			PeekBack = Fn<<(self: Self) -> T?>>(),
			PeekFront = Fn<<(self: Self) -> T?>>(),
		}
	end
end
local Deque = MakeTrait("Deque", dequeDef, dequeDef)
type Deque<Self, T> = typeof(Deque.Of<<Self, T>>(nil :: any))
type DequeImpl<Self, T> = typeof(Deque.ImplOf<<Self, T>>(nil :: any))

-- 3. Stack 트레이트 (기본 구현 IsEmpty 포함)
local function stackDef<M>(mode: M)
	return function<Self, T>(of: (Self & ItemRead<T>) | AnyToken)
		return {
			Push = Fn<<(self: Mut<Self, T, M>, item: T) -> Self>>(),
			Pop = Fn<<(self: Mut<Self, T, M>) -> T?>>(),
			Peek = Fn<<(self: Self) -> T?>>(),
			IsEmpty = Default(mode, function(ops: any)
				return function(self: Self): boolean
					return ops.Peek(self) == nil
				end
			end),
		}
	end
end
const Stack = MakeTrait("Stack", stackDef<<"full">>, stackDef<<"impl">>)
type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))

-- 4. Queue 트레이트 (기본 구현 IsEmpty 포함)
local function queueDef<M>(mode: M)
	return function<Self, T>(of: (Self & ItemRead<T>) | AnyToken)
		return {
			Push = Fn<<(self: Mut<Self, T, M>, item: T) -> Self>>(),
			Pop = Fn<<(self: Mut<Self, T, M>) -> T?>>(),
			Peek = Fn<<(self: Self) -> T?>>(),
			-- IsEmpty = Default(mode, function(ops: Queue<Self, T>)
			-- 	return function(self: Self): boolean
			-- 		return ops.Peek(self) == nil
			-- 	end
			-- end),
		}
	end
end
local Queue = MakeTrait("Queue", queueDef, queueDef)
type Queue<Self, T> = typeof(Queue.Of<<Self, T>>(nil :: any))
type QueueImpl<Self, T> = typeof(Queue.ImplOf<<Self, T>>(nil :: any))

-- 컨테이너 정의: Arr<T> 및 CircularDeque<T>
type Arr<T> = {
	read __type: AnyToken,
	read __generics: { read Item: (T) -> T },
	read __readGenerics: { read Item: () -> T },
	n: number,
}
type ArrRead<T> = {
	read __type: AnyToken,
	read __readGenerics: { read Item: () -> T },
	n: number,
}

type CircularDeque<T> = {
	read __type: AnyToken,
	read __generics: { read Item: (T) -> T },
	read __readGenerics: { read Item: () -> T },
}
type CircularDequeRead<T> = {
	read __type: AnyToken,
	read __readGenerics: { read Item: () -> T },
}

-- 구현 등록 시험: Arr용 Collection 및 Stack 직접 구현 (기본 구현 IsEmpty 생략 가능)
type A = { read __probeA: true }

local arrToken: AnyToken = { name = "Arr" }

local arrCollection: CollectionImpl<Arr<A>, A> = {
	Len = function(self) return self.n end,
	Clear = function(self) self.n = 0 end,
	-- IsEmpty는 생략(기본 구현 사용)
}
Collection.ImplFor(arrToken, arrCollection)

local arrStack: StackImpl<Arr<A>, A> = {
	Push = function(self, _item) return self end,
	Pop = function(_self) return nil end,
	Peek = function(_self) return nil end,
	-- IsEmpty 생략
}
Stack.ImplFor(arrToken, arrStack)

-- Blanket 구현 시험: Deque로부터 Stack 생성
Stack.ImplWhere({ Deque }, function(deps)
	local d: Deque<any, any> = deps[Deque]
	local impl: StackImpl<any, any> = {
		Push = d.PushBack,
		Pop = d.PopBack,
		Peek = d.PeekBack,
		-- IsEmpty 생략
	}
	return impl
end)

-- 사용 및 제네릭 알고리즘 시험
local myArr: Arr<number> = nil :: any
local borrowedArr: ArrRead<number> = myArr

-- 1. Of로 꺼내기
local arrOps = Stack.Of(myArr)
arrOps.Push(myArr, 10)
local p: number? = arrOps.Peek(myArr)

-- 2. 읽기 전용으로 Peek 호출 (성공해야 함)
local peekVal: number? = Stack.Of(borrowedArr).Peek(borrowedArr)

-- 3. 읽기 전용으로 Push 호출 시도 (타입 에러가 나야 함)
-- NEG: Stack.Of(borrowedArr).Push(borrowedArr, 20)

-- 4. 제네릭 알고리즘
local function drainStack<S, T>(stackOps: Stack<S, T>, s: S): number
	local count = 0
	while not stackOps.IsEmpty(s) do
		stackOps.Pop(s)
		count += 1
	end
	return count
end

local cnt: number = drainStack(Stack.Of(myArr), myArr)

-- canary
local canary: string = 1
