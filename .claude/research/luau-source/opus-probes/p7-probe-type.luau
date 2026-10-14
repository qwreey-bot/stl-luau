--!strict
-- 탐침 타입 몸통: 구체(봉인된) 테이블 타입이라 Subtyping 의 제네릭 갈래(Subtyping.cpp:833-835, 895)를 아예 안 탐
type A = { read __probeA: true }
type B = { read __probeB: true }
local function a(x: A): string return x end -- NEG
local function c(x: A): A? return 123 end -- NEG
local function d(x: number?): A? return x end -- NEG
local function e(x: A): B return x end -- NEG (A ≠ B)
local function ok1(x: A): A? return x end -- OK (T <: T? 에 해당 — 여기선 정상)
local function ok2(xs: { A }): A? return xs[1] end -- OK
-- 경계(구조적 타입이라): 탐침이 진짜 타입 변수보다 넓게 받아들이는 자리
local function edge1(x: A): {} return x end -- 0건(테이블이면 {} 의 서브타입) — 진짜 T 라면 거절돼야 함
local function edge2(x: A): { read __probeA: boolean } return x end -- 0건(필드 이름을 알면 통과)
local function edge3(x: A): unknown return x end -- 0건(정상)
local function edge4(x: any): A return x end -- 0건(any)
return { a, c, d, e, ok1, ok2, edge1, edge2, edge3, edge4 }
