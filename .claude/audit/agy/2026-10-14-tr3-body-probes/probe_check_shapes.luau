--!strict
local Trait = require("../.claude/research/trait-v4/Trait")
type ItemIndex<E, I> = Trait.ItemIndex<E, I>
type AnyToken = Trait.AnyToken
type A = Trait.A
type B = Trait.B

const Fn, Default = Trait.Fn, Trait.Default

type ProbeA = { read __probeA: true }
type ProbeB = { read __probeB: true }
type ProbeC = { read __probeC: true }

-- Let's test a trait where builder has internal leak vs signature leak
const TraitInternal = Trait.Trait("Internal", function<Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken)
	return {
		FirstIndex = Fn<<(list: Self) -> I?>>(),

		-- Leak 1: Signature is pinned (item: string)
		PinnedSig = Default(function(ops: TraitInternal<Self, E, I>)
			return function(list: Self, item: string): I?
				return nil
			end
		end),

		-- Leak 2: Signature looks good, but internal body leaks (returns 123 into I?)
		BodyLeak = Default(function(ops: TraitInternal<Self, E, I>)
			return function(list: Self, item: E): I?
				return 123 -- internal leak!
			end
		end),
	}
end)
export type TraitInternal<Self, E, I> = typeof(TraitInternal.Of<<Self, E, I>>(nil :: any))

-- Approach 1: Top-level signature probe check on the trait
type ExpectedTrait<Self, E, I> = {
	FirstIndex: (list: Self) -> I?,
	PinnedSig: (list: Self, item: E) -> I?,
	BodyLeak: (list: Self, item: E) -> I?,
}

-- Does this catch Leak 1? Does this catch Leak 2?
local _checkTrait: ExpectedTrait<ProbeA, ProbeB, ProbeC> = nil :: TraitInternal<ProbeA, ProbeB, ProbeC>

local canary: string = 1
return { TraitInternal, canary }
