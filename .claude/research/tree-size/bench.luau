--!nolint
-- 부분 크기 칸의 값: 지금의 레드블랙 대 크기 칸을 든 두 판(아래에서 위로 / 내려가면서). `-O2`, 최소값.
local stl = require("../../../src")
local cmp = stl.Common.compareNumber
local variants = {
	{ name = "지금(크기 칸 없음)", rb = stl.RedBlack :: any },
	{ name = "크기 칸 — 아래에서 위로", rb = require("./RedBlackSizedUp") :: any },
	{ name = "크기 칸 — 내려가면서", rb = require("./RedBlackSizedDown") :: any },
}
local N = 100000
local shuffled, order = table.create(N), table.create(N)
for i = 1, N do
	shuffled[i] = (i * 2654435761) % 4294967296
	order[i] = ((i * 40503) % N) + 1
end
local function best(runs: number, fn: () -> ()): number
	local bestTime = math.huge
	for _ = 1, runs do
		local t = os.clock()
		fn()
		bestTime = math.min(bestTime, os.clock() - t)
	end
	return bestTime * 1000
end
local rows = { "넣기 N (흩어진 키)", "넣기 N (오름차순)", "있던 키 덮어쓰기 N", "지우기 N (흩어진 순서)", "넣고 지우기 섞음 N", "노드당 메모리(바이트)" }
local out = {}
for vi, v in variants do
	local rb = v.rb
	local insert, remove, find = rb.Insert, rb.Remove, stl.Search.Find
	local res = {}
	res[1] = best(11, function()
		local root = nil
		for i = 1, N do
			root = insert(root, shuffled[i], i, cmp)
		end
	end)
	res[2] = best(11, function()
		local root = nil
		for i = 1, N do
			root = insert(root, i, i, cmp)
		end
	end)
	local filled = nil
	for i = 1, N do
		filled = insert(filled, shuffled[i], i, cmp)
	end
	res[3] = best(11, function()
		local root = filled
		for i = 1, N do
			root = insert(root, shuffled[i], -i, cmp)
		end
	end)
	-- 지우기: 매번 새로 지어야 하니 지우는 구간만 따로 잽니다
	do
		local bestRemove = math.huge
		for _ = 1, 9 do
			local root, nodes = nil, table.create(N)
			for i = 1, N do
				local node
				root, node = insert(root, shuffled[i], i, cmp)
				nodes[i] = node
			end
			local t = os.clock()
			for i = 1, N do
				root = remove(root, nodes[order[i]])
			end
			bestRemove = math.min(bestRemove, os.clock() - t)
		end
		res[4] = bestRemove * 1000
	end
	res[5] = best(9, function()
		local root, nodes, held = nil, table.create(1024), 0
		for i = 1, N do
			local node, isNew
			root, node, isNew = insert(root, shuffled[i] % 5000, i, cmp)
			if isNew then
				held += 1
				nodes[held] = node
			end
			if held >= 1000 then
				for j = held, held - 499, -1 do
					root = remove(root, nodes[j])
				end
				held -= 500
			end
		end
	end)
	collectgarbage("collect")
	local before = gcinfo()
	local keep = nil
	for i = 1, N do
		keep = insert(keep, shuffled[i], i, cmp)
	end
	collectgarbage("collect")
	res[6] = (gcinfo() - before) * 1024 / N
	out[vi] = res
	keep = nil
end
print(string.format("%-28s %14s %22s %22s", "", variants[1].name, variants[2].name, variants[3].name))
for r, label in rows do
	local a, b, c = out[1][r], out[2][r], out[3][r]
	print(string.format("%-26s %10.2f %14.2f (%.2f배) %14.2f (%.2f배)", label, a, b, b / a, c, c / a))
end
