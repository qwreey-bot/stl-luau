--!strict
--[[
	Entry — 종류를 모르는 코드의 진입점을 **시스템이 만듭니다**(2026-10-14 사용자: *"그걸 래핑하는 함수 자체를 Trait 시스템
	단에서 만들어주는게 맞다고 보이는듯"*). 트레이트의 함수마다 하나: 값의 토큰으로 완성 표를 찾고 **함수 번호**로 꺼내
	가변인자를 그대로 넘깁니다. 함수 번호는 여기서만 씁니다(이름 조회는 상수가 아니라 해시를 다시 찾음 — perf 53절).
	값: 손으로 쓴 진입점보다 호출당 +3.5ns 안팎(가변인자 1.5~2ns + 닫힌 값 읽기).
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Errors = require("./Errors")

const Entry = {}

function Entry.make(trait: any, traitName: string, fnName: string, fnNum: number): (...any) -> ...any
	const entryMiss = Errors.entryMiss
	return function(self: any, ...: any): ...any
		const impl = if type(self) == "table" then trait[rawget(self, "__type")] else nil
		if impl == nil then
			return entryMiss(traitName, fnName, self)
		end
		return impl[fnNum](self, ...)
	end
end

return Entry
