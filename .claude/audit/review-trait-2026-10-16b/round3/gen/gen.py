# 프로브 생성기: 칸 모양마다 파일 하나. 각 줄 끝 주석 -- POS / -- NEG / -- BND
import os, sys
OUT = sys.argv[1]
HEAD = '''--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = {{ read Item: () -> T }}
type Assoc<T> = {{ read Item: () -> T, read Mut: (T) -> T }}
type ValueRead<T> = {{ read __type: stl.TraitToken<any>, read __traits: {{ read {R}: AssocRead<T> }} }}
type Value<T> = {{ read __type: stl.TraitToken<any>, read __traits: {{ read {R}: Assoc<T> }} }}
local Bag
do
	Bag = Trait.Trait("{R}", function<Self, T>({PARAMS})
		return table.freeze({{
			ToList = Trait.Fn<<(bag: Self) -> {{ read [number]: T }}>>(), -- 다른 인덱서 칸(유지되는 칸)
{SLOTS}
		}})
	end)
end
type MyBag<T> = {{ read __type: stl.TraitToken<"{R}x">, read __traits: {{ read {R}: Assoc<T> }} }}
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
'''
TWO = "of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken"
ONE = "of: (Self & Value<T>) | AnyToken"
cases = {
 # 콜백 인자 안의 T
 "cb": (["Each = Trait.Fn<<(bag: Self, fn: (T) -> (), pool: { read [number]: T }) -> ()>>(),"],
   ["Bag.Each(b, function(x: number) end, { 1 }) -- POS",
    "Bag.Each(b, function(x: number) end, arr) -- POS",
    "Bag.Each(b, function(x: string) end, { 1 }) -- NEG",
    "Bag.Each(b, function(x: number) end, { \"s\" }) -- NEG"]),
 # 인덱서 없는 표 필드의 T
 "field": (["Conf = Trait.Fn<<(bag: Self, opts: { read x: T, read list: { read [number]: T } }) -> ()>>(),"],
   ["Bag.Conf(b, { x = 1, list = { 2 } }) -- POS",
    "Bag.Conf(b, { x = 1, list = arr }) -- POS",
    "Bag.Conf(b, { x = \"s\", list = { 2 } }) -- NEG",
    "Bag.Conf(b, { x = 1, list = { \"s\" } }) -- NEG"]),
 # 가변 꼬리 ...T
 "tail": (["PushMany = Trait.FnMut<<(bag: Self, pool: { read [number]: T }, ...T) -> ()>>(),"],
   ["Bag.PushMany(b, { 1 }, 2, 3) -- POS",
    "Bag.PushMany(b, arr, 2) -- POS",
    "Bag.PushMany(b, { 1 }, \"s\") -- NEG",
    "Bag.PushMany(b, { \"s\" }, 2) -- NEG"]),
 # 반환에만 T (인자엔 Self 만)
 "ret": (["Pop2 = Trait.FnMut<<(bag: Self) -> (T?, { read [number]: T })>>(),"],
   ["local r1: number?, r2 = Bag.Pop2(b) -- POS",
    "local r3: string? = Bag.Pop2(b) -- NEG"]),
 # T? (유니온) — bareGeneric 이 잡음
 "opt": (["PushOpt = Trait.FnMut<<(bag: Self, x: T?, rest: { read [number]: T }) -> ()>>(),"],
   ["Bag.PushOpt(b, 1, { 2 }) -- POS",
    "Bag.PushOpt(b, nil, { 2 }) -- POS",
    "Bag.PushOpt(b, 1, arr) -- BND",
    "Bag.PushOpt(b, \"s\", { 2 }) -- NEG"]),
 # 둘째 Self
 "self2": (["Merge = Trait.FnMut<<(bag: Self, other: Self, pool: { read [number]: T }) -> ()>>(),"],
   ["Bag.Merge(b, b, { 1 }) -- POS",
    "Bag.Merge(b, b, arr) -- BND",
    "Bag.Merge(b, b, { \"s\" }) -- NEG"]),
 # 두 리스트 인자(맨 T 없음)
 "two": (["Zip = Trait.Fn<<(bag: Self, a: { read [number]: T }, c: { read [number]: T }) -> ()>>(),"],
   ["Bag.Zip(b, { 1 }, { 2 }) -- POS",
    "Bag.Zip(b, arr, arr) -- POS",
    "Bag.Zip(b, { 1 }, { \"s\" }) -- NEG"]),
 # 반환하는 함수 안의 T
 "retfn": (["Sink = Trait.Fn<<(bag: Self, pool: { read [number]: T }) -> (T) -> ()>>(),"],
   ["local s1 = Bag.Sink(b, { 1 }); s1(2) -- POS",
    "local s2 = Bag.Sink(b, { 1 }); s2(\"s\") -- NEG"]),
 # 콜백이 T 를 돌려줌
 "cbret": (["Fill = Trait.FnMut<<(bag: Self, gen: () -> T, pool: { read [number]: T }) -> ()>>(),"],
   ["Bag.Fill(b, function(): number return 1 end, { 1 }) -- POS",
    "Bag.Fill(b, function(): string return \"s\" end, { 1 }) -- NEG"]),
 # T 가 쓰기 가능 인덱서 { T } 안에만(맨 T 없음)
 "rwlist": (["Drain = Trait.FnMut<<(bag: Self, into: { T }) -> ()>>(),"],
   ["local into: { number } = {}; Bag.Drain(b, into) -- POS",
    "local into2: { string } = {}; Bag.Drain(b, into2) -- NEG"]),
 # 맵 인덱서 { [T]: boolean }
 "keyset": (["HasAll = Trait.Fn<<(bag: Self, keys: { read [T]: boolean }) -> boolean>>(),"],
   ["local h1: boolean = Bag.HasAll(b, { [1] = true }) -- POS",
    "local h2 = Bag.HasAll(b, { s = true }) -- NEG"]),
 # 교집합 T & {}
 "inter": (["PushI = Trait.FnMut<<(bag: Self, x: T & {}, rest: { read [number]: T }) -> ()>>(),"],
   []),
 # 칸 자신의 제네릭 U 와 T
 "own": (["MapInto = Trait.Fn<<<U>(bag: Self, f: (T) -> U, into: { U }) -> { U }>>(),"],
   ["local into3: { string } = {}; local m1: { string } = Bag.MapInto(b, function(x: number): string return \"\" end, into3) -- POS",
    "local into4: { string } = {}; local m2 = Bag.MapInto(b, function(x: string): string return \"\" end, into4) -- NEG"]),
 # 맨 T 를 칸 제네릭 U 로 감싼 경우: 인자 x: U, 콜백 (T) -> U
 "ownbare": (["FoldL = Trait.Fn<<<U>(bag: Self, init: U, f: (U, T) -> U, pool: { read [number]: T }) -> U>>(),"],
   ["local f1: number = Bag.FoldL(b, 0, function(a: number, x: number): number return a end, { 1 }) -- POS",
    "local f2: number = Bag.FoldL(b, 0, function(a: number, x: string): number return a end, { 1 }) -- NEG"]),
}
for one in (False, True):
  for name, (slots, lines) in cases.items():
    R = ("O" if one else "T") + name
    src = HEAD.format(R=R, PARAMS=ONE if one else TWO, SLOTS="\n".join("\t\t\t" + s for s in slots))
    src += "\n".join(lines) + "\nreturn nil\n"
    open(os.path.join(OUT, f"g-{R}.luau"), "w").write(src)
