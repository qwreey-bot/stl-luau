--!strict
-- 타입 프로브 t01: `View` 가 다루는 정의의 모양 — 조용히 `any`/`unknown`/`never` 가 되는 것이 있는가.
-- 각 덩어리마다 NEG(에러가 나야 함)를 하나씩 둡니다.
local stl = require("../../../../src")
local Trait = stl.Trait
type Tok = stl.TraitToken<string>
type Box = { read __type: Tok, read __generics: { read Item: (number) -> number }, value: number }
local box: Box = nil :: any

-- (1) 기준: 평범한 정의
local Plain = Trait.Trait("T01.Plain", function<Self>(of: Self | Tok)
	return table.freeze({ Len = Trait.Fn<<(v: Self) -> number>>() })
end)
local p1: string = Plain.Of(box).Len(box) -- NEG(1)

-- (2) Fn 에 타입 인자를 잊음
local NoArg = Trait.Trait("T01.NoArg", function<Self>(of: Self | Tok)
	return table.freeze({ Len = Trait.Fn() })
end)
local p2: string = NoArg.Of(box).Len(box) -- NEG(2)? 
local p2b: string = NoArg.Of(box).Len(1, 2, 3) -- NEG(2b)?
local p2impl: typeof(NoArg.ImplOf<<Box>>(nil :: any)) = { Len = 5 } -- NEG(2c)? 함수가 아닌 값

-- (3) table.freeze 없이(읽기·쓰기 필드)
local NoFreeze = Trait.Trait("T01.NoFreeze", function<Self>(of: Self | Tok)
	return { Len = Trait.Fn<<(v: Self) -> number>>() }
end)
local p3: string = NoFreeze.Of(box).Len(box) -- NEG(3)

-- (4) 제네릭 기본값 — 함수 제네릭엔 기본값 문법이 없음(파싱 에러) → 해당 없음. 대신 제네릭 둘
local DefGen = Trait.Trait("T01.DefGen", function<Self, T>(of: (Self & stl.TraitItem<T>) | Tok)
	return table.freeze({ Get = Trait.Fn<<(v: Self) -> T>>() })
end)
local p4: string = DefGen.Of(box).Get(box) -- NEG(4)?

-- (5) 타입 팩 제네릭
local Pack = Trait.Trait("T01.Pack", function<Self, R...>(of: Self | Tok)
	return table.freeze({ Call = Trait.Fn<<(v: Self) -> R...>>() })
end)
local p5 = Pack.Of<<Box, (number, string)>>(box).Call(box)
local p5n: string = p5 -- NEG(5)

-- (6) 칸 타입이 any
local AnySlot = Trait.Trait("T01.AnySlot", function<Self>(of: Self | Tok)
	return table.freeze({ Len = Trait.Fn<<any>>(), Size = Trait.Fn<<(v: Self) -> number>>() })
end)
local p6: string = AnySlot.Of(box).Size(box) -- NEG(6) 다른 칸은 그대로 검사돼야

-- (7) 칸에 오버로드
local Over = Trait.Trait("T01.Over", function<Self>(of: Self | Tok)
	return table.freeze({ Get = Trait.Fn<<((v: Self, k: string) -> string) & ((v: Self, k: number) -> number)>>() })
end)
local p7: string = Over.Of(box).Get(box, 1) -- NEG(7)

-- (8) 정의가 유니온을 돌려줌(조건에 따라 다른 표)
local Uni = Trait.Trait("T01.Uni", function<Self>(of: Self | Tok)
	if of == nil then
		return table.freeze({ Len = Trait.Fn<<(v: Self) -> number>>() })
	end
	return table.freeze({ Len = Trait.Fn<<(v: Self) -> number>>(), Extra = Trait.Fn<<(v: Self) -> number>>() })
end)
local p8: string = Uni.Of(box).Len(box) -- NEG(8)

-- (9) 중첩 표(칸 안에 표 — 실수)
local Nested = Trait.Trait("T01.Nested", function<Self>(of: Self | Tok)
	return table.freeze({ Len = Trait.Fn<<(v: Self) -> number>>(), Sub = { X = Trait.Fn<<(v: Self) -> number>>() } })
end)

-- (10) of 에 주석이 없음
local NoOfAnn = Trait.Trait("T01.NoOfAnn", function<Self>(of)
	return table.freeze({ Len = Trait.Fn<<(v: Self) -> number>>() })
end)
local p10: string = NoOfAnn.Of(box).Len(box) -- NEG(10)

-- (11) 제네릭 없는 정의(Self 를 안 씀)
local NoGen = Trait.Trait("T01.NoGen", function(of: Tok)
	return table.freeze({ Len = Trait.Fn<<(v: any) -> number>>() })
end)
local p11: string = NoGen.Of(box).Len(box) -- NEG(11)

-- (12) Default 의 빌더 반환 주석이 없음
local NoDefAnn = Trait.Trait("T01.NoDefAnn", function<Self>(of: Self | Tok)
	return table.freeze({
		Len = Trait.Fn<<(v: Self) -> number>>(),
		IsEmpty = Trait.Default(function(ops: any)
			return function(v: Self): boolean
				return ops.Len(v) == 0
			end
		end),
	})
end)
local p12: string = NoDefAnn.Of(box).IsEmpty(box) -- NEG(12)

-- (13) 정의 함수를 지역으로 먼저 두고 넘김
local function sizedDef<Self>(of: Self | Tok)
	return table.freeze({ Len = Trait.Fn<<(v: Self) -> number>>() })
end
local Local = Trait.Trait("T01.Local", sizedDef)
local p13: string = Local.Of(box).Len(box) -- NEG(13)

-- (14) 칸 함수에 제네릭 기본값/팩 — 생략

local canary: string = 1
return { p1, p2, p2b, p2impl, p3, p4, p5n, p6, p7, p8, Nested, p10, p11, p12, p13, canary }
