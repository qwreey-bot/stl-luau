# 리뷰 6라운드 돌연변이 — d7aa5bd 의 새 줄. 사본에서 전체 테스트를 -O1·-O2 로, 종료 코드로 판정.
import os, shutil, subprocess, tempfile
REPO = "/code/Projects/stl-luau"
C, B, E = "src/Common.luau", "src/Trait/Build.luau", "src/Trait/Errors.luau"
MUTS = [
	("N1 성공 뒤 일지를 안 지움", B, "\tend)\n\tjournals[thread] = nil\nend", "\tend)\nend"),
	("N2 실패(되돌림) 때 일지를 안 지움", B, "\t\tconst undo = journals[thread]\n\t\tjournals[thread] = nil\n", "\t\tconst undo = journals[thread]\n"),
	("N3 약한 키를 뺌", B, "setmetatable({}, { __mode = \"k\" })", "setmetatable({}, {})"),
	("N4 부른 쪽을 한 칸 더 위(level + 2)", C, "debug.info(level + 1, \"f\") == exports.transact", "debug.info(level + 2, \"f\") == exports.transact"),
	("N5 부른 쪽 대신 그 C 프레임 자신(level)", C, "debug.info(level + 1, \"f\") == exports.transact", "debug.info(level, \"f\") == pcall"),
	("N6 deferring 조건을 뺌", C, "if deferring > 0 and source == \"[C]\" and", "if source == \"[C]\" and"),
	("N7 중첩 검사를 deferring 으로(스레드 무시)", B, "\tif journals[thread] ~= nil then\n\t\tErrors.nested()", "\tif next(journals) ~= nil then\n\t\tErrors.nested()"),
	("N8 되돌림 순서: 일지를 지운 뒤가 아니라 되돌린 뒤 지움", B, "\t\tconst undo = journals[thread]\n\t\tjournals[thread] = nil\n\t\tfor at = #undo, 1, -1 do\n\t\t\tundo[at]()\n\t\tend\n", "\t\tconst undo = journals[thread]\n\t\tfor at = #undo, 1, -1 do\n\t\t\tundo[at]()\n\t\tend\n\t\tjournals[thread] = nil\n"),
	("N9 중첩 에러 대신 조용히 무시(아무것도 안 함)", B, "\tif journals[thread] ~= nil then\n\t\tErrors.nested()\n\tend", "\tif journals[thread] ~= nil then\n\t\treturn\n\tend"),
]
for label, f, a, b in MUTS:
	base = tempfile.mkdtemp(prefix="stl-mut6-")
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
			msg = next((l for l in out.splitlines() if "rror" in l), "")[:170]
			res.append((caught, o, r.returncode, msg))
		print(("잡힘 " if all(c for c, *_ in res) else "생존 ") + label, " | ".join(f"{o} rc={rc} {m}" for _, o, rc, m in res), flush=True)
	finally:
		shutil.rmtree(base)
