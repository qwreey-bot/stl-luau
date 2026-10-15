--!nocheck
-- 프로브 11: Restore 는 값만 걷고 **키**는 걷지 않음 — 테이블을 키로 쓴 HashMap(키가 Arr)을 되읽으면?
local stl = require("../../../../src")
local fake = function(name) return { name = name } end -- 되읽은 토큰 모양
local keyArr = { n = 1, 10, __type = fake("Stl.Arr") }
local m = { data = { [keyArr] = "v" }, size = 1, __type = fake("Stl.HashMap") }
stl.Trait.Restore(m)
print("map restored", stl.isHashMap(m), "key restored", stl.isArr(keyArr))
local s = { map = { data = { [keyArr] = keyArr }, size = 1, __type = fake("Stl.HashMap") }, __type = fake("Stl.HashSet") }
stl.Trait.Restore(s)
print("set: key restored (값으로도 있어서)", stl.isArr(keyArr))
