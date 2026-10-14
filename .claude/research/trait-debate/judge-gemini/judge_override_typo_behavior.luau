--!strict
-- probe 5: 재정의 오타(IndexOff) 시 정적 타입 및 런타임 거동 실측
local TraitV9 = require("../.claude/research/trait-v9/Trait")

local function listDef<M>(mode: M)
	return function<Self, E>(of: Self)
		return {
			Get = TraitV9.Fn<<(Self, number) -> E?>>(),
			IndexOf = TraitV9.Default(mode, function(ops: any)
				return function(s: Self, e: E): number? return 1 end
			end),
		}
	end
end

const List = TraitV9.Trait("List", listDef(TraitV9.FULL), listDef(TraitV9.IMPL))
type ListImpl<Self, E> = typeof(List.ImplOf<<Self, E>>(nil :: any))

type Container = { n: number }
const TOKEN = TraitV9.Token("TestContainer")

-- [정적 타입 관찰]:
-- ListImpl은 { Get: ..., IndexOf: ...? } 형태이므로, Luau의 너른 레코드 서브타이핑에 의해
-- 오타 난 키 'IndexOff'가 추가된 테이블도 정적 타입 검사는 0건으로 통과합니다.
const badOverrideImpl: ListImpl<Container, number> = {
	Get = function(s, i) return 1 end,
	IndexOff = function(s, e) return 2 end, -- 오타!
}

print("Static typecheck reached.")

-- [런타임 거동 관찰]:
-- 등록 시점에 Trait.ImplFor가 오타 키를 즉시 검출하여 에러를 던지는가?
local ok, err = pcall(function()
	List.ImplFor(TOKEN, badOverrideImpl)
end)

if not ok then
	print("Runtime caught typo successfully: " .. tostring(err))
else
	print("Runtime silently allowed unknown key!")
end

local canary: string = 1
return { canary }
