--!nocheck
-- 프로브 04: Restore 는 재귀로 걷습니다 — 깊은 구조(직렬화한 연결 덱: 노드 사슬)에서?
local stl = require("../../../../src")
local Trait = stl.Trait
local function deepCopy(x, seen)
	seen = seen or {}
	if type(x) ~= "table" then return x end
	if seen[x] then return seen[x] end
	local out = {}
	seen[x] = out
	-- 반복으로 복사(재귀 깊이 없이): 간단히 큐
	local queue, qi = { { x, out } }, 1
	while queue[qi] do
		local src, dst = queue[qi][1], queue[qi][2]
		qi += 1
		for k, v in src do
			if type(v) == "table" then
				if not seen[v] then
					seen[v] = {}
					table.insert(queue, { v, seen[v] })
				end
				dst[k] = seen[v]
			else
				dst[k] = v
			end
		end
	end
	return out
end
for _, n in { 1000, 10000, 50000, 200000 } do
	local d = stl.LinkedDeque.New()
	for i = 1, n do stl.LinkedDeque.PushBack(d, i) end
	local copy = deepCopy(d)
	local ok, err = pcall(function() return Trait.Restore(copy) end)
	print(n, ok, if ok then (stl.isLinkedDeque(copy)) else string.sub(tostring(err), 1, 120))
end
-- 대조: Arr(얕음)
local a = deepCopy(stl.Arr.Of(1, 2, 3))
print("arr", stl.isArr(Trait.Restore(a)))
