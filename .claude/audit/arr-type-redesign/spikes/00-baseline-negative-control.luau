--!strict
-- 음성 대조군: 현재 Arr<T> 설계가 "틀린 코드"를 실제로 잡는가?
-- 진단 0건은 의미가 없습니다 — **NEG-n 이 전부 에러로 나와야** 타입이 살아있는 것.
-- CANARY 는 arr 과 무관한 자명한 타입 에러입니다. 이게 안 뜨면 이 파일이
-- 애초에 검사되지 않고 있다는 뜻이라 측정 자체가 무효입니다.
local arr = require("../../../../src-old/arr")

--#region POS: 정상 사용례 — 에러가 나면 안 됨
local a = arr(1, 2, 3)
local pos1: number = a.n
local pos2: number? = a[1]
local pos3 = a:push(4)
local pos4: number? = a:max()
local pos5 = a:map(function(x: number)
	return tostring(x)
end)
local pos6: string? = pos5[1]
--#endregion

--#region NEG: 전부 에러여야 함
local neg1: string = a.n -- NEG-1: n 은 number 인데 string 에 대입
local neg2 = a:push("문자열") -- NEG-2: Arr<number> 에 string push
local neg3 = a:no_such_method() -- NEG-3: 없는 메소드
local neg4: string = pos3.n -- NEG-4: 체이닝 결과의 n 도 number
local neg5 = a:map(function(x: string)
	return x
end) -- NEG-5: 콜백 파라미터가 number 인데 string 으로 받음
local neg6: string = arr.sized(3, 1)[1] -- NEG-6: Arr<number> 원소를 string 에 대입
--#endregion

--#region CANARY: arr 과 무관. 반드시 에러여야 함
local canary: string = 42
--#endregion

return { pos1, pos2, pos3, pos4, pos6, neg1, neg2, neg3, neg4, neg5, neg6, canary }
