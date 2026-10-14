--!strict
type DefaultTag = { read __default: true }
local function Fn<T>(): T return true :: any end
local function Default<T>(): T & DefaultTag return true :: any end
type function Optionalize(input: type): type
	-- 꼬리표가 붙은 필드는 선택 필드로(꼬리표는 뗌)
	const props = input:properties()
	for key, v in props do
		const t = v.read
		if t and t.tag == "intersection" then
			local tagged, rest = false, {}
			for _, c in t:components() do
				if c.tag == "table" and c:readproperty(types.singleton("__default")) then
					tagged = true
				else
					table.insert(rest, c)
				end
			end
			if tagged then
				const inner = if #rest == 1 then rest[1] else types.intersectionof(table.unpack(rest))
				props[key] = { read = types.optional(inner) }
			end
		end
	end
	return types.newtable(props, input:indexer(), input:metatable())
end
const fns = {
	Get = Fn<<(list: { n: number }, idx: number) -> number?>>(),
	Fold = Default<<<U>(list: { n: number }, init: U, fn: (U, number) -> U) -> U>>(),
}
type For = Optionalize<typeof(fns)>
-- 진입점: 꼬리표 붙은 함수를 부를 수 있나
local l = { n = 3 }
const a: number? = fns.Get(l, 1)
const b: number = fns.Fold(l, 0, function(acc: number, x: number): number return acc + x end)
const negB: string = fns.Fold(l, 0, function(acc: number, x: number): number return acc + x end)
-- 등록: Fold 없이 / Fold 틀리게 / Get 없이
const ok: For = { Get = function(_l: { n: number }, _i: number): number? return nil end }
const negFold: For = { Get = function(_l: { n: number }, _i: number): number? return nil end, Fold = 5 }
const negGet: For = { Fold = function<U>(_l: { n: number }, init: U, _f: (U, number) -> U): U return init end }
local canary: string = 1
return { a, b, negB, ok, negFold, negGet, canary }
