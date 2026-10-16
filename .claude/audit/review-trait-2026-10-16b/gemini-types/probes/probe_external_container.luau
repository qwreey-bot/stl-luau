--!strict
local stl = require("../src")
local Trait = stl.Trait
type A = { read __probeA: true }

-- Define an external container
type MyDeque<T> = {
	items: { T },
	read __type: stl.TraitToken<"My.Deque">,
	read __traits: {
		read Deque: stl.DequeAssoc<T>,
		read Collection: stl.CollectionAssoc,
	},
}

local MyDequeToken = Trait.NewToken("My.Deque")

local function newMyDeque<T>(): MyDeque<T>
	local self = {
		items = {},
		__type = MyDequeToken,
	}
	return self :: any
end

local myDequeImpl: stl.DequeProvided<MyDeque<A>, A> = {
	PushFront = function(self: MyDeque<A>, item: A): MyDeque<A>
		table.insert(self.items, 1, item)
		return self
	end,
	PushBack = function(self: MyDeque<A>, item: A): MyDeque<A>
		table.insert(self.items, item)
		return self
	end,
	PopFront = function(self: MyDeque<A>): A?
		return if #self.items > 0 then table.remove(self.items, 1) else nil
	end,
	PopBack = function(self: MyDeque<A>): A?
		return table.remove(self.items)
	end,
	Front = function(self: MyDeque<A>): A?
		return self.items[1]
	end,
	Back = function(self: MyDeque<A>): A?
		return self.items[#self.items]
	end,
}

local myCollectionImpl: stl.CollectionProvided<MyDeque<A>> = {
	Len = function(self: MyDeque<A>): number
		return #self.items
	end,
	Clear = function(self: MyDeque<A>): MyDeque<A>
		table.clear(self.items)
		return self
	end,
}

stl.Deque.ImplFor(MyDequeToken, myDequeImpl)
stl.Collection.ImplFor(MyDequeToken, myCollectionImpl)

local md = newMyDeque<<number>>()
stl.Deque.PushBack(md, 10)
stl.Deque.PushBack(md, 20)
local front = stl.Deque.Front(md)
local len = stl.Collection.Len(md)

-- Convert to Stack via Deque.AsStack
local s = stl.Deque.AsStack(md)
stl.Stack.Push(s, 30)
local top = stl.Stack.Pop(s)

print("External container test passed:", front, len, top)
