--!strict
-- J6: 편한 진입점은 모든 후보에서 any(지금 src 의 손으로 쓴 진입점보다 후퇴). 트레이트 모듈이 진입점에 타입만 덧씌우는
-- 캐스트(비용 0)로 되찾을 수 있나 — 그리고 그 캐스트가 정의와 어긋나면(표류) 잡히나
local P = require("../trait-v9/Traits")
local Trait = require("../trait-v9/Trait")
local stl = require("../../../src")
type ItemIndexRead<E, I> = Trait.ItemIndexRead<E, I>
type Item<T> = Trait.Item<T>
const IndexOf: <S, E, I>(list: S & ItemIndexRead<E, I>, item: E) -> I? = P.List.IndexOf :: any
const Push: <S, T>(stack: S & Item<T>, item: T) -> S = P.Stack.Push :: any
local d = P.Kinds.tag(stl.CircularDeque.Of(1, 2, 3), P.Kinds.CD)
const where: number? = IndexOf(d, 2)
const NEG_item = IndexOf(d, "z") -- NEG
const NEG_ret: string? = IndexOf(d, 2) -- NEG
const pushed = Push(d, 4)
const NEG_push = Push(d, "x") -- NEG
local borrowed: stl.CircularDequeRead<number> = d
const NEG_borrowPush = Push(borrowed, 1) -- NEG: 빌린 참조로 쓰기
-- 표류 검사: 캐스트한 진입점 타입이 정의의 완성 보기와 맞는지(탐침 타입으로 한 번 대입)
type A = Trait.A
type CD<T> = stl.CircularDeque<T>
const _driftOk: (CD<A>, A) -> number? = P.List.Of<<CD<A>, A, number>>(nil :: any).IndexOf
const wrongEntry: <S, E, I>(list: S & ItemIndexRead<E, I>, item: E) -> E? = P.List.IndexOf :: any
const _driftNeg: (CD<A>, A) -> number? = wrongEntry -- NEG? 표류(E? 를 돌려준다고 잘못 적음)를 대입이 잡나
local canary: string = 1
return { where, NEG_item, NEG_ret, pushed, NEG_push, NEG_borrowPush, _driftOk, _driftNeg, canary }
