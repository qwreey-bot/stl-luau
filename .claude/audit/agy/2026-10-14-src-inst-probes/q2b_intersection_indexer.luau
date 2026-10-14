--!strict
-- probes/q2b_intersection_indexer.luau
-- Q2-(b) [string]: any 인덱서가 든 타입과 교집합이면 X.Of<<..>> 를 못 붙이는 현상
type PlainObj = {
	read Of: <Self, T>(x: Self) -> (Self, T),
}

type SingleWithIndexer = {
	read Of: <Self, T>(x: Self) -> (Self, T),
	[string]: any,
}

type IntersectionWithIndexer = {
	read Of: <Self, T>(x: Self) -> (Self, T),
} & { [string]: any }

local p: PlainObj = nil :: any
local s: SingleWithIndexer = nil :: any
local i: IntersectionWithIndexer = nil :: any

-- 정상 케이스 1: 단독 객체는 Of<<..>> 명시적 인스턴스화 가능
local _f_p = p.Of<<number, string>>

-- 정상 케이스 2: 동일 테이블 내부에 인덱서와 Of 가 함께 정의된 경우 명시적 인스턴스화 가능
local _f_s = s.Of<<number, string>>

-- 음성 대조군 (-- NEG 1건):
-- 교집합으로 인덱서가 결합되면 Of 의 타입이 'FunctionType | error' 유니온으로 단순화되어
-- 'Cannot instantiate type parameters on something without type parameters' 에러 발생
local NEG_inter_of = i.Of<<number, string>> -- NEG

local canary: string = 1
