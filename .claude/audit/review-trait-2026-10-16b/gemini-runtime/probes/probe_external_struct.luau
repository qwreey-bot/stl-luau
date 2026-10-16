local Trait = require("../src/Trait")
local stl = require("../src")
local Stack = stl.Stack

-- External user defines a new kind using Trait.Struct
local MyKind = Trait.Struct("MyLib.MyStack")

local MyModule = {}
function MyModule.New()
	return { items = {}, __type = MyKind.Token }
end

MyKind.Seal(MyModule)

print("MyModule sealed!")
print("Trait.TokenOf(MyModule) == MyKind.Token:", Trait.TokenOf(MyModule) == MyKind.Token)

-- Implement Stack for MyModule
Stack.ImplFor(MyModule, {
	Push = function(self, item)
		table.insert(self.items, item)
		return self
	end,
	Pop = function(self)
		return table.remove(self.items)
	end,
	Peek = function(self)
		return self.items[#self.items]
	end,
})

print("Stack.ImplFor succeeded!")

local s_val = MyModule.New()
print("Trait.Implements(Stack, s_val):", Trait.Implements(Stack, s_val))

local s_ops = Stack.OfMut(s_val)
s_ops.Push(s_val, 100)
s_ops.Push(s_val, 200)
print("Peek:", s_ops.Peek(s_val))
print("Pop:", s_ops.Pop(s_val))
print("Pop:", s_ops.Pop(s_val))

-- Test Converter with MyModule
local toStack = Trait.Converter(Stack, MyModule)
local converted = toStack(s_val)
print("converted == s_val:", converted == s_val)

-- Test Converter to MyModule
local toMyKind = Trait.Converter(MyModule)
local converted2 = toMyKind(s_val)
print("toMyKind == s_val:", converted2 == s_val)
