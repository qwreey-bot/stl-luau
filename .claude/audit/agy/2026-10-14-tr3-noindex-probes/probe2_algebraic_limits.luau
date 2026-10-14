--!strict
-- probe2: 순수 타입 연산자(|, &)의 한계 실측

type F = (number) -> boolean

-- [한계 1] F | never: 솔버가 F | never를 F로 축약하지 못하고 호출을 거절함
local fNever: F | never = function(n: number): boolean return n > 0 end
local resNever = fNever(10) -- FAIL: Cannot call a value of type never in union

-- [한계 2] F | (...any) -> ...never: 더미 바닥 함수 유니온
type BottomFn = (...any) -> ...never
local fBottom: F | BottomFn = function(n: number): boolean return n > 0 end
-- 잘못된 인자를 넘겼을 때의 에러 메시지:
fBottom("wrong") -- FAIL: 에러 메시지가 복잡해짐

-- 그리고 반환값이 void인 함수:
type Action = () -> ()
local a: Action | BottomFn = function() end -- Void 반환 함수와 ...never 충돌 가능성

-- [한계 3] 인터섹션으로 타입을 넓힐 수 없음
-- F & T 는 항상 F의 서브타입이지 슈퍼타입(F?)이 될 수 없음.
type Super<T, M> = T & M
type SubTest = Super<F, unknown> -- F & unknown = F (F? 가 될 수 없음)

local canary: string = 1
