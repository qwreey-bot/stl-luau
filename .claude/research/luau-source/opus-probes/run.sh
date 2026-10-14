#!/bin/bash
# 사용: ./run.sh <luau-analyze 경로> <출력 파일>
# 프로브 전부를 돌려 TypeError 줄만 모음(Unused 경고 제외)
AN=${1:-/code/.local/share/mise/installs/luau/0.742/luau-analyze}
OUT=${2:-/dev/stdout}
cd "$(dirname "$0")"
{
for f in p1-body.luau p2-annotated-lambda.luau p3-hack-reach.luau p4a.luau p4b.luau p5/*.luau p6/*.luau p7-probe-type.luau; do
  echo "== $f"
  ( ulimit -v 2097152; timeout 120 "$AN" "$f" ) 2>&1 | grep -E "TypeError" | sed -E 's/^\.\/[^(]*//' | sed -E 's/(TypeError: .{0,90}).*/\1/'
done
} > "$OUT"
