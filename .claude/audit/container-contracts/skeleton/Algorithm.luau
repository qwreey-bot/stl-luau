--!strict
--[[
	Algorithm — 계약만 알고 구현은 모르는 공용 알고리즘.

	여기 있는 것들은 소스에 **한 번만** 존재하고 배열/연결/트리 구현이
	전부 공짜로 씁니다. Types 만 require 합니다(말단 바로 위 층).
]]
local Types = require("./Types")

type ListCore<E, I> = Types.ListCore<E, I>
type MapCore<K, V> = Types.MapCore<K, V>

local exports = {}

function exports.IndexOf<E, I>(list: ListCore<E, I>, item: E): I?
	local idx = list:FirstIndex()
	while idx ~= nil do
		if list:Get(idx) == item then
			return idx
		end
		idx = list:NextIndex(idx)
	end
	return nil
end

function exports.Count<E, I>(list: ListCore<E, I>): number
	local total, idx = 0, list:FirstIndex()
	while idx ~= nil do
		total += 1
		idx = list:NextIndex(idx)
	end
	return total
end

function exports.Keys<K, V>(map: MapCore<K, V>): { K }
	local records = map:Records()
	local out: { K } = table.create(#records)
	for i, rec in records do
		out[i] = rec.key
	end
	return out
end

return exports
