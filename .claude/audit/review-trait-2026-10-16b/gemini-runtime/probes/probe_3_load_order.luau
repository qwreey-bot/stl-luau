-- 관점 3 종합 프로브: 모듈 로드 순서 및 순환 의존 시험
-- 다양한 require 조합을 격리된 코루틴/함수 환경에서 테스트

print("=== 1. Traits/Stack 만 단독 require ===")
local Stack = require("../src/Traits/Stack")
print("Stack 트레이트 로드 성공:", Stack ~= nil)

print("\n=== 2. 이후 Collections/CircularDeque 로드 ===")
local CircularDeque = require("../src/Collections/CircularDeque")
local Trait = require("../src/Trait")
local cd = CircularDeque.Of(1, 2, 3)
print("CircularDeque 가 Stack 구현하는가:", Trait.Implements(Stack, cd))
local s = Stack.OfMut(cd)
s.Push(cd, 99)
print("Stack.Pop(cd):", s.Pop(cd))

print("\n=== 3. Traits/Deque 단독 로드와 순환 require 검사 ===")
local Deque = require("../src/Traits/Deque")
local Queue = require("../src/Traits/Queue")
print("Deque, Queue 로드 성공:", Deque ~= nil, Queue ~= nil)
print("Deque.AsStack 함수 존재:", Deque.AsStack ~= nil)
print("Deque.AsQueue 함수 존재:", Deque.AsQueue ~= nil)
