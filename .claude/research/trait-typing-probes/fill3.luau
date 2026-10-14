--!strict
local stl = require("../../../src")
local CircularDeque = stl.CircularDeque
type CircularDeque<T> = stl.CircularDeque<T>

-- 사용자 실험의 FillGeneric(교집합·합집합 갈래를 바로잡음) + 여러 제네릭을 한 번에: map 은 { 이름: 타입 } 테이블 타입
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
		-- 바꿔 끼우는 이름은 이 함수의 제네릭 목록에서 뺌(남은 제네릭은 그대로)
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
		-- `Self & 마커` 에서 Self 를 채우면 채운 타입 하나로 접음 — 마커는 진입점(어떤 컨테이너든)용이고 구체 타입은 이미
		-- 그 마커를 듦. 남겨 두면 솔버가 구현의 제네릭을 교집합에 맞춰 풀지 못함(실험)
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
		return if tag == "intersection" then types.intersectionof(table.unpack(comps)) else types.unionof(table.unpack(comps))
	end
	return input
end

-- 진입점과 등록을 한 시그니처로: 쓰는 진입점은 불변 마커(MarkerMut), 보는 것은 읽기 마커
type Marker<T> = stl.DequeMarker<T>
type MarkerMut<T> = stl.DequeMarkerMut<T>
type StackFns = {
	Push: <Self, T>(stack: Self & MarkerMut<T>, item: T) -> Self,
	Pop: <Self, T>(stack: Self & MarkerMut<T>) -> T?,
	Peek: <Self, T>(stack: Self & Marker<T>) -> T?,
}
-- (A) 등록 — Self 와 T 를 다 채움 / Self 만 채움(T 는 제네릭 그대로)
type ForBoth = FillGenerics<StackFns, { Self: CircularDeque<string>, T: string }>
type ForSelf = FillGenerics<StackFns, { Self: CircularDeque<any> }>
local okBoth: ForBoth = { Push = CircularDeque.PushBack, Pop = CircularDeque.PopBack, Peek = CircularDeque.Back }
local okSelf: ForSelf = { Push = CircularDeque.PushBack, Pop = CircularDeque.PopBack, Peek = CircularDeque.Back }
local negBoth: ForBoth = { Push = CircularDeque.PushBack, Pop = CircularDeque.Len, Peek = CircularDeque.Back }
local negSelf: ForSelf = { Push = CircularDeque.PushBack, Pop = CircularDeque.Len, Peek = CircularDeque.Back }
-- (B) 진입점 — StackFns 그대로가 진입점 타입
local Stack: StackFns = nil :: any
local d = CircularDeque.Of(1, 2, 3)
local back: CircularDeque<number> = Stack.Push(d, 4)
local popped: number? = Stack.Pop(d)
local negPushStr = Stack.Push(d, "x")
local negPop: string? = Stack.Pop(d)
local peekRead: number? = Stack.Peek(d :: stl.CircularDequeRead<number>)
local negPopRead = Stack.Pop(d :: stl.CircularDequeRead<number>)
-- (C) 끝에 붙는 ...any: 람다로 적은 함수의 추론 타입
local lam = function<Self>(s: Self): Self
	return s
end
local showLam: never = lam
local showFilled: never = (nil :: any) :: FillGenerics<typeof(lam), { Self: { __aa: boolean } }>
local canary: string = 1
return { showLam, showFilled, okBoth, okSelf, negBoth, negSelf, back, popped, negPushStr, negPop, peekRead, negPopRead, canary }
