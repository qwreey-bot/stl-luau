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
# ⭐ 총 건수 게이트. [2026-09-22 부터] 기준선은 **0건**입니다 — 재작성이
# 끝나 src-old 가 사라졌으므로 더 이상 "원래 그만큼 났다" 가 없습니다.
#
# 0건을 기준으로 삼는 게 안전한 이유: 이 저장소에서 0건은 원래 경보입니다
# (타입 검사가 통째로 죽어도 0건이 나옵니다). 그걸 아래 **음성 대조군
# 배터리**가 막아 줍니다 — 틀린 코드가 정말 틀리다고 나오는지 따로 세니,
# 0건이 "검사가 죽은 0건" 이 아니라 "정말 깨끗한 0건" 임이 보장됩니다.
# 둘은 같이 있어야 뜻이 있습니다.
total=$(printf '%s\n' "$out" | grep -c '): TypeError:')
if [ "$total" != "0" ]; then
	echo "  → TypeError 가 $total 건 있습니다. 기준선은 0건입니다."
	fail=1
fi

# ⭐ 음성 대조군 배터리 — 이 저장소에서 가장 중요한 게이트다.
# 진단 건수가 0 이 되는 것은 "타입이 완벽해졌다" 가 아니라 보통 "타입 검사가
# 죽었다" 는 뜻이다(2026-08-31 에 실제로 0/6 이었다). 스파이크마다 나와야 할
# 에러 개수를 고정해두고, 줄면 NEG 가 조용히 안 잡히기 시작한 것으로 본다.
echo
echo "=== 음성 대조군 배터리 (스파이크별 기대 진단 건수)"
spike_fail=0
spike_n=0
# 셋째 칸(선택)은 **에러가 난 줄 번호 목록**입니다(같은 줄 여러 건은 반복).
# 건수만 세면 한 NEG 가 사라진 자리에 다른 줄의 에러가 새로 생겨 **상쇄**될
# 수 있습니다 — 2026-09-30 리뷰가 실제로 21 → 21 상쇄를 재현했습니다.
while IFS=$'\t' read -r want path lines; do
	case "$want" in ''|\#*) continue ;; esac
	if [ ! -f "$path" ]; then
		echo "  MISSING  $path"
		spike_fail=1
		continue
	fi
	base=$(basename "$path")
	got_lines=$(luau-analyze "$path" 2>&1 |
		grep -oE "(^|/)${base//./\\.}\([0-9]+,[0-9]+\): TypeError: " |
		sed -E 's/.*\(([0-9]+),.*/\1/' | sort -n | paste -sd, -)
	got=$(if [ -z "$got_lines" ]; then echo 0; else echo "$got_lines" | tr ',' '\n' | wc -l | tr -d ' '; fi)
	spike_n=$((spike_n + 1))
	if [ "$got" != "$want" ]; then
		echo "  FAIL  $path"
		echo "        기대 $want 건, 실측 $got 건 (줄: ${got_lines:-없음})"
		spike_fail=1
	elif [ -n "$lines" ] && [ "$lines" != "$got_lines" ]; then
		echo "  FAIL  $path"
		echo "        건수는 같지만 에러 줄이 다릅니다 — NEG 가 사라진 자리를 다른 에러가 메웠을 수 있음"
		echo "        기대 줄: $lines"
		echo "        실측 줄: $got_lines"
		spike_fail=1
	fi
done < scripts/spike-expectations.tsv
if [ "$spike_fail" = "0" ]; then
	echo "  스파이크 $spike_n 개 전부 기대치와 일치"
else
	echo "  → 어느 NEG 가 사라졌는지 확인할 것. 기대치를 바꿨다면"
	echo "     scripts/spike-expectations.tsv 도 같이 고칠 것."
	fail=1
fi

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
	# init.luau 는 디렉터리 자신을 가리킨다: src/init.luau → ./src
	rel="${m%.luau}"; rel="${rel%/init}"; path="./$rel"
	printf 'require("%s")\nreturn true\n' "$path" > "$req_probe"
	if ! out=$(luau "$req_probe" 2>&1); then
		echo "  FAIL  $path"
		printf '        %s\n' "$(printf '%s' "$out" | head -1)"
		req_fail=1
	fi
done < <(find src -name "*.luau" | sort)
if [ "$req_fail" = "0" ]; then echo "  모든 모듈 require OK"; else fail=1; fi

echo
echo "=== 포맷 (stylua)"
if command -v stylua >/dev/null 2>&1; then
	if stylua --check src tests >/dev/null 2>&1; then
		echo "  포맷 OK"
	else
		echo "  FAIL  포맷이 어긋납니다. \`stylua src tests\` 로 맞추세요:"
		stylua --check src tests 2>&1 | grep '^Diff in' | sed 's/^/        /'
		fail=1
	fi
else
	echo "  건너뜀 — stylua 가 PATH 에 없습니다 (mise.toml 에 고정돼 있습니다)"
fi

echo
echo "=== luau tests/run.luau"
luau tests/run.luau || fail=1

exit "$fail"
