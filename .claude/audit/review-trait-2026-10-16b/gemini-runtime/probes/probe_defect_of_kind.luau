-- 재현 프로브: X.Of(kind) / X.OfMut(kind) 호출 시 asToken(kind) 변환 누락으로 인한 에러
local stl = require("../src")
local Trait = stl.Trait
local List = stl.List

print("=== 1. List.Of(stl.Arr) 호출 시도 ===")
local ok1, err1 = pcall(function()
	return List.Of(stl.Arr)
end)
print("성공 여부:", ok1)
print("에러 메시지:", err1)

print("\n=== 2. List.OfMut(stl.Arr) 호출 시도 ===")
local ok2, err2 = pcall(function()
	return List.OfMut(stl.Arr)
end)
print("성공 여부:", ok2)
print("에러 메시지:", err2)

print("\n=== 3. 대조: Trait.ImplOf(List, stl.Arr) ===")
local ok3, res3 = pcall(function()
	return Trait.ImplOf(List, stl.Arr)
end)
print("성공 여부:", ok3, "결과가 nil이 아닌가:", res3 ~= nil)

print("\n=== 4. 대조: List.Of(Trait.TokenOf(stl.Arr)) ===")
local ok4, res4 = pcall(function()
	return List.Of(Trait.TokenOf(stl.Arr))
end)
print("성공 여부:", ok4, "결과가 nil이 아닌가:", res4 ~= nil)
