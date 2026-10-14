--!strict
--[[ Errors — 시스템의 에러 메시지를 한곳에. 전부 `Common.raise`(사용자 줄). ]]
local Common = require("../../../../src/Common")
Common.registerSource(debug.info(1, "s"))
local Registry = require("./Registry")
const raise = Common.raise

const Errors = {}

function Errors.tokenName(name: any): never
	return raise(`Trait: Token needs a name string, got {typeof(name)}`)
end
function Errors.tokenTaken(name: string): never
	return raise(
		`Trait: a token named {name} already exists — names are unique (namespace yours, like "MyLib.{name}")`
	)
end
function Errors.notToken(who: string, value: any): never
	return raise(`Trait: {who} needs a token (from Trait.Token), got {typeof(value)}`)
end
function Errors.notTrait(who: string, value: any): never
	return raise(`Trait: {who} needs a trait (from Trait.Trait), got {typeof(value)}`)
end
function Errors.badFns(name: string): never
	return raise(`Trait: {name} needs a table of functions made with Trait.Fn`)
end
function Errors.defaultsNotTable(name: string, got: any): never
	return raise(`Trait: defaults of {name} must return a table of functions, got {typeof(got)}`)
end
function Errors.defaultsUnknown(name: string, fnName: any): never
	return raise(`Trait: defaults of {name} gave {tostring(fnName)}, which {name} does not declare with Trait.Default`)
end
function Errors.defaultMissing(name: string, fnName: string): never
	return raise(`Trait: {name} declares {fnName} with Trait.Default but its defaults do not provide it`)
end
function Errors.unknownName(trait: string, token: string, fnName: any): never
	return raise(`Trait: {token} gave {tostring(fnName)} to {trait}, which {trait} does not have`)
end
function Errors.notFunction(trait: string, token: string, fnName: any, value: any): never
	return raise(`Trait: {token} gave a {typeof(value)} as {tostring(fnName)} for {trait} — it must be a function`)
end
function Errors.missing(trait: string, token: string, fnName: string): never
	return raise(`Trait: {token} is missing {fnName} for {trait}`)
end
function Errors.already(trait: string, token: string): never
	return raise(`Trait: {token} already implements {trait}`)
end
function Errors.overlap(trait: string, token: string): never
	return raise(
		`Trait: two blanket implementations of {trait} apply to {token} — implement {trait} for {token} directly ({trait}.ImplFor) or narrow an ImplWhere`
	)
end
function Errors.builderNotTable(trait: string, got: any): never
	return raise(`Trait: the builder given to {trait}.ImplWhere must return a table, got {typeof(got)}`)
end
function Errors.emptyWhere(trait: string): never
	return raise(`Trait: {trait}.ImplWhere needs a list of traits`)
end
function Errors.notImplemented(trait: string, token: any): never
	const name = if type(token) == "table" then rawget(token :: any, "name") else nil
	return raise(`{trait}: {tostring(name or typeof(token))} does not implement {trait}`)
end
function Errors.reserved(trait: string, fnName: string): never
	return raise(`Trait: {trait} cannot have a function named {fnName} — the trait object uses that name`)
end
function Errors.inheritRequired(trait: string, token: string, fnName: string): never
	return raise(
		`Trait: {token} gave Trait.Inherit as {fnName} for {trait}, but {fnName} has no default implementation`
	)
end
function Errors.defaultNotFunction(trait: string, fnName: string, got: any): never
	return raise(`Trait: the default implementation of {fnName} in {trait} must build a function, got {typeof(got)}`)
end
function Errors.defaultCycle(trait: string, fnName: string): never
	return raise(
		`Trait: default implementations of {trait} need each other while building ({fnName}) — read a sibling when called, not when built`
	)
end
function Errors.entryMiss(trait: string, fnName: string, value: any): never
	if type(value) == "table" then
		const raw = rawget(value, "__type")
		const rawName = if type(raw) == "table" then rawget(raw :: any, "name") else nil
		if type(rawName) == "string" then
			-- 진짜 토큰이면 구현이 없는 것, 이름만 같은 사본(직렬화 뒤)이면 되찾으라고 — 둘을 가름(v4 는 늘 둘 다 적어 오해를 부름)
			if Registry.isToken[raw] then
				return raise(`{trait}: {fnName} needs a {trait} — {rawName} does not implement {trait}`)
			end
			return raise(
				`{trait}: {fnName} needs a {trait} — the value's type token {rawName} is a copy (serialized?): Trait.Restore it`
			)
		end
	end
	return raise(`{trait}: {fnName} needs a {trait} (got {typeof(value)} without a type token)`)
end

return Errors
