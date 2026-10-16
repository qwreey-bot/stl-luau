#!/usr/bin/env bash
# usage: judge.sh REVDIR probe... — 각 프로브를 REVDIR 에서 luau-analyze, 줄별 태그와 에러 수를 대조
S=/tmp/claude-0/-code-Projects-stl-luau/1cb06079-132e-4d95-8fed-df0aa2d5e80d/scratchpad/r3
R=$1; shift
mkdir -p $R/probes
for p in "$@"; do
  cp $S/probes/$p $R/probes/
  out=$( cd $R && ulimit -v 2097152; timeout 120 luau-analyze probes/$p 2>&1 )
  python3 - "$R/probes/$p" "$out" <<'PY'
import sys, re, collections
path, out = sys.argv[1], sys.argv[2]
lines = open(path).read().split("\n")
errs = collections.defaultdict(list)
for l in out.split("\n"):
    m = re.match(r".*?\((\d+),\d+\): (.*)", l)
    if m and not m.group(2).startswith("LocalUnused"): errs[int(m.group(1))].append(m.group(2)[:160])
name = path.split("/")[-1]
for i, l in enumerate(lines, 1):
    tag = None
    m = re.search(r"-- (POS|NEG|BND)\b", l)
    if m: tag = m.group(1)
    n = len(errs.get(i, []))
    bad = (tag == "POS" and n > 0) or (tag == "NEG" and n == 0)
    if tag or n:
        print(f"{'!!' if bad else '  '} {name}:{i} [{tag or '-'}] errs={n} :: {l.strip()[:90]}")
        for e in errs.get(i, [])[:2]:
            print(f"        {e}")
PY
done
