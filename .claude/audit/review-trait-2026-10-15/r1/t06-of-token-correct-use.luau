--!strict
-- 타입 프로브 t06: `X.Of(토큰)` 으로 얻은 표를 **맞는 종류**에 쓰면? (POS 여야 자연스러움)
local stl = require("../../../../src")
local ops = stl.List.Of(stl.Arr.Token)
local a = stl.Arr.Of(1, 2, 3)
local v = ops.Get(a, 1) -- POS 이기를
local st = stl.Stack.Of(stl.CircularDeque.Token)
local d = stl.CircularDeque.Of(1, 2)
st.Push(d, 3) -- POS 이기를
-- 명시적 타입 인자로는?
local ops2 = stl.List.Of<<stl.Arr<number>, number, number>>(stl.Arr.Token)
local v2: number? = ops2.Get(a, 1)
return { v, v2 }
