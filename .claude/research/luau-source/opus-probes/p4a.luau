--!strict
local function id<T>(x: T): T return x end
local function takeFn(f: (x: number) -> number) end
takeFn(id) -- A
