--!strict
-- 모듈 값을 내보내는 세 가지 모양을 **같은 배터리**로 비교.
-- 각 모양마다: (A) 호출 가능? (B) 원소 타입 T 가 추론되나? (C) 모듈 오타를 잡나?
--
-- 기대 진단 5건. B/C 가 "잡힘" 이어야 그 칸이 ✅:
--   (10) m1_B ✅   (11) m1_C 없음 ❌
--   (16) m2_B 없음 ❌   (17) m2_C ✅
--   (23) m3_B ✅   (24) m3_C ✅
--   (26) canary ✅
--
-- 결론: **순수 테이블(모양 3)만 B 와 C 를 동시에 얻습니다.** 호출 문법이 대가.
-- __call 은 호출/오타검출은 되지만 타입 인자가 안 실려 Data<any> 가 됩니다
-- (quad typing-limits.md §7 "타입 레벨 __call 은 죽은 경로" 와 같은 결론).
type Data<T> = { n: number, [number]: T }
type Statics = { sized: <T>(len: number, fill: T) -> Data<T>, is_arr: (v: any) -> boolean }

-- ── 모양 1: 함수 & 테이블 교집합 (지금 stl-luau)
local M1 = (nil :: any) :: (<T>(...T) -> Data<T>) & Statics
local m1 = M1(1, 2, 3)
local m1_B: string = m1[1] -- B: 잡히면 T=number 로 추론된 것
local m1_C = M1.nosuch -- C: 잡히면 오타 검출됨

-- ── 모양 2: setmetatable + __call
local M2 = (nil :: any) :: setmetatable<Statics, { __call: <T>(self: any, ...T) -> Data<T> }>
local m2 = M2(1, 2, 3)
local m2_B: string = m2[1]
local m2_C = M2.nosuch

-- ── 모양 3: 순수 테이블 (호출 불가, of/new 로 생성)
type Statics3 = { of: <T>(...T) -> Data<T>, sized: <T>(len: number, fill: T) -> Data<T>, is_arr: (v: any) -> boolean }
local M3 = (nil :: any) :: Statics3
local m3 = M3.of(1, 2, 3)
local m3_B: string = m3[1]
local m3_C = M3.nosuch

local canary: string = 42
return { m1, m1_B, m1_C, m2, m2_B, m2_C, m3, m3_B, m3_C, canary }
