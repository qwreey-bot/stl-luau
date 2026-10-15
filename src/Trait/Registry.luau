--!strict
--[[
	Registry — 시스템이 기억하는 것 전부(강한 배열·표). 트레이트와 토큰은 **정의**라 버리지 않습니다(버리는 것은
	정의되지 않은 동작 — 2026-10-14 사용자 결정). 그래서 약한 테이블이 없고, 도는 것은 늘 숫자 루프입니다(약한 테이블을
	도는 중 GC 가 항목을 건너뛰던 결함이 원리적으로 없음).
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))

-- 트레이트 하나의 기록. 트레이트 객체(사용자가 쥐는 것)에는 진입점과 시스템 필드(`Of`·`FnTok` …)만 두고 나머지는 여기에.
-- 완성 표도 여기(`impls`) — 트레이트 객체에 `[토큰] = 완성 표` 로 두었더니 값의 `__type` 이 문자열이고 진입점 이름과 같으면
-- (`__type = "Get"`) 진입점 함수를 완성 표로 읽어 라이브러리 줄에서 죽었습니다(2026-10-15 리뷰 1라운드).
export type Blanket = { deps: { any }, build: (deps: { [any]: any }) -> { [string]: any } }
export type Record = {
	name: string,
	fnNames: { string }, -- 정렬한 이름(함수 번호 = 위치)
	fnTok: { [string]: number },
	impls: { [any]: { [any]: any } }, -- [토큰] = 완성 표(`{ [함수 번호] = f, 이름 = f }`). 키는 토큰뿐
	required: { [string]: true }, -- 필수 이름
	builders: { [string]: (ops: any) -> any }, -- [기본 구현 이름] = 빌더(그 종류의 완성 표를 받아 함수를 돌려줌)
	explicit: { [any]: { [string]: any } }, -- [토큰] = For 로 넘긴 표의 사본
	blankets: { Blanket }, -- Where 로 등록한 뭉텅이 구현
	dependents: { any }, -- 나를 Where 에 적은 트레이트들(표식)
	dependentSet: { [any]: true },
}

const Registry = {
	tokens = {} :: { any }, -- 만든 순서
	byName = {} :: { [string]: any }, -- 이름 → 진짜 토큰(직렬화 뒤 되찾기)
	isToken = {} :: { [any]: true },
	traits = {} :: { any },
	records = {} :: { [any]: Record },
}

return Registry
