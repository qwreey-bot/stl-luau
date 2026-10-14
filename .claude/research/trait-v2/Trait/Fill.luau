--!strict
--[[
	Fill — 트레이트 시그니처의 제네릭을 다루는 타입 도구(2026-10-14 사용자와 함께 찾은 모양 — `bench-ignoreme/probe/rewrite*.luau`,
	`tags.luau`). 타입 함수를 쓰지 않는다는 규약의 **예외 자리**입니다(시그니처와 등록 검사에만 — 자료 타입에는 쓰지 않음).

	## 왜 이런 모양인가

	Rust 의 `impl<T> Stack for CircularDeque<T>` 는 타입 시스템 안의 선언이지만 우리 `Impl` 은 런타임 호출이라, 종류의 원소
	타입(연관 타입)은 **종류의 타입에 적어 둘 수밖에 없습니다**: `read __generics: { read Item: Inv<T> }`.
	- 받는 쪽(시그니처)이 그것을 **역추론**해야 하는데, 타입 함수를 거치면 역추론이 안 되고, 이름을 매개변수로 받는 평범한
	  별칭(`{ [Name]: T }`)은 인덱서가 됩니다. 그래서 시그니처에는 **표식**(`UseGeneric<Item>`)만 적고, `Fn` 의 출력에 씌운
	  타입 함수(`RewriteSig`)가 표식을 **이미 풀린 모양**으로 바꿔 끼웁니다:
	  `<Self>(s: Self, x: UseGeneric<Item>) -> Self`  →  `<Self, Item>(s: Self & { read __generics: { read Item: (Item) -> Item } }, x: Item) -> Self`
	- 자료 쪽은 **글자 그대로**(타입 함수 금지): 자료 타입이 타입 함수의 결과면 그 종류의 제네릭 함수가 전부 `T` 를 못 풀었고,
	  `__generics` 필드만 타입 함수여도 등록 검사가 깨졌습니다(실험).
	- 연관 타입은 **불변**(`Inv<T> = (T) -> T`): 공변이면 넣는 쪽 검사(원소 타입)가 전부 빠졌습니다(실험).
]]

-- 불변 팬텀. 종류의 `__generics` 에 연관 타입을 적을 때: `read __generics: { read Item: Inv<T> }`.
export type Inv<T> = (T) -> T

-- 제네릭 이름을 만듦(정의 자리를 하나로 — 철자는 여기서만). 지금은 그 이름의 문자열 타입.
export type function CreateGeneric(name: type): type
	if not name:is("singleton") then
		error("CreateGeneric needs a string literal type")
	end
	return name
end

-- 시그니처 안의 표식: "여기에 그 종류의 연관 타입 `Tag` 가 온다".
export type UseGeneric<Tag> = { read __genericMarker: Tag }

-- 라이브러리의 연관 타입 어휘(바깥 사람도 같은 도구로 자기 것을 만듦)
export type Item = CreateGeneric<"Item">
export type Index = CreateGeneric<"Index">

-- `Fn<<시그니처>>()` 의 출력에 씌움: 표식 → 새 제네릭, 첫 매개변수(Self) → `Self & { read __generics: { 이름: Inv<그 제네릭> } }`
export type function RewriteSig(fnType: type): type
	if fnType.tag ~= "function" then
		error("RewriteSig needs a function type")
	end
	const found: { [string]: type } = {}
	local function walk(t: type): type
		if t.tag == "table" then
			const marker = t:readproperty(types.singleton("__genericMarker"))
			if marker and marker:is("singleton") then
				const name = marker:value() :: string
				if not found[name] then
					found[name] = types.generic(name)
				end
				return found[name]
			end
			return t
		elseif t.tag == "union" or t.tag == "intersection" then
			const comps = t:components()
			for i, c in comps do
				comps[i] = walk(c)
			end
			return if t.tag == "union"
				then types.unionof(table.unpack(comps))
				else types.intersectionof(table.unpack(comps))
		elseif t.tag == "function" then
			const p, r = t:parameters(), t:returns()
			if p.head then
				for i, v in p.head do
					p.head[i] = walk(v)
				end
			end
			if r.head then
				for i, v in r.head do
					r.head[i] = walk(v)
				end
			end
			return types.newfunction(p, r, t:generics())
		end
		return t
	end
	const params, returns = fnType:parameters(), fnType:returns()
	if params.head then
		for i, v in params.head do
			params.head[i] = walk(v)
		end
	end
	if returns.head then
		for i, v in returns.head do
			returns.head[i] = walk(v)
		end
	end
	const generics = fnType:generics()
	const props: any = {} -- (`type` 은 타입 함수 안에만 있어 모듈 바깥에 별칭을 둘 수 없음)
	for name, g in found do
		props[types.singleton(name)] = { read = types.newfunction({ head = { g } }, { head = { g } }) }
		table.insert(generics, g)
	end
	if params.head and params.head[1] and next(found) ~= nil then
		params.head[1] = types.intersectionof(
			params.head[1],
			types.newtable({ [types.singleton("__generics")] = { read = types.newtable(props) } } :: any)
		)
	end
	return types.newfunction(params, returns, generics)
