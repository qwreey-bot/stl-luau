--!strict
-- 최소화 시도 — **재현 안 됨(0건)**. 시제품의 `Entries` 에서는 진입점마다 제네릭을 새로 만들지 않으면 `List.IndexOf(a, 20)` 이
-- `Expected this to be 'E', but got 'number'` 였는데(새로 만들면 0건 — 끄고 켜서 확인), 그 조건을 손으로 줄인 이 모양(함수 둘이 같은 제네릭,
-- 공변·불변 첫 인자)으로는 나지 않습니다. 정확한 조건은 모름 — 상류에 올리기 전에 최소화가 남은 일.
type function Two(def)
	local params = def:parameters().head
	local g = def:generics()
	local item = g[1]
	local props: { [type]: { read: type?, write: type? } } = {}
	props[types.singleton("read")] = { read = types.newfunction({ head = { params[1], item } }, { head = {} }, g) }
	props[types.singleton("write")] = { read = types.newfunction({ head = { params[2], item } }, { head = {} }, g) }
	return types.newtable(props)
end
type function OnlyRead(def)
	local params = def:parameters().head
	local g = def:generics()
	local props: { [type]: { read: type?, write: type? } } = {}
	props[types.singleton("read")] = { read = types.newfunction({ head = { params[1], g[1] } }, { head = {} }, g) }
	return types.newtable(props)
end
type Def = <T>(r: { read get: () -> T }, w: { read set: (T) -> T }) -> ()
local two: Two<Def> = nil :: any
local only: OnlyRead<Def> = nil :: any
local box: { read get: () -> number, read set: (number) -> number } = nil :: any
two.read(box, 1) -- 기대 0건
two.write(box, 1) -- 0건
only.read(box, 1) -- 0건
local hand: { read read: <T>(x: { read get: () -> T }, item: T) -> (), read write: <T>(x: { read set: (T) -> T }, item: T) -> () } = nil :: any
hand.read(box, 1) -- 0건(손으로 적으면 됨)
