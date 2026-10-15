--!nocheck
-- 프로브 03: 명시적 스택으로 바뀐 Restore — 얼린 뿌리, 표가 아닌 뿌리, 고리, 메타테이블(__iter/__index), 넓은 그래프
local stl = require("../../../../src")
local T = stl.Trait
local function fake(name, extra)
	local t = { __type = { name = name }, n = 0 }
	for k, v in extra or {} do
		t[k] = v
	end
	return t
end

-- 표가 아닌 뿌리 / nil
print("nil", pcall(T.Restore, nil))
print("number", pcall(T.Restore, 5))
-- 얼린 뿌리: 자기 토큰은 못 바꾸지만 안쪽은 되찾음
local inner = fake("Stl.Arr")
local root = table.freeze(fake("Stl.Arr", { inner = inner }))
T.Restore(root)
print("얼린 뿌리: 뿌리", T.TokenOf(root) == nil, "안쪽", T.TokenOf(inner) == stl.Arr.Token)
-- 고리 + 자기 참조
local a = fake("Stl.Arr")
local b = fake("Stl.HashMap", { back = a })
a.next = b
a.self = a
T.Restore(a)
print("고리", T.TokenOf(a) == stl.Arr.Token, T.TokenOf(b) == stl.HashMap.Token)
-- __index 메타테이블은 무관(raw 로 읽음)
local proto = { __type = stl.Arr.Token }
local viaIndex = setmetatable({ n = 0 }, { __index = proto })
T.Restore(viaIndex)
print("__index 로 물려받은 __type 은 그대로(자기 키 아님)", rawget(viaIndex, "__type") == nil)
-- __iter 메타테이블: 걷기가 사용자 __iter 를 부름(옛 재귀 판과 같음 — `for k, v in node`)
local iterCalls = 0
local hidden = fake("Stl.Arr")
local withIter = setmetatable({ child = hidden }, {
	__iter = function(t)
		iterCalls += 1
		return next, {} -- 아무것도 안 내는 순회자
	end,
})
T.Restore({ withIter })
print("__iter 호출", iterCalls, "안쪽 되찾음", T.TokenOf(hidden) == stl.Arr.Token)
-- 던지는 __iter: 어디서 터지나
local throwing = setmetatable({}, { __iter = function() error("boom") end })
local ok, err = pcall(function()
	T.Restore({ throwing })
end)
print("던지는 __iter", ok, err)
-- 넓은 그래프(가지 20만) — 스택이 넓이만큼 자람
local wide = {}
for i = 1, 200000 do
	wide[i] = fake("Stl.Arr")
end
local t0 = os.clock()
T.Restore(wide)
print("넓은 20만", T.TokenOf(wide[1]) == stl.Arr.Token and T.TokenOf(wide[200000]) == stl.Arr.Token, string.format("%.3fs", os.clock() - t0))
-- 이미 진짜 토큰인 값: 그대로
local real = stl.Arr.Of(1, 2)
T.Restore(real)
print("진짜", T.TokenOf(real) == stl.Arr.Token, real[1], real[2])
-- 모르는 이름: 그대로
local unk = fake("Nope.Unknown")
T.Restore(unk)
print("모르는 이름 그대로", type(unk.__type) == "table" and unk.__type.name == "Nope.Unknown")
-- __type 이 문자열 이름인 직렬화(흔한 모양?)
local str = { __type = "Stl.Arr", n = 0 }
T.Restore(str)
print("__type 이 문자열", typeof(str.__type), str.__type)
