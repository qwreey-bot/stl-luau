--!strict
--[[
	전체 테스트 엔트리.

	실행: luau tests/run.luau
	개별 파일만 돌리려면: luau tests/arr.luau

	각 테스트 파일은 require 되는 시점에 자기 검사를 수행하고, 실패하면
	assert 가 그 자리에서 터져 luau 가 exit 1 로 종료합니다. 별도 러너나
	집계 로직은 두지 않습니다 (.claude/base/architecture.md 의
	"테스트: assert + print" 절 참고).

	새 테스트 파일을 추가하면 아래 목록에도 반드시 넣으세요. require 대상은
	항상 문자열 리터럴로 적습니다 — 동적 경로는 luau 의 require-by-string 이
	해석하지 못합니다.

	이 파일의 이름을 init.luau 로 바꾸지 마세요 — luau 는 init.luau 를
	디렉터리 인덱스 모듈로 특별 취급해서 require 가 모호해집니다.
]]

require("./spec.arr-old")

print()
print("=== ALL SUITES PASS ===")
