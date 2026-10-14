--!strict
-- 실험 A: HasValue 의 제네릭 파라미터 위치를 맞추어본다!
-- MyMap<K, V> 에서 K는 0번, V는 1번.
-- HasValue2<K, V> 로 V를 1번 파라미터로 둔다!
type HasKey<K> = { read __key: K }
type HasValue2<K, V> = { read __value: V }

local function keyOf<Self, K>(x: Self & HasKey<K>): K
	return nil :: any
end
local function valueOf2<Self, K, V>(x: Self & HasValue2<K, V>): V
	return nil :: any
end

type MyMap<K, V> = { size: number, read __key: K, read __value: V }

local m: MyMap<string, number> = nil :: any
local _k: string = keyOf(m)
local _v2: number = valueOf2(m) -- V가 1번째 파라미터라면 string이 안 섞이나?!

-- 실험 B: HasValue 를 타입 별칭이 아니라 직접 테이블 리터럴로 적는다!
local function valueOfLit<Self, V>(x: Self & { read __value: V }): V
	return nil :: any
end
local _vLit: number = valueOfLit(m)

local canary: string = 1
