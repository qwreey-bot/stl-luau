--!strict
-- probes/mod_consumer.luau
-- mod_trait을 require하여 다시 내보내고(re-export), 제네릭 함수를 제공하는 모듈

local modTrait = require("./mod_trait")

export type Stack<Self, T> = modTrait.Stack<Self, T>
export type StackImpl<Self, T> = modTrait.StackImpl<Self, T>

local function checkEmpty<S, T>(ops: Stack<S, T>, s: S): boolean
	return ops.IsEmpty(s)
end

return {
	Stack = modTrait.Stack,
	checkEmpty = checkEmpty,
}
