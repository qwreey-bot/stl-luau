#!/usr/bin/env bash
# agy-delegate.sh — Gemini(Antigravity CLI `agy`) 과제를 격리된 git worktree 에서 돌립니다.
#
#   agy-delegate.sh run <이름> <프롬프트 파일> [--model M] [--timeout 초]
#   agy-delegate.sh remove <이름>          # 메인 세션이 결과를 다 읽은 뒤
#   agy-delegate.sh list
#
# 왜(사용자, 2026-10-02 — quad 에서 먼저 도입, 같은 날 stl-luau 로 소급): 다른 모델 계열은
# 같은 코드를 다르게 봅니다(근본 원인, 틀 밖으로 튀어오르기, 같은 메커니즘의 발견 묶기). 대신
# flash 는 조작 실수가 **훨씬** 잦고 agy 하네스가 완고하지 않아 변경이 여기저기 튈 수 있으니,
# **읽기 전용 과제여도** 매번 자기 worktree 에서 돌립니다. 절차는 .claude/skills/delegate-agy.
#
# 격리(quad 의 2026-10-02 실측을 따름 — `agy --sandbox` 는 cwd 밖 쓰기를 막지 않았고 이
# 컨테이너에서 `unshare -m` 은 권한이 없음):
#   - worktree 는 /code/Projects/stl-luau-agy/<이름>, 브랜치 agy/<이름>(HEAD 에서);
#   - agy 는 권한 없는 uid 로 `setpriv` 실행. **quad 와 uid 를 나눕니다**(quad 61000, 여기
#     61001) — 한쪽 worktree 를 다른 쪽 과제가 고칠 수 없게. worktree 와 그 .git/worktrees/<이름>
#     만 이 uid 소유라 메인 작업 트리·다른 worktree·.git/objects 에는 못 씀 → 커밋 불가 → 새로
#     push 할 것도 없음. pre-push 훅(GIT_CONFIG_*)이 두 번째 줄로 push 를 거부;
#   - HOME 은 **과제마다 따로** /code/Projects/stl-luau-agy/.homes/<이름>, /code/.gemini(agy OAuth)를
#     새로 복사 — 하나를 공유하면 둘을 동시에 띄울 때 복사가 서로를 지워 한쪽이 시작도 못 했습니다
#     (2026-10-02, `cp: cannot create directory …/.gemini: File exists`);
#   - 실행 전후 메인 레포의 HEAD 와 `git status` 를 비교해 guard.txt 에 적음.
set -euo pipefail

ROOT=/code/Projects/stl-luau
BASE=/code/Projects/stl-luau-agy
HOMES=$BASE/.homes
HOOKS=$BASE/.hooks
AGY_UID=61001
AGY=/code/.local/share/mise/installs/antigravity-cli/latest/agy
DEFAULT_MODEL=gemini-3.8-flash-high
# agy uid 가 쓸 도구(검사·포맷·테스트). mise 설치 디렉터리는 누구나 읽기 가능.
TOOL_PATH=/code/.local/share/mise/installs/luau/0.734:/code/.local/share/mise/installs/stylua/2.5.2

die() { echo "agy-delegate: $*" >&2; exit 2; }

cmd=${1:-}; shift || true
case "$cmd" in
list)
	git -C "$ROOT" worktree list | grep "$BASE/" || echo "(없음)"
	exit 0
	;;
remove)
	name=${1:?이름}
	[[ "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "이름이 이상함"
	git -C "$ROOT" worktree remove --force "$BASE/$name"
	git -C "$ROOT" branch -D "agy/$name"
	rm -rf "${HOMES:?}/${name:?}"
	exit 0
	;;
run) ;;
*) die "사용법: run <이름> <프롬프트 파일> [--model M] [--timeout 초] | remove <이름> | list" ;;
esac

name=${1:?이름}; promptFile=${2:?프롬프트 파일}; shift 2
model=$DEFAULT_MODEL; timeoutSec=3600
while [[ $# -gt 0 ]]; do
	case "$1" in
	--model) model=$2; shift 2 ;;
	--timeout) timeoutSec=$2; shift 2 ;;
	*) die "모르는 옵션 $1" ;;
	esac
