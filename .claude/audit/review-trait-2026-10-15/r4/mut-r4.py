# 리뷰 4라운드: 875fcdc 의 Every 겹침 검사 돌연변이. 사본에서 전체 테스트(-O1·-O2), 종료 코드로 판정.
import os, shutil, subprocess, sys, tempfile
REPO = "/code/Projects/stl-luau"
I, E = "src/Trait/init.luau", "src/Trait/Errors.luau"
CHECK = "\tconst blankets = rec.blankets\n\tfor b = 1, #blankets do\n\t\tif #list == 0 or #blankets[b].deps == 0 then\n\t\t\tErrors.everyOverlap(rec.name, #list == 0)\n\t\tend\n\tend\n"
COND = "if #list == 0 or #blankets[b].deps == 0 then"
MUTS = [
	("R01 검사 전체 삭제", [(I, CHECK, "")]),
	("R02 추가하는 쪽이 Every 인 갈래 빠짐", [(I, COND, "if #blankets[b].deps == 0 then")]),
	("R03 이미 Every 가 있는 갈래 빠짐", [(I, COND, "if #list == 0 then")]),
	("R04 or → and", [(I, COND, "if #list == 0 and #blankets[b].deps == 0 then")]),
	("R05 메시지 갈래 인자 뒤집음", [(I, "Errors.everyOverlap(rec.name, #list == 0)", "Errors.everyOverlap(rec.name, #list ~= 0)")]),
	("R06 루프가 둘째부터", [(I, "\tfor b = 1, #blankets do\n\t\tif #list == 0 or", "\tfor b = 2, #blankets do\n\t\tif #list == 0 or")]),
	("R07 검사를 기록 뒤로(onWhere 다음)", [(I, CHECK, ""), (I, "\tBuild.onWhere(trait, { deps = list, build = build })\n", "\tBuild.onWhere(trait, { deps = list, build = build })\n" + CHECK)]),
	("R08 Errors 갈래 뒤집음", [(E, "\tif addingEvery then", "\tif not addingEvery then")]),
	("R09 Every 판정을 deps 원본으로(동등 기대)", [(I, COND, "if deps == Every or #blankets[b].deps == 0 then")]),
	("R10 검사를 목록 만들기 전으로(list 가 늘 빈 것)", [(I, CHECK, ""), (I, "\tconst list: { any } = {}\n", "\tconst list: { any } = {}\n" + CHECK)]),
	("R11 검사를 고리 검사 뒤로(동등 기대 — 메시지 우선순위만)", [(I, CHECK, ""), (I, "\tBuild.onWhere(trait, { deps = list, build = build })\n", CHECK + "\tBuild.onWhere(trait, { deps = list, build = build })\n")]),
	("R12 첫 뭉텅이만 봄(break 없이 첫 칸)", [(I, "\tfor b = 1, #blankets do\n\t\tif #list == 0 or", "\tfor b = 1, math.min(1, #blankets) do\n\t\tif #list == 0 or")]),
]
only = set(sys.argv[1:])
for label, edits in MUTS:
	if only and label.split()[0] not in only:
		continue
	base = tempfile.mkdtemp(prefix="stl-mut-r4-")
	try:
		for item in ["src", "tests", ".luaurc"]:
			s = os.path.join(REPO, item)
			(shutil.copytree if os.path.isdir(s) else shutil.copy)(s, os.path.join(base, item))
		for f, a, b in edits:
			p = os.path.join(base, f); t = open(p).read()
			assert t.count(a) == 1, (label, t.count(a))
			open(p, "w").write(t.replace(a, b))
		res = []
		for opt in ["-O1", "-O2"]:
			r = subprocess.run(["bash", "-c", f"ulimit -v 1048576; timeout 120 /code/.local/share/mise/installs/luau/0.742/luau {opt} tests/run.luau"], capture_output=True, text=True, cwd=base)
			out = r.stdout + r.stderr
			caught = r.returncode != 0 or "ALL SUITES PASS" not in out
			msg = next((l for l in out.splitlines() if "rror" in l or "assert" in l.lower() or "memory" in l), "")[:200]
			res.append((opt, caught, r.returncode, msg))
		caughtAny = any(c for _, c, _, _ in res)
		print(("잡힘 " if caughtAny else "생존 ") + label, " | ".join(f"{o} rc={rc} {m}" for o, _, rc, m in res), flush=True)
	finally:
		shutil.rmtree(base)
