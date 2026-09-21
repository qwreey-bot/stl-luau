--!strict
--[[
	Types — 여러 컨테이너가 공유하는 **계약**만 둡니다.

	**말단 모듈입니다**: 다른 컨테이너 모듈을 require 하지 않습니다. 그래서
	(a) 순환 require 가 원천적으로 불가능하고 (b) 선언 순서 의존 누수가
	생기지 않습니다(다른 모듈에서 이미 풀린 타입으로 들어오므로).
	근거: .claude/audit/container-contracts/REPORT.md 3절.
]]

-- 전략 주입
export type Comparator<T> = (a: T, b: T) -> number
export type Hasher<T> = (value: T, maxHash: number) -> number

-- 맵 계열이 공유하는 항목 표현
export type Record<K, V> = { key: K, value: V }

-- 위치 타입을 파라미터로 뺀 순차 컨테이너 계약.
-- 배열 기반은 I = number, 연결 기반은 I = 노드.
export type ListCore<E, I> = {
	Get: (self: ListCore<E, I>, idx: I) -> E?,
	FirstIndex: (self: ListCore<E, I>) -> I?,
	LastIndex: (self: ListCore<E, I>) -> I?,
	NextIndex: (self: ListCore<E, I>, idx: I) -> I?,
	PrevIndex: (self: ListCore<E, I>, idx: I) -> I?,
}

export type MapCore<K, V> = {
	Get: (self: MapCore<K, V>, k: K) -> V?,
	Set: (self: MapCore<K, V>, k: K, v: V) -> (),
	Records: (self: MapCore<K, V>) -> { Record<K, V> },
}

return {}
