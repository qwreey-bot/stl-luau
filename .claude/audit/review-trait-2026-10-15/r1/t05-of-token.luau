--!strict
-- 타입 프로브 t05: `X.Of(토큰)`(규약: 값 또는 토큰)으로 얻은 완성 표의 타입, 그리고 `Of()` 인자 없음.
local stl = require("../../../../src")
local ops = stl.List.Of(stl.Arr.Token)
local d = stl.CircularDeque.Of(1, 2, 3)
local h = stl.HashMap.New<<string, number>>()
local x1 = ops.Get(h, "nope") -- 다른 종류의 값을 Arr 의 표에: NEG 이기를
local x2: string = ops.IndexOf(d, 1) -- 반환 타입
local st = stl.Stack.Of(stl.CircularDeque.Token)
st.Push(h, 1) -- 맵을 덱의 스택 표에
local z = stl.List.Of() -- 인자 없음
local canary: string = 1
return { x1, x2, z, canary }
