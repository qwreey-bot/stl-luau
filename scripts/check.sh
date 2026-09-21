#!/usr/bin/env bash
# 타입 검사 + 테스트. quad 의 scripts/test.sh 를 따릅니다.
#
# 타입 검사기는 luau-lsp 가 아니라 **luau-analyze** 입니다 — 근거는
# .claude/base/typing-limits.md 의 "체커: luau-analyze" 절. 플래그가 필요
# 없습니다: new solver 가 기본이고, strict 여부는 .luaurc 와 각 파일 상단의
# --!strict 가 정합니다.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0

# tests 를 넣으면 require 로 src 도 같이 끌려와 같은 파일이 "src/arr.luau" 와
# "./src/arr.luau" 두 경로로 중복 보고됩니다. 정규화 후 중복을 지웁니다.
out=$(luau-analyze src tests 2>&1 | sed "s|^$PWD/||; s|^\./||" | sort -u)
[ -n "$out" ] && printf '%s\n' "$out"

echo
echo "=== 타입 진단 요약 (파일별 TypeError)"
printf '%s\n' "$out" | grep '): TypeError:' | grep -oE '^[^(]+' | sort | uniq -c
echo "총 $(printf '%s\n' "$out" | grep -c '): TypeError:')건"
# 타입 에러로 실패시키지 않습니다. Arr<T> 재설계(.claude/todos.md 1번) 전까지는
# 300건대가 정상이고, 여기서 게이트를 걸면 스크립트가 늘 빨간불이라 쓸모가
# 없어집니다. 이 스크립트는 그 숫자를 **재는** 도구이고, 게이트는 테스트입니다.

# ⭐ require 경로는 정적 검사가 못 잡는다 — @self 대신 ./ 를 쓰면 luau-analyze 는
# 진단 0건으로 통과하고 런타임에서만 크래시한다(quad qa-round5 PS-9, 자체 실측).
# 그래서 모든 모듈을 실제로 require 해본다. init.luau 를 새로 추가할 때 특히 중요.
echo
echo "=== require 게이트 (모든 src 모듈을 런타임에 불러봄)"
# 프로브는 저장소 루트에 둬야 ./src 가 올바르게 해석된다
req_probe=".check-require-probe.luau"
trap 'rm -f "$req_probe"' EXIT
req_fail=0
while IFS= read -r m; do
	[ -s "$m" ] || continue   # 빈 파일은 건너뜀
	rel="${m#src/}"; rel="${rel%.luau}"
	# init.luau 는 디렉터리 자신을 가리킨다: src/init.luau → ./src
	if [ "$rel" = "init" ]; then path="./src"; else path="./src/${rel%/init}"; fi
	printf 'require("%s")\nreturn true\n' "$path" > "$req_probe"
	if ! out=$(luau "$req_probe" 2>&1); then
		echo "  FAIL  $path"
		printf '        %s\n' "$(printf '%s' "$out" | head -1)"
		req_fail=1
	fi
done < <(find src -name "*.luau" | sort)
if [ "$req_fail" = "0" ]; then echo "  모든 모듈 require OK"; else fail=1; fi

echo
echo "=== luau tests/run.luau"
luau tests/run.luau || fail=1

exit "$fail"
