--!nocheck
-- 기본 사실 확인: 메인 스레드의 coroutine.running(), 꼬리 호출이 프레임을 남기는지
print("main running:", coroutine.running(), type(coroutine.running()))
local function g()
	local out = {}
	for l = 1, 6 do
		local f, s = debug.info(l, "fs")
		table.insert(out, tostring(s) .. ":" .. tostring(f))
	end
	return table.concat(out, " | ")
end
local function f()
	return g()
end
print("tail:", f())
local function viaPcall()
	local ok, r = pcall(g)
	return r
end
print("pcall:", viaPcall())
