import os, sys
sys.path.insert(0, os.path.dirname(__file__))
OUT = sys.argv[1]
exec(open(os.path.join(os.path.dirname(__file__), "gen.py")).read().split("cases = {")[0].replace("OUT = sys.argv[1]", ""))
cases = {
 # Default + Sig, 꼬리
 "dsigtail": (['''PushManyD = Trait.Default(function(_ops: any): (bag: Self, pool: { read [number]: T }, ...T) -> ()
				return function(_bag: Self, _pool: { read [number]: T }, ...: T) end
			end, Trait.Sig<<(bag: Self, pool: { read [number]: T }, ...T) -> ()>>()),'''],
   ["Bag.PushManyD(b, { 1 }, 2) -- POS", "Bag.PushManyD(b, { 1 }, \"s\") -- NEG"]),
 # DefaultMut + Sig, 맨 T
 "dmutbare": (['''PushD = Trait.DefaultMut(function(_ops: any): (bag: Self, x: T, pool: { read [number]: T }) -> ()
				return function(_bag: Self, _x: T, _pool: { read [number]: T }) end
			end, Trait.Sig<<(bag: Self, x: T, pool: { read [number]: T }) -> ()>>()),'''],
   ["Bag.PushD(b, 1, { 1 }) -- POS", "Bag.PushD(b, \"s\", { 1 }) -- NEG", "Bag.PushD(b, 1, arr) -- BND"]),
 # Default 칸 타입(Sig 없음), 맨 T
 "dbare": (['''PushE = Trait.Default(function(_ops: any): (bag: Self, x: T, pool: { read [number]: T }) -> ()
				return function(_bag: Self, _x: T, _pool: { read [number]: T }) end
			end),'''],
   ["Bag.PushE(b, 1, { 1 }) -- POS", "Bag.PushE(b, \"s\", { 1 }) -- NEG"]),
 # Sig 가 꼬리 없는데 구현 칸은 꼬리 ...any (List.Some 꼴) + 인덱서 + 콜백 안 T
 "sigcb": (['''SomeIn = Trait.Default(function(_ops: any): (bag: Self, pool: { read [number]: T }, pred: (T, ...any) -> boolean) -> boolean
				return function(_bag: Self, _pool: { read [number]: T }, _pred: (T, ...any) -> boolean): boolean return false end
			end, Trait.Sig<<(bag: Self, pool: { read [number]: T }, pred: (T) -> boolean) -> boolean>>()),'''],
   ["local so1: boolean = Bag.SomeIn(b, { 1 }, function(x: number): boolean return true end) -- POS",
    "local so2: boolean = Bag.SomeIn(b, arr, function(x: number): boolean return true end) -- POS",
    "local so3: boolean = Bag.SomeIn(b, { 1 }, function(x: string): boolean return true end) -- NEG"]),
 # 꼬리 ...T? (유니온 꼬리)
 "tailopt": (["PushManyO = Trait.FnMut<<(bag: Self, pool: { read [number]: T }, ...T?) -> ()>>(),"],
   ["Bag.PushManyO(b, { 1 }, 2, nil) -- POS", "Bag.PushManyO(b, { 1 }, \"s\") -- NEG"]),
 # 맨 T 만 꼬리에, 인덱서는 반환
 "tailret": (["PushRet = Trait.FnMut<<(bag: Self, ...T) -> { read [number]: T }>>(),"],
   ["local pr = Bag.PushRet(b, 1, 2) -- POS", "Bag.PushRet(b, \"s\") -- NEG", "local pr2: number? = pr[1] -- POS"]),
 # 교집합
 "inter2": (["PushI = Trait.FnMut<<(bag: Self, x: T & number, rest: { read [number]: T }) -> ()>>(),"],
   ["Bag.PushI(b, 1, { 2 }) -- POS"]),
 # 맨 T 칸이 둘, 인덱서 칸이 둘(정상)
 "bare2": (["PushA = Trait.FnMut<<(bag: Self, x: T, rest: { read [number]: T }) -> ()>>(),",
            "PushB = Trait.FnMut<<(bag: Self, x: T?, rest: { T }) -> ()>>(),"],
   ["Bag.PushA(b, 1, { 2 }) -- POS", "Bag.PushB(b, 1, { 2 }) -- POS", "Bag.PushA(b, \"s\", { 2 }) -- NEG", "Bag.PushB(b, \"s\", { 2 }) -- NEG"]),
 # 맨 T 를 돌려받는 콜백 인자가 직접 T 가 아닌 함수 타입 (T) -> T
 "fnparam": (["Apply = Trait.FnMut<<(bag: Self, f: (T) -> T, pool: { read [number]: T }) -> ()>>(),"],
   ["Bag.Apply(b, function(x: number): number return x end, { 1 }) -- POS", "Bag.Apply(b, function(x: string): string return x end, { 1 }) -- NEG"]),
}
for one in (False, True):
  for name, (slots, lines) in cases.items():
    R = ("O" if one else "T") + name
    src = HEAD.format(R=R, PARAMS=ONE if one else TWO, SLOTS="\n".join("\t\t\t" + s for s in slots))
    src += "\n".join(lines) + "\nreturn nil\n"
    open(os.path.join(OUT, f"k-{R}.luau"), "w").write(src)
