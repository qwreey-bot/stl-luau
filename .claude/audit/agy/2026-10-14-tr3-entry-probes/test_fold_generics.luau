--!strict
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }

local function Fn<F>(): F
	return nil :: any
end

const ListEntries = {
	Fold = Fn<< <Self, E, I, U>(list: Self & ItemIndex<E, I>, init: U, fn: (acc: U, item: E, idx: I) -> U) -> U >>(),
}

-- 방법 1: typeof(ListEntries.Fold<<Self, E, I, any>>) 로 하면?
type ListOpsBad<Self, E, I> = {
	Fold: typeof(ListEntries.Fold<<Self, E, I, any>>),
}

type MyList<E> = {
	read __generics: { read Item: (E) -> E, read Index: (number) -> number },
}

-- partial instantiation test:
local f = ListEntries.Fold<<MyList<number>, number, number>>
local list: MyList<number> = nil :: any
local res1 = f(list, 0, function(acc: number, item: number, idx: number) return acc + item end)
local res2 = f(list, "init", function(acc: string, item: number, idx: number) return acc .. tostring(item) end)

local _check_res1: number = res1
local _check_res2: string = res2
local NEG_res: boolean = res1 -- NEG

local canary: string = 1
