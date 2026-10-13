-- 시제품 검증: 부분 크기 칸이 늘 "그 부분 트리의 노드 수" 인지, 넣기·지우기·덮어쓰기를 무작위로.
local stl = require("../../../src")
local cmp = stl.Common.compareNumber
for _, name in { "RedBlackSizedUp", "RedBlackSizedDown" } do
	local Rb = require("./" .. name) :: any
	local seed = 99
	local function rand(limit: number): number
		seed = (seed * 48271) % 2147483647
		return seed % limit
	end
	local function check(node: any): number
		if node == nil then
			return 0
		end
		local n = 1 + check(node[2]) + check(node[3])
		assert(node[7] == n, `{name}: 크기 칸 {node[7]} ≠ 실제 {n} (키 {node[5]})`)
		return n
	end
	for round = 1, 40 do
		local root: any, count = nil, 0
		for step = 1, 600 do
			local key = rand(300)
			if rand(3) > 0 then
				local isNew
				root, _, isNew = Rb.Insert(root, key, step, cmp)
				if isNew then
					count += 1
				end
			else
				local node = stl.Search.Find(root, key, cmp)
				if node ~= nil then
					root = Rb.Remove(root, node)
					count -= 1
				end
			end
			assert(check(root) == count, `{name} {round}/{step}: 전체 수`)
		end
	end
	print(name, "크기 칸 검증 통과")
end
