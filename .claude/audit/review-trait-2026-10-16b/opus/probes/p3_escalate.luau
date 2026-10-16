--!strict
local stl = require("../src")
local Trait = stl.Trait
local a = stl.Arr.Of(1, 2, 3)
local r: stl.ArrRead<number> = a
local d = stl.CircularDeque.Of(1, 2)
local dr: stl.CircularDequeRead<number> = d
-- 1. 토큰으로 꺼낸 완성 표 — 읽기 참조·원소 타입
local tok = Trait.TokenOf(stl.Arr) :: stl.TraitToken<string>
local opsC = stl.Collection.OfMut(tok)
local e1 = opsC.Clear(r) -- 빌린 참조 Clear? (기대: 에러)
local dtok = Trait.TokenOf(stl.CircularDeque) :: stl.TraitToken<string>
local opsD = stl.Deque.OfMut(dtok)
local e2 = opsD.PushBack(dr, "x") -- 빌린 참조 + 틀린 원소 (기대: 에러)
local e3: string = opsD.PopBack(d) -- 원소 (기대: 에러)
-- 2. 명시적 타입 인자로
local opsD2 = stl.Deque.OfMut<<stl.CircularDeque<number>, number>>(dtok)
local e4 = opsD2.PushBack(d, "x") -- 기대: 에러
-- 3. Arr.Set 구멍
local e5 = stl.Arr.Set(a, 1, nil) -- Arr<number> 에 nil (기대: 에러)
local e6 = stl.Arr.Set(r, 1, 5) -- 빌린 참조로 쓰기 (기대: 에러)
local wide: stl.ArrRead<number?> = a
local e7 = stl.Arr.Set(wide, 1, nil) -- 넓힌 읽기 참조로 nil 쓰기(기대: 에러)
-- 4. 소비 규약: ArrConsumed 가 넓힌 Arr 받음
local nums = stl.Arr.Of(1, 2)
local e8 = stl.Arr.CompactInplace(r) -- 빌린 참조(기대: 에러)
-- 5. Arr<number> → Arr<number?> 대입(불변 — 기대 에러)
local e9: stl.Arr<number?> = nums
-- 6. Concat 섞기 (기대 에러)
local e10 = stl.Arr.Concat(stl.Arr.Of(1), stl.Arr.Of("x"))
-- 7. Arr 를 { read [number]: T } 리스트로
local ok1 = stl.HashSet.FromList(nums)
local canary: string = 1
return nil
