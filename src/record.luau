--!strict
--[[
	record — 키·값 쌍.

	맵 계열 컨테이너가 항목을 표현할 때 씁니다. 재작성에서 `Types.Record` 로
	흡수될 후보입니다(`.claude/question.md` E 항목).
	지금은 require 가 가능하도록 타입을 export 하고 모듈 형태를 갖춥니다.
]]
export type Record<K, V> = { key: K, value: V }

return {}
