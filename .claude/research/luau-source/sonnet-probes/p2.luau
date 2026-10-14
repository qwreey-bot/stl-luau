--!strict
local function a<V>(v: V): number return v end  -- body
local function b<V>(v: V): string return v end
local function c<V>(v: V) local x: number = v return x end
local function d<V>(v: V) return v + 1 end
local function e<V>(v: V, w: number) local x: V = w return x end
print(a, b, c, d, e)
