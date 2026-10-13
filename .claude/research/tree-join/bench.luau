local stl = require("../../../src")
local ST = require("./SearchTree")
local Avl, get, check, directInsert = ST.Avl, ST.get, ST.check, ST.directInsert
local TreeMap = stl.TreeMap
local cmp = stl.Common.compareNumber
local function best(f, n)
	local m = math.huge
	for _ = 1, n or 7 do
		local t = os.clock(); f(); t = os.clock() - t
		if t < m then m = t end
	end
	return m * 1000
end

-- 1) 정확성: 무작위 넣기·지우기·쪼개기·합치기를 정렬 배열 모델과
math.randomseed(7)
for _ = 1, 200 do
	local root, model = nil, {}
	for _ = 1, 200 do
		local k = math.random(1, 150) * 10
		if math.random() < 0.7 then
			root = Avl.Insert(root, k, k + 1, cmp); model[k] = k + 1
		else
			local removed; root, removed = Avl.Remove(root, k, cmp)
			assert((removed ~= nil) == (model[k] ~= nil), "Remove 반환"); model[k] = nil
		end
	end
	local keys, want = {}, {}
	check(root, keys)
	for k in model do table.insert(want, k) end
	table.sort(want)
	assert(#keys == #want, "키 수")
	for i, k in want do assert(keys[i] == k and get(root, k, cmp) == model[k], "키·값") end
	-- 쪼개기: 가운데 키 기준으로 둘 다 온전한 균형 트리이고 합치면 원래 키들
	local pivot = want[math.max(1, #want // 2)] or 5
	local l, mid, r = Avl.Split(root, pivot, cmp)
	local lk, rk = {}, {}
	check(l, lk); check(r, rk)
	for _, k in lk do assert(k < pivot) end
	for _, k in rk do assert(k > pivot) end
	assert(#lk + #rk + (if mid then 1 else 0) == #want, "쪼갠 뒤 합")
	local joined = if mid then ST.avlJoin(l, mid, r) else Avl.Join2(l, r)
	local jk = {}
	check(joined, jk)
	assert(#jk == #want, "다시 이은 뒤")
end
print("정확성 OK (200회 x 200걸음: 넣기·지우기·Split·Join, AVL 불변식)")

-- 2) 속도
for _, N in { 10000, 100000 } do
	local keys = table.create(N)
	for i = 1, N do keys[i] = (i * 7919) % (N * 4) end
	local probe = table.create(N)
	for i = 1, N do probe[i] = keys[(i * 31) % N + 1] end
	local insertAvl, insertDirect, setTree = Avl.Insert, directInsert, TreeMap.Set
	local tJoin = best(function() local root = nil; for i = 1, N do root = insertAvl(root, keys[i], i, cmp) end end)
	local tDirect = best(function() local root = nil; for i = 1, N do root = insertDirect(root, keys[i], i, cmp) end end)
	local tFlat = best(function() local m = TreeMap.New(cmp); for i = 1, N do setTree(m, keys[i], i) end end, 3)
	local root, flat = nil, TreeMap.New(cmp)
	for i = 1, N do root = insertDirect(root, keys[i], i, cmp); setTree(flat, keys[i], i) end
	local getTree = TreeMap.Get
	local gNode = best(function() for i = 1, N do get(root, probe[i], cmp) end end)
	local gFlat = best(function() for i = 1, N do getTree(flat, probe[i]) end end)
	print(string.format("N=%d 무작위 넣기(ms): Join 위의 넣기 %.1f | 직접 회전 %.1f | 정렬 배열(지금 TreeMap) %.1f   ||  조회: 노드 트리 %.1f | 정렬 배열 %.1f",
		N, tJoin, tDirect, tFlat, gNode, gFlat))
	-- 쪼개기: 가운데 키에서 둘로. 노드 트리는 O(log n), 정렬 배열은 복사
	local sorted = table.clone(keys); table.sort(sorted)
	local R = 2000
	-- 기준 키를 매번 바꿉니다 — 같은 키로 되풀이하면 다시 이을 때 그 노드가 뿌리가 돼 다음 쪼개기가 O(1) 이 됨
	local tSplit = best(function()
		for i = 1, R do
			local l, mid, r = Avl.Split(root, sorted[(i * 7919) % N + 1], cmp)
			root = ST.avlJoin(l, mid, r) -- 다시 이어 다음 반복에 씀(쪼개기 + 잇기 한 쌍)
		end
	end)
	local check = {}
	ST.check(root, check)
	assert(#check == #TreeMap.Keys(flat), "쪼개고 잇기를 되풀이한 뒤에도 온전")
	local records = TreeMap.Records(flat)
	local tCopy = best(function()
		for _ = 1, 20 do
			local half = table.create(N // 2)
			table.move(records, 1, N // 2, 1, half)
			local rest = table.create(N // 2)
			table.move(records, N // 2 + 1, #records, 1, rest)
		end
	end)
	print(string.format("       가운데에서 쪼개기: 노드 트리(Split + Join 한 쌍) %.4f ms/회 | 정렬 배열(두 조각으로 복사) %.4f ms/회", tSplit / R, tCopy / 20))
end
