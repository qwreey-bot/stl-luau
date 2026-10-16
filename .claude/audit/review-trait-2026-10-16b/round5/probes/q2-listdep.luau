--!strict
-- 라이브러리 트레이트(List)를 조건으로 하는 사용자 트레이트 + ImplWhere — 인덱서 칸 여럿
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
local Ext
do
	Ext = Trait.Trait("Q2.Ext", function<Self, E, I>(of: (Self & stl.ListRead<E, I>) | AnyToken, ofMut: (Self & stl.List<E, I>) | AnyToken)
		return table.freeze({
			ContainsAll = Trait.Fn<<(list: Self, items: { read [number]: E }) -> boolean>>(),
			Positions = Trait.Fn<<(list: Self, items: { read [number]: E }) -> { read [number]: I? }>>(),
			PickAt = Trait.Fn<<(list: Self, idx: { read [number]: I }) -> { read [number]: E? }>>(),
			FirstOf = Trait.Fn<<(list: Self, items: { read [number]: E }) -> E?>>(),
			At = Trait.Fn<<(list: Self, i: I) -> E?>>(),
			SetMany = Trait.FnMut<<(list: Self, at: { read [number]: I }, v: E) -> ()>>(),
			SetFrom = Trait.FnMut<<(list: Self, src: { read [I]: E }) -> ()>>(),
			Fill = Trait.DefaultMut(function(_ops: any): (list: Self, src: { read [number]: E }) -> Self
				return function(list: Self, _src: { read [number]: E }): Self
					return list
				end
			end),
		})
	end)
	Ext.ImplWhere({ stl.List }, function(_deps: any)
		local function noop(...: any): any return (...) end
		return {
			ContainsAll = function(_l: any, _i: any) return true end,
			Positions = function(_l: any, _i: any) return {} end,
			PickAt = function(_l: any, _i: any) return {} end,
			FirstOf = function(l: any, _i: any) return l[1] end,
			At = function(l: any, i: any) return l[i] end,
			SetMany = noop,
			SetFrom = noop,
		}
	end)
end
local arr = stl.Arr.Of(10, 20)
local arrS = stl.Arr.Of("a")
local cd = stl.CircularDeque.FromList({ 1, 2 })
local ca1: boolean = Ext.ContainsAll(arr, { 10 }) -- POS
local ca2: boolean = Ext.ContainsAll(arr, arr) -- POS
local ca3: boolean = Ext.ContainsAll(cd, { 1 }) -- POS
local p1 = Ext.Positions(arr, { 10 }) -- POS
local p2: number? = p1[1] -- POS
local p3: string? = p1[1] -- NEG
local k1 = Ext.PickAt(arr, { 1 }) -- POS
local k2: number? = k1[1] -- POS
local k3: string? = k1[1] -- NEG
Ext.PickAt(arr, { "x" }) -- NEG (위치 타입) — 읽기 조건이라 넓어질 수 있음
local f1: number? = Ext.FirstOf(arr, { 10 }) -- POS
local f2: string? = Ext.FirstOf(arr, { 10 }) -- NEG
local a1: number? = Ext.At(arr, 1) -- POS
local a2: string? = Ext.At(arr, 1) -- NEG
Ext.SetMany(arr, { 1 }, 5) -- POS
Ext.SetMany(arr, { 1 }, "s") -- NEG
Ext.SetMany(arr, { "x" }, 5) -- NEG
Ext.SetFrom(arr, { [1] = 5 }) -- POS
Ext.SetFrom(arr, { [1] = "s" }) -- NEG
local fl: stl.Arr<number> = Ext.Fill(arr, { 1 }) -- POS
Ext.Fill(arr, arr) -- BND? (-> Self 맨 반환이면 다시 지음)
Ext.Fill(arr, { "s" }) -- NEG
local hm = stl.HashMap.New<<string, number>>()
Ext.ContainsAll(hm, { 1 }) -- NEG (리스트 아님)
print(ca1, ca2, ca3, f1, a1, Ext.FirstOf(cd, { 1 }))
return { p2, p3, k2, k3, f2, a2, fl, arrS }
