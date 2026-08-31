#!/usr/bin/env bash
# 타입 검사 + 테스트. quad 의 scripts/test.sh 를 따릅니다.
#
# 타입 검사기는 luau-lsp 가 아니라 **luau-analyze** 입니다 — 근거는
# .claude/base/typing-limits.md 의 "체커: luau-analyze" 절. 플래그가 필요
# 없습니다: new solver 가 기본이고, strict 여부는 .luaurc 와 각 파일 상단의
# --!strict 가 정합니다.
set -uo pipefail
cd "$(dirname "$0")/.."

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

echo
echo "=== luau tests/run.luau"
luau tests/run.luau
