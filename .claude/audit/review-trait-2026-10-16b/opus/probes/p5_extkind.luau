--!strict
local stl = require("../src")
local Trait = stl.Trait
type A = stl.TraitToken<any>
const Kind = Trait.Struct("P5.Bag")
local tokOk: stl.TraitToken<"P5.Bag"> = Kind.Token
local tokBad: stl.TraitToken<"P5.Other"> = Kind.Token -- 기대: 에러(이름 싱글턴)
export type Bag<T> = {
	read __type: stl.TraitToken<"P5.Bag">,
	read __traits: { read Stack: stl.StackAssoc<T> },
	items: { T },
}
local function New<T>(): Bag<T>
	return { __type = Kind.Token, items = {} } :: any
end
local function Push<T>(b: Bag<T>, x: T): Bag<T>
	table.insert(b.items, x)
	return b
end
local function Pop<T>(b: Bag<T>): T?
	return table.remove(b.items)
end
local function Peek<T>(b: Bag<T>): T?
	return b.items[#b.items]
end
const BagModule = Kind.Seal({ New = New, Push = Push, Pop = Pop, Peek = Peek })
type PA = stl.TraitToken<"P5.ProbeA">
const stackImpl: stl.StackProvided<Bag<Trait.A>, Trait.A> = { Push = BagModule.Push, Pop = BagModule.Pop, Peek = BagModule.Peek }
stl.Stack.ImplFor(BagModule, stackImpl)
local b = BagModule.New<<number>>()
stl.Stack.Push(b, 1) -- 정의 자리에서 __traits.Stack 을 적었으니 됨
stl.Stack.Push(b, "x") -- 기대: 에러
local n: number? = stl.Stack.Pop(b)
-- 바깥 종류 이름의 위조: 같은 모양의 다른 종류 토큰
const Kind2 = Trait.Struct("P5.Bag2")
local fake: Bag<number> = { __type = Kind2.Token, items = {} } :: any -- 캐스트라 통과(참고)
local canary: string = 1
return nil
