--!strict
--[[
	Optional — `nil` 구멍을 **값으로** 만드는 태그 테이블.

	## 왜 `T?` 로 안 되는가

	`T?` 는 테이블 안에서 **자리를 차지하지 못합니다.** 배열에 `nil` 을 넣으면
	"값이 없다" 가 아니라 "칸이 없다" 가 되어, `#` 와 `n` 이 어긋나고
	`table.sort` 가 조용히 잘리고 집계마다 구멍 검사가 붙습니다(`Arr` 의
	checked/unchecked 갈림이 그래서 있습니다).

	`Optional<T>` 는 그 칸을 **"없음이라는 값"** 으로 채웁니다.

	```lua
	local o = Optional.Present(3)     -- { isPresent = true, value = 3 }
	local x = Optional.Absent         -- { isPresent = false } (싱글턴)
	if o.isPresent then print(o.value) end   -- 여기서 value 가 number 로 좁혀짐
	```

	## 이름 — Java/Guava 계보

	`Present`/`Absent`, 태그 `isPresent`. Java 8+ `Optional.isPresent()`,
	Guava `Optional.absent()` 에서 옵니다. `Some`/`None` 을 피한 이유: quad 이
	`q.None` 을 **센티넬**(다른 뜻)로 쓰고 있어, `local None = …` 으로 풀어 쓰는
	순간 한 파일 안에서 부딪힙니다. 그리고 여기서 중요한 것은 "없음이라는 하나의
	값" 이 아니라 *데이터가 부재한다* 는 상태입니다.
	(`.claude/papers/02-optional.md`)

	## ⭐ 메소드가 없습니다 — 네임스페이스 함수입니다 (실측으로 강제됨)

	`o:UnwrapOr(0)` 이 아니라 `Optional.UnwrapOr(o, 0)` 입니다. 태그 유니온에
	메소드 교집합을 얹으면(컨테이너들과 같은 방식) 메소드의 `T` 가
	`number | nil` 로 잡혀 추론이 무너집니다(`spikes/45`). 덤으로 메타테이블이
	없으니 `.value` 읽기에 메타테이블 세금(1.59배)도 안 붙습니다.

	## ⚠️ 좁히기 함정 하나

	**같은 스코프에서 좁히기 전에 `o.value` 를 한 번이라도 읽으면**, 그 뒤
	`if o.isPresent then o.value` 가 좁혀지지 않습니다(Luau 새 솔버의 동작,
	`spikes/45`). `.value` 를 직접 읽기보다 `UnwrapOr`/`Unwrap` 을 쓰거나,
	좁힐 땐 새 지역 별칭(`local p = o`)을 쓰세요.
]]

export type Optional<T> = { isPresent: true, value: T } | { isPresent: false, value: nil }

-- 없음. **싱글턴**이고 동결돼 있습니다. `{ isPresent: false, value: nil }` 은
-- 모든 `Optional<T>` 의 한 갈래라 어느 자리에나 들어갑니다.
const Absent: { isPresent: false, value: nil } = table.freeze({ isPresent = false, value = nil }) :: any

-- 값이 있음. 호출마다 테이블 하나를 만듭니다(동결하지 않습니다 — 생성이
-- 잦은 자리라 `table.freeze` 호출을 아낍니다. 대신 **고치지 마세요**).
const function Present<T>(value: T): Optional<T>
	return { isPresent = true, value = value }
end

-- `T?` 에서 건너오는 문. `nil` 이면 `Absent`, 아니면 `Present(v)`.
-- ⚠️ 그래서 "값이 nil 인 Present" 는 이걸로 못 만듭니다 — 필요하면 `Present(nil)`.
const function Of<T>(value: T?): Optional<T>
	if value == nil then
		return Absent
	end
	return { isPresent = true, value = value :: T }
end

-- 값. **없으면 에러**입니다.
const function Unwrap<T>(o: Optional<T>): T
	if o.isPresent then
		return o.value
	end
	error("Optional: Unwrap called on Absent", 2)
end

-- 값, 없으면 `fallback`.
const function UnwrapOr<T>(o: Optional<T>, fallback: T): T
	if o.isPresent then
		return o.value
	end
	return fallback
end

-- 값이 있으면 변환하고, 없으면 `Absent` 그대로.
const function Map<T, G>(o: Optional<T>, fn: (value: T) -> G): Optional<G>
	if o.isPresent then
		return { isPresent = true, value = fn(o.value) }
	end
	return Absent
end

-- `T?` 로 나가는 문. 없으면 `nil`.
-- ⚠️ "값이 nil 인 Present" 와 `Absent` 가 여기서 둘 다 `nil` 이 됩니다.
const function ToNil<T>(o: Optional<T>): T?
	if o.isPresent then
		return o.value
	end
	return nil
end

-- 이 값이 Optional 인가.
-- ⚠️ **모양으로 판별합니다**(메타테이블이 없으므로). `isPresent` 가 불리언인
-- 아무 테이블이나 통과합니다 — 식별이 아니라 계약 확인입니다. `Absent` 도
-- 싱글턴 식별이 아니라 모양으로 봅니다: 리터럴 `{ isPresent = false }` 는 타입상
-- `Optional<T>` 이고 `UnwrapOr` 등도 그렇게 다루므로, 여기서만 거부하면
-- 어긋납니다(2026-09-30 리뷰).
const function isOptional(value: any): boolean
	return type(value) == "table" and type(rawget(value, "isPresent")) == "boolean"
end

return {
	Present = Present,
	Absent = Absent,
	Of = Of,
	Unwrap = Unwrap,
	UnwrapOr = UnwrapOr,
	Map = Map,
	ToNil = ToNil,
	isOptional = isOptional,
}
