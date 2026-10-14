--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }
type AnyToken = { read name: string }

type Factory = <Self, T>(of: (Self & Item<T>) | AnyToken) -> {
	Push: (stack: Self, item: T) -> Self,
}

-- Case 1: ObjectWithIndexer & Entries
type ObjectWithIndexer<F> = { read Of: F, read [string]: any }
type Entries = {
	Push: <Self, T>(stack: Self & Item<T>, item: T) -> Self,
}

type TraitObj1 = ObjectWithIndexer<Factory> & Entries

local t1: TraitObj1 = nil :: any
-- t1.Of<<C, T>>(TOKEN) 이 되는가?
local test1 = t1.Of<<number, number>>(nil :: any)

-- Case 2: ObjectWithoutIndexer & Entries
type ObjectWithoutIndexer<F> = { read Of: F }
type TraitObj2 = ObjectWithoutIndexer<Factory> & Entries

local t2: TraitObj2 = nil :: any
local test2 = t2.Of<<number, number>>(nil :: any)

local canary: string = 1
