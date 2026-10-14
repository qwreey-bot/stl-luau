--!strict
type HasKey<K> = { read __key: K }
type HasValue<V> = { read __value: V }

local function keyOf<Self, K>(x: Self & HasKey<K>): K
	return nil :: any
end

type MyMap<K, V> = { size: number, read __key: K, read __value: V }

local m: MyMap<string, number> = nil :: any
local _k: string = keyOf(m)

-- keyOf 호출 후 m.__value 의 타입이 무엇인가?
local _dbg: string = m.__value
