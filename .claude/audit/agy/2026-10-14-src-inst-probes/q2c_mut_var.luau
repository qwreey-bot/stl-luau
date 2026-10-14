--!strict
type HasKey<K> = { read __key: K }
type HasValue<V> = { read __value: V }
type HasItem<T> = { read __item: T }

local function keyOf<Self, K>(x: Self & HasKey<K>): K
	return nil :: any
end
local function valueOf<Self, V>(x: Self & HasValue<V>): V
	return nil :: any
end
local function itemOf<Self, T>(x: Self & HasItem<T>): T
	return nil :: any
end

type MyMap<K, V> = { size: number, read __key: K, read __value: V, read __item: boolean }

-- 실험 1: 동일 변수 m 사용
local m: MyMap<string, number> = nil :: any
local _k1: string = keyOf(m)
local _v1: number = valueOf(m) -- 여기서 에러 났었음!

-- 실험 2: 서로 다른 변수 m1, m2 사용
local m1: MyMap<string, number> = nil :: any
local m2: MyMap<string, number> = nil :: any
local _k2: string = keyOf(m1)
local _v2: number = valueOf(m2) -- 여기도 에러 나나?

local canary: string = 1
