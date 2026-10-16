--!strict
local HasAll: (keys: { read [number]: boolean }) -> boolean = nil :: any
local h = HasAll({ s = true }) -- NEG
return h
