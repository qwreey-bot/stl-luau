--!strict
-- probes/q2c_positional_unify.luau
-- Q2-(c) Unifier2 가 서로 다른 별칭의 타입 파라미터를 위치(positional) 순서로 맹목적 단일화하여
--        연관 타입에 엉뚱한 타입이 합(Union)으로 오염되는 현상
type HasKey<K> = { read __key: K }
type HasValue<V> = { read __value: V }

-- 위치를 일치시킨 별칭 (K=0, V=1)
type HasValueAligned<K, V> = { read __value: V }

local function keyOf<Self, K>(x: Self & HasKey<K>): K return nil :: any end
local function valueOf<Self, V>(x: Self & HasValue<V>): V return nil :: any end
local function valueOfAligned<Self, K, V>(x: Self & HasValueAligned<K, V>): V return nil :: any end
local function valueOfInline<Self, V>(x: Self & { read __value: V }): V return nil :: any end

type MyMap<K, V> = { size: number, read __key: K, read __value: V }
local m: MyMap<string, number> = nil :: any

-- 정상 케이스 1: keyOf 는 0번 인덱스(K)가 MyMap 의 0번 인덱스(string)와 우연히 일치하여 정상 추론
local _k: string = keyOf(m)

-- 정상 케이스 2: 위치를 정렬한 HasValueAligned 는 1번 인덱스(V)가 MyMap 의 1번 인덱스(number)와 일치하여 오염 없음
local _v_aligned: number = valueOfAligned(m)

-- 정상 케이스 3: 제네릭 타입 별칭을 쓰지 않고 인라인 테이블 타입을 사용하면 instantiatedTypeParams 가 없어 오염 없음
local _v_inline: number = valueOfInline(m)

-- 음성 대조군 (-- NEG 1건):
-- valueOf 는 HasValue<V> 의 0번 인덱스(V)가 MyMap 의 0번 인덱스(string)와 단일화되어
-- V 가 'number | string' 이 되므로 number 변수에 대입 시 불일치 에러 발생
local NEG_v_corrupted: number = valueOf(m) -- NEG

local canary: string = 1