done
[[ "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "이름은 [a-z0-9-]"
[[ -f "$promptFile" ]] || die "프롬프트 파일 없음: $promptFile"
WT=$BASE/$name
[[ -e "$WT" ]] && die "$WT 가 이미 있음 — 다른 이름을 쓰거나 remove 하세요"

mkdir -p "$BASE" "$HOOKS" "$HOMES"
# HOME: 과제마다 따로, OAuth 상태를 새로 복사(사용자 자신의 agy 사용이 갱신했을 수 있음)
AGY_HOME=$HOMES/$name
rm -rf "${AGY_HOME:?}"
mkdir -p "$AGY_HOME"
cp -r /code/.gemini "$AGY_HOME/.gemini"
chown -R $AGY_UID:$AGY_UID "$AGY_HOME"
printf '#!/bin/sh\necho "push refused: agy delegate worktree" >&2\nexit 1\n' > "$HOOKS/pre-push"
chmod 755 "$HOOKS/pre-push"

git -C "$ROOT" worktree add -q -b "agy/$name" "$WT" HEAD
mkdir -p "$WT/.agy"

{
	cat <<EOF
# 작업 환경 (반드시 지킬 것)

- 너는 git worktree \`$WT\`(브랜치 \`agy/$name\`) 안에서 일한다. 이 디렉터리가 stl-luau 레포의 사본이다. **이 디렉터리 밖의 파일을 만들거나 고치지 말 것** — 너는 권한이 낮은 별도 사용자로 돌고 있어 밖에는 어차피 쓸 수 없다. 원본 레포 경로(\`$ROOT\`)는 읽기만 가능하다; 읽을 때도 이 worktree 안의 같은 파일을 읽어라(같은 커밋이다).
- 이 프로젝트의 진입점은 레포 루트의 \`GEMINI.md\` 다(agy 가 작업공간 규칙으로 자동으로 싣는다 — 안 보이면 직접 읽어라).
- \`git commit\`·\`git push\`·\`git stash\`·\`git reset\`·\`git checkout\`(브랜치 전환)·\`git worktree\` 명령을 쓰지 말 것. 실험으로 파일을 고치는 것은 이 worktree 안에서 허용된다(메인 세션이 diff 를 본다) — 고쳤다면 보고서에 무엇을 왜 고쳤는지 적을 것.
- 실행은 항상 \`( ulimit -v 4000000; timeout 600 <명령> )\` 꼴로. 전체 검사는 \`./scripts/check.sh\`(타입·음성 대조군·require·에러 규약·포맷·테스트), 테스트만은 \`luau tests/run.luau\` — 판정은 **exit code**(0 이 통과)이지 출력의 "PASS" 줄 수가 아니다. 프로브는 worktree 루트나 \`tests/\` 옆에 만들어 \`luau <파일>\` 로 돌리고, 타입은 \`luau-analyze <파일>\`(새 솔버, strict) 로 본다. \`require\` 경로는 그 파일 기준 상대 경로다(루트의 프로브면 \`require("./src/Arr")\`).
- **최종 보고서는 반드시 \`$WT/AGY_REPORT.md\` 파일에 한국어로 쓴다.** 주장마다 근거(파일:줄, 실행한 명령과 출력)를 붙이고, 직접 실행해 확인한 것은 "실측", 코드를 읽고 추론한 것은 "추정"으로 표시한다. 틀릴 수 있는 주장을 단정하지 말 것. 다 못 한 것은 "미완"으로 적는다. 기준 커밋은 \`git rev-parse HEAD\` 로 직접 확인해 적어라(입력 문서에 적힌 커밋을 옮기지 말 것).
- 이 프로젝트의 결정은 사용자가 한다. 너의 제안은 "제안"이지 결정이 아니다 — 새 함수·이름·규약을 제안할 때는 그렇다고 적어라.

# 과제

EOF
	cat "$promptFile"
} > "$WT/.agy/prompt.md"

chown -R $AGY_UID:$AGY_UID "$WT" "$ROOT/.git/worktrees/$name"

before_head=$(git -C "$ROOT" rev-parse HEAD)
before_status=$(git -C "$ROOT" status --porcelain=v1 | sha1sum)
echo "agy-delegate: 시작 $name ($model) $(date -Is) — worktree $WT"

set +e
(cd "$WT" && setpriv --reuid=$AGY_UID --regid=$AGY_UID --clear-groups \
	env HOME="$AGY_HOME" PATH="$TOOL_PATH:$PATH" \
	GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0="$HOOKS" \
	timeout $((timeoutSec + 60)) "$AGY" --model "$model" --dangerously-skip-permissions \
	--print-timeout "${timeoutSec}s" -p "$(cat "$WT/.agy/prompt.md")") > "$WT/.agy/stdout.txt" 2>&1
rc=$?
set -e

after_head=$(git -C "$ROOT" rev-parse HEAD)
after_status=$(git -C "$ROOT" status --porcelain=v1 | sha1sum)
{
	echo "exit: $rc"
	echo "finished: $(date -Is)"
	if [[ "$before_head" == "$after_head" && "$before_status" == "$after_status" ]]; then
		echo "main repo: unchanged"
	else
		echo "main repo: CHANGED during the run (HEAD $before_head -> $after_head; status hash differs) — 메인 세션이나 사용자가 한 것인지 확인"
	fi
	echo "worktree changes:"
	git -c safe.directory="$WT" -C "$WT" status --porcelain=v1 | grep -v '^?? .agy/' || true
} > "$WT/.agy/guard.txt"

echo "agy-delegate: 끝 $name — exit $rc"
cat "$WT/.agy/guard.txt"
if [[ -f "$WT/AGY_REPORT.md" ]]; then
	echo "report: $WT/AGY_REPORT.md ($(wc -c < "$WT/AGY_REPORT.md") bytes)"
else
	echo "report: MISSING — $WT/.agy/stdout.txt 를 볼 것"
fi
