--!nocheck
-- 처음 require 될 때 자기 종류의 토큰을 만드는 사용자 모듈(흔한 모양)
local stl = require("../../../../../src")
local M = {}
M.Token = stl.Trait.NewToken("P61.UserKind") -- 4행
return M
