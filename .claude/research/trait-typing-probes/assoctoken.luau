--!strict
--[[ 라이브러리가 주는 것 ]]
-- 토큰의 타입이 연관 타입을 듦(불변 팬텀은 안에 숨김). 런타임 토큰은 종류마다 하나({ name = … })
export type Token<N, T = never> = { read name: N, read __assoc: { read Item: (T) -> T } }
export type MapToken<N, K, V> = { read name: N, read __assoc: { read Key: (K) -> K, read Value: (V) -> V } }
-- 받는 쪽 별칭
type HasItem<T> = { read __type: { read __assoc: { read Item: (T) -> T } } }
type HasKey<K> = { read __type: { read __assoc: { read Key: (K) -> K } } }
type HasValue<V> = { read __type: { read __assoc: { read Value: (V) -> V } } }
local function itemOf<Self, T>(x: Self & HasItem<T>): T
	return nil :: any
end
local function push<Self, T>(x: Self & HasItem<T>, item: T): Self
	return x
end
local function walk<Self, T>(x: Self & HasItem<T>): () -> T?
	return nil :: any
end
local function keyOf<Self, K>(x: Self & HasKey<K>): K
	return nil :: any
end
local function valueOf<Self, V>(x: Self & HasValue<V>): V
	return nil :: any
end
local function put<Self, K, V>(x: Self & HasKey<K> & HasValue<V>, k: K, v: V): Self
	return x
end

--[[ 사용자가 쓰는 것: 토큰 타입에 원소 타입을 적기만 ]]
const BAG = { name = "My.Bag" } :: Token<"My.Bag", any>
type Bag<T> = { items: { T }, count: number, read __type: Token<"My.Bag", T> }
local function newBag<T>(): Bag<T>
	return { items = {}, count = 0, __type = BAG :: any }
end
local bag = newBag<<boolean>>()
local t1: boolean = itemOf(bag)
local t2: Bag<boolean> = push(bag, true)
for x in walk(bag) do
	local _ok: boolean = x
end
local negT1: number = itemOf(bag) -- NEG
local negT2 = push(bag, 1) -- NEG

type MyMap<K, V> = { data: { [K]: V }, read __type: MapToken<"My.Map", K, V> }
local mm: MyMap<string, number> = nil :: any
local k: string = keyOf(mm)
local v: number = valueOf(mm)
local m2: MyMap<string, number> = put(mm, "a", 1)
local negK: number = keyOf(mm) -- NEG
local negPut = put(mm, 1, 1) -- NEG
local negPut2 = put(mm, "a", "b") -- NEG

local canary: string = 1
return { t1, t2, negT1, negT2, k, v, m2, negK, negPut, negPut2, canary }
