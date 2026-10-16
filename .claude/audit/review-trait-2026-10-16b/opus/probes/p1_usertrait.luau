--!strict
-- 사용자 트레이트: subst/occurs/Entries 가 잃는 것
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
export type AssocRead<T> = { read Item: () -> T }
export type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
export type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag: AssocRead<T> } }
export type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag: Assoc<T> } }
type Box<T> = { read v: T }

local Bag
do
	Bag = Trait.Trait("P1.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			-- (a) Self 가 인덱서 안에만(배열) — occurs 가 인덱서를 안 봄
			MergeAll = Trait.FnMut<<(bag: Self, others: { Self }) -> ()>>(),
			-- (b) Self 가 맵 인덱서의 값
			ByName = Trait.Fn<<(bag: Self, named: { [string]: Self }) -> number>>(),
			-- (c) 읽기 전용 필드 반환
			Peek = Trait.Fn<<(bag: Self) -> Box<T>>>(),
			-- (d) 겹침(오버로드) 칸 — Sig 없음
			Over = Trait.Default(function(_ops: any): ((bag: Self, x: number) -> number) & ((bag: Self, x: string) -> string)
				return nil :: any
			end),
			-- (e) 칸 자신의 제네릭이 정의 제네릭과 같은 이름
			MapTo = Trait.Default(function(_ops: any): <T>(bag: Self, f: (T) -> T) -> T
				return nil :: any
			end),
			-- (f) 가변 꼬리
			PutMany = Trait.FnMut<<(bag: Self, ...T) -> ()>>(),
			-- (g) 생성자 모양 — self 없음
			Make = Trait.Fn<<() -> Self>>(),
		})
	end)
end
local _da: nil = Bag.MergeAll
local _db: nil = Bag.ByName
local _dc: nil = Bag.Peek
local _dd: nil = Bag.Over
local _de: nil = Bag.MapTo
local _df: nil = Bag.PutMany
local _dg: nil = Bag.Make
local canary: string = 1
return nil
