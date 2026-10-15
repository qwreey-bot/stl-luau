#!/usr/bin/env python3
# 돌연변이 시험 — 사본에서만(mktemp -d), 자원 상한(ulimit -v 1GB, timeout 60).
# 쓰는 법: python3 mutate.py mutations_rt.py  (MUTATIONS = [(label, file, old, new), ...])
import os, sys, shutil, subprocess, tempfile, runpy
REPO = "/code/Projects/stl-luau"
LUAU = "/code/.local/share/mise/installs/luau/0.742/luau"
muts = runpy.run_path(sys.argv[1])["MUTATIONS"]
mode = sys.argv[2] if len(sys.argv) > 2 else "tests"
base = tempfile.mkdtemp(prefix="stl-mut-")
for item in ["src", "tests", "scripts", ".luaurc", "stylua.toml", ".claude"]:
    s = os.path.join(REPO, item)
    (shutil.copytree if os.path.isdir(s) else shutil.copy)(s, os.path.join(base, item))
results = []
for label, f, old, new in muts:
    path = os.path.join(base, f)
    orig = open(path).read()
    cnt = orig.count(old)
    if cnt != 1:
        results.append((label, "PATTERN x%d" % cnt, ""))
        continue
    open(path, "w").write(orig.replace(old, new))
    try:
        if mode == "tests":
            cmd = f"ulimit -v 1048576; timeout 60 {LUAU} tests/run.luau"
        else:
            cmd = f"PATH=/code/.local/share/mise/installs/luau/0.742:$PATH timeout 600 ./scripts/check.sh"
        p = subprocess.run(["bash", "-c", cmd], cwd=base, capture_output=True, text=True)
        rc = p.returncode
        out = (p.stdout + p.stderr)
        if rc == 0:
            verdict = "SURVIVED"
        elif rc in (124, 134, 137, 143) or "not enough memory" in out:
            verdict = "caught(runaway rc=%d)" % rc
        else:
            verdict = "caught(rc=%d)" % rc
        lines = [l for l in out.splitlines() if "rror" in l or "assert" in l or "FAIL" in l or "→" in l]
        results.append((label, verdict, (lines[0] if lines else out.strip().splitlines()[-1] if out.strip() else "")[:200]))
    finally:
        open(path, "w").write(orig)
for r in results:
    print("\t".join(r))
shutil.rmtree(base)
