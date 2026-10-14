--!strict
type DefFull = <F>(build: () -> F) -> F
type DefImpl = <F>(build: () -> F) -> F?

local function testFull(def: DefFull)
	local f = def(function() return 123 end)
	local s: number = f
	local canary: string = 1 -- canary
end

local function testImpl(def: DefImpl)
	local f = def(function() return 123 end)
	local s: number? = f
	local canary: string = 1 -- canary
end