end

-- 등록 검사: 트레이트의 시그니처 표(`typeof(fns)` — RewriteSig 를 거친 것)에서 Self 를 종류 `S` 로, 덧붙은 제네릭을
-- `S.__generics` 에서 꺼내 채운 "이 종류에 대한" 표. `Default` 로 적은 칸(꼬리표 `__default`)은 선택 필드.
-- 등록 표는 **이 별칭으로 주석을 단 지역 변수**여야 검사가 섭니다(인자·반환으로 바로 넘기면 구현의 제네릭을 안 풂).
export type function ImplFor(trait: type, s: type): type
	const gens = s:readproperty(types.singleton("__generics"))
	if not gens then
		error("ImplFor: this kind does not declare __generics")
	end
	local function fill(t: type, map: { [string]: type }): type
		if t.tag == "generic" then
			const name = t:name()
			return if name and map[name] then map[name] else t
		elseif t.tag == "intersection" then
			-- `Self & { __generics }` 는 S 하나로 접음
			for _, c in t:components() do
				if c.tag == "generic" and c:name() == "Self" then
					return map.Self
				end
			end
			const comps = t:components()
			for i, c in comps do
				comps[i] = fill(c, map)
			end
			return types.intersectionof(table.unpack(comps))
		elseif t.tag == "union" then
			const comps = t:components()
			for i, c in comps do
				comps[i] = fill(c, map)
			end
			return types.unionof(table.unpack(comps))
		elseif t.tag == "function" then
			const p, r = t:parameters(), t:returns()
			if p.head then
				for i, v in p.head do
					p.head[i] = fill(v, map)
				end
			end
			if r.head then
				for i, v in r.head do
					r.head[i] = fill(v, map)
				end
			end
			const kept = {}
			for _, g in t:generics() do
				const name = g:name()
				if not (name and map[name]) then
					table.insert(kept, g)
				end
			end
			return types.newfunction(p, r, kept)
		end
		return t
	end
	const out: any = {}
	for key, v in trait:properties() do
		local fnType = v.read :: type
		local optional = false
		-- `Default` 꼬리표(`__default` 와의 교집합)를 떼고 선택 필드로
		if fnType.tag == "intersection" then
			const rest = {}
			for _, c in fnType:components() do
				if c.tag == "table" and c:readproperty(types.singleton("__default")) then
					optional = true
				else
					table.insert(rest, c)
				end
			end
			fnType = if #rest == 1 then rest[1] else types.intersectionof(table.unpack(rest))
		end
		const map: { [string]: type } = { Self = s }
		if fnType.tag == "function" then
			for _, g in fnType:generics() do
				const name = g:name()
				if name and name ~= "Self" then
					const phantom = gens:readproperty(types.singleton(name))
					if phantom then
						map[name] = (phantom:parameters().head :: { type })[1]
					end
				end
			end
		end
		const filled = fill(fnType, map)
		out[key] = { read = if optional then types.optional(filled) else filled }
	end
	return types.newtable(out)
end

return {}
