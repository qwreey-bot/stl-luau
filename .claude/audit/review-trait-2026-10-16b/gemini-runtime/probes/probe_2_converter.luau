-- 관점 2 종합 프로브: Trait.Converter 의 동작과 엣지 케이스
local Trait = require("../src/Trait")
local stl = require("../src")
local Stack = stl.Stack
local CircularDeque = stl.CircularDeque

print("=== 1. 토큰 있는 변환자 (종류 지정) ===")
local toStackWithKind = Trait.Converter(Stack, CircularDeque)
local cd = CircularDeque.Of(1, 2, 3)
print("성공적 변환 (동일 인스턴스 반환):", toStackWithKind(cd) == cd)

print("\n=== 2. 토큰 없는 변환자 (트레이트만 지정) ===")
local toStackAny = Trait.Converter(Stack)
print("성공적 변환 (동일 인스턴스 반환):", toStackAny(cd) == cd)

print("\n=== 3. 미구현 종류 전달 시 ===")
local ok_notimpl, err_notimpl = pcall(function()
	return toStackAny(stl.Arr.Of(1, 2))
end)
print("toStackAny(Arr):", ok_notimpl, err_notimpl)

print("\n=== 4. 등록 전 Converter 생성 시점 차이 ===")
local UnregTok = Trait.NewToken("UnregTok")
local ok_conv_tok, err_conv_tok = pcall(function()
	return Trait.Converter(Stack, UnregTok)
end)
print("미등록 토큰으로 Converter 생성:", ok_conv_tok, err_conv_tok)

local ok_conv_nil, conv_nil = pcall(function()
	return Trait.Converter(Stack)
end)
print("미등록 시점에 Converter(Stack, nil) 생성:", ok_conv_nil, conv_nil ~= nil)

print("\n=== 5. 비테이블 및 primitive 전달 시 ===")
local function testBadVal(v)
	local ok, err = pcall(function() return toStackAny(v) end)
	print("toStackAny(" .. tostring(v) .. "):", ok, err)
end
testBadVal(nil)
testBadVal(123)
testBadVal("text")
testBadVal(true)

print("\n=== 6. 되읽은 값의 Restore 전후 ===")
local deser = table.clone(cd)
deser.__type = table.clone(cd.__type)
local ok_pre, err_pre = pcall(function() return toStackWithKind(deser) end)
print("Restore 전 toStackWithKind:", ok_pre, err_pre)
Trait.Restore(deser)
local ok_post, res_post = pcall(function() return toStackWithKind(deser) end)
print("Restore 후 toStackWithKind:", ok_post, res_post == deser)

