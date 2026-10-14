--!strict
type HasItem<T> = { read __item: T }
type HasKey<K> = { read __key: K }
type HasValue<V> = { read __value: V }
local function keyOf<Self, K>(x: Self & HasKey<K>): K
	return nil :: any
end
local function valueOf<Self, V>(x: Self & HasValue<V>): V
	return nil :: any
end
local function itemOf<Self, T>(x: Self & HasItem<T>): T
	return nil :: any
end
-- (2b) 연관 타입을 컨테이너 테이블 타입 **안의 필드**로
type MyMap<K, V> = { size: number, read __key: K, read __value: V, read __item: boolean }
local m: MyMap<string, number> = nil :: any
local k: string = keyOf(m)
local v: number = valueOf(m)
local it: boolean = itemOf(m)
local negK: number = keyOf(m) -- NEG
local negV: string = valueOf(m) -- NEG
-- (2c) 받는 쪽도 교집합 없이(Self 없이 별칭만)
local function keyOf2<K>(x: HasKey<K>): K
	return nil :: any
end
local k2: string = keyOf2(m)
local negK2: number = keyOf2(m) -- NEG
local canary: string = 1
return { k, v, it, negK, negV, k2, negK2, canary }
