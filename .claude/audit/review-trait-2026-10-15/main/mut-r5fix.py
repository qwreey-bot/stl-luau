# 리뷰 4라운드 뒤의 묶음(되돌리기) 돌연변이 — 사본에서 전체 테스트를 -O1·-O2 로, 종료 코드로 판정.
import os, shutil, subprocess, tempfile
REPO = "/code/Projects/stl-luau"
C, B, I = "src/Common.luau", "src/Trait/Build.luau", "src/Trait/init.luau"
MUTS = [
	("U1 일지를 앞에서부터 되돌림", B, "\t\tfor at = #undo, 1, -1 do", "\t\tfor at = 1, #undo do"),
	("U2 테이블 에러를 다 표식으로", C, "\tif type(err) == \"table\" and rawget(err :: any, DEFERRED) ~= nil then", "\tif type(err) == \"table\" then"),
	("U3 미루기의 부른 쪽 확인 없음", C, " and debug.info(level + 1, \"f\") == exports.transact then", " then"),
	("U4 중첩 등록 허용(바깥 묶음에 섞음)", B, "\tif journals[thread] ~= nil then\n\t\tErrors.nested()\n\tend", "\tif journals[thread] ~= nil then\n\t\tfn()\n\t\treturn\n\tend"),
	("U5 일지를 스레드와 무관하게 하나로", B, "\tconst thread = coroutine.running()\n", "\tconst thread = (nil :: any) or \"one\"\n"),
]
for label, f, a, b in MUTS:
	base = tempfile.mkdtemp(prefix="stl-muttx-")
	try:
		for item in ["src", "tests", ".luaurc"]:
			s = os.path.join(REPO, item)
			(shutil.copytree if os.path.isdir(s) else shutil.copy)(s, os.path.join(base, item))
		p = os.path.join(base, f); t = open(p).read()
		assert t.count(a) == 1, (label, t.count(a))
		open(p, "w").write(t.replace(a, b))
		res = []
		for o in ["-O1", "-O2"]:
			r = subprocess.run(["bash", "-c", f"ulimit -v 1048576; timeout 120 /code/.local/share/mise/installs/luau/0.742/luau {o} tests/run.luau"], capture_output=True, text=True, cwd=base)
			out = r.stdout + r.stderr
			caught = r.returncode != 0 or "ALL SUITES PASS" not in out
			msg = next((l for l in out.splitlines() if "rror" in l), "")[:150]
			res.append((caught, o, r.returncode, msg))
		print(("잡힘 " if all(c for c, *_ in res) else "생존 ") + label, " | ".join(f"{o} rc={rc} {m}" for _, o, rc, m in res))
	finally:
		shutil.rmtree(base)
