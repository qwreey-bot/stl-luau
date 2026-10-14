--!strict
type HasKey<K> = { read __key: K }
type HasValue<V> = { read __value: V }

local function keyOf<Self1, K>(x: Self1 & HasKey<K>): K
	return nil :: any
end
local function valueOf<Self2, V>(x: Self2 & HasValue<V>): V
	return nil :: any
end

type MyMap<K, V> = { size: number, read __key: K, read __value: V, read __item: boolean }

local m: MyMap<string, number> = nil :: any
local _k: string = keyOf(m)
local _v: number = valueOf(m)

local canary: string = 1
