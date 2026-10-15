#!/usr/bin/env bash
# 편집기 조건 검사 — 게이트(check.sh)가 아닙니다. 사용자가 실제로 보는 검사기로 src 와 음성 대조군 배터리를 봅니다.
#
# 왜(2026-10-15): 게이트는 luau 배포판의 `luau-analyze`(mise.toml 의 버전 — 지금 0.742)로 돌지만, 사용자는 luau-lsp(최신 1.70.1 =
# Luau 0.740)와 Roblox Studio 로 봅니다. Studio 의 타입 검사는 luau-lsp 와 같고 환경 타입만 다릅니다(사용자 — quad 의 실측: 에러 포맷·
# 번호까지 같음). 그래서 **luau-lsp + Studio 의 지금 FFlag** 가 사용자 쪽 조건입니다. 이 조건으로 처음 돌렸을 때 게이트가 못 본 라이브러리
# 줄 에러 31건이 나왔습니다(`src/Trait/Build.luau` — 0.740 의 `setmetatable` 타입).
#
# 쓰는 법: ./scripts/editor-check.sh [luau-lsp 경로]
#   - FFlag 는 Roblox clientsettings 에서 받습니다(luau-lsp 의 편집기 기본 동작과 같은 출처). 못 받으면 FFlag 없이 돌고 그렇다고 알림.
#   - 이 luau-lsp 가 모르는 FFlag(이미 졸업했거나 더 새 것)는 걸러 냅니다.
#   - 결과는 차이만 보여 줍니다. 알려진 차이(아래 KNOWN)는 따로 표시 — 0.742 에서 고쳐진 솔버 결함이라 게이트와 다른 것.
# 메모리·시간 상한을 겁니다(conventions — luau 실행의 자원 상한).
set -u
cd "$(dirname "$0")/.." || exit 2
LSP=${1:-$(command -v luau-lsp || true)}
if [ -z "$LSP" ] || [ ! -x "$LSP" ]; then
	echo "luau-lsp 를 찾지 못했습니다 — 경로를 인자로 주세요(예: mise 의 github-johnny-morganz-luau-lsp 설치 디렉터리)"
	exit 2
fi
echo "=== 편집기 조건: $("$LSP" --version 2>&1 | head -1) + Studio FFlag"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
flags=()
if curl -s --max-time 20 https://clientsettingscdn.roblox.com/v2/settings/application/PCStudioApp -o "$tmp/studio.json" &&
	command -v jq > /dev/null; then
	jq -r '.applicationSettings | to_entries[] | select(.key|test("^(D?FFlag|D?FInt)Luau")) | "\(.key|sub("^D?(FFlag|FInt)";""))=\(.value)"' \
		"$tmp/studio.json" | sed 's/=True$/=true/;s/=False$/=false/' > "$tmp/all.txt"
	# 이 luau-lsp 가 모르는 이름을 걸러 냄(모르는 FFlag 가 하나라도 있으면 검사를 하지 않고 이름만 늘어놓음)
	probe=$(mapfile -t a < "$tmp/all.txt"; ( ulimit -v 4194304; timeout 120 "$LSP" analyze --platform standard --no-flags-enabled \
		"${a[@]/#/--flag:}" src/Types.luau 2>&1 ))
	printf '%s\n' "$probe" | grep -oE "Unknown FFlag: [A-Za-z0-9_]+" | awk '{print $3"="}' | sort -u > "$tmp/unknown.txt"
	grep -v -F -f "$tmp/unknown.txt" "$tmp/all.txt" > "$tmp/known.txt" || true
	mapfile -t known < "$tmp/known.txt"
	flags=("${known[@]/#/--flag:}")
	echo "  Studio FFlag $(wc -l < "$tmp/known.txt")개 적용(모르는 것 $(wc -l < "$tmp/unknown.txt")개 거름)"
else
	echo "  ⚠️ Studio FFlag 를 못 받음 — FFlag 없이 돕니다(결과가 Studio 와 다를 수 있음)"
fi
run() {
	( ulimit -v 4194304; timeout 300 "$LSP" analyze --platform standard --no-flags-enabled "${flags[@]}" \
		--flag:LuauSolverV2=true "$@" 2>&1 )
}
# 0.742 에서 고쳐진 솔버 결함 때문에 게이트와 다른 것(편집기가 Luau 0.742 이상을 실으면 지울 것)
KNOWN=".claude/audit/arr-type-redesign/spikes/57-bare-lambda-free-type.luau"
fail=0
echo
echo "--- src (라이브러리 파일 — 사용자의 Studio 에 그대로 뜸)"
src_err=$(run src | grep -E "TypeError" || true)
if [ -n "$src_err" ]; then
	printf '%s\n' "$src_err" | head -20
	fail=1
else
	echo "  0건"
fi
echo
echo "--- 음성 대조군 배터리(scripts/spike-expectations.tsv 와 같은 줄인가)"
same=0
while IFS=$'\t' read -r want path lines || [ -n "$want" ]; do
	[[ $want =~ ^[[:space:]]*(#|$) ]] && continue
	path=${path%"${path##*[![:space:]]}"}
	lines=${lines//[[:space:]]/}
	base=$(basename "$path")
	got=$(run "$path" | grep -oE "(^|/)${base//./\\.}\([0-9]+,[0-9]+\): TypeError: " |
		sed -E 's/.*\(([0-9]+),.*/\1/' | sort -n | paste -sd, -)
	if [ "$got" == "$lines" ]; then
		same=$((same + 1))
	elif [[ " $KNOWN " == *" $path "* ]]; then
		echo "  알려진 차이  $path"
	else
		echo "  DIFF  $path"
		echo "        게이트: $lines"
		echo "        편집기: $got"
		fail=1
	fi
done < scripts/spike-expectations.tsv
echo "  같은 줄: $same"
exit $fail
