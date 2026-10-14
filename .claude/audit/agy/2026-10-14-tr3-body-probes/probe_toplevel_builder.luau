--!strict
local Trait = require("../.claude/research/trait-v4/Trait")
type ItemIndex<E, I> = Trait.ItemIndex<E, I>
type AnyToken = Trait.AnyToken
type A = Trait.A
type B = Trait.B

type ProbeSelf = { read __probeSelf: true }
type ProbeE = { read __probeE: true }
type ProbeI = { read __probeI: true }

-- Probe implementation of DefaultSig
local DEFAULT_MARK = table.freeze({})
local function DefaultSig<Sig, Builder>(builder: Builder): Sig
	return table.freeze({ [DEFAULT_MARK] = builder }) :: any
end

-- Top-level builder using probe types!
type ProbeList = {
	Get: (list: ProbeSelf, idx: ProbeI) -> ProbeE?,
	FirstIndex: (list: ProbeSelf) -> ProbeI?,
	NextIndex: (list: ProbeSelf, idx: ProbeI) -> ProbeI?,
	IndexOf: (list: ProbeSelf, item: ProbeE) -> ProbeI?,
}

-- Good builder
local function buildIndexOf(ops: ProbeList): (list: ProbeSelf, item: ProbeE) -> ProbeI?
	const get, firstIndex, nextIndex = ops.Get, ops.FirstIndex, ops.NextIndex
	return function(list: ProbeSelf, item: ProbeE): ProbeI?
		local idx = firstIndex(list)
		while idx ~= nil do
			if get(list, idx) == item then
				return idx
			end
			idx = nextIndex(list, idx)
		end
		return nil
	end
end

-- Bad builder 1: element pinned to string
local function badBuild_pinnedElem(ops: ProbeList): (list: ProbeSelf, item: ProbeE) -> ProbeI?
	const get, firstIndex, nextIndex = ops.Get, ops.FirstIndex, ops.NextIndex
	return function(list: ProbeSelf, item: string): ProbeI? -- NEG: string vs ProbeE
		return nil
	end
end

-- Bad builder 2: return type pinned to number
local function badBuild_pinnedReturn(ops: ProbeList): (list: ProbeSelf, item: ProbeE) -> ProbeI?
	const firstIndex = ops.FirstIndex
	return function(list: ProbeSelf, item: ProbeE): number? -- NEG: number? vs ProbeI?
		return 123
	end
end

-- Bad builder 3: returning literal number into ProbeI?
local function badBuild_literalReturn(ops: ProbeList): (list: ProbeSelf, item: ProbeE) -> ProbeI?
	return function(list: ProbeSelf, item: ProbeE): ProbeI?
		return 123 -- NEG: 123 vs ProbeI?
	end
end

-- Bad builder 4: sibling with wrong return type
local function badBuild_wrongSibling(ops: ProbeList): (list: ProbeSelf, item: ProbeE) -> ProbeI?
	const get = ops.Get
	return function(list: ProbeSelf, item: ProbeE): ProbeI?
		return get(list, item) -- NEG: item (ProbeE) passed to idx (ProbeI)
	end
end

local canary: string = 1
return {
	buildIndexOf,
	badBuild_pinnedElem,
	badBuild_pinnedReturn,
	badBuild_literalReturn,
	badBuild_wrongSibling,
	canary,
}
