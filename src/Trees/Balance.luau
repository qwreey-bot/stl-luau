--!strict
--[[
	Balance — **자가 균형의 계약**(2층 트리부). 균형 방식(`RedBlack`·`Avl`)이 맞추는 모양과, 트리를 조립하는
	쪽이 받은 방식을 확인하는 `Expect`.

	예전에는 `Trees/Search` 안에 있었습니다(`Search.Balance`·`Search.ExpectBalance`). 찾기 조각과 균형 계약은
	다른 일이라 갈랐습니다(2026-10-13 이름 검토 — 넷이 전부 "찾기 모듈에 균형 계약이 얹혀 있다" 고 짚음).

	새 균형 방식은 `src/Trees/` 에 파일 하나 + 끝에 `const _balance: Balance.Scheme = Module` 한 줄입니다.
]]
local Types = require("../Types")
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))

type Comparator<T> = Types.Comparator<T>

-- ⭐ **자가 균형의 계약**(2026-10-13 사용자: *"자가균형 같은 경우는 Insert, Remove 를 계약으로 하나의 추상화를 둘 수
-- 있을법 … 트리 쓰는 곳에서 자가균형을 뭘로 할 지 default 가 있고, 직접 선택도 가능한 구조"*). `RedBlack`·`Avl`
-- 모듈이 그대로 이 모양입니다 — 트리를 조립하는 쪽은 이것 하나를 받아 쓰고(기본은 레드블랙), 바깥에서 만든 균형
-- 방식도 같은 모양이면 들어갑니다. 노드 타입은 방식마다 달라 여기서는 `any` 입니다 — 조립하는 쪽이 뿌리를
-- "그 방식의 노드" 로만 다루면 됩니다(읽을 때는 `Search.KeyNodeRead`).
-- - `Insert(root, key, value, compare)` → `(새 뿌리, 그 키의 노드, 새로 만들었나)`. 있던 키면 값만 바꿈.
-- - `Remove(root, node)` → 새 뿌리(비면 `nil`). `node` 는 그 트리의 노드, 떼어 낸 뒤 연결이 끊김.
-- - `Join(left, mid, right)` → 두 트리(뿌리, 비었으면 `nil`)와 가운데 노드를 이은 새 뿌리. 키는 `left` < `mid` < `right`
--   여야 하고(검사 안 함), O(log n) 안에 끝나야 합니다(높이 차만큼이면 가장 좋음). 부분을 떼어 내는 `Split` 이 이것 위에 섭니다
--   (2026-10-14 사용자: *"부분형으로 뭐보다 크거나 작은 영역을 때어 트리로"*, *"만들어보자"*).
-- - `AsRoot(node)` → 부모에서 떼어 낸 **부분 트리의 뿌리**(없으면 `nil`)를 홀로 선 트리의 뿌리로 만들어 그대로 돌려줌.
--   레드블랙은 뿌리를 검정으로 칠하고, AVL 은 할 일이 없음(높이는 부분 트리마다 이미 맞음).
-- - `FromSorted(keys, values, count)` → 정렬된 목록에서 O(n) 으로 지은 뿌리. `Clone(root)` → 구조째 베낀 뿌리.
-- 바깥에서 만드는 방식의 노드는 **탐색 트리 노드의 칸 배치**(`Trees/Search` 머리)를 따라야 합니다(조립하는 쪽이 값·왼쪽·오른쪽·부모·키 칸 — `1`~`5` — 을
-- 직접 읽음).
-- ⚠️ **인자는 `never`, 반환은 `unknown` 으로 적습니다**(2라운드 리뷰). 인자와 반환을 전부 `any` 로 적었던 때는 반환 수·
-- 반환 타입·인자 수가 다른 함수가 0건으로 들어갔습니다(어느 `any` 가 어느 것을 푸는지는 함수마다 다름 — 3라운드 실측) — `Insert` 가 셋째 반환을 안 주는 방식, `Remove` 가 새 뿌리를
-- 안 돌려주는 방식, 함수가 하나 빠진 모듈, 심지어 `Search` 모듈까지(파라미터가 `any` 인 함수 타입 자리는 Luau 가
-- 서명을 견주지 않음). `never` 인자는 "무엇을 받든 됨"(어떤 노드 타입의 함수든 들어옴), `unknown` 반환은 "무엇을
-- 주든 되지만 **줘야 함**" 입니다. 대신 이 타입으로는 부를 수 없어, 조립하는 쪽은 `(scheme :: any).Insert(…)` 로
-- 부릅니다(`TreeMap`). 음성 대조군은 `spikes/67`. 남는 경계: 반환을 **`any` 로 적은** 함수는 반환 수가 달라도
-- 통과합니다(`any` 는 무엇에든 맞음) — 노드 타입을 적은 방식이면 잡힙니다.
export type Scheme = {
	read Insert: (root: never, key: never, value: never, compare: never) -> (unknown, unknown, boolean),
	read Remove: (root: never, node: never) -> unknown,
	read Join: (left: never, mid: never, right: never) -> unknown,
	read AsRoot: (node: never) -> unknown,
	read FromSorted: (keys: never, values: never, count: number) -> unknown,
	read Clone: (root: never) -> unknown,
}

-- 균형 방식 인자를 확인해 돌려줍니다(`nil` 이면 `fallback`). 트리를 조립하는 쪽의 생성자가 씁니다 — 엉뚱한 값
-- (`"avl"`, 다른 모듈)이 생성 때는 통과하고 첫 넣기에서 라이브러리 줄의 `attempt to call a nil value` 였습니다
-- (2026-10-13 리뷰). 함수 여섯이 있는지만 봅니다(서명은 타입의 몫). `who` 는 메시지 머리(`"TreeMap: New"`).
const function Expect(balance: any, fallback: Scheme, who: string): Scheme
	if balance == nil then
		return fallback
	end
	if
		type(balance) ~= "table"
		or type(rawget(balance, "Insert")) ~= "function"
		or type(rawget(balance, "Remove")) ~= "function"
		or type(rawget(balance, "Join")) ~= "function"
		or type(rawget(balance, "AsRoot")) ~= "function"
		or type(rawget(balance, "FromSorted")) ~= "function"
		or type(rawget(balance, "Clone")) ~= "function"
	then
		Common.raise(
			`{who} needs a balance scheme with Insert, Remove, Join, AsRoot, FromSorted and Clone (RedBlack, Avl, …), got {typeof(
				balance
			)}`
		)
	end
	return balance
end

-- ⭐ **부분을 떼어 냅니다**: 트리를 `key` 보다 작은 키들의 트리, 키가 `key` 인 노드(없으면 `nil`), 큰 키들의 트리로
-- 가릅니다 — `(작은 쪽 뿌리, 그 노드, 큰 쪽 뿌리)`. **원래 트리는 없어집니다**(노드를 새로 만들지 않고 다시 이음 —
-- 쥐고 있던 노드는 살아 있고 둘 중 한 트리에 속함). 뿌리에서 `key` 쪽으로 내려가며 **비교를 먼저 다 하고**, 올라오며
-- 떼고 방식의 `Join` 으로 다시 잇습니다 — 비교는 높이만큼(O(log n)), 잇기는 방식의 `Join` 값만큼(AVL 은 다 합쳐
-- O(log n), 레드블랙은 잇기마다 검정 높이를 세어 O(log² n) — 10만 개에서 4~7.5 μs, perf 49절).
-- 균형 방식마다 따로 쓰지 않습니다 — `Join`·`AsRoot` 만 주면 됩니다.
-- 돌려준 가운데 노드는 연결이 끊긴 노드입니다(어느 쪽에 붙이려면 `Join(nil, 노드, 큰 쪽)` 처럼).
-- 받은 뿌리의 타입 그대로 돌려줍니다(레드블랙 노드를 넣으면 레드블랙 노드 셋). 방식과 노드의 종류가 맞는지는
-- 타입이 못 봅니다(계약이 노드 타입을 모름) — 그 트리를 만든 방식을 넘기세요.
-- 비교자가 던지면: 고치기 전에 비교가 다 끝나므로 **트리는 그대로**입니다(관측 — 계약은 아님. 예전엔 떼어 낸 뒤에
-- 견줘서 첫 비교에서 던져도 조각났습니다, 5라운드 리뷰).
const LEFT, RIGHT, PARENT, KEY = 2, 3, 4, 5
const function Split<N, K>(
	scheme: Scheme,
	root: (N & { read __links: "binary", read __key: K })?,
	key: K,
	compare: Comparator<K>
): (N?, N?, N?)
	const join: (any, any, any) -> any = (scheme :: any).Join
	const asRoot: (any) -> any = (scheme :: any).AsRoot
	const function split(node: any): (any, any, any)
		if node == nil then
			return nil, nil, nil
		end
		-- 이 층의 비교가 이 층의 어떤 고치기보다도 먼저입니다(아래 층도 같으니, 비교가 전부 끝난 뒤에야 고치기 시작)
		const order = compare(key, node[KEY])
		if order == 0 then
			const left, right = node[LEFT], node[RIGHT]
			node[LEFT] = nil
			node[RIGHT] = nil
			node[PARENT] = nil
			if left ~= nil then
				left[PARENT] = nil
			end
			if right ~= nil then
				right[PARENT] = nil
			end
			-- 잇기를 거치지 않고 나가는 부분 트리는 홀로 선 트리로(레드블랙: 뿌리가 빨강일 수 있음)
			return asRoot(left), node, asRoot(right)
		elseif order < 0 then
			-- 가를 자리는 왼쪽 안: 이 노드와 오른쪽은 통째로 큰 쪽
			const small, found, large = split(node[LEFT])
			const right = node[RIGHT]
			-- 가운데 노드는 "연결이 없는 노드" 로 넘깁니다(계약 — 내장 방식의 `Join` 은 두 자식 칸을 어차피 덮어쓰지만
			-- 바깥에서 만든 방식이 그 전제에 기댈 수 있음)
			node[LEFT] = nil
			node[RIGHT] = nil
			if right ~= nil then
				right[PARENT] = nil
			end
			return small, found, join(large, node, right)
		end
		const small, found, large = split(node[RIGHT])
		const left = node[LEFT]
		node[LEFT] = nil
		node[RIGHT] = nil
		if left ~= nil then
			left[PARENT] = nil
		end
		return join(left, node, small), found, large
	end
	return split(root)
end

-- stylua: ignore
return {
	Expect = Expect, Split = Split,
}
