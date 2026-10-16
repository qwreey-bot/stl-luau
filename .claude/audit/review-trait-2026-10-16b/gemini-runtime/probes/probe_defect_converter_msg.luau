-- 재현 프로브: Trait.Converter 에 직렬화 복사본(미 Restore 값) 전달 시 혼란스러운 에러 문구
local stl = require("../src")
local Trait = stl.Trait
local Stack = stl.Stack
local Deque = stl.Deque

local toStackWithKind = Trait.Converter(Stack, stl.CircularDeque)
local toStackAny = Trait.Converter(Stack)

local cd = stl.CircularDeque.Of(1, 2)
-- 직렬화 후 되읽은 상태를 흉내 냄 (동일한 name 문자열을 갖는 새로운 테이블 __type)
local deserialized = table.clone(cd)
deserialized.__type = table.clone(cd.__type)

print("=== 1. Converter(Stack, stl.CircularDeque) 에 되읽은 값 전달 ===")
local ok1, err1 = pcall(function()
	return toStackWithKind(deserialized)
end)
print("성공 여부:", ok1)
print("에러 메시지:", err1)

print("\n=== 2. Converter(Stack) (또는 Deque.AsStack) 에 되읽은 값 전달 ===")
local ok2, err2 = pcall(function()
	return toStackAny(deserialized)
end)
print("성공 여부:", ok2)
print("에러 메시지:", err2)

print("\n=== 3. 대조: 일반 진입점(Errors.entryMiss)의 에러 메시지 ===")
local ok3, err3 = pcall(function()
	return Stack.Peek(deserialized)
end)
print("성공 여부:", ok3)
print("에러 메시지:", err3)
