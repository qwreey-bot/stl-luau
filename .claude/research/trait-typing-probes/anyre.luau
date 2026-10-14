--!strict
type N = { v: number }
-- 1. any 지역, 조건부 재대입, 돌려주기
local function f1(x: N, y: any): N?
	local t: any = x
	if y then
		t = y.next
	end
	return t
end
-- 2. any 지역을 nil 거르는 조건 뒤에 재대입, 그다음 인덱싱
local function f2(start: any)
	local node: any = start
	while true do
		local above: any = node.parent
		if above == nil or not above.red then
			break
		end
		if above.right == node then
			above = node
		end
		above.red = false
	end
end
-- 3. 재대입 없이
local function f3(x: N, y: any): N?
	local t: any = x
	return t
end
return { f1, f2, f3 }
