--!strict
--[[
	시제품: 기본 구현과 의존을 가진 트레이트 (papers/07).

	지금의 `src/Trait.luau` 는 `[토큰] = 구현` 표까지입니다. 여기서는 두 가지를 더합니다:
	- **기본 구현(provided)**: 구현이 필수 함수만 주면 나머지는 트레이트가 채웁니다. 구현이 같은 이름을
	  주면 그것이 이깁니다(재정의). **등록할 때 한 번** 합쳐 완성된 함수 표를 만들어 두므로 호출 비용은
	  지금의 트레이트 조회와 같습니다.
	- **의존(requires)**: 다른 트레이트를 먼저 구현했어야 등록됩니다(Rust 의 supertrait / where).
	  기본 구현은 의존 트레이트의 완성된 표를 받아 씁니다.

	- ⭐ **저절로 따라오는 구현(blanket)**: 필수 함수가 없는 트레이트는 **등록이 필요 없습니다** — 의존
	  트레이트를 다 구현한 종류면 처음 쓸 때 기본 구현으로 완성 표를 만들어 캐시합니다(Rust 의
	  `impl<T: List + Build> Seq for T`). 컨테이너를 만드는 쪽은 자기가 아는 트레이트만 등록하고,
	  **트레이트 쪽이 자기가 무엇을 요구하는지 압니다** — 나중에 누가 새 트레이트를 더해도 이미 있는
	  컨테이너를 고칠 필요가 없습니다. 재정의하고 싶은 종류만 `Impl` 로 따로 등록합니다(처음 쓰기 전에).

	`defaults(impl, full, deps)`:
	- `impl` — 구현이 준 표. 필수 함수는 여기서 꺼내 지역 변수로 잡아 두면 원소마다의 호출이 테이블
	  조회 없이 upvalue 호출이 됩니다.
	- `full` — 합쳐지는 중인 완성 표. 기본 구현이 **다른 기본 구현**을 부를 땐 `full.X` 로 늦게
	  찾아야 재정의된 판을 씁니다(Rust 와 같은 뜻).
	- `deps` — `[의존 트레이트] = 그 종류의 완성 표`.
]]
export type Spec = {
	required: { string },
	requires: { any }?,
	defaults: ((impl: any, full: any, deps: { [any]: any }) -> { [string]: any })?,
}
export type Trait = { name: string, impls: { [any]: any }, spec: Spec }

local function New(name: string, spec: Spec): Trait
	return { name = name, impls = {}, spec = spec }
end

local resolve: (trait: Trait, token: any) -> any

-- 의존 트레이트들의 완성 표. 하나라도 없으면 그 트레이트를 돌려줍니다(둘째 값).
local function depsOf(trait: Trait, token: any): ({ [any]: any }?, Trait?)
	const deps: { [any]: any } = {}
	for _, dep in trait.spec.requires or {} do
		const depImpl = resolve(dep, token)
		if depImpl == nil then
			return nil, dep
		end
		deps[dep] = depImpl
	end
	return deps, nil
end

local function Impl(trait: Trait, token: any, impl: { [string]: any })
	const spec = trait.spec
	const deps, missing = depsOf(trait, token)
	if deps == nil then
		error(`{token.name} must implement {(missing :: Trait).name} before {trait.name}`, 2)
	end
	for _, fnName in spec.required do
		if type(impl[fnName]) ~= "function" then
			error(`{token.name} is missing {fnName} for {trait.name}`, 2)
		end
	end
	const full: { [string]: any } = {}
	if spec.defaults then
		for fnName, fn in spec.defaults(impl, full, deps) do
			full[fnName] = fn
		end
	end
	for fnName, fn in impl do
		full[fnName] = fn -- 구현이 준 것이 이김
	end
	trait.impls[token] = table.freeze(full)
end

-- 그 종류의 완성 표. 등록된 것이 없어도, 필수 함수가 없는 트레이트면 의존만으로 만들어 캐시합니다.
function resolve(trait: Trait, token: any): any
	const found = trait.impls[token]
	if found ~= nil or token == nil then
		return found
	end
	if #trait.spec.required > 0 then
		return nil -- 필수 함수가 있는 트레이트는 그 종류가 직접 등록해야 함
	end
	const deps = depsOf(trait, token)
	if deps == nil then
		return nil
	end
	Impl(trait, token, {})
	return trait.impls[token]
end

local function ImplOf(trait: Trait, value: any): any
	if type(value) ~= "table" then
		return nil
	end
	const token = rawget(value, "__type")
	-- 뜨거운 길은 지금과 같은 조회 하나. 없을 때만 저절로 따라오는 구현을 찾습니다.
	return trait.impls[token] or resolve(trait, token)
end

return { New = New, Impl = Impl, ImplOf = ImplOf }
