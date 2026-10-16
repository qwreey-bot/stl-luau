--!strict
export type function DiffIndexers(readT, rwT)
	local rIdx = readT:indexer()
	local wIdx = rwT:indexer()
	
	local rKeys, wKeys = {}, {}
	for k, v in rIdx do
		rKeys[k] = tostring(v)
	end
	for k, v in wIdx do
		wKeys[k] = tostring(v)
	end
	
	error("readIdx: " .. rKeys.index .. "->" .. rKeys.readresult .. "/" .. tostring(rKeys.writeresult) ..
	      " vs rwIdx: " .. wKeys.index .. "->" .. wKeys.readresult .. "/" .. tostring(wKeys.writeresult))
end

type Diff = DiffIndexers<{ read [string]: number }, { [string]: number }>
