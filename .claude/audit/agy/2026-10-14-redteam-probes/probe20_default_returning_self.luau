--!strict
-- probes/probe20_default_returning_self.luau
-- 기본 구현 메서드가 Self를 반환할 때의 타입 보존 및 검증

type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
local function Fn<F>(): F return nil :: any end
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end

local function Trait<F, G>(
	name: string,
	def: (mode: "full") -> F,
	implDef: (mode: "impl") -> G
): { read Of: F, read ImplOf: G }
	return nil :: any
end

local function cloneDef<M>(mode: M)
	return function<Self, T>(of: (Self & Item<T>) | Token)
		return {
			-- 기본 구현이 Self를 반환
			Duplicate = Default(mode, function(ops: any)
				return function(s: Self): Self
					return s
				end
			end),
		}
	end
end

const Cloneable = Trait("Cloneable", cloneDef<<"full">>, cloneDef<<"impl">>)
export type Cloneable<Self, T> = typeof(Cloneable.Of<<Self, T>>(nil :: any))
export type CloneableImpl<Self, T> = typeof(Cloneable.ImplOf<<Self, T>>(nil :: any))

type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local a: Arr<number> = nil :: any
local ops = Cloneable.Of(a)

-- 정상: Duplicate(a)는 Arr<number>를 반환해야 함
local dup: Arr<number> = ops.Duplicate(a)

-- NEG: 다른 컨테이너 타입으로 대입 시 잡히는가?
type Other<T> = { m: string, read __generics: { read Item: (T) -> T } }
local NEG_dup: Other<number> = ops.Duplicate(a) -- NEG: Arr<number>는 Other<number>가 아님!

local canary: string = 1
return { canary, dup, NEG_dup }
