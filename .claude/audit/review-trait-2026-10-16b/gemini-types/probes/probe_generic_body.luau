--!strict
local stl = require("../src")

-- 1. Call List entry points inside generic function body
local function testListGet<E, I>(list: stl.ListRead<E, I>, idx: I): E?
	return stl.List.Get(list, idx)
end

local function testListFold<E, I, U>(list: stl.ListRead<E, I>, init: U, fn: (acc: U, item: E, idx: I) -> U): U
	return stl.List.Fold(list, init, fn)
end

local function testListIndexOf<E, I>(list: stl.ListRead<E, I>, item: E): I?
	return stl.List.IndexOf(list, item)
end

-- 2. Call Deque entry points inside generic function body
local function testDequeFront<T>(deque: stl.DequeRead<T>): T?
	return stl.Deque.Front(deque)
end

local function testDequePushBack<T>(deque: stl.Deque<T>, item: T): stl.Deque<T>
	return stl.Deque.PushBack(deque, item)
end

-- 3. Call Map entry points inside generic function body
local function testMapGet<K, V>(map: stl.Map<K, V>, key: K): V?
	return stl.Map.Get(map, key)
end

local function testMapSet<K, V>(map: stl.Map<K, V>, key: K, val: V)
	stl.Map.Set(map, key, val)
end

-- 4. Call Set entry points inside generic function body
local function testSetHas<T>(set: stl.Set<T>, item: T): boolean
	return stl.Set.Has(set, item)
end

local function testSetAdd<T>(set: stl.Set<T>, item: T): boolean
	return stl.Set.Add(set, item)
end

-- 5. Call Stack entry points inside generic function body
local function testStackPush<T>(s: stl.Stack<T>, item: T): stl.Stack<T>
	return stl.Stack.Push(s, item)
end

local function testStackPop<T>(s: stl.Stack<T>): T?
	return stl.Stack.Pop(s)
end

-- 6. Call Collection entry points inside generic function body
local function testCollectionLen(c: stl.CollectionRead): number
	return stl.Collection.Len(c)
end

local function testCollectionClear<C>(c: C & stl.Collection): C
	return stl.Collection.Clear(c)
end

return {
	testListGet = testListGet,
	testListFold = testListFold,
	testListIndexOf = testListIndexOf,
	testDequeFront = testDequeFront,
	testDequePushBack = testDequePushBack,
	testMapGet = testMapGet,
	testMapSet = testMapSet,
	testSetHas = testSetHas,
	testSetAdd = testSetAdd,
	testStackPush = testStackPush,
	testStackPop = testStackPop,
	testCollectionLen = testCollectionLen,
	testCollectionClear = testCollectionClear,
}
