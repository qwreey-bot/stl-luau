--!strict
local LM = require("./p11_ListModB")
const List = LM.List
export type MyArr<T> = { items: { T }, read __generics: { read Item: (T) -> T }, read __readGenerics: { read Item: () -> T, read Index: () -> number } }
local m: MyArr<number> = nil :: any
const has: boolean = List.Of(m).Contains(m, 1)
const NEG_has: string = List.Of(m).Contains(m, 1) -- NEG
const NEG_arg = List.Of(m).Contains(m, "x") -- NEG
local canary: string = 1
return { has, NEG_has, NEG_arg, canary }
