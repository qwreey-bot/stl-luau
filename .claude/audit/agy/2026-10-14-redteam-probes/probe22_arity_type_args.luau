--!strict
-- probes/probe22_arity_type_args.luau
-- 3개의 제네릭 매개변수를 받는 Trait.Of에 2개만 명시적 타입 인자로 넘겼을 때

type Token = { read name: string }
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
local function Fn<F>(): F return nil :: any end

local function Trait<F, G>(
	name: string,
	def: (mode: "full") -> F,
	implDef: (mode: "impl") -> G
): { read Of: F, read ImplOf: G }
	return nil :: any
end

local function listDef<M>(mode: M)
	return function<Self, E, I>(of: (Self & ItemIndex<E, I>) | Token)
		return {
			Get = Fn<<(list: Self, idx: I) -> E?>>(),
		}
	end
end

const List = Trait("List", listDef<<"full">>, listDef<<"impl">>)
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T, read Index: (number) -> number } }
local ARR: Token = { name = "Arr" }

-- 실수: 3개인데 2개만 넘김
local ops = List.Of<<Arr<string>, string>>(ARR) -- 2개만 넘김 -> I가 unknown으로 전락
local ops_excess = List.Of<<Arr<string>, string, number, boolean>>(ARR) -- NEG: 4개 넘김 (1개 초과)

local canary: string = 1
return { canary, ops }
