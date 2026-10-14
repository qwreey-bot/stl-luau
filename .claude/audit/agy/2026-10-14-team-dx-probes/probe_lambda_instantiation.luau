--!strict
-- probe_lambda_instantiation.luau
-- 람다 리터럴에 명시적 타입 인자를 바로 붙일 수 있는가?

local f = (function<T>(x: T): T return x end)<<number>>
local n: number = f(1)

local canary: string = 1
