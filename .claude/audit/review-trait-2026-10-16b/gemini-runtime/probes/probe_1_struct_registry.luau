-- 관점 1 종합 프로브: Trait.Struct/Seal 과 Registry/Build 상호작용
local Trait = require("../src/Trait")
local stl = require("../src")

print("=== 1. 닫힌 트레이트(stl.Arr)를 ImplWhere 의존에 전달 ===")
local T1 = Trait.Trait("T1", function(of)
	return table.freeze({
		Foo = Trait.Fn<<() -> string>>(),
	})
end)
T1.ImplWhere({ stl.Arr }, function(deps)
	return {
		Foo = function() return "arr_foo" end,
	}
end)
local arr = stl.Arr.Of(1, 2)
local cd = stl.CircularDeque.Of(1, 2)
print("Arr 가 T1 구현하는가:", Trait.Implements(T1, arr))
print("CircularDeque 가 T1 구현하는가:", Trait.Implements(T1, cd))
print("T1.Of(arr).Foo():", T1.Of(arr).Foo())

print("\n=== 2. 닫힌 트레이트의 명시 ImplFor 오버라이드 ===")
T1.ImplFor(stl.Arr, {
	Foo = function() return "overridden_foo" end,
})
print("오버라이드 후 T1.Of(arr).Foo():", T1.Of(arr).Foo())

print("\n=== 3. 닫힌 트레이트의 조회 API 동작 ===")
print("Trait.ImplOf(stl.Arr, arr) == stl.Arr:", Trait.ImplOf(stl.Arr, arr) == stl.Arr)
print("Trait.Implements(stl.Arr, arr):", Trait.Implements(stl.Arr, arr))
print("Trait.Implements(stl.Arr, cd):", Trait.Implements(stl.Arr, cd))
print("Trait.Impls(stl.Arr)[Trait.TokenOf(stl.Arr)] == stl.Arr:", Trait.Impls(stl.Arr)[Trait.TokenOf(stl.Arr)] == stl.Arr)

print("\n=== 4. 봉인 전후 및 중복 봉인 ===")
local KindTest = Trait.Struct("KindTest")
local testTok = KindTest.Token
print("봉인 전 TokenOf(testMod):", Trait.TokenOf({}))
local testMod = { New = function() return { __type = testTok } end }
KindTest.Seal(testMod)
print("봉인 후 TokenOf(testMod) == testTok:", Trait.TokenOf(testMod) == testTok)

local ok_seal2, err_seal2 = pcall(function()
	KindTest.Seal({})
end)
print("동일 Kind 2회 봉인 에러:", ok_seal2, err_seal2)

local ok_seal3, err_seal3 = pcall(function()
	Trait.Struct("KindTest2").Seal(testMod)
end)
print("이미 봉인된 모듈 재봉인 에러:", ok_seal3, err_seal3)

print("\n=== 5. 미봉인 표 / 잘못된 종류 전달 ===")
local unsealed = {}
local ok_for, err_for = pcall(function()
	T1.ImplFor(unsealed, { Foo = function() return "bad" end })
end)
print("미봉인 표 ImplFor 에러:", ok_for, err_for)

