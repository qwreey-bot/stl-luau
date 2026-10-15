--!nocheck
-- 프로브 03: builder 안의 등록(중첩)은 바깥 묶음의 일지에 섞임 — (a) 안쪽 실패를 builder 가 잡으면 반쯤 남고,
-- (b) 안쪽이 성공한 뒤 바깥이 실패하면 안쪽(예: builder 가 처음 require 한 모듈의 토큰·등록)까지 되돌려져, 캐시된 모듈은
-- 사라진 토큰을 쥔 채 남음.
local stl = require("../../../../src")
local T = stl.Trait
local function tr(name, fns)
	return T.Trait(name, function()
		return table.freeze(fns)
	end)
end
-- (a)
local Q = tr("P03.Q", { Get = T.Fn() })
local P = tr("P03.P", { Name = T.Fn() })
local X = tr("P03.X", { Run = T.Fn() })
local function blanketName() return "blanket" end
P.ImplWhere({ Q }, function() return { Name = blanketName } end)
X.ImplWhere({ P }, function(deps)
	return if deps[P].Name == blanketName then { Run = blanketName } else {}
end)
local kind = T.NewToken("P03.Kind")
Q.ImplFor(kind, { Get = print })
local held = P.Of(kind)
local Outer = tr("P03.Outer", { Run = T.Fn() })
local innerErr
Outer.ImplWhere(T.Every, function()
	if innerErr == nil then
		local ok, err = pcall(function()
			P.ImplFor(kind, { Name = function() return "explicit" end })
		end)
		innerErr = tostring(err)
	end
	return { Run = function() end }
end)
print("(a) 안쪽 에러:", innerErr)
print("    놓였던 표가 옛 내용?", held.Name == blanketName, "/ 다시 등록:", pcall(function()
	P.ImplFor(kind, { Name = function() return "explicit2" end })
end))

-- (b) 지연 require 흉내: 모듈은 처음 한 번만 실행되고 캐시됨
local cache
local function requireHelper()
	if cache == nil then
		local helperToken = T.NewToken("P03.Helper")
		cache = { Token = helperToken }
	end
	return cache
end
local Show = tr("P03.Show", { Show = T.Fn() })
local Broken = tr("P03.Broken", { Need = T.Fn() })
local okB, errB = pcall(function()
	Show.ImplWhere(T.Every, function()
		local Helper = requireHelper()
		return { Show = function() return Helper.Token.name end }
	end)
	-- 같은 등록 안이 아니라 별개 — 대신 바깥 실패를 만들기 위해 Every builder 가 빠뜨림
end)
print("(b0) 바깥 등록:", okB, errB)
local okC, errC = pcall(function()
	Broken.ImplWhere(T.Every, function()
		requireHelper()
		return {} -- Need 빠뜨림 → 바깥 실패
	end)
end)
print("(b) 바깥 실패:", okC, tostring(errC))

-- (b') 처음 require 가 바깥 실패 등록 안에서 일어난 경우
local cache2
local function requireHelper2()
	if cache2 == nil then
		cache2 = { Token = T.NewToken("P03.Helper2") }
	end
	return cache2
end
local Broken2 = tr("P03.Broken2", { Need = T.Fn() })
local okD, errD = pcall(function()
	Broken2.ImplWhere(T.Every, function()
		requireHelper2()
		return {}
	end)
end)
print("(b') 바깥 실패:", okD, tostring(errD))
print("    캐시된 모듈의 토큰이 아직 토큰인가:", T.TokenOf(T.Stamp ~= nil and { __type = cache2.Token }) ~= nil)
print("    그 토큰으로 Stamp:", pcall(function() return T.Stamp({}, cache2.Token) end))
print("    같은 이름의 토큰을 또 만들 수 있음(이름 유일 깨짐):", pcall(function() return T.NewToken("P03.Helper2") ~= cache2.Token end))
