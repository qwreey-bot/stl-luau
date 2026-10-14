--!strict
--[[
	시제품 — 숫자 토큰 + 트레이트 객체의 배열 부분(2026-10-14 사용자 설계).

	- `NewToken(name)` 은 **숫자**(1부터). 이름은 `names[번호]`.
	- 트레이트 객체의 **배열 부분** `T[종류번호]` 가 그 종류의 완성 표, 구현이 없으면 `false`(빈칸 없이 순수 배열).
	- 완성 표는 **번호와 이름을 둘 다** 듦: `{ [1] = PushBack, PushBack = PushBack, … }`.
	- 함수 번호는 `T.Fn.이름`.
	- 진입점은 시스템이 만듦(`Entry`) — 가변인자로 넘김. 견주려고 고정 인자판(`Entry1`·`Entry2`)도.
	미리 만들기·다시 짓기·검증·에러 규약은 뺐습니다(재려는 것은 조회와 넘기기).
]]
local names: { string } = {}
local tokenCount = 0
const traits: { any } = {}

const function NewToken(name: string): number
	tokenCount += 1
	names[tokenCount] = name
	for _, trait in traits do
		trait[tokenCount] = false
	end
	return tokenCount
end

const function New(name: string, fnNames: { string }): any
	const trait: any = { name = name, Fn = {}, fnNames = fnNames }
	for at, fnName in fnNames do
		trait.Fn[fnName] = at
	end
	for tok = 1, tokenCount do
		trait[tok] = false
	end
	table.insert(traits, trait)
	return trait
end

const function Impl(trait: any, token: number, given: { [string]: any })
	const full = table.create(#trait.fnNames)
	for at, fnName in trait.fnNames do
		const fn = given[fnName]
		full[at] = fn
		full[fnName] = fn
	end
	trait[token] = full
end

const function miss(trait: any, value: any, fnName: string): any
	return error(`{trait.name}: {fnName} needs a {trait.name}`, 0)
end

-- 가변인자로 넘기는 진입점(사용자 제안 — 시스템이 이름마다 만들어 줌)
const function Entry(trait: any, fnName: string): (...any) -> ...any
	const fnNum = trait.Fn[fnName]
	return function(self: any, ...: any): ...any
		const impl = if type(self) == "table" then trait[rawget(self, "__type")] else nil
		if not impl then
			return miss(trait, self, fnName)
		end
		return impl[fnNum](self, ...)
	end
end

-- 견주기: 인자 수를 고정한 진입점(시스템이 인자 수를 알면 만들 수 있는 판)
const function Entry1(trait: any, fnName: string): (any) -> any
	const fnNum = trait.Fn[fnName]
	return function(self: any): any
		const impl = if type(self) == "table" then trait[rawget(self, "__type")] else nil
		if not impl then
			return miss(trait, self, fnName)
		end
		return impl[fnNum](self)
	end
end
const function Entry2(trait: any, fnName: string): (any, any) -> any
	const fnNum = trait.Fn[fnName]
	return function(self: any, a: any): any
		const impl = if type(self) == "table" then trait[rawget(self, "__type")] else nil
		if not impl then
			return miss(trait, self, fnName)
		end
		return impl[fnNum](self, a)
	end
end
-- 견주기: 가변인자 + 이름 조회(번호 대신 이름 문자열 — 상수가 아니라 인라인 캐시가 없음)
const function EntryByName(trait: any, fnName: string): (...any) -> ...any
	return function(self: any, ...: any): ...any
		const impl = if type(self) == "table" then trait[rawget(self, "__type")] else nil
		if not impl then
			return miss(trait, self, fnName)
		end
		return impl[fnName](self, ...)
	end
end

const function NameOf(token: number): string?
	return names[token]
end

-- stylua: ignore
return {
	NewToken = NewToken, New = New, Impl = Impl, Entry = Entry, Entry1 = Entry1, Entry2 = Entry2,
	EntryByName = EntryByName, NameOf = NameOf,
}
