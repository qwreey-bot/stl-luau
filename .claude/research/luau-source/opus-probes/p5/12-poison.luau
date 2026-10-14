--!strict
local function id<T>(x: T): T return x end
type Spec = { process: (x: number) -> number }
local function takeFn(f: (x: number) -> number) end
local function takeSpec(s: Spec) end
takeSpec({ process = id })
takeFn(id) -- 앞의 실패가 캐시를 오염?
