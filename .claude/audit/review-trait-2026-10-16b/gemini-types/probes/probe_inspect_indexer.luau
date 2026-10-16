--!strict
export type function InspectIndexer(t)
	local idx = t:indexer()
	if idx == nil then
		error("no indexer")
	end
	error("readresult=" .. tostring(idx.readresult) .. ", writeresult=" .. tostring(idx.writeresult))
end

type TRead = InspectIndexer<{ read [string]: number }>
