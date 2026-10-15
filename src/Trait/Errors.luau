--!strict
--[[ Errors — 트레이트 시스템의 에러 메시지를 한곳에. 전부 `Common.raise`(사용자 줄 — 에러 규약). ]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Registry = require("./Registry")
const raise = Common.raise

const Errors = {}

function Errors.tokenName(name: any): never
	return raise(`Trait: NewToken needs a name string, got {typeof(name)}`)
end
function Errors.tokenTaken(name: string): never
	return raise(
		`Trait: a token named {name} already exists — token names are unique (namespace yours, like "MyLib.{name}")`
	)
end
function Errors.notToken(who: string, value: any): never
	return raise(`Trait: {who} needs a type token (from Trait.NewToken), got {typeof(value)}`)
end
function Errors.notTrait(who: string, value: any): never
	return raise(`Trait: {who} needs a trait (from Trait.Trait), got {typeof(value)}`)
end
function Errors.traitName(name: any): never
	return raise(`Trait: Trait needs a name string, got {typeof(name)}`)
end
function Errors.badFns(name: string): never
	return raise(
		`Trait: {name} needs a definition function returning a table of Trait.Fn / Trait.Default (Trait.Trait(name, function(of) return table.freeze(...) end))`
	)
end
-- 표를 준 쪽: 명시 구현이면 그 종류, 뭉텅이 구현이면 그 뭉텅이(종류 탓을 하지 않게 — 리뷰 1라운드 참고 11).
local function giver(trait: string, token: string, blanket: boolean?): string
	return if blanket then `a blanket implementation of {trait} (ImplWhere) for {token}` else token
end
function Errors.unknownName(trait: string, token: string, fnName: any, blanket: boolean?): never
	return raise(
		`Trait: {giver(trait, token, blanket)} gave {tostring(fnName)} to {trait}, which {trait} does not have — pass a table of only that trait's functions (not a whole module)`
	)
end
function Errors.notFunction(trait: string, token: string, fnName: any, value: any, blanket: boolean?): never
	return raise(
		`Trait: {giver(trait, token, blanket)} gave a {typeof(value)} as {tostring(fnName)} for {trait} — it must be a function`
	)
end
function Errors.implNotTable(trait: string, value: any): never
	return raise(`Trait: {trait}.ImplFor needs a table of functions, got {typeof(value)}`)
end
function Errors.missing(trait: string, token: string, fnName: string, blanket: boolean?): never
	return raise(`Trait: {giver(trait, token, blanket)} is missing {fnName} for {trait}`)
end
function Errors.already(trait: string, token: string): never
	return raise(`Trait: {token} already implements {trait}`)
end
function Errors.overlap(trait: string, token: string): never
	return raise(
		`Trait: two blanket implementations of {trait} apply to {token} — implement {trait} for {token} directly ({trait}.ImplFor) or narrow an ImplWhere`
	)
end
function Errors.builderNotFunction(trait: string, got: any): never
	return raise(`Trait: {trait}.ImplWhere needs a function that builds the implementation, got {typeof(got)}`)
end
function Errors.builderNotTable(trait: string, got: any): never
	return raise(`Trait: the builder given to {trait}.ImplWhere must return a table, got {typeof(got)}`)
end
function Errors.emptyWhere(trait: string): never
	return raise(
		`Trait: {trait}.ImplWhere needs a list of traits (a misspelled trait name reads as nil) — use {"{}"} for every kind`
	)
end
function Errors.whereCycle(trait: string, dep: string): never
	if trait == dep then
		return raise(`Trait: {trait}.ImplWhere cannot depend on {trait} itself`)
	end
	return raise(
		`Trait: {trait}.ImplWhere on {dep} makes a cycle — {dep} already comes from {trait} through blanket implementations`
	)
end
function Errors.notImplemented(trait: string, token: any): never
	const name = if type(token) == "table" then rawget(token :: any, "name") else nil
	return raise(`{trait}: {tostring(name or typeof(token))} does not implement {trait}`)
end
function Errors.reserved(trait: string, fnName: string): never
	return raise(`Trait: {trait} cannot have a function named {fnName} — the trait object uses that name`)
end
function Errors.exposeTaken(trait: string, entryName: any): never
	return raise(`Trait: Expose got an entry named {tostring(entryName)}, which {trait} already has`)
end
function Errors.exposeNotTable(got: any): never
	return raise(`Trait: Expose needs a table of entry functions, got {typeof(got)}`)
end
function Errors.stampBad(got: any): never
	return raise(`Trait: Stamp needs a table that is not frozen, got {typeof(got)}`)
end
function Errors.defaultNotFunction(trait: string, fnName: string, got: any): never
	return raise(`Trait: the default implementation of {fnName} in {trait} must build a function, got {typeof(got)}`)
end
function Errors.defaultCycle(trait: string, fnName: string): never
	return raise(
		`Trait: default implementations of {trait} need each other while building ({fnName}) — read a sibling when called, not when built`
	)
end
-- 값에서 구현을 못 찾았을 때(진입점·`Of`·`ExpectImpl`). 셋으로 가릅니다: 이 사본의 토큰인데 구현이 없음 / 이름 있는 토큰
-- 모양이지만 이 사본의 토큰이 아님(직렬화했다 되읽음, 다른 사본의 라이브러리) / 토큰 없음.
function Errors.entryMiss(trait: string, who: string, value: any): never
	if type(value) == "table" then
		const raw = rawget(value, "__type")
		const rawName = if type(raw) == "table" then rawget(raw :: any, "name") else nil
		if type(rawName) == "string" then
			if Registry.isToken[raw] then
				return raise(`{trait}: {who} needs a {trait} — {rawName} does not implement {trait}`)
			end
			return raise(
				`{trait}: {who} needs a {trait} — got a {rawName} this library does not know (deserialized? Trait.Restore it — or from another copy of the library)`
			)
		end
	end
	return raise(`{trait}: {who} needs a {trait} (got {typeof(value)} without a type token)`)
end

return Errors
