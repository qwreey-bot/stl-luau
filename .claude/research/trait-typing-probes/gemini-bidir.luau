--!strict
-- PROBE 5: Bidirectional Type Propagation Bug in Function Table Arguments (Luau Upstream Candidate)

local function id<T>(x: T): T
	return x
end

type Spec = {
	process: (x: number) -> number,
}

-- Case A: Direct assignment to typed variable -> SUCCEEDS (id is instantiated as (number) -> number)
local varA: Spec = {
	process = id,
}

-- Case B: Direct function argument -> SUCCEEDS (id is instantiated directly)
local function takeDirect(f: (number) -> number) end
takeDirect(id)

-- Case C: Table literal passed to function argument -> FAILS with TypeError!
-- Luau fails to propagate expected type 'Spec' into the table literal's fields,
-- leaving 'id' as uninstantiated generic '<T>(T) -> T', which then fails subtyping!
local function takeSpec(s: Spec) end
takeSpec({
	process = id, -- TypeError: Expected '(number) -> number', but got '<T>(T) -> T'
})

local canary: string = 1
return { varA, canary }
