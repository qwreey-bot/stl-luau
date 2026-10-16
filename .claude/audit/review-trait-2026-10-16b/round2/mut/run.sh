#!/usr/bin/env bash
# usage: run.sh ID... ; each mutation in a fresh copy of base, check.sh exit code
S=/tmp/claude-0/-code-Projects-stl-luau/1cb06079-132e-4d95-8fed-df0aa2d5e80d/scratchpad
for id in "$@"; do
  W=$(mktemp -d -p $S/mut); cp -r $S/base/. $W/; rm -rf $W/probes
  python3 - "$id" "$W" <<'PY'
import sys; sys.path.insert(0, "/tmp/claude-0/-code-Projects-stl-luau/1cb06079-132e-4d95-8fed-df0aa2d5e80d/scratchpad/mut")
from mutations import M
i, w = sys.argv[1], sys.argv[2]
f, old, new, d = M[i]
p = f"{w}/{f}"; s = open(p).read()
n = s.count(old)
if n != 1: print(f"{i}: APPLY-FAIL count={n}"); sys.exit(3)
open(p, "w").write(s.replace(old, new))
PY
  if [ $? -ne 0 ]; then echo "$id APPLYFAIL" >> $S/mut/results.tsv; continue; fi
  ( cd $W && timeout 400 ./scripts/check.sh > $S/mut/$id.log 2>&1 ); rc=$?
  echo -e "$id\t$rc" >> $S/mut/results.tsv
  rm -rf $W
done
