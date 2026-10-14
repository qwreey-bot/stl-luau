--!strict
local function id<T>(x: T): T return x end
type Spec = { process: (x: number) -> number }
local function takeFn(f: (x: number) -> number) end
local function takeSpec(s: Spec) end
local f2: (x: number) -> number = id
local f3: (x: number) -> number = id
