--!strict
local TE = require("./TraitE2")
local Trait = require("./trait-v8/Trait")
const Fn = Trait.Fn
type Item<T> = Trait.Item<T>
type AnyToken = Trait.AnyToken
const Stack = TE.Trait("StackRun", function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return { Push = Fn<<(s: Self, v: T) -> Self>>(), Pop = Fn<<(s: Self) -> T?>>() }
end)
const T = Trait.Token("My.Arr")
Stack.ImplFor(T, { Push = function(s: any, v: any) table.insert(s.items, v) return s end, Pop = function(s: any) return table.remove(s.items) end })
const v: any = { items = {}, __type = T }
Stack.Push(v, 5)
print("D runtime pop:", Stack.Of(v).Pop(v))
