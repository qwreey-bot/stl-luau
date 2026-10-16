--!strict
--[[
	Trait — 타입 토큰과 트레이트 **시스템**(2026-10-15 들임 — 질문 AY, 정본 설계·실험은 `.claude/research/trait-v9`·`trait-debate`,
	같은 날 정의를 한 번만 넘기는 레코드 안으로 — `.claude/research/trait-udtf`).
	트레이트 하나하나(계약 타입·기본 구현·진입점 서명)는 `src/Traits/` 에 파일 하나씩.

	⚠️ **이 시스템은 계속 바뀔 수 있습니다**(사용자: *"trait 시스템 자체는 계속 변화할 수 있는걸로 둬야겠어. 타입 시스템이
	변경됨에 따라서 영향을 받는지라"*) — 타입 모양이 Luau 새 솔버의 동작(사용자 타입 함수 `View`, 명시적 타입 인자)에 기댑니다.

	## 값과 토큰
	값에는 **타입 토큰 하나**(`__type` 필드 — 컨테이너 모듈이 `Trait.NewToken("Stl.Arr")` 로 만든 얼린 테이블). 토큰 이름은
	**유일**합니다(라이브러리 것은 `Stl.` 접두). 직렬화했다 되읽은 값은 토큰의 정체성을 잃으니 `Trait.Restore(값)` 이 이름으로
	이 사본의 진짜 토큰을 되찾아 줍니다. 위조는 막지 않습니다(토큰을 베껴 넣으면 그 종류).

	## 트레이트 = 정의(팩토리)
	```lua
	export type AssocRead<T> = { read Item: () -> T }                       -- 트레이트가 가진 연관 타입 레코드(공변 칸)
	export type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }       -- + 불변 팬텀(바꿀 수 있는 참조만 적음)
	export type ValueRead<T> = { read __type: Trait.Token<any>, read __traits: { read Deque: AssocRead<T> } } -- 배럴의 stl.DequeRead<T>
	export type Value<T> = { read __type: Trait.Token<any>, read __traits: { read Deque: Assoc<T> } }        -- 배럴의 stl.Deque<T>
	const DequeBase = Trait.Trait("Deque", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			PushBack = Trait.FnMut<<(deque: Self, item: T) -> Self>>(),   -- 필수·쓰기
			Front = Trait.Fn<<(deque: Self) -> T?>>(),                   -- 필수·읽기
			Count = Trait.Default(function(ops: any): (deque: Self) -> number … end), -- 기본 구현(빌더)·읽기 (쓰기는 DefaultMut)
		})
	end)
	export type ReadFull<Self, T> = typeof(DequeBase.Of<<Self, T>>(nil :: any))    -- 읽기 보기(쓰기 칸 없음)
	export type Full<Self, T> = typeof(DequeBase.OfMut<<Self, T>>(nil :: any))     -- 완성 표
	export type Provided<Self, T> = typeof(DequeBase.ImplOf<<Self, T>>(nil :: any)) -- 등록 표(기본 구현 칸은 선택)
	```
	- 정의는 **한 번** 넘깁니다. 칸은 타입으로 레코드(`{ required, mut, fn }`)이고, 타입 함수 `View` 가 정의 함수의 타입을 받아 세 보기
	  (읽기 = 쓰기 칸을 뺌, 완성 = 칸마다 `fn`, 등록 = 기본 구현 칸만 `fn?`)로 **다시 지어** `Of`·`OfMut`·`ImplOf` 의 타입으로 줍니다 —
	  제네릭 목록은 정의의 것 그대로.
	- ⭐ **읽기·쓰기는 칸에 적습니다**(2026-10-15 질문 BA — Rust 의 `&self`/`&mut self` 를 칸에). `X.Of(v)` 는 읽기 보기(정의의 **첫 매개변수**
	  조건 — 빌린 읽기 참조도), `X.OfMut(v)` 는 완성 표(**둘째 매개변수** 조건 — 바꿀 수 있는 참조만, 없으면 첫째). 런타임은 같은 표입니다.
	  예전엔 읽기·쓰기를 트레이트 통째의 `of` 와 진입점마다의 마커 두 곳에서 정해 어긋났습니다(빌린 참조가 `Collection.Of` 를 거쳐 `Clear`).
	- ⭐ **진입점 서명은 정의에서 지어집니다**(타입 함수 `Entries` — 트레이트 객체 타입에 자동으로 붙음): 쓰기 칸은 둘째 조건을, 읽기 칸은 첫째
	  조건을 첫 인자로 받습니다. 마커를 손으로 고르지 않습니다. 부르는 쪽 서명이 칸 타입과 다르면 `Default(build, Trait.Sig<<서명>>())`
	  (`List.Some` — 구현은 `(E, I, ...any)` 를 받아야, 부르는 쪽은 꼬리 없는 술어 변수를 넘길 수 있어야). `Self` 가 첫 인자에만 나오면
	  빼서 손으로 쓰던 서명과 제네릭 순서가 같습니다 — 명시적 타입 인자를 일부만 주면 솔버 내부 에러라 순서가 곧 공개 표면.
	  ⚠️ 진입점마다 제네릭을 **새로** 만들어 바꿔 끼웁니다(`subst`) — 정의의 것을 나눠 쓰면 `List.IndexOf(a, 20)` 이 `Expected 'E', got
	  'number'` 였습니다(끄고 켜서 확인, 손으로 줄인 재현은 0건 — 원인 모름, `.claude/research/trait-ofmut`).
	- ⭐ **트레이트마다 자기 연관 타입 레코드**(질문 BA — 사용자: *"Trait 를 아예 드러내는게 나아보이겠다"*): 컨테이너는 자기 타입에
	  `read __traits: { read Deque: Deque.Assoc<T>, read List: List.Assoc<T, number>, … }` 한 줄로 "어느 트레이트를 무슨 인자로 구현하는가" 를
	  적습니다(Rust 의 `impl Deque<T> for X`). 이름·위치·변성은 그 트레이트 안의 일이라 트레이트끼리 합의할 필요가 없고 뜻이 부딪히지
	  않습니다. 빌린 읽기 타입은 `AssocRead` 를 적습니다. ⚠️ 등록(런타임)은 타입을 못 바꿉니다 — 바깥에서 뭉텅이로 만족시킨 트레이트는
	  타입에 안 붙고, 쓰는 쪽이 교집합 별칭(`Arr<T> & { read __traits: { read X: … } }`)과 그것을 돌려주는 중간자 함수로 덧붙입니다.
	- ⚠️ 같은 파일에서 정의하고 등록하려면 정의를 `do … end` 안에 — 파일 꼭대기에서 정의하면 그 파일의 등록 표에서 칸 자체가 제네릭인
	  함수(`Fold<U>`)의 실수가 0건입니다(다시 지은 `<U>` 가 모듈 스코프를 받음 — 상류 `Subtyping.cpp:830`, 질문 AZ, `spikes/70`).
	- 팩토리는 런타임에 **한 번**(of = nil) 불려 이름(`Fn`·`FnMut` = 필수, `Default`·`DefaultMut` = 기본 구현 빌더)을 줍니다. `table.freeze` 로
	  돌려주면 트레이트 타입의 필드가 `read` 가 됩니다. 정의가 함수가 아니거나 표를 돌려주지 않거나 칸이 그 넷이 아니면 `View` 가 타입
	  에러로 알립니다(`'View' type function errored at runtime: Trait.Trait: …` — 보기 셋이라 같은 줄에 세 번).
	- `Default(build)` 의 `build(ops)` 는 그 종류의 완성 표를 받아 함수를 돌려줍니다(형제를 지역으로 붙잡아도 됨 — 다시
	  지어질 때 다시 불림). ⚠️ 계약: 던지지 않고 부작용 없이 함수만 돌려줌. `ops` 는 `any` 라 읽기 기본 구현이 쓰기 형제를 불러도 타입이
	  못 막습니다. 기본 구현 타입에 오버로드(`&`)를 쓰지 마세요(등록 보기의 `(A & B)?` 에 한쪽 갈래만 든 재정의가 0건 — 상류 결함).

	## 등록·조회
	- `X.ImplFor(토큰, 표)` — 표는 **그 트레이트의 함수만**(모르는 이름은 에러), `X.Provided<종류<A>, A>` 주석을 단 **지역 변수**에 적어
	  넘깁니다(타입 검사 — 표 리터럴을 바로 넘기면 검사가 안 됨). 기본 구현 칸은 안 적으면 기본 구현, 적으면 재정의.
	  `__index` 가 테이블인 사슬로 물려받은 함수도 칩니다(등록 때 한 번 읽어 사본으로).
	- `X.ImplWhere({ 의존 트레이트 }, function(deps) return { … } end)` — 뭉텅이 구현(의존을 다 구현한 모든 종류에. `Trait.Any` 면 모든
	  종류). 명시 구현(`ImplFor`)이 덮고, 뭉텅이끼리 겹치면 에러. 몸통은 탐침 타입(`Trait.A`·`Trait.B`)으로 짜면 원소까지 검사됨.
	- 표는 **미리** 지어 둡니다(토큰·트레이트·등록이 생길 때) — 조회는 짓지 않습니다. 의존 표가 다시 지어지면 위로 번짐.
	- `X.Of(값 또는 토큰)` — 완성 표(없으면 사용자 줄 에러). `Trait.ImplOf(X, 값)` 은 없으면 nil, `Trait.Implements(X, 값)` 은 불리언.
	- 진입점(`X.이름(값, …)`)은 **시스템이 만듭니다** — 트레이트 파일이 서명을 타입으로만 입힙니다(교집합 — 객체 타입에 인덱서가
	  없어야 `X.Of<<…>>` 가 됨).
]]
-- 폴더 모듈의 init 은 `./`·`../` 가 폴더의 부모(src) 기준, 형제 조각은 `@self/`
local Common = require("./Common")
Common.registerSource(debug.info(1, "s"))
local Registry = require("@self/Registry")
local Build = require("@self/Build")
local Entry = require("@self/Entry")
local Errors = require("@self/Errors")

-- 타입 토큰. `N` 은 이름의 리터럴 타입.
export type Token<N> = { read name: N }
-- ⚠️ `name` 은 `string` 으로 — `any`·`unknown` 이면 그 필드가 **없는** 테이블도 만족해(빠진 읽기 필드를 `nil` 로 봄 — 상류의
-- 의도된 동작), 팩토리의 `(Self & ValueRead<T>) | AnyToken` 의 토큰 갈래가 아무 값이나 받았음.
export type AnyToken = Token<string>
-- "모든 종류" 표식(`X.ImplWhere(Trait.Any, …)`)의 타입 — 빈 목록 `{}` 은 에러입니다(아래 `Any`).
export type AnyKind = { read __anyKind: true }
-- ⭐ 공용 연관 타입(`Item`·`ItemIndexRead` …)은 없습니다(2026-10-15 질문 BA — 사용자: "Trait 를 아예 드러내는게 나아보이겠다").
-- 트레이트마다 자기 연관 타입 레코드(`Deque.Assoc<T>`·`Deque.AssocRead<T>`)를 갖고, 컨테이너가 자기 타입에
-- `read __traits: { read Deque: Deque.Assoc<T>, … }` 로 "어느 트레이트를 무슨 인자로 구현하는가" 를 적습니다(Rust 의 `impl Deque<T> for X`).
-- 이름·위치·변성은 그 트레이트 안의 일 — 트레이트끼리 이름에 합의할 필요가 없고 뜻이 부딪히지 않습니다.
-- 탐침 타입: 등록 표의 타입 주석과 뭉텅이 몸통에 — "모든 T 에 대해" 를 서로 다른 불투명 타입으로 흉내 냄. 구체 타입(`string`)으로
-- 적으면 원소를 못박은 함수가 샙니다. 제네릭 함수의 **몸통 안**은 상류 결함(`Subtyping.cpp:830`)으로 검사가 거의 안 돼서, 몸통도
-- 탐침 타입으로 짜는 것이 원리상 맞는 우회입니다(`.claude/research/luau-source/README.md`).
export type A = { read __probeA: true }
export type B = { read __probeB: true }
export type C = { read __probeC: true }
-- 트레이트 객체. `Of` 의 타입이 팩토리 그 자체(트레이트마다 손으로 적지 않음). ⚠️ 인덱서를 두지 않습니다 — `[string]: any` 와
-- 교집합이면 `X.Of<<…>>` 가 함수가 아니게 돼(`T & any` → `T | error`) 진입점 서명을 교집합으로 입힐 수 없었습니다.
export type Object<R, F, G> = {
	read Of: R, -- 읽기 보기 꺼내기(값이나 토큰으로) — `FnMut` 칸이 없음. 읽기 전용으로 빌린 참조도 받음(정의의 첫 매개변수)
	read OfMut: F, -- 완성 표 꺼내기 — 모든 칸. 바꿀 수 있는 참조만(정의의 둘째 매개변수 — 없으면 첫째). 런타임은 `Of` 와 같은 함수
	read ImplOf: G, -- 타입 전용: `typeof(X.ImplOf<<…>>(nil :: any))` 로 등록 표 타입을 얻음(런타임은 `Of` 와 같은 함수)
	read ImplFor: (kind: any, impl: any) -> (), -- 종류(봉인한 모듈 표 — `stl.Arr`) 또는 토큰
	read ImplWhere: (deps: { any } | AnyKind, build: (deps: { [any]: any }) -> any) -> (),
	read FnTok: { [string]: number },
}

-- 트레이트의 세 보기. `def` 는 정의 함수의 타입(`<Self, T>(of, ofMut?) -> { 이름: { required, mut, fn } }`), `mode` 는 `"read"`(읽기 보기 — 쓰기 칸을 뺌, 첫 매개변수), `"full"`(완성 표 — 칸마다
-- `fn`) 또는 `"impl"`(등록 표 — 기본 구현 칸은 `fn?`). 반환 표만 다시 짓고 매개변수와 **제네릭 목록은 정의의 것 그대로** 되넘깁니다 —
-- 그래서 `Of<<Self, T>>` 가 되고, 정의할 때 바로 줄어듭니다(제네릭이 함수 타입 안에 묶여 있어 바깥 제네릭이 정해지길 기다리지
-- 않음 — 별칭에 걸면 `outer_generics_irreducible` 로 안 줄어듦, `.claude/research/trait-udtf`).
-- - 정의의 가변 꼬리(`...any`)는 떼어 냅니다 — 남기면 `X.Of(d, 1, 2)` 가 0건이었습니다.
-- - ⚠️ 다시 지은 제네릭은 적용한 자리의 스코프를 받고 제네릭 기본값·바운드는 사라집니다(지금 정의엔 없음).
-- - 실수는 `error` 로 — 타입 에러 `'View' type function errored at runtime: …` 로 정의 줄에 뜹니다. 정의나 그 반환이 `any` 면
--   보기도 `any`(검사를 끄는 관용구).
export type function View(def, mode)
	-- `any` 는 검사를 끄는 관용구 그대로(런타임만 보는 테스트·동적 정의) — 정의나 그 반환이 `any` 면 보기도 `any`.
	if def:is("any") then
		return types.any
	end
	local m = mode:value()
	local full, read = m == "full", m == "read"
	if not def:is("function") then
		error(
			"Trait.Trait: the definition must be a function `function<Self, …>(of) return table.freeze({ … }) end`"
		)
	end
	local returns = def:returns().head
	local fns = if returns == nil then nil else returns[1]
	if fns ~= nil and fns:is("any") then
		return types.any
	end
	if fns == nil or not fns:is("table") then
		error("Trait.Trait: the definition must return a table of Trait.Fn / Trait.Default slots")
	end
	local REQUIRED, FN, MUT = types.singleton("required"), types.singleton("fn"), types.singleton("mut")
	local out: { [type]: { read: type?, write: type? } } = {}
	for key, prop in fns:properties() do
		local slot = prop.read
		local fnType = if slot ~= nil and slot:is("table") then slot:readproperty(FN) else nil
		local required = if slot ~= nil and slot:is("table") then slot:readproperty(REQUIRED) else nil
		local mut = if slot ~= nil and slot:is("table") then slot:readproperty(MUT) else nil
		if fnType == nil or required == nil or mut == nil then
			local value = if key:is("singleton") then key:value() else nil
			local name = if type(value) == "string" then value else "?"
			error(`Trait.Trait: '{name}' must be Trait.Fn / FnMut<<…>>() or Trait.Default / DefaultMut(…)`)
		end
		local isRequired = required:is("singleton") and required:value() == true
		local isMut = mut:is("singleton") and mut:value() == true
		if not (read and isMut) then
			out[key] = { read = if full or read or isRequired then fnType else types.optional(fnType) }
		end
	end
	-- 매개변수: 하나면 세 보기가 같이 씀, 둘이면 첫째(읽기 — 빌린 참조도 받는 조건)는 읽기 보기, 둘째(바꿀 수 있는 참조)는 완성·등록 보기
	local head = def:parameters().head
	local params: { type } = if head == nil then {} else head
	if #params > 2 then
		error("Trait.Trait: the definition takes `of` (read) and optionally `ofMut` — at most two parameters")
	end
	local param = if read or #params < 2 then params[1] else params[2]
	return types.newfunction({ head = { param } }, { head = { types.newtable(out) } }, def:generics())
end

-- 진입점 서명을 정의에서 짓습니다(질문 BA). 칸마다 `<정의의 제네릭…, 칸의 제네릭…>(첫 인자: 조건, 나머지…) -> 반환` —
-- 첫 인자의 조건은 읽기 칸이면 정의의 첫 매개변수(`of`), 쓰기 칸이면 둘째(`ofMut`)에서 토큰 갈래를 뺀 것(유니온의 첫 갈래).
export type function Entries(def)
	if def:is("any") then
		return types.any
	end
	-- 정의자 실수는 `View` 가 알립니다 — 여기서는 조용히 빈 표(같은 줄에 에러가 겹쳐 뜨지 않게).
	if not def:is("function") then
		return types.newtable()
	end
	local returns = def:returns().head
	local fns = if returns == nil then nil else returns[1]
	if fns == nil or fns:is("any") then
		return types.any
	end
	if not fns:is("table") then
		return types.newtable()
	end
	local head = def:parameters().head
	local params: { type } = if head == nil then {} else head
	-- 조건에서 토큰 갈래(`AnyToken` = `{ read name: string }` — `X.Of(토큰)` 을 받으려고 둔 것)를 뺀 나머지. 갈래가 여럿이면(스택: 덱 레코드
	-- **또는** 스택 레코드) 그 합.
	local NAME = types.singleton("name")
	local function isTokenBranch(t: type): boolean
		if not t:is("table") then
			return false
		end
		local count = 0
		for _ in t:properties() do
			count += 1
		end
		return count == 1 and t:readproperty(NAME) ~= nil
	end
	local function subject(p: type?): type?
		if p == nil then
			return nil
		end
		if p:is("union") then
			local rest: { type } = {}
			for _, c in p:components() do
				if not isTokenBranch(c) then
					table.insert(rest, c)
				end
			end
			return if #rest == 0 then nil elseif #rest == 1 then rest[1] else types.unionof(table.unpack(rest))
		end
		return p
	end
	local readSubject = subject(params[1])
	local mutSubject = subject(params[2]) or readSubject
	local MUT, FN, ENTRY = types.singleton("mut"), types.singleton("fn"), types.singleton("entry")
	local defGenerics = def:generics()
	-- 진입점마다 정의의 제네릭을 **새로** 만들어 바꿔 끼웁니다 — 여러 진입점이 같은 제네릭 객체를 나눠 쓰면 원소 인자에서 묶이지 않았습니다
	-- (칸 하나면 됨 — `.claude/research/trait-ofmut`).
	local function subst(t: type, map: { [type]: type }, memo: { [type]: type }): type
		local hit = map[t] or memo[t]
		if hit ~= nil then
			return hit
		end
		if t:is("union") or t:is("intersection") then
			local parts: { type } = {}
			for i, c in t:components() do
				parts[i] = subst(c, map, memo)
			end
			return if t:is("union")
				then types.unionof(table.unpack(parts))
				else types.intersectionof(table.unpack(parts))
		elseif t:is("negation") then
			return types.negationof(subst(t:inner(), map, memo))
		elseif t:is("function") then
			local function pack(p: { head: { type }?, tail: type? }): { head: { type }?, tail: type? }
				local head: { type } = {}
				for i, h in p.head or {} do
					head[i] = subst(h, map, memo)
				end
				return { head = head, tail = if p.tail == nil then nil else subst(p.tail, map, memo) }
			end
			return types.newfunction(pack(t:parameters()), pack(t:returns()), t:generics())
		elseif t:is("table") then
			local out = types.newtable()
			memo[t] = out
			for key, prop in t:properties() do
				local r = if prop.read == nil then nil else subst(prop.read, map, memo)
				local w = if prop.write == nil then nil else subst(prop.write, map, memo)
				if r ~= nil and w ~= nil and prop.read == prop.write then
					out:setproperty(key, r)
				else
					if r ~= nil then
						out:setreadproperty(key, r)
					end
					if w ~= nil then
						out:setwriteproperty(key, w)
					end
				end
			end
			local idx = t:indexer()
			if idx ~= nil then
				out:setindexer(subst(idx.index, map, memo), subst(idx.readresult, map, memo))
			end
			return out
		end
		return t
	end
	local out: { [type]: { read: type?, write: type? } } = {}
	for key, prop in fns:properties() do
		local slot = prop.read
		local fnType = if slot ~= nil and slot:is("table") then slot:readproperty(FN) else nil
		local entry = if slot ~= nil and slot:is("table") then slot:readproperty(ENTRY) else nil
		if entry ~= nil and entry:is("function") then
			fnType = entry
		end
		local mut = if slot ~= nil and slot:is("table") then slot:readproperty(MUT) else nil
		if fnType ~= nil and fnType:is("function") and mut ~= nil then
			local isMut = mut:is("singleton") and mut:value() == true
			local fp = fnType:parameters()
			local fhead = if fp.head == nil then {} else fp.head
			local newHead: { type } = {}
			for i, p in fhead do
				newHead[i] = if i == 1 then (if isMut then mutSubject else readSubject) or p else p
			end
			-- `Self`(정의의 첫 제네릭)가 첫 인자에만 나오면 빼서 손으로 쓰던 서명(`<E, I>(list: ValueRead<E, I>, …)`)과 제네릭 순서를 맞춤 —
			-- 명시적 타입 인자를 일부만 주면 솔버 내부 에러라(`f<<A>>` 에 `<A, B>`) 순서가 곧 공개 표면입니다.
			local selfG = defGenerics[1]
			local usesSelf = false
			local function occurs(t: type, seen: { [type]: boolean }): boolean
				if t == selfG then
					return true
				end
				if seen[t] then
					return false
				end
				seen[t] = true
				if t:is("union") or t:is("intersection") then
					for _, c in t:components() do
						if occurs(c, seen) then
							return true
						end
					end
				elseif t:is("function") then
					for _, p in { t:parameters(), t:returns() } do
						for _, h in p.head or {} do
							if occurs(h, seen) then
								return true
							end
						end
						if p.tail ~= nil and occurs(p.tail, seen) then
							return true
						end
					end
				elseif t:is("negation") then
					return occurs(t:inner(), seen)
				elseif t:is("table") then
					for _, prop in t:properties() do
						if
							(prop.read ~= nil and occurs(prop.read, seen))
							or (prop.write ~= nil and occurs(prop.write, seen))
						then
							return true
						end
					end
					-- 인덱서 안도(`{ Self }`·`{ [k]: Self }` — 안 보던 때는 `Self` 를 빼 버려 묶이지 않은 제네릭이 남고 트레이트의 진입점이 전부
					-- 사라졌음, 2026-10-16 리뷰 1라운드 F1)
					local ix = t:indexer()
					if ix ~= nil and (occurs(ix.index, seen) or occurs(ix.readresult, seen)) then
						return true
					end
				end
				return false
			end
			for i, p in fhead do
				if i > 1 and occurs(p, {}) then
					usesSelf = true
				end
			end
			if fp.tail ~= nil and occurs(fp.tail, {}) then
				usesSelf = true
			end
			local fr = fnType:returns()
			for _, r in fr.head or {} do
				if occurs(r, {}) then
					usesSelf = true
				end
			end
			-- `Self & 조건` 에서 `Self` 를 뺌 — 조건이 갈래 여럿이면(`(Self & A) | (Self & B)` 로 펼쳐졌을 수도) 갈래마다. 못 빼는 모양이면 `Self` 를 둠.
			local function dropSelf(t: type): type?
				if t:is("union") then
					local parts: { type } = {}
					for _, c in t:components() do
						local d = dropSelf(c)
						if d == nil then
							return nil
						end
						table.insert(parts, d)
					end
					return types.unionof(table.unpack(parts))
				end
				if not t:is("intersection") then
					return nil
				end
				local found = false
				local rest: { type } = {}
				for _, c in t:components() do
					if c == selfG then
						found = true
					else
						table.insert(rest, c)
					end
				end
				if not found or #rest == 0 then
					return nil
				end
				return if #rest == 1 then rest[1] else types.intersectionof(table.unpack(rest))
			end
			local dropped = if usesSelf or newHead[1] == nil then nil else dropSelf(newHead[1])
			if dropped == nil then
				usesSelf = true
			else
				newHead[1] = dropped
			end
			-- ⚠️ 칸 자신의 제네릭 이름(`<T>`)이 정의의 것과 겹치면 **그 진입점 서명만 뺍니다**(런타임 진입점은 있음 — 칸의 제네릭 이름을 바꾸세요).
			-- 그대로 지으면 "Duplicate type parameter" 로 트레이트의 진입점이 **전부** 사라졌고(리뷰 1라운드 F2), 새 이름으로 바꿔 지어도 타입 함수가
			-- 받은 정의 안에서 바깥 `T` 와 가린 `T` 가 섞여(첫 인자가 칸의 `T` 를 가리킴) 믿을 수 없었습니다(`spikes/74` 의 경계 줄).
			local ownNames: { [string]: boolean } = {}
			for _, g in fnType:generics() do
				const name: string? = g:name()
				if type(name) == "string" then
					ownNames[name] = true
				end
			end
			-- ⚠️ **인덱서가 든 칸은 다시 짓지 않습니다**(정의의 제네릭을 그대로): 타입 함수는 읽기 전용 인덱서를 만들지도(`setreadindexer` 미지원,
			-- `writeresult` 무시) 알아보지도(`{ read [K]: V }` 와 `{ [K]: V }` 가 같게 보임) 못해, 다시 지으면 `read` 를 잃었습니다 — `Map.Iter`
			-- 결과에 쓰기가 0건으로 맵 안쪽을 오염시키고, 읽기 리스트를 받는 칸이 `Arr` 를 거절(리뷰 1라운드 T2·F3). 손대지 않고 돌려준 타입은
			-- 읽기 전용이 살아 있습니다(`View` 와 같음). 그 칸 하나만 정의의 제네릭을 쓰니 "나눠 쓰면 안 묶임" 은 안 남습니다(`spikes/74`).
			local function hasIndexer(t: type, seen: { [type]: boolean }): boolean
				if seen[t] then
					return false
				end
				seen[t] = true
				if t:is("union") or t:is("intersection") then
					for _, c in t:components() do
						if hasIndexer(c, seen) then
							return true
						end
					end
				elseif t:is("negation") then
					return hasIndexer(t:inner(), seen)
				elseif t:is("function") then
					for _, pk in { t:parameters(), t:returns() } do
						for _, h in pk.head or {} do
							if hasIndexer(h, seen) then
								return true
							end
						end
						if pk.tail ~= nil and hasIndexer(pk.tail, seen) then
							return true
						end
					end
				elseif t:is("table") then
					if t:indexer() ~= nil then
						return true
					end
					for _, prop in t:properties() do
						if
							(prop.read ~= nil and hasIndexer(prop.read, seen))
							or (prop.write ~= nil and hasIndexer(prop.write, seen))
						then
							return true
						end
					end
				end
				return false
			end
			local clash = false
			for _, g in defGenerics do
				const name: string? = g:name()
				if type(name) == "string" and ownNames[name] then
					clash = true
				end
			end
			if not clash then
				local keepOriginal = hasIndexer(fnType, {})
				local generics: { type } = {}
				local map: { [type]: type } = {}
				for i, g in defGenerics do
					local n = g
					if not keepOriginal then
						n = types.generic(g:name() or "T", g:ispack())
						map[g] = n
					end
					if i > 1 or usesSelf then
						table.insert(generics, n)
					end
				end
				for _, g in fnType:generics() do
					table.insert(generics, g)
				end
				local built = types.newfunction({ head = newHead, tail = fp.tail }, fnType:returns(), {})
				local renamed = if keepOriginal then built else subst(built, map, {})
				out[key] = { read = types.newfunction(renamed:parameters(), renamed:returns(), generics) }
			end
		end
	end
	return types.newtable(out)
end

-- 값에 타입 토큰을 싣는 필드 이름. 모듈들은 이 문자열을 **리터럴로** 다시 적습니다 — 이 값을 받아 쓰면 상수 접기가 안 돼
-- 생성이 7~11% 느렸습니다(perf 21절).
const TYPE_KEY = "__type"

const records = Registry.records
const isToken = Registry.isToken
const RESERVED: { [string]: boolean } = table.freeze(
	{ Of = true, OfMut = true, ImplOf = true, ImplFor = true, ImplWhere = true, FnTok = true } :: { [string]: boolean }
)
const FN_MARK = table.freeze({})
const FN_MUT_MARK = table.freeze({})
const DEFAULT_MARK = table.freeze({})
const MUT_MARK = table.freeze({})

--[[ 토큰 ]]

-- 새 타입 토큰. 이름은 유일 — 라이브러리 것은 `Stl.`, 바깥 것은 자기 이름공간(`MyLib.Thing`).
const function NewToken<N>(name: N & string): Token<N>
	if type(name) ~= "string" then
		Errors.tokenName(name)
	end
	if Registry.byName[name] ~= nil then
		Errors.tokenTaken(name)
	end
	const token = table.freeze({ name = name })
	-- 묶음으로: "모든 종류" 뭉텅이를 이 종류에 짓다 던지면 토큰도 남지 않음(같은 이름으로 다시 만들 수 있음)
	Build.transact(function()
		Registry.byName[name] = token
		isToken[token] = true
		table.insert(Registry.tokens, token)
		Build.note(function()
			Registry.byName[name] = nil
			isToken[token] = nil
			const at = table.find(Registry.tokens, token)
			if at ~= nil then
				table.remove(Registry.tokens, at)
			end
		end)
		Build.onToken(token)
	end)
	return token :: any
end

-- 값의 타입 토큰. 테이블이 아니거나, `__type` 이 없거나 이 사본의 토큰이 아니면 nil. 봉인한 종류(`stl.Arr` — 질문 BB)를 넘기면 그 종류의 토큰.
const function TokenOf(value: any): Token<string>?
	if type(value) ~= "table" then
		return nil
	end
	const kindTok = Registry.kindToken[value]
	if kindTok ~= nil then
		return kindTok
	end
	const token = rawget(value, TYPE_KEY)
	return if isToken[token] then token :: any else nil
end

-- 값에 타입 토큰을 붙입니다(사용자 컨테이너의 생성자용 — 라이브러리 모듈은 `"__type"` 리터럴로 직접).
const function Stamp<T>(value: T, token: AnyToken): T
	if not isToken[token] then
		Errors.notToken("Stamp", token)
	end
	if type(value) ~= "table" or table.isfrozen(value :: any) then
		Errors.stampBad(value)
	end
	(value :: any)[TYPE_KEY] = token
	return value
end

-- 직렬화로 복사된 값(과 그 안의 테이블들)의 `__type` 을 **이름으로** 이 사본의 진짜 토큰으로 되돌립니다. 이름이 이 사본에 없는
-- 것은 그대로 둡니다. 돌아 물린 테이블도 됩니다.
-- 걷기는 명시적 스택으로 — 재귀로 걸었더니 되읽은 LinkedDeque 5만 개(노드가 사슬)에서 stack overflow 였습니다(리뷰 1라운드).
const function Restore<T>(value: T): T
	const seen: { [any]: true } = {}
	const stack: { any } = { value }
	local top = 1
	while top > 0 do
		const node = stack[top]
		stack[top] = nil
		top -= 1
		if type(node) == "table" and not seen[node] then
			seen[node] = true
			const raw = rawget(node, TYPE_KEY)
			if type(raw) == "table" and not isToken[raw] then
				const tokenName = rawget(raw :: any, "name")
				const real = if type(tokenName) == "string" then Registry.byName[tokenName] else nil
				if real ~= nil and not table.isfrozen(node) then
					rawset(node, TYPE_KEY, real)
				end
			end
			-- raw 로 걸음(`rawget` 으로 읽는 `__type` 과 같게 — 사용자 `__iter` 를 부르지 않음, 2라운드 참고)
			for key, child in next, node do
				if key ~= TYPE_KEY and type(child) == "table" and not seen[child] then
					top += 1
					stack[top] = child
				end
			end
		end
	end
	return value
end

--[[ 종류 = 닫힌 트레이트(2026-10-15 질문 BB — 사용자: *"Arr 조차 Trait 이여야 하는거 아닌가 … rust 처럼 익명 trait? struct Arr impl Arr {}"*) ]]
-- 종류마다 **그 종류 하나만 구현하는 닫힌 트레이트**. 다른 곳에서 구현될 일이 없어 `ImplFor`·`ImplWhere` 가 없고, 한 번 봉인하면 끝입니다.
-- 모듈 맨 위에서 `Trait.Struct(이름)`(토큰도 같이 — `NewToken` 자리), 맨 끝에서 `Kind.Seal(모듈 표)` — **그 표가 곧 종류의 정체이자 닫힌
-- 트레이트**입니다(`stl.Arr`). 그래서 쓰는 쪽은 토큰을 만지지 않습니다: `Stack.ImplFor(stl.Arr, impl)`, `Trait.Converter(stl.Arr)`(아래로),
-- `Trait.Implements(stl.Arr, v)`. 함수는 그 자리 그대로(직접 호출 — 닫혀 있으니 구현을 찾을 일이 없음).
-- 토큰은 라이브러리 안쪽에서만(생성자가 `__type` 에 찍는 상수 — `Kind.Token`).
export type Kind<N> = {
	read Token: Token<N>,
	read Seal: <M>(module: M) -> M,
}
const kindToken = Registry.kindToken
const function Struct<N>(name: N & string): Kind<N>
	const token = NewToken(name)
	local sealed = false
	const function Seal(module: any): any
		if sealed then
			Errors.structSealed(name)
		end
		if type(module) ~= "table" or records[module] ~= nil or kindToken[module] ~= nil then
			Errors.structBad(name, module)
		end
		sealed = true
		kindToken[module] = token
		-- 닫힌 트레이트의 기록: 구현은 그 종류 하나(완성 표 = 모듈 표 자체). 뭉텅이·다시 짓기에 끼지 않음(`Registry.traits` 에 안 넣음)
		records[module] = {
			name = name,
			fnNames = {},
			fnTok = {},
			impls = { [token] = module },
			required = {},
			builders = {},
			explicit = {},
			blankets = {},
			dependents = {},
			dependentSet = {},
		}
		return module
	end
	return table.freeze({ Token = token, Seal = Seal }) :: any
end
-- 종류 자리에 봉인한 종류(모듈 표)를 넘겨도 되게: 토큰이면 그대로, 종류면 그 토큰
const function asToken(kind: any): any
	return kindToken[kind] or kind
end

--[[ 트레이트 ]]

-- 필수 함수의 칸: 런타임엔 표식, 타입은 레코드(`View` 가 보기마다 `fn` 으로). `Fn` 은 읽기(Rust 의 `&self`), `FnMut` 은 쓰기
-- (`&mut self` — 읽기 보기 `X.Of` 에 없음).
const function Fn<F>(): { required: true, mut: false, fn: F }
	return FN_MARK :: any
end
const function FnMut<F>(): { required: true, mut: true, fn: F }
	return FN_MUT_MARK :: any
end
-- 기본 구현의 칸: 빌더(그 종류의 완성 표 `ops` 를 받아 함수를 돌려줌). 타입은 레코드 — `View` 가 완성 보기에서는 빌더가 돌려주는
-- 함수, 등록 보기에서는 그 함수의 선택 칸으로. `DefaultMut` 은 쓰기 칸.
-- 둘째 인자(선택): **부르는 쪽 서명** `Trait.Sig<<…>>()` — 등록 표의 칸 타입(구현하는 쪽)과 진입점 서명(부르는 쪽)이 다를 때
-- (`List.Some` 의 술어: 구현은 `(E, I, ...any)` 를 받을 수 있어야 하고, 부르는 쪽은 꼬리 없는 `(E, I) -> boolean` 변수를 넘길 수 있어야 함).
const function Default<F, G>(build: (ops: any) -> F, sig: { read sig: G }?): { required: false, mut: false, fn: F, entry: G }
	return table.freeze({ [DEFAULT_MARK] = build }) :: any
end
const function DefaultMut<F, G>(
	build: (ops: any) -> F,
	sig: { read sig: G }?
): { required: false, mut: true, fn: F, entry: G }
	return table.freeze({ [DEFAULT_MARK] = build, [MUT_MARK] = true }) :: any
end
const function Sig<G>(): { read sig: G }
	return nil :: any
end

-- "모든 종류" 의 뭉텅이 구현을 밝혀 적는 표식. 빈 목록(`{}`)을 그 뜻으로 받았더니 의존 이름의 오타(`{ traits.Dequ }` = `{ nil }`, 길이 0)가
-- 조용히 모든 종류가 됐습니다(2026-10-15 리뷰 1라운드 참고 7 → 사용자: *"런타임 검사로 두는거 확인"*). 이제 빈 목록은 에러.
const Any: AnyKind = table.freeze({}) :: any

-- 등록(아래 `Trait` 가 트레이트 객체의 `ImplFor`·`ImplWhere` 로 붙임)
local implFor: (trait: any, token: any, impl: any) -> ()
local implWhere: (trait: any, deps: any, build: any) -> ()

-- 트레이트 `Trait.Trait(이름, 정의)`. 런타임은 정의를 한 번(of = nil) 불러 칸 이름을 얻습니다.
const function newTrait(name: string, def: any): any
	if type(name) ~= "string" then
		Errors.traitName(name)
	end
	local fns: any = def
	if type(fns) == "function" then
		const make = fns :: (any) -> any
		fns = make(nil)
	end
	if type(fns) ~= "table" then
		Errors.badFns(name)
	end
	const fnNames: { string } = {}
	const required: { [string]: true } = {}
	const builders: { [string]: (ops: any) -> any } = {}
	const mutable: { [string]: true } = {}
	for fnName, mark in fns :: any do
		if type(fnName) ~= "string" then
			Errors.badFns(name)
		end
		if RESERVED[fnName] then
			Errors.reserved(name, fnName)
		end
		if mark == FN_MARK or mark == FN_MUT_MARK then
			required[fnName] = true
			if mark == FN_MUT_MARK then
				mutable[fnName] = true
			end
		elseif type(mark) == "table" and type(rawget(mark, DEFAULT_MARK)) == "function" then
			builders[fnName] = rawget(mark, DEFAULT_MARK) :: any
			if rawget(mark, MUT_MARK) == true then
				mutable[fnName] = true
			end
		else
			Errors.badFns(name)
		end
		table.insert(fnNames, fnName)
	end
	table.sort(fnNames)
	const fnTok: { [string]: number } = {}
	for at, fnName in fnNames do
		fnTok[fnName] = at
	end
	const trait: any = { FnTok = table.freeze(fnTok) }
	const impls: { [any]: any } = {}
	for at, fnName in fnNames do
		trait[fnName] = Entry.make(impls, name, fnName, at)
	end
	trait.Of = function(x: any): any
		const full = if isToken[x] then impls[x] elseif type(x) == "table" then impls[rawget(x, TYPE_KEY)] else nil
		if full == nil then
			return if isToken[x] then Errors.notImplemented(name, x) else Errors.entryMiss(name, "Of", x)
		end
		return full
	end
	trait.OfMut = trait.Of
	trait.ImplOf = trait.Of
	trait.ImplFor = function(token: any, impl: any)
		implFor(trait, token, impl)
	end
	trait.ImplWhere = function(deps: any, build: any)
		implWhere(trait, deps, build)
	end
	records[trait] = {
		name = name,
		fnNames = fnNames,
		fnTok = fnTok,
		impls = impls,
		required = required,
		builders = builders,
		mutable = mutable,
		explicit = {},
		blankets = {},
		dependents = {},
		dependentSet = {},
	}
	table.insert(Registry.traits, trait)
	return trait
end

-- 종류 하나의 구현. 같은 (트레이트, 토큰) 을 두 번 명시 등록하면 에러(덮어쓰기를 허용하면 내장 구현이 전역으로 조용히 바뀜).
-- 뭉텅이 구현으로 따라온 것 위에는 등록할 수 있습니다(빠른 판을 나중에 얹는 길 — 같은 표를 다시 짓고 위로 번짐).
function implFor(trait: any, kind: any, impl: any)
	const token = asToken(kind)
	const rec = records[trait]
	if not isToken[token] then
		Errors.notToken(`{rec.name}.ImplFor`, token)
	end
	if type(impl) ~= "table" then
		Errors.implNotTable(rec.name, impl)
	end
	Build.transact(function()
		Build.onFor(trait, token, impl)
	end)
end

function implWhere(trait: any, deps: any, build: any)
	const rec = records[trait]
	if deps ~= Any and (type(deps) ~= "table" or rawlen(deps) == 0) then
		Errors.emptyWhere(rec.name)
	end
	if type(build) ~= "function" then
		Errors.builderNotFunction(rec.name, build)
	end
	-- 숫자 루프로 읽어 사본으로(넘긴 목록을 나중에 고쳐도 그대로). 빈 칸(오타 난 이름 = nil)은 길이 안이면 에러. ⚠️ **끝의** 오타
	-- (`{ Deque, Typo }` = `{ Deque }`)는 길이에 안 잡혀 런타임이 못 봅니다(조건이 넓어짐) — `--!strict` 의 타입이 잡음.
	const list: { any } = {}
	for at = 1, if deps == Any then 0 else rawlen(deps) do
		const dep = rawget(deps, at)
		if records[dep] == nil then
			Errors.notTrait(`{rec.name}.ImplWhere`, dep)
		end
		list[at] = dep
	end
	-- 의존 고리는 등록 줄에서 거절: 의존 중 하나가 뭉텅이 구현을 따라 이 트레이트에 닿으면(자기 자신 포함) 명시 구현이 뭉텅이를
	-- 덮을 때마다 다시 짓기가 서로를 끝없이 불러 라이브러리 줄의 stack overflow 였습니다(2026-10-15 리뷰 1라운드).
	const seen: { [any]: true } = {}
	local function reaches(from: any): boolean
		if from == trait then
			return true
		end
		if seen[from] then
			return false
		end
		seen[from] = true
		const blankets = records[from].blankets
		for b = 1, #blankets do
			const bdeps = blankets[b].deps
			for at = 1, #bdeps do
				if reaches(bdeps[at]) then
					return true
				end
			end
		end
		return false
	end
	-- "모든 종류" 뭉텅이와 다른 뭉텅이는 같은 트레이트에 함께 둘 수 없음: 다른 뭉텅이의 조건을 갖춘 종류마다 **반드시** 겹치니(명시
	-- 구현이 이기면 그 뭉텅이는 결코 안 쓰임) 등록 줄에서 거절. 예전엔 조건을 갖춘 첫 종류가 생길 때 무관한 줄에서 겹침 에러가 났고,
	-- Any 의 번짐에서 드러나면 그 뒤 모든 `NewToken` 이 던졌습니다(2026-10-15 리뷰 3라운드).
	const blankets = rec.blankets
	for b = 1, #blankets do
		if #list == 0 or #blankets[b].deps == 0 then
			Errors.anyOverlap(rec.name, #list == 0)
		end
	end
	for at = 1, #list do
		if reaches(list[at]) then
			Errors.whereCycle(rec.name, records[list[at]].name)
		end
	end
	Build.transact(function()
		Build.onWhere(trait, { deps = list, build = build })
	end)
end

type TraitFn = <F>(name: string, def: F) -> Object<View<F, "read">, View<F, "full">, View<F, "impl">> & Entries<F>
const Trait: TraitFn = newTrait :: any

--[[ 조회 — 종류를 모르는 코드, 트레이트 파일이 씀 ]]

-- 값의 종류가 `trait` 를 구현하면 그 완성 표, 아니면 nil.
const function ImplOf(trait: any, value: any): any
	if records[trait] == nil then
		Errors.notTrait("ImplOf", trait)
	end
	const token = TokenOf(value)
	return if token == nil then nil else records[trait].impls[token]
end

const function Implements(trait: any, value: any): boolean
	if records[trait] == nil then
		Errors.notTrait("Implements", trait)
	end
	const token = TokenOf(value)
	return token ~= nil and records[trait].impls[token] ~= nil
end

-- 값의 종류가 구현한 `trait` 의 완성 표. 없으면 **사용자 줄 에러**(`"Map: Arr.GroupBy needs a Map — …"`). 트레이트 인자를 검사하지
-- 않습니다(라이브러리 안에서 자기 트레이트를 넘기는 자리 — 호출당 조회 하나).
const function ExpectImpl(trait: any, value: any, who: string): any
	const rec = records[trait]
	const impl = if type(value) == "table" then rec.impls[rawget(value, TYPE_KEY)] else nil
	if impl == nil then
		return Errors.entryMiss(rec.name, who, value)
	end
	return impl
end

-- ⭐ **중간자**(질문 BA — 사용자: *"a to b 계약자가 두 점이 확실한지 보게 하는게 나을듯"*): 바깥에서 등록한 트레이트를 타입에 붙이는 변환자.
-- 등록(런타임)은 타입을 못 바꾸니, 그 쌍을 아는 쪽이 **타입을 적어** 씁니다 — 위로(종류 → 트레이트)와 아래로(트레이트 → 종류) 둘 다 같은 함수:
--   const asStack: <T>(a: Arr<T>) -> stl.Stack<T> = Trait.Converter(stl.Stack, Arr.Token)
--   const asArr: <T>(s: stl.Stack<T>) -> Arr<T> = Trait.Converter(stl.Stack, Arr.Token)
-- 두 점을 봅니다: **`token` 이 `trait` 를 구현하는가는 만들 때 한 번**(등록은 되돌릴 수 없음 — 그러니 등록 뒤에 만드세요), **값이 `token` 의
-- 종류인가는 부를 때마다**(아니면 사용자 줄 에러). 값을 그대로 돌려줍니다(감싸지 않음 — 데이터는 엔티티). 호출당 13~20ns(perf 55절) — 값
-- 하나에 한 번이면 됩니다(바꾼 변수를 쥐고 쓰기). ⚠️ 타입 주석의 원소 대응(`Arr<T>` ↔ `Stack<T>` 의 `T`)은 적는 쪽의 책임입니다 — 시스템은
-- 종류와 등록만 봅니다.
-- 토큰을 빼면(`Trait.Converter(Stack)`) **그 트레이트를 구현한 종류면 무엇이든** — 부를 때마다 등록을 봅니다(트레이트에서 트레이트로:
-- `Deque.AsStack` — 덱이면 스택이지만 스택은 덱을 모르니, 덱 쪽이 이것으로 내줌).
const function Converter(trait: any, token: any?): (value: any) -> any
	const rec = records[trait]
	if rec == nil then
		Errors.notTrait("Converter", trait)
	end
	const traitName: string = rec.name
	if token == nil then
		const impls = rec.impls
		return function(value: any): any
			if type(value) ~= "table" or impls[rawget(value, TYPE_KEY)] == nil then
				return Errors.convertMismatch(traitName, nil, value)
			end
			return value
		end
	end
	token = asToken(token)
	if not isToken[token] then
		Errors.notToken(`{traitName}.Converter`, token)
	end
	if rec.impls[token] == nil then
		Errors.notImplemented(traitName, token)
	end
	const kindName: string = (token :: any).name
	return function(value: any): any
		if type(value) ~= "table" or rawget(value, TYPE_KEY) ~= token then
			return Errors.convertMismatch(traitName, kindName, value)
		end
		return value
	end
end

-- 그 트레이트의 `[토큰] = 완성 표` 표 — 트레이트 파일의 알고리즘 진입점이 구현 찾기를 펼칠 때(`impls[rawget(v, "__type")] or
-- ExpectImpl(…)` — perf 51절). 키는 토큰뿐이라 문자열 `__type` 은 "없음". ⚠️ 읽기만 — 고치면 시스템이 지은 표가 어긋납니다.
const function Impls(trait: any): { [any]: { [any]: any } }
	const rec = records[trait]
	if rec == nil then
		Errors.notTrait("Impls", trait)
	end
	return rec.impls
end

-- 트레이트 객체에 **알고리즘 진입점**(트레이트 함수가 아닌 것 — `Map.Keys` 처럼 구현을 써서 도는 함수)을 얹어 돌려줍니다.
-- 트레이트 함수·시스템 필드와 겹치는 이름은 에러(먼저 전부 검사하고 얹음 — 도중에 걸려 반쯤 얹힌 채 남지 않게).
const function Expose<T, E>(trait: T, entries: E): T & E
	const rec = records[trait]
	if rec == nil then
		Errors.notTrait("Expose", trait)
	end
	if type(entries) ~= "table" then
		Errors.exposeNotTable(entries)
	end
	for entryName in entries :: any do
		if type(entryName) ~= "string" or RESERVED[entryName] or rawget(trait :: any, entryName) ~= nil then
			Errors.exposeTaken(rec.name, entryName)
		end
	end
	for entryName, fn in entries :: any do
		(trait :: any)[entryName] = fn
	end
	return trait :: any
end

-- stylua: ignore
return {
	TYPE_KEY = TYPE_KEY,
	NewToken = NewToken, TokenOf = TokenOf, Stamp = Stamp, Restore = Restore,
	Struct = Struct, Trait = Trait, Fn = Fn, FnMut = FnMut, Default = Default, DefaultMut = DefaultMut, Sig = Sig, Any = Any,
	ImplOf = ImplOf, Implements = Implements, ExpectImpl = ExpectImpl, Expose = Expose, Impls = Impls, Converter = Converter,
}
