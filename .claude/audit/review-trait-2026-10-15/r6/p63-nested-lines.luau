--!nocheck
-- 프로브 63: 중첩 등록 에러의 줄 — ImplFor / ImplWhere / NewToken, 뭉텅이 builder / 기본 구현 빌더(형제 읽기로 지어지는 것 포함)
local stl = require("../../../../src")
local T = stl.Trait
local function tr(name, fns)
	return T.Trait(name, function()
		return table.freeze(fns)
	end)
end
local Other = tr("P63.Other", { Go = T.Fn() })
local someKind = T.NewToken("P63.Some")
local function show(label, f)
	local ok, err = pcall(f)
	print(label, ok, err)
end
local n = 0
local function blanketWith(action)
	n += 1
	local X = tr("P63.X" .. n, { Run = T.Fn() })
	return function()
		X.ImplWhere({ stl.Map }, function()
			action()
			return { Run = print }
		end)
	end
end
show("ImplFor (기대: 그 등록 줄):", blanketWith(function()
	Other.ImplFor(someKind, { Go = print }) -- 25
end))
show("ImplWhere (기대: 그 등록 줄):", blanketWith(function()
	Other.ImplWhere({ stl.List }, function() return { Go = print } end) -- 28
end))
show("NewToken (기대: 그 등록 줄):", blanketWith(function()
	T.NewToken("P63.Inner") -- 31
end))
-- 기본 구현 빌더: A 의 빌더가 형제 B 를 읽으면 그 자리에서 B 의 빌더가 돌고, B 가 등록
local D = tr("P63.D", {
	Get = T.Fn(),
	A = T.Default(function(ops)
		local b = ops.B
		return function() return b() end
	end),
	B = T.Default(function(_ops)
		T.NewToken("P63.FromDefault") -- 42
		return function() return 1 end
	end),
})
show("기본 구현 빌더 (기대: 그 등록 줄):", function()
	D.ImplFor(T.NewToken("P63.DKind"), { Get = print })
end)
print("뒤의 등록 정상:", pcall(T.NewToken, "P63.After"))
print("P63.Inner 이름은 빔:", pcall(T.NewToken, "P63.Inner"))
print("P63.FromDefault 이름은 빔:", pcall(T.NewToken, "P63.FromDefault"))
print("P63.DKind 이름은 빔(바깥 토큰 등록은 따로 성공):", pcall(T.NewToken, "P63.DKind"))
