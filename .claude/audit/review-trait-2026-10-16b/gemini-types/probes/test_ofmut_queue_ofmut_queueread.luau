--!strict

local stl = require("../src")
local cd = stl.CircularDeque.Of(1, 2)
local r: stl.CircularDequeRead<number> = cd
local asQueue: <T>(d: stl.CircularDequeRead<T>) -> stl.QueueRead<T> = stl.Deque.AsQueueRead
local q = asQueue(r)
local m = stl.Queue.OfMut(q)
