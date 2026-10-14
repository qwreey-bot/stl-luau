--!strict
local Trait = require("./Trait")
type A = Trait.A
type B = Trait.B
local function d1<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T1F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T1F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T1F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T1F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T1F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T1F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T1 = Trait.Trait("T1", d1<<"full">>, d1<<"impl">>)
export type T1F<Self, E, I> = typeof(T1.Of<<Self, E, I>>(nil :: any))
export type T1I<Self, E, I> = typeof(T1.ImplOf<<Self, E, I>>(nil :: any))
const impl1_1: T1I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end, D2 = function(s: A, x: number): number return 1 end,}
const impl1_2: T1I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl1_3: T1I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl1_4: T1I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl1_5: T1I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl1_6: T1I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl1_7: T1I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl1_8: T1I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d2<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T2F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T2F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T2F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T2F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T2F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T2F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T2 = Trait.Trait("T2", d2<<"full">>, d2<<"impl">>)
export type T2F<Self, E, I> = typeof(T2.Of<<Self, E, I>>(nil :: any))
export type T2I<Self, E, I> = typeof(T2.ImplOf<<Self, E, I>>(nil :: any))
const impl2_1: T2I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl2_2: T2I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl2_3: T2I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl2_4: T2I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl2_5: T2I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl2_6: T2I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl2_7: T2I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl2_8: T2I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d3<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T3F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T3F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T3F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T3F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T3F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T3F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T3 = Trait.Trait("T3", d3<<"full">>, d3<<"impl">>)
export type T3F<Self, E, I> = typeof(T3.Of<<Self, E, I>>(nil :: any))
export type T3I<Self, E, I> = typeof(T3.ImplOf<<Self, E, I>>(nil :: any))
const impl3_1: T3I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl3_2: T3I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl3_3: T3I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl3_4: T3I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl3_5: T3I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl3_6: T3I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl3_7: T3I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl3_8: T3I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d4<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T4F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T4F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T4F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T4F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T4F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T4F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T4 = Trait.Trait("T4", d4<<"full">>, d4<<"impl">>)
export type T4F<Self, E, I> = typeof(T4.Of<<Self, E, I>>(nil :: any))
export type T4I<Self, E, I> = typeof(T4.ImplOf<<Self, E, I>>(nil :: any))
const impl4_1: T4I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl4_2: T4I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl4_3: T4I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl4_4: T4I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl4_5: T4I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl4_6: T4I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl4_7: T4I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl4_8: T4I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d5<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T5F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T5F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T5F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T5F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T5F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T5F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T5 = Trait.Trait("T5", d5<<"full">>, d5<<"impl">>)
export type T5F<Self, E, I> = typeof(T5.Of<<Self, E, I>>(nil :: any))
export type T5I<Self, E, I> = typeof(T5.ImplOf<<Self, E, I>>(nil :: any))
const impl5_1: T5I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl5_2: T5I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl5_3: T5I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl5_4: T5I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl5_5: T5I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl5_6: T5I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl5_7: T5I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl5_8: T5I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d6<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T6F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T6F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T6F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T6F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T6F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T6F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T6 = Trait.Trait("T6", d6<<"full">>, d6<<"impl">>)
export type T6F<Self, E, I> = typeof(T6.Of<<Self, E, I>>(nil :: any))
export type T6I<Self, E, I> = typeof(T6.ImplOf<<Self, E, I>>(nil :: any))
const impl6_1: T6I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl6_2: T6I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl6_3: T6I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl6_4: T6I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl6_5: T6I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl6_6: T6I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl6_7: T6I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl6_8: T6I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d7<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T7F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T7F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T7F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T7F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T7F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T7F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T7 = Trait.Trait("T7", d7<<"full">>, d7<<"impl">>)
export type T7F<Self, E, I> = typeof(T7.Of<<Self, E, I>>(nil :: any))
export type T7I<Self, E, I> = typeof(T7.ImplOf<<Self, E, I>>(nil :: any))
const impl7_1: T7I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl7_2: T7I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl7_3: T7I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl7_4: T7I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl7_5: T7I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl7_6: T7I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl7_7: T7I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl7_8: T7I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d8<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T8F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T8F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T8F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T8F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T8F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T8F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T8 = Trait.Trait("T8", d8<<"full">>, d8<<"impl">>)
export type T8F<Self, E, I> = typeof(T8.Of<<Self, E, I>>(nil :: any))
export type T8I<Self, E, I> = typeof(T8.ImplOf<<Self, E, I>>(nil :: any))
const impl8_1: T8I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl8_2: T8I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl8_3: T8I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl8_4: T8I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl8_5: T8I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl8_6: T8I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl8_7: T8I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl8_8: T8I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d9<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T9F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T9F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T9F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T9F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T9F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T9F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T9 = Trait.Trait("T9", d9<<"full">>, d9<<"impl">>)
export type T9F<Self, E, I> = typeof(T9.Of<<Self, E, I>>(nil :: any))
export type T9I<Self, E, I> = typeof(T9.ImplOf<<Self, E, I>>(nil :: any))
const impl9_1: T9I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl9_2: T9I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl9_3: T9I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl9_4: T9I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl9_5: T9I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl9_6: T9I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl9_7: T9I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl9_8: T9I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d10<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T10F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T10F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T10F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T10F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T10F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T10F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T10 = Trait.Trait("T10", d10<<"full">>, d10<<"impl">>)
export type T10F<Self, E, I> = typeof(T10.Of<<Self, E, I>>(nil :: any))
export type T10I<Self, E, I> = typeof(T10.ImplOf<<Self, E, I>>(nil :: any))
const impl10_1: T10I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl10_2: T10I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl10_3: T10I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl10_4: T10I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl10_5: T10I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl10_6: T10I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl10_7: T10I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl10_8: T10I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d11<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T11F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T11F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T11F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T11F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T11F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T11F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T11 = Trait.Trait("T11", d11<<"full">>, d11<<"impl">>)
export type T11F<Self, E, I> = typeof(T11.Of<<Self, E, I>>(nil :: any))
export type T11I<Self, E, I> = typeof(T11.ImplOf<<Self, E, I>>(nil :: any))
const impl11_1: T11I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl11_2: T11I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl11_3: T11I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl11_4: T11I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl11_5: T11I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl11_6: T11I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl11_7: T11I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl11_8: T11I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d12<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T12F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T12F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T12F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T12F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T12F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T12F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T12 = Trait.Trait("T12", d12<<"full">>, d12<<"impl">>)
export type T12F<Self, E, I> = typeof(T12.Of<<Self, E, I>>(nil :: any))
export type T12I<Self, E, I> = typeof(T12.ImplOf<<Self, E, I>>(nil :: any))
const impl12_1: T12I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl12_2: T12I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl12_3: T12I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl12_4: T12I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl12_5: T12I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl12_6: T12I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl12_7: T12I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl12_8: T12I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d13<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T13F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T13F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T13F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T13F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T13F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T13F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T13 = Trait.Trait("T13", d13<<"full">>, d13<<"impl">>)
export type T13F<Self, E, I> = typeof(T13.Of<<Self, E, I>>(nil :: any))
export type T13I<Self, E, I> = typeof(T13.ImplOf<<Self, E, I>>(nil :: any))
const impl13_1: T13I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl13_2: T13I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl13_3: T13I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl13_4: T13I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl13_5: T13I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl13_6: T13I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl13_7: T13I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl13_8: T13I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d14<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T14F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T14F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T14F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T14F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T14F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T14F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T14 = Trait.Trait("T14", d14<<"full">>, d14<<"impl">>)
export type T14F<Self, E, I> = typeof(T14.Of<<Self, E, I>>(nil :: any))
export type T14I<Self, E, I> = typeof(T14.ImplOf<<Self, E, I>>(nil :: any))
const impl14_1: T14I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl14_2: T14I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl14_3: T14I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl14_4: T14I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl14_5: T14I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl14_6: T14I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl14_7: T14I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl14_8: T14I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d15<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T15F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T15F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T15F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T15F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T15F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T15F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T15 = Trait.Trait("T15", d15<<"full">>, d15<<"impl">>)
export type T15F<Self, E, I> = typeof(T15.Of<<Self, E, I>>(nil :: any))
export type T15I<Self, E, I> = typeof(T15.ImplOf<<Self, E, I>>(nil :: any))
const impl15_1: T15I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl15_2: T15I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl15_3: T15I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl15_4: T15I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl15_5: T15I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl15_6: T15I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl15_7: T15I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl15_8: T15I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d16<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T16F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T16F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T16F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T16F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T16F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T16F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T16 = Trait.Trait("T16", d16<<"full">>, d16<<"impl">>)
export type T16F<Self, E, I> = typeof(T16.Of<<Self, E, I>>(nil :: any))
export type T16I<Self, E, I> = typeof(T16.ImplOf<<Self, E, I>>(nil :: any))
const impl16_1: T16I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl16_2: T16I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl16_3: T16I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl16_4: T16I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl16_5: T16I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl16_6: T16I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl16_7: T16I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl16_8: T16I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d17<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T17F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T17F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T17F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T17F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T17F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T17F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T17 = Trait.Trait("T17", d17<<"full">>, d17<<"impl">>)
export type T17F<Self, E, I> = typeof(T17.Of<<Self, E, I>>(nil :: any))
export type T17I<Self, E, I> = typeof(T17.ImplOf<<Self, E, I>>(nil :: any))
const impl17_1: T17I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl17_2: T17I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl17_3: T17I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl17_4: T17I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl17_5: T17I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl17_6: T17I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl17_7: T17I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl17_8: T17I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d18<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T18F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T18F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T18F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T18F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T18F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T18F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T18 = Trait.Trait("T18", d18<<"full">>, d18<<"impl">>)
export type T18F<Self, E, I> = typeof(T18.Of<<Self, E, I>>(nil :: any))
export type T18I<Self, E, I> = typeof(T18.ImplOf<<Self, E, I>>(nil :: any))
const impl18_1: T18I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl18_2: T18I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl18_3: T18I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl18_4: T18I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl18_5: T18I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl18_6: T18I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl18_7: T18I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl18_8: T18I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d19<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T19F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T19F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T19F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T19F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T19F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T19F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T19 = Trait.Trait("T19", d19<<"full">>, d19<<"impl">>)
export type T19F<Self, E, I> = typeof(T19.Of<<Self, E, I>>(nil :: any))
export type T19I<Self, E, I> = typeof(T19.ImplOf<<Self, E, I>>(nil :: any))
const impl19_1: T19I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl19_2: T19I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl19_3: T19I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl19_4: T19I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl19_5: T19I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl19_6: T19I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl19_7: T19I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl19_8: T19I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local function d20<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
 return {
  R1 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R2 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R3 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R4 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R5 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  R6 = Trait.Fn<<(s: Self, i: I) -> E?>>(),
  D1 = Trait.Default(mode, function(ops: T20F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D2 = Trait.Default(mode, function(ops: T20F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D3 = Trait.Default(mode, function(ops: T20F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D4 = Trait.Default(mode, function(ops: T20F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D5 = Trait.Default(mode, function(ops: T20F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
  D6 = Trait.Default(mode, function(ops: T20F<Self, E, I>) const g = ops.R1; const r2 = ops.R2; return function(s: Self, x: E): I? local k = r2(s, 1 :: any) :: any; if g(s, k) == x then return k end; return nil end end),
 }
end end
const T20 = Trait.Trait("T20", d20<<"full">>, d20<<"impl">>)
export type T20F<Self, E, I> = typeof(T20.Of<<Self, E, I>>(nil :: any))
export type T20I<Self, E, I> = typeof(T20.ImplOf<<Self, E, I>>(nil :: any))
const impl20_1: T20I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl20_2: T20I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl20_3: T20I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl20_4: T20I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl20_5: T20I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl20_6: T20I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl20_7: T20I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
const impl20_8: T20I<A, B, number> = { R1 = function(s: A, i: number): B? return nil end, R2 = function(s: A, i: number): B? return nil end, R3 = function(s: A, i: number): B? return nil end, R4 = function(s: A, i: number): B? return nil end, R5 = function(s: A, i: number): B? return nil end, R6 = function(s: A, i: number): B? return nil end,}
local canary: string = 1
return canary