--!nocheck
-- 벤치 b01: 결함 1 의 고침 후보 셋의 진입점 비용(시스템 Entry 와 같은 모양을 흉내). 최소값 사용.
local TOKEN = table.freeze({ name = "B" })
local impl = { function(self, x) return self end }
local trait = { [TOKEN] = impl, Get = function() end }
local impls = { [TOKEN] = impl }
local function miss() error("miss") end
local function makeA() -- 지금
	return function(self, ...)
		local i = if type(self) == "table" then trait[rawget(self, "__type")] else nil
		if i == nil then return miss() end
		return i[1](self, ...)
	end
end
local function makeB() -- 토큰이 테이블인지 봄
	return function(self, ...)
		local t = if type(self) == "table" then rawget(self, "__type") else nil
		local i = if type(t) == "table" then trait[t] else nil
		if i == nil then return miss() end
		return i[1](self, ...)
	end
end
local function makeC() -- 따로 둔 구현 표(옛 시스템 모양)
	return function(self, ...)
		local i = if type(self) == "table" then impls[rawget(self, "__type")] else nil
		if i == nil then return miss() end
		return i[1](self, ...)
	end
end
local v = { __type = TOKEN }
local N = 5e6
for _, pair in { { "A now", makeA() }, { "B guard", makeB() }, { "C separate", makeC() } } do
	local f = pair[2]
	local best = math.huge
	for _ = 1, 7 do
		local t0 = os.clock()
		for _ = 1, N do f(v, 1) end
		best = math.min(best, os.clock() - t0)
	end
	print(pair[1], string.format("%.2f ns/call", best / N * 1e9))
end
