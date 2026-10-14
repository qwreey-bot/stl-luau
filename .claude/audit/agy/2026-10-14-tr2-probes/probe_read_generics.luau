--!strict
-- probe_read_generics.luau: ArrRead 에 공변성을 해치지 않고 연관타입/마커를 줄 수 있는가?

-- 기본 Parent / Child 타입
type Animal = { tag: string }
type Dog = { tag: string, bark: () -> () }

-- 1. 현재 ArrData vs ArrRead
type ArrData<T> = {
	n: number,
	read __generics: { read Item: (T) -> T }, -- 불변 팬텀
	[number]: T,
}

type ArrRead<T> = {
	read n: number,
	read __genericsRead: { read Item: () -> T }, -- 공변 팬텀 () -> T
	read [number]: T,
}

local dog: Dog = { tag = "dog", bark = function() end }
local dogsData: ArrData<Dog> = {
	n = 1,
	__generics = { Item = function(x: Dog) return x end },
	[1] = dog,
}
local dogsRead: ArrRead<Dog> = {
	n = 1,
	__genericsRead = { Item = function() return dog end },
	[1] = dog,
}

-- 공변성 테스트: Dog -> Animal 로 전달 가능한가?
local function takeAnimalRead(r: ArrRead<Animal>)
	print(r.n)
end

-- 이것이 타입 에러 없이 통과하는가?
takeAnimalRead(dogsRead) -- 공변성 유지!

-- 만약 불변 팬텀이 든 타입을 넘기면 에러가 나는지 확인:
type ArrBadRead<T> = {
	read n: number,
	read __generics: { read Item: (T) -> T },
	read [number]: T,
}
local dogsBadRead: ArrBadRead<Dog> = {
	n = 1,
	__generics = { Item = function(x: Dog) return x end },
	[1] = dog,
}
local function takeAnimalBadRead(r: ArrBadRead<Animal>)
	print(r.n)
end
local NEG_invariant = takeAnimalBadRead(dogsBadRead) -- NEG: 불변이라 Animal 에 못 들어감!

local canary: string = 1

return {
	takeAnimalRead,
	NEG_invariant,
	canary,
}
