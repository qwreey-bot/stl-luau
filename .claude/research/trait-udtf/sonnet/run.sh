#!/bin/bash
# usage: run.sh dir file  -> 에러 줄 번호 목록 + 시간
cd "$1"
s=$(date +%s%N)
out=$( ( ulimit -v 2097152; timeout 120 /code/.local/share/mise/installs/luau/0.742/luau-analyze "$2" 2>&1 ) )
e=$(date +%s%N)
echo "$out" | grep -E "^\./$2\([0-9]+," | grep -E "TypeError|SyntaxError" | sed -E 's/.*\(([0-9]+),.*/\1/' | sort -n | tr '\n' ','
echo
echo "$out" | grep -v "^\./$2" | grep -E "^\./|^[A-Za-z]" | grep -E "Error" | head -20
echo "ms $(( (e - s) / 1000000 ))"
