--!strict
type function Show(t)
	local ix = t:indexer()
	local ri = t:readindexer()
	local wi = t:writeindexer()
	print("indexer", ix and ix.index and ix.index.tag, ix and ix.readresult and ix.readresult.tag, ix and ix.writeresult and ix.writeresult.tag)
	print("readindexer", ri and ri.index and ri.index.tag, ri and ri.result and ri.result.tag)
	print("writeindexer", wi and wi.index and wi.index.tag, wi and wi.result and wi.result.tag)
	return t
end
type A = Show<{ read [string]: number }>
type B = Show<{ [string]: number }>
local x: A = nil :: any
local y: B = nil :: any
return { x, y }
