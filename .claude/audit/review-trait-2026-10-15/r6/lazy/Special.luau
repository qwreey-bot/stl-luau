--!nocheck
-- builder 가 처음 require 하는 사용자 모듈: 로드 때 자기 종류를 만들고 Q 를 구현
local stl = require("../../../../../src")
local Shared = require("./Shared")
local K3 = stl.Trait.NewToken("P62.K3")
Shared.Q.ImplFor(K3, { Get = function() return "three" end })
return { Token = K3 }
