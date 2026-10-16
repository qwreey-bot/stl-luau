--!strict
type function RO(t)
	local idx = t:indexer()
	local out = types.newtable()
	out:setindexer(idx.index, idx.readresult)
	return out
end
type function RONever(t)
	local idx = t:indexer()
	return types.newtable({}, { index = idx.index, readresult = idx.readresult, writeresult = types.never })
end
type Src = { read [string]: number }
local a: RO<Src> = nil :: any
a.x = 1 -- 쓰기(RO 는 읽기·쓰기라 통과)
local b: RONever<Src> = nil :: any
b.x = 1 -- 기대: 에러
local v: number = b.y -- 읽기는 됨
local w: RONever<Src> = ({} :: { read [string]: number }) -- 읽기 전용 표를 받는가
local canary: string = 1
return { v, w }
