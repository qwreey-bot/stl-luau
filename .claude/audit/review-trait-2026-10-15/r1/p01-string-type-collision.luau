--!nocheck
-- 프로브 01: 토큰이 아닌 문자열 `__type` 이 트레이트 객체의 필드 이름(함수 이름·시스템 필드)과 같을 때.
-- 기대(규약): "토큰 없음" 분류의 사용자 줄 에러. 
local stl = require("../../../../src")
local function try(label, f)
	local where = debug.info(1, "l") + 1
	local ok, err = pcall(f)
	print(label, ok, err)
end
-- 사용자의 자체 셋 클래스(문자열 태그)를 실수로 맵 진입점에
local mySet = { __type = "Set", items = {} }
local mySet2 = { __type = "Set", items = {} }
try("Map.Keys", function() return stl.Map.Keys(mySet) end)
try("Map.Of", function() local t = stl.Map.Of(mySet); return typeof(t) end)
try("Map.Get(entry)", function() return stl.Map.Get(mySet, 1) end)
try("Arr.GroupBy into", function() return stl.Arr.GroupBy(stl.Arr.Of(1, 2), function(x) return x end, mySet2) end)
try("Collection.Len(__type=Len)", function() return stl.Collection.Len({ __type = "Len" }) end)
try("Stack.Push(__type=Push)", function() return stl.Stack.Push({ __type = "Push" }, 1) end)
try("Map.Keys(__type=FnTok)", function() return stl.Map.Keys({ __type = "FnTok" }) end)
-- 대조: 이름이 겹치지 않는 문자열 태그
try("Map.Keys(__type=Bag)", function() return stl.Map.Keys({ __type = "Bag" }) end)
try("Implements", function() return stl.Trait.Implements(stl.Map, mySet) end)
