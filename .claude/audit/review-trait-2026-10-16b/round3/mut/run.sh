#!/usr/bin/env bash
S=/tmp/claude-0/-code-Projects-stl-luau/1cb06079-132e-4d95-8fed-df0aa2d5e80d/scratchpad/r3
id=$1
W=$(mktemp -d -p $S/mut); cp -r $S/b2b514f/. $W/; rm -rf "${W:?}/probes"
python3 - "$id" "$W" <<'PY'
import sys; sys.path.insert(0, "/tmp/claude-0/-code-Projects-stl-luau/1cb06079-132e-4d95-8fed-df0aa2d5e80d/scratchpad/r3/mut")
from mutations import M
i, w = sys.argv[1], sys.argv[2]
f, old, new, d = M[i]
p = f"{w}/{f}"; s = open(p).read()
n = s.count(old)
if n != 1: print(f"{i}: APPLY-FAIL count={n}"); sys.exit(3)
open(p, "w").write(s.replace(old, new))
PY
if [ $? -ne 0 ]; then echo -e "$id\tAPPLYFAIL" >> $S/mut/results.tsv; exit; fi
( cd $W && timeout 400 ./scripts/check.sh > $S/mut/$id.log 2>&1 ); rc=$?
echo -e "$id\t$rc" >> $S/mut/results.tsv
# 생존 시 프로브도 돌려 봄
cp -r $S/probes $W/probes
echo "$W" > $S/mut/$id.dir
