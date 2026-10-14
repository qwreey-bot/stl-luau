--!strict
--[[ 변형 D 의 얇은 겉(v8 런타임 위): 바깥 겹이 `mode` 대신 `Default` 자체를 받음 — 정의자가 모드를 들고 다니지 않음.
     기본 구현이 없는 트레이트는 A 모양(한 겹) 그대로 받는지도 본다(오버로드). ]]
local Trait = require("./trait-v8/Trait")
export type DefaultFn<M> = <F>(build: (ops: any) -> F) -> index<{ full: F, impl: F? }, M>

type DefineWithDefaults = <F, G>(name: string, def: ((Default: DefaultFn<"full">) -> F) & ((Default: DefaultFn<"impl">) -> G)) -> Trait.Object<F, G>

const function WithDefaults<F, G>(name: string, def: ((Default: DefaultFn<"full">) -> F) & ((Default: DefaultFn<"impl">) -> G)): Trait.Object<F, G>
	const wrapped = function(mode: any): any
		return (def :: any)(function(build: any): any
			return Trait.Default(mode, build)
		end)
	end
	return Trait.Trait(name, wrapped :: any)
end

const function Plain<F>(name: string, factory: F): Trait.Object<F, F>
	return Trait.Trait(name, function(_mode: any): any
		return factory
	end :: any) :: any
end

-- 한 이름이 두 모양을 받게(오버로드)
const Define: DefineWithDefaults & (<F>(name: string, factory: F) -> Trait.Object<F, F>) = function(name: string, def: any): any
	-- 런타임 판별: 한 번 불러 표가 나오면 한 겹(기본 구현 없음), 함수가 나오면 두 겹
	const probe = def(function(build: any): any return Trait.Default(nil, build) end)
	if type(probe) == "function" then
		return WithDefaults(name, def)
	end
	return Plain(name, def)
end :: any

return { WithDefaults = WithDefaults, Plain = Plain, Define = Define }
