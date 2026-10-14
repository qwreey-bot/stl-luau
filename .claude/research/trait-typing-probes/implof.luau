--!strict
local stl = require("../../../src")
--!strict
--[[
	Fill — 트레이트 시그니처에서 "이 종류에 대한" 모양을 끌어내는 타입 함수(2026-10-14 사용자 실험에서 — 타입 함수를 쓰지
	않는다는 규약의 예외 자리). `FillGenerics<시그니처 표, { Self: 종류, T: 원소 }>` 는 각 함수의 제네릭 중 그 이름들을
	구체 타입으로 바꿔 끼우고 함수의 제네릭 목록에서 뺍니다.
	- `Self & 마커` 처럼 바꿔 끼울 제네릭이 든 **교집합은 채운 타입 하나로 접습니다** — 마커는 진입점(어떤 컨테이너든)용이고
	  구체 타입은 이미 마커를 듦. 접지 않으면 솔버가 구현의 제네릭을 교집합에 맞춰 풀지 못했음(실험).
	- 등록 표는 **이 별칭으로 주석을 단 지역 변수**로 적어야 검사가 섭니다 — 함수의 반환값·인자로 넘기면 솔버가 구현의
	  제네릭을 풀지 않아 맞게 써도 에러였음(실험).
]]
type function FillGenerics(input: type, map: type): type
	const tag = input.tag
	if tag == "generic" then
		const name = input:name()
		if name then
			const into = map:readproperty(types.singleton(name))
			if into then
				return into
			end
		end
		return input
	elseif tag == "table" then
		const props = input:properties()
		for key, v in props do
			-- `Trait.Default<<시그니처>>()` 로 적은 칸(꼬리표 `__default` 와의 교집합)은 **선택 필드**로 — 기본 구현이 채우니
			-- 등록 표에 없어도 됨. 꼬리표는 뗌.
			const read = v.read
			if read and read.tag == "intersection" then
				local tagged = false
				const rest = {}
				for _, c in read:components() do
					if c.tag == "table" and c:readproperty(types.singleton("__default")) then
						tagged = true
					else
						table.insert(rest, c)
					end
				end
				if tagged then
					const inner = if #rest == 1 then rest[1] else types.intersectionof(table.unpack(rest))
					props[key] = { read = types.optional(FillGenerics(inner, map)) }
					continue
				end
			end
			props[key] = {
				read = if v.read then FillGenerics(v.read, map) else nil,
				write = if v.write then FillGenerics(v.write, map) else nil,
			}
		end
		const indexer = input:indexer()
		return types.newtable(
			props,
			if indexer
				then {
					index = FillGenerics(indexer.index, map),
					readresult = FillGenerics(indexer.readresult, map),
					writeresult = FillGenerics(indexer.writeresult, map),
				}
				else nil,
			input:metatable()
		)
	elseif tag == "function" then
		const kept = {}
		for _, g in input:generics() do
			const name = g:name()
			if not (name and map:readproperty(types.singleton(name))) then
				table.insert(kept, g)
			end
		end
		const params = input:parameters()
		const returns = input:returns()
		if params.head then
			for i, v in params.head do
				params.head[i] = FillGenerics(v, map)
			end
		end
		if params.tail then
			params.tail = FillGenerics(params.tail, map)
		end
		if returns.head then
			for i, v in returns.head do
				returns.head[i] = FillGenerics(v, map)
			end
		end
		if returns.tail then
			returns.tail = FillGenerics(returns.tail, map)
		end
		return types.newfunction(params, returns, kept)
	elseif tag == "intersection" or tag == "union" then
		const comps = input:components()
		if tag == "intersection" then
			for _, c in comps do
				if c.tag == "generic" then
					const name = c:name()
					const into = if name then map:readproperty(types.singleton(name)) else nil
					if into then
						return into
					end
				end
			end
		end
		for i, v in comps do
			comps[i] = FillGenerics(v, map)
		end
		return if tag == "intersection"
			then types.intersectionof(table.unpack(comps))
			else types.unionof(table.unpack(comps))
	end
	return input
end


-- 공용 원소 마커를 흉내: 덱의 __dequeItem 을 원소 마커로 씀(실제로는 모든 컨테이너가 같은 이름 하나)
type ItemOf<C> = index<C, "__dequeItem">
-- 트레이트 시그니처: 종류 확인 없이 원소 마커만(동적 경로)
type Item<T> = { read __dequeItem: T }
type StackFns = {
	Push: <Self, T>(stack: Self & Item<T>, item: T) -> Self,
	Pop: <Self, T>(stack: Self & Item<T>) -> T?,
}
-- ImplOf: 값의 타입에서 Self 와 원소를 채운 "이 종류의 함수 표"
local function ImplOf<F, C>(trait: F, value: C): FillGenerics<F, { Self: C, T: ItemOf<C> }>
	return nil :: any
end
local Stack: StackFns = nil :: any
local d = stl.CircularDeque.Of(1, 2, 3)
local s = ImplOf(Stack, d)
local back: stl.CircularDeque<number> = s.Push(d, 4)
local popped: number? = s.Pop(d)
local negPush = s.Push(d, "x")              -- NEG: 원소 타입
local negPop: string? = s.Pop(d)            -- NEG: 반환 타입
local push = s.Push                          -- 미리 꺼내 둠
for i = 1, 3 do
	push(d, i)
end
local negHoist = push(d, "y")               -- NEG: 꺼내 둔 함수도 검사
local canary: string = 1
return { back, popped, negPush, negPop, negHoist, canary }
