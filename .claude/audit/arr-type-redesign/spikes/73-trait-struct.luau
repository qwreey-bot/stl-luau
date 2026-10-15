--!strict
--[[
	종류 = 닫힌 트레이트(질문 BB, 2026-10-15 — 사용자: "Arr 조차 Trait 이여야 하는거 아닌가 … struct Arr impl Arr {}", "read [number]: T 를 공개 해야할 까").
	- `Trait.Struct` 로 만든 종류(모듈 표)를 종류 자리에 넘김 — 토큰을 안 만짐: `Converter(stl.Stack, stl.Arr)`, 아래로 `Converter(stl.Arr)`.
	- `CircularDeque` 의 공개 타입은 칸·링 버퍼 안쪽(`head`·`cap`)을 보이지 않고 `size` 는 읽기만(시제품 — `Arr` 은 아직 그대로).

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 줄마다 + CANARY 1).
]]
local stl = require("../../../../src")
type Arr<T> = stl.Arr<T>
local Trait = stl.Trait

-- 1. 종류를 넘기는 변환자 — 위로·아래로
local asStack: <T>(a: Arr<T>) -> stl.Stack<T> = Trait.Converter(stl.Stack, stl.Arr)
local asArr: <T>(s: stl.Stack<T>) -> Arr<T> = Trait.Converter(stl.Arr)
local s = asStack(stl.Arr.Of(1, 2))
local back: Arr<number> = asArr(s)
local negBack: Arr<string> = asArr(s) -- NEG: 원소 타입

-- 2. 원형 덱의 공개 타입: 칸과 안쪽은 안 보임, 크기는 읽기만
local d = stl.CircularDeque.Of(10, 20)
local size: number = d.size
local first: number? = stl.CircularDeque.At(d, 1)
local negIndex = d[1] -- NEG: 물리 칸을 바로 읽음
d[3] = 30 -- NEG: 칸에 바로 씀(길이가 안 따라옴)
d.size = 5 -- NEG: 크기를 바로 고침
local negHead = d.head -- NEG: 링 버퍼 안쪽
local borrowed: stl.CircularDequeRead<number> = d
local wide: stl.CircularDequeRead<number?> = d -- 공변(원소는 레코드에서)
local negWrite = stl.CircularDeque.PushBack(borrowed, 1) -- NEG: 빌린 참조로 쓰기
local negElem: stl.CircularDequeRead<string> = d -- NEG: 원소 타입

-- 3. Arr 의 칸과 n 은 읽기만 공개(질문 BB (나) ②): 읽기는 직접, 쓰기는 함수로
local arr = stl.Arr.Of(1, 2, 3)
local firstArr: number = arr[1]
local lenArr: number = arr.n
stl.Arr.Set(arr, 1, 5)
local fromArr = stl.HashSet.FromList(arr) -- 리스트를 읽기만 하는 생성자는 Arr 를 받음
arr[1] = 9 -- NEG: 칸에 바로 씀
arr.n = 0 -- NEG: 길이를 바로 고침
stl.Arr.Set(arr, 1, "x") -- NEG: 원소 타입
local negConcat = table.concat(arr, ",") -- NEG(대가): 내장 함수는 읽고 쓰는 리스트를 요구 — Arr.Join 이나 캐스트
local wideArr: stl.ArrRead<number?> = arr -- 읽기 타입으로는 공변 그대로

local canary: string = 1
return { back, negBack, size, first, negIndex, negHead, wide, negWrite, negElem, firstArr, lenArr, fromArr, negConcat, wideArr, canary }
