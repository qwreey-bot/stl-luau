--!strict
-- (1) 글자 그대로의 대괄호 키는 속성인가
type Lit = { ["Test"]: number }
local lit: Lit = nil :: any
local l1: number = lit.Test -- 속성이면 됨
local negL: string = lit.Test -- NEG

-- (2) 이름을 박은 별칭 여럿의 교집합 — 받는 쪽은 별칭 그대로(타입 함수 없음)
type HasItem<T> = { read __item: T }
type HasKey<K> = { read __key: K }
type HasValue<V> = { read __value: V }
local m = {} :: { size: number } & HasKey<string> & HasValue<number> & HasItem<boolean>
local function keyOf<Self, K>(x: Self & HasKey<K>): K
	return nil :: any
end
local function valueOf<Self, V>(x: Self & HasValue<V>): V
	return nil :: any
end
local function itemOf<Self, T>(x: Self & HasItem<T>): T
	return nil :: any
end
local k: string = keyOf(m)
local v: number = valueOf(m)
local it: boolean = itemOf(m)
local negK: number = keyOf(m) -- NEG
local negV: string = valueOf(m) -- NEG

-- (3) 타입 함수로 만든 속성: 선언 쪽은 되고, 받는 쪽 역추론은?
type function Prop(name: type, t: type): type
	return types.newtable({ [name] = { read = t } })
end
local p = {} :: Prop<"__node", string>
local pn: string = p.__node -- 선언 쪽: 속성으로 풀림?
local function nodeOf<T>(x: Prop<"__node", T>): T
	return nil :: any
end
local inferred: string = nodeOf(p) -- 받는 쪽 역추론
local negInferred: number = nodeOf(p) -- NEG(역추론이 되면 잡힘)

local canary: string = 1
return { l1, negL, k, v, it, negK, negV, pn, inferred, negInferred, canary }
