--!strict
-- probes/probe12_default_explicit_signature.luau
-- Default에 명시적 타입 인자 Default<<F, M>>를 줄 수 있는가?

type Token = { read name: string }
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end

local function testDef<M>(mode: M)
	return function<Self>(of: Self)
		-- 시도 1: Default에 F와 M을 명시적 인자로 전달
		local m1 = Default<<(s: Self) -> boolean, M>>(mode, function(ops: any)
			return function(s: Self): boolean return true end
		end)
		
		-- 시도 2: 만약 잘못된 반환 타입(number)을 람다가 반환하면 명시적 F에서 잡히는가?
		local m2 = Default<<(s: Self) -> boolean, M>>(mode, function(ops: any)
			return function(s: Self): number return 123 end -- NEG: boolean이어야 함!
		end)
		
		return { m1 = m1, m2 = m2 }
	end
end

local canary: string = 1
return { testDef, canary }
