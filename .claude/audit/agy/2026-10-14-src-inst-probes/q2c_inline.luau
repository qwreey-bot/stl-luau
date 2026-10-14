--!strict
type HasKey<K> = { read __key: K }
type HasValue<V> = { read __value: V }

local function keyOf<Self, K>(x: Self & HasKey<K>): K
	return nil :: any
end
local function valueOf<Self, V>(x: Self & HasValue<V>): V
	return nil :: any
end

-- 타입 별칭 없이 인라인 타입으로 선언
local m1: { size: number, read __key: string, read __value: number } = nil :: any
local m2: { size: number, read __key: string, read __value: number } = nil :: any

local _k: string = keyOf(m1)
local _v: number = valueOf(m2)

local canary: string = 1
