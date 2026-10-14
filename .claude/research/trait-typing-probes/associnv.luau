--!strict
-- 연관 타입을 불변 팬텀(함수 타입)으로
type HasItem<T> = { read __item: (T) -> T }
type HasKey<K> = { read __key: (K) -> K }
type HasValue<V> = { read __value: (V) -> V }
local function keyOf<Self, K>(x: Self & HasKey<K>): K
	return nil :: any
end
local function valueOf<Self, V>(x: Self & HasValue<V>): V
	return nil :: any
end
local function itemOf<Self, T>(x: Self & HasItem<T>): T
	return nil :: any
end
local function push<Self, T>(x: Self & HasItem<T>, item: T): Self
	return x
end
type MyMap<K, V> = { size: number, read __key: (K) -> K, read __value: (V) -> V, read __item: (boolean) -> boolean }
local m: MyMap<string, number> = nil :: any
local k: string = keyOf(m)
local v: number = valueOf(m)
local it: boolean = itemOf(m)
local negK: number = keyOf(m) -- NEG
local negV: string = valueOf(m) -- NEG
local back: MyMap<string, number> = push(m, true)
local negPush = push(m, 1) -- NEG
local canary: string = 1
return { k, v, it, negK, negV, back, negPush, canary }
