--!strict
-- 라이브러리가 주는 것(사용자는 이름만 씀)
type Item<T> = { read __item: (T) -> T }
type Key<K> = { read __key: (K) -> K }
type Value<V> = { read __value: (V) -> V }
local function itemOf<Self, T>(x: Self & Item<T>): T
	return nil :: any
end
local function keyOf<Self, K>(x: Self & Key<K>): K
	return nil :: any
end
local function valueOf<Self, V>(x: Self & Value<V>): V
	return nil :: any
end
local function push<Self, T>(x: Self & Item<T>, item: T): Self
	return x
end

-- (A) 사용자: 자기 타입에 별칭을 교집합으로 붙이기만
type MyBag<T> = { items: { T }, count: number } & Item<T>
local bag: MyBag<boolean> = nil :: any
local a1: boolean = itemOf(bag)
local a2: MyBag<boolean> = push(bag, true)
local negA1: number = itemOf(bag) -- NEG
local negA2 = push(bag, 1) -- NEG
type MyMap<K, V> = { data: { [K]: V } } & Key<K> & Value<V>
local mm: MyMap<string, number> = nil :: any
local a3: string = keyOf(mm)
local a4: number = valueOf(mm)
local negA3: number = keyOf(mm) -- NEG
local negA4: string = valueOf(mm) -- NEG

-- (B) 토큰 필드 안에: 사용자는 원래 적는 `__type` 에 연관 타입을 같이 적음
type Token<N, A> = { read name: N, read __assoc: A }
type ItemB<T> = { read __type: { read __assoc: { read Item: (T) -> T } } }
local function itemOfB<Self, T>(x: Self & ItemB<T>): T
	return nil :: any
end
type MyBagB<T> = { items: { T }, read __type: Token<"MyBagB", { read Item: (T) -> T }> }
local bagB: MyBagB<string> = nil :: any
local b1: string = itemOfB(bagB)
local negB1: number = itemOfB(bagB) -- NEG

local canary: string = 1
return { a1, a2, negA1, negA2, a3, a4, negA3, negA4, b1, negB1, canary }
