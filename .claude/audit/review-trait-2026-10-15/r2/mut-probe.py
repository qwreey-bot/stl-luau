# 생존 돌연변이를 사본에 넣고 이 폴더의 프로브 하나를 돌림: python3 mut-probe.py <프로브.luau> R01 R02 …
import os, shutil, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = "/code/Projects/stl-luau"
src = open(os.path.join(HERE, "mut-r2.py")).read()
B, I, E, M, N = "src/Trait/Build.luau", "src/Trait/init.luau", "src/Trait/Errors.luau", "src/Traits/Map.luau", "src/Trait/Entry.luau"
MUTS = eval(src[src.index("MUTS = [") + 7: src.index("\n]\n") + 2])
probe = sys.argv[1]
want = set(sys.argv[2:])
for label, f, a, b in MUTS:
	if label.split()[0] not in want:
		continue
	base = tempfile.mkdtemp(prefix="stl-mutp-r2-")
	try:
		shutil.copytree(os.path.join(REPO, "src"), os.path.join(base, "src"))
		shutil.copy(os.path.join(REPO, ".luaurc"), os.path.join(base, ".luaurc"))
		pd = os.path.join(base, ".claude/audit/review-trait-2026-10-15/r2")
		os.makedirs(pd)
		shutil.copy(os.path.join(HERE, probe), pd)
		p = os.path.join(base, f); t = open(p).read()
		assert t.count(a) == 1, label
		open(p, "w").write(t.replace(a, b))
		r = subprocess.run(["bash", "-c", f"ulimit -v 1048576; timeout 60 /code/.local/share/mise/installs/luau/0.742/luau {probe}"], capture_output=True, text=True, cwd=pd)
		out = (r.stdout + r.stderr).strip().splitlines()
		print(f"== {label} rc={r.returncode}")
		for line in out[:14]:
			print("   ", line[:260])
	finally:
		shutil.rmtree(base)
