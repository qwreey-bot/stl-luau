--!nocheck
-- 프로브 61: 고친 3(중첩 등록은 에러)이 정당한 쓰임을 거절하는가
local stl = require("../../../../src")
local T = stl.Trait
local function tr(name, fns)
	return T.Trait(name, function()
		return table.freeze(fns)
	end)
end

-- (a) builder 가 처음으로 require 한 모듈이 로드 때 토큰을 만듦 — require 는 다른 스레드에서 모듈을 돌리는가?
local A = tr("P61.A", { Run = T.Fn() })
local okA, errA = pcall(function()
	A.ImplWhere({ stl.Map }, function(_deps)
		local UserKind = require("./lazy/UserKind") -- 16행
		return { Run = function() return UserKind end }
	end)
end)
print("(a) lazy require 안의 NewToken:", okA, errA)
print("    A 등록이 남았나:", T.Implements(A, stl.HashMap.New()))
-- require 캐시: 모듈이 실패로 끝났으니 다시 require 하면?
local okA2, errA2 = pcall(require, "./lazy/UserKind")
print("    다시 require:", okA2, if okA2 then errA2.Token.name else errA2)

-- (b) 기본 구현 빌더가 돌려준 함수가 **나중에** 등록 → 허용
local B = tr("P61.B", {
	Get = T.Fn(),
	Lazy = T.Default(function(_ops)
		return function(_self)
			return T.NewToken("P61.LaterToken")
		end
	end),
})
local kB = T.NewToken("P61.KindB")
B.ImplFor(kB, { Get = print })
print("(b) 돌려준 함수가 나중에 등록:", pcall(function() return B.Of(kB).Lazy(nil).name end))

-- (c) builder 가 중첩 등록의 에러를 pcall 로 삼키고 계속 → 바깥 등록은 온전?
local C = tr("P61.C", { Run = T.Fn() })
local innerErr
C.ImplWhere({ stl.Map }, function(_deps)
	local ok2, e = pcall(function()
		T.NewToken("P61.InnerC")
	end)
	innerErr = e
	return { Run = function() return "c" end }
end)
print("(c) 삼킨 안쪽 에러:", innerErr)
print("    바깥 등록 됨:", T.Implements(C, stl.HashMap.New()), C.Of(stl.HashMap.New()).Run())
print("    그 뒤 같은 스레드의 등록:", pcall(T.NewToken, "P61.AfterC"))
print("    안쪽 토큰 이름은 비어 있음:", pcall(T.NewToken, "P61.InnerC"))

-- (d) require 가 돌리는 스레드: 모듈 본문의 coroutine.running() 이 부른 쪽과 같은가
local main = coroutine.running()
local Probe = require("./lazy/ThreadProbe")
print("(d) require 본문 스레드 == 부른 스레드:", Probe.thread == main)
