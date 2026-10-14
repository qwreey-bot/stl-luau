--!strict
local function mk<M>(mode: M): index<{ full: () -> boolean, impl: (() -> boolean)? }, M>
	return nil :: any
end
local function take<F>(def: (mode: "full") -> F): F
	return nil :: any
end
const f = take(mk)
local SHOW: number = f
const s: string = f() -- 기대: 에러
const n: number = f() -- 기대: 에러
const t: { x: string } = f() -- 기대: 에러
return { s, n, t }
