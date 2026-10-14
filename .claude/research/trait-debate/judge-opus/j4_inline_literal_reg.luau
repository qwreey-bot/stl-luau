--!strict
-- J4: 등록 표를 주석 단 지역 없이 리터럴로 바로 넘기면(D3 의 ImplFor 는 impl: any) 타입 검사가 하나도 없음 — 모든 후보 공통
local P = require("../trait-v9/Traits")
local Trait = require("../trait-v9/Trait")
local stl = require("../../../src")
P.Stack.ImplFor(Trait.Token("J4.Bad"), { Push = stl.Arr.Len, Pop = 42 }) -- 0건이어야(경계): 서명이 틀리고 Peek 가 빠짐
P.List.ImplFor(Trait.Token("J4.Bad2"), { Get = "nope" }) -- 0건이어야(경계)
local canary: string = 1
return canary
