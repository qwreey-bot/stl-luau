--!strict
--[[
	Stack — 나중에 넣은 것이 먼저 나오는(LIFO) 컨테이너의 트레이트(2026-10-14 사용자 결정, 질문 AV: *"트레이트로 두는거 동의. stack 으로 무엇을 쓸지,
	queue 로 무엇을 쓸 지는 유저가 선택 가능하다고 봐"*).

	⭐ **Stack 는 덱을 모릅니다**(2026-10-15 사용자: *"Stack 은 Deque 가 뭔지 알 필요가 있을까?"* — 질문 BA). 필수 `Push`·`Pop`·`Peek` 만 정하고,
	"덱이면 스택" 은 **덱 쪽**(`Traits/Deque`)이 압니다: 런타임 뭉텅이 구현 `Stack.ImplWhere({ Deque }, …)`(`Push` = `PushBack`, `Pop` = `PopBack`,
	`Peek` = `Back` — 덱의 함수 그 자체, 질문 AW·perf 52절)과 변환자 `Deque.AsStack(d)`(타입으로 `stl.Stack<T>` 가 됨). 덱이 아닌 종류도
	`Stack.ImplFor(토큰, 표)` 로 스택이 되고, 그 종류를 타입으로 스택으로 쓰려면 `Trait.Converter(Stack, 토큰)` 에 타입을 적어 씁니다(`spikes/72`).
	덱인 종류에 직접 등록하면 그것이 뭉텅이 구현을 덮습니다(빠른 판을 얹는 길).

	⚠️ 진입점을 거치면 구현 찾기가 붙습니다. 종류를 아는 코드는 그 모듈의 함수(`CircularDeque.PushBack`)를 직접 쓰세요.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")
type AnyToken = Trait.AnyToken
const Fn, FnMut = Trait.Fn, Trait.FnMut

--[[ 연관 타입 레코드와 값 타입 — 타입에만 있는 필드(질문 BA) ]]
-- Stack 자기 레코드 — Stack 은 덱을 모릅니다(2026-10-15 사용자: *"Stack 은 Deque 가 뭔지 알 필요가 있을까?"*). 덱은 런타임에 stack을 구현하지만(뭉텅이
-- 구현은 `Traits/Deque` 에) 타입으로는 `Deque.AsStack(d)` 를 거쳐 `stl.Stack<T>` 가 됩니다(그 값은 스택으로만 보임 — `spikes/72`).
export type AssocRead<T> = { read Item: () -> T }
export type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
export type ValueRead<T> = { read __type: Trait.Token<any>, read __traits: { read Stack: AssocRead<T> } } -- stl.StackRead<T>
export type Value<T> = { read __type: Trait.Token<any>, read __traits: { read Stack: Assoc<T> } } -- stl.Stack<T>

--[[ 정의 ]]
-- `Push` 는 자기 자신을 돌려주고, `Pop`·`Peek` 은 비었으면 `nil`.
const StackBase = Trait.Trait(
	"Stack",
	function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			Push = FnMut<<(stack: Self, item: T) -> Self>>(),
			Pop = FnMut<<(stack: Self) -> T?>>(),
			Peek = Fn<<(stack: Self) -> T?>>(),
		})
	end
)
-- 완성 표(= 등록 표 — 기본 구현이 없음)
export type Full<Self, T> = typeof(StackBase.OfMut<<Self, T>>(nil :: any))
export type ReadFull<Self, T> = typeof(StackBase.Of<<Self, T>>(nil :: any))
export type Provided<Self, T> = typeof(StackBase.ImplOf<<Self, T>>(nil :: any))

--[[ 진입점 서명 — 정의에서 지어짐(`Trait.Entries`): 쓰기 칸은 `Value`, 읽기 칸은 `ValueRead` 를 받음 ]]
const Stack = StackBase

return Stack
