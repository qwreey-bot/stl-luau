--!strict
-- probes/probe6_default_generics_void_varargs.luau
-- 1. 제네릭 매개변수를 가진 기본 구현 (Fold<U>)
-- 2. 반환이 없는 기본 구현 (Clear() -> ())
-- 3. 가변 인자를 가진 기본 구현 (Concat(s, ...))
-- 4. 오버로드된 함수로 재정의

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

local function richDef<M>(mode: M)
	return function<Self, T>(of: (Self & Item<T>) | Token)
		return {
			-- 필수
			Get = Fn<<(s: Self) -> T?>>(),
			
			-- 1. 자체 제네릭을 가진 기본 구현
			Fold = Default(mode, function(ops: any)
				return function<U>(s: Self, init: U, fn: (acc: U, item: T) -> U): U
					return init
				end
			end),
			
			-- 2. 반환값이 없는 기본 구현 (void: ())
			Clear = Default(mode, function(ops: any)
				return function(s: Self): ()
				end
			end),
			
			-- 3. 가변 인자를 가진 기본 구현
			Log = Default(mode, function(ops: any)
				return function(s: Self, ...: any): ()
				end
			end),
		}
	end
end

const Rich = Trait("Rich", richDef<<"full">>, richDef<<"impl">>)
export type Rich<Self, T> = typeof(Rich.Of<<Self, T>>(nil :: any))
export type RichImpl<Self, T> = typeof(Rich.ImplOf<<Self, T>>(nil :: any))

type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local a: Arr<number> = nil :: any
local ops = Rich.Of(a)

-- [테스트 1] Fold<U>
local folded_num: number = ops.Fold(a, 0, function(acc, item) return acc + item end)
local folded_str: string = ops.Fold(a, "init", function(acc, item) return acc .. tostring(item) end)
local NEG_fold_mismatch: string = ops.Fold(a, 0, function(acc, item) return acc + item end) -- NEG: number -> string 대입 불가
local NEG_fold_explicit = ops.Fold<<string>>(a, 0, function(acc, item) return acc end) -- NEG: init은 string이어야 함

-- [테스트 2] Clear() -> ()
local clear_ret = ops.Clear(a)
local NEG_clear_ret: string = ops.Clear(a) -- NEG: void는 string에 대입 불가

-- [테스트 3] Log(s, ...)
ops.Log(a, 1, "test", true)
local NEG_log_arg = ops.Log("not_a") -- NEG: 첫 번째 인자는 Arr<number>여야 함

-- [테스트 4] 등록 시 재정의 검사
type A = { read __probeA: true }
-- 정상 재정의
local ok_impl: RichImpl<Arr<A>, A> = {
	Get = function(s) return s[1] end,
	Fold = function<U>(s: Arr<A>, init: U, fn: (U, A) -> U): U return init end,
	Clear = function(s: Arr<A>): () end,
}

-- 잘못된 Clear 재정의 (인자 타입 불일치)
local NEG_clear_override: RichImpl<Arr<A>, A> = {
	Get = function(s) return s[1] end,
	Clear = function(s: string): () end, -- NEG: Arr<A>여야 함
}

-- 잘못된 Fold 재정의 (누적 타입 U를 고정해버림)
local NEG_fold_pinU: RichImpl<Arr<A>, A> = {
	Get = function(s) return s[1] end,
	Fold = function(s: Arr<A>, init: number, fn: (number, A) -> number): number return init end, -- NEG
}

local canary: string = 1
return { canary, ok_impl, NEG_clear_override, NEG_fold_pinU, folded_num, folded_str }
