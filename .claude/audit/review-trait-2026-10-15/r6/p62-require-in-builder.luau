--!nocheck
-- 프로브 62: builder 안의 require 는 **다른 스레드**(require 가 모듈을 새 스레드에서 돌림)라 중첩 검사를 지나 자기 묶음으로 커밋됨.
-- 바깥 등록이 그 뒤 실패하면 바깥은 되돌려지지만, 안쪽 등록이 번져 지은 **바깥 트레이트의 표**는 남음(뭉텅이는 사라졌는데 구현됨).
local stl = require("../../../../src")
local T = stl.Trait
local Shared = require("./lazy/Shared")
local function tr(name, fns)
	return T.Trait(name, function()
		return table.freeze(fns)
	end)
end
local Q = tr("P62.Q", { Get = T.Fn() })
Shared.Q = Q
local A = tr("P62.A", { Run = T.Fn() })
local k1 = T.NewToken("P62.K1")
local k2 = T.NewToken("P62.K2")
Q.ImplFor(k1, { Get = function() return "one" end })
Q.ImplFor(k2, { Get = function() return "two" end })
local seenTwo = 0
local ok, err = pcall(function()
	A.ImplWhere({ Q }, function(deps)
		if deps[Q].Get() == "two" then
			seenTwo += 1
			if seenTwo == 2 then -- 놓는 단계(뭉텅이를 적은 뒤)에서 처음 require
				require("./lazy/Special")
				return {} -- 그리고 이 종류에선 빠짐 → 바깥 등록 실패
			end
		end
		return { Run = function() return "run" end }
	end)
end)
print("바깥 등록:", ok, err)
local Special = require("./lazy/Special")
local v3 = T.Stamp({}, Special.Token)
print("K3 는 Q:", T.Implements(Q, v3))
print("뭉텅이가 되돌려졌는데 K3 는 A:", T.Implements(A, v3), if T.Implements(A, v3) then A.Of(v3).Run() else nil)
print("K1 은 A(되돌려짐 → false 여야):", T.Implements(A, T.Stamp({}, k1)))
