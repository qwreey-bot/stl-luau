--!strict
local stl = require("../../../src")
type DequeMarkerMut<T> = stl.DequeMarkerMut<T>
type StackMarkerMut<T> = { read __type: { read name: any }, read __stackItem: T, read __stackMut: (T) -> T }
type Push = <Self, T>(stack: Self & (DequeMarkerMut<T> | StackMarkerMut<T>), item: T) -> Self
type Pop = <Self, T>(stack: Self & (DequeMarkerMut<T> | StackMarkerMut<T>)) -> T?
local push: Push = nil :: any
local pop: Pop = nil :: any
-- 덱(덱 마커만 있음)
local d = stl.CircularDeque.Of(1, 2)
local d2: stl.CircularDeque<number> = push(d, 3)
local p1: number? = pop(d)
local negD = push(d, "x")
local negP1: string? = pop(d)
-- 스택 마커를 단 배열(Arr 의 데이터 타입에 팬텀을 더한 모양을 흉내)
type MyArr<T> = stl.Arr<T> & { read __stackItem: T, read __stackMut: (T) -> T }
local a: MyArr<number> = nil :: any
local a2: MyArr<number> = push(a, 3)
local p2: number? = pop(a)
local negA = push(a, "x")
local negP2: string? = pop(a)
local canary: string = 1
return { d2, p1, negD, negP1, a2, p2, negA, negP2, canary }
