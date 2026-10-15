# 리뷰 1라운드 수정분의 돌연변이 — 사본에서 전체 테스트(-O1)를 돌려 잡히는지. 종료 코드로 판정(124/134/137/143 = 폭주, 잡힘).
import os, re, shutil, subprocess, tempfile
REPO = "/code/Projects/stl-luau"
B, I, E, M = "src/Trait/Build.luau", "src/Trait/init.luau", "src/Trait/Errors.luau", "src/Traits/Map.luau"
old = open(os.path.join(os.path.dirname(__file__), "old-init.luau")).read()
oldRestore = old[old.index("const function Restore<T>"):old.index("--[[ 트레이트 ]]")]
cur = open(os.path.join(REPO, I)).read()
curRestore = cur[cur.index("-- 걷기는 명시적 스택으로"):cur.index("--[[ 트레이트 ]]")]
MUTS = [
	("M04 겹침 검사 생략", B, "\t\t\tif found ~= nil then\n\t\t\t\tErrors.overlap(rec.name, token.name)\n\t\t\tend\n\t\t\tfound, foundDeps", "\t\t\tfound, foundDeps"),
	("M05 onWhere 겹침 선검사 생략", B, "\t\t\t\tif depsOf(rec.blankets[b].deps, token) ~= nil then\n\t\t\t\t\tErrors.overlap", "\t\t\t\tif false then\n\t\t\t\t\tErrors.overlap"),
	("M16 사본 대신 넘긴 표", B, "\tconst full = assemble(rec, token, copy)\n\trec.explicit[token] = copy", "\tconst full = assemble(rec, token, copy)\n\trec.explicit[token] = given"),
	("M23 얼린 표 조건 제거", I, "if real ~= nil and not table.isfrozen(node) then", "if real ~= nil then"),
	("M37 아무 표나 기본 구현", I, "\t\telseif type(mark) == \"table\" and type(rawget(mark, DEFAULT_MARK)) == \"function\" then", "\t\telseif type(mark) == \"table\" then"),
	("M38 명시 구현 있는 종류도 겹침 검사", B, "\t\tif rec.explicit[token] == nil and depsOf(blanket.deps, token) ~= nil then\n\t\t\tfor b = 1", "\t\tif depsOf(blanket.deps, token) ~= nil then\n\t\t\tfor b = 1"),
	("X1 Map 펼친 조회를 트레이트 객체로", M, "const mapImpls = Trait.Impls(MapBase)", "const mapImpls = MapBase :: any"),
	("X1b Entry 를 트레이트 객체로", I, "trait[fnName] = Entry.make(impls, name, fnName, at)", "trait[fnName] = Entry.make(trait, name, fnName, at); impls[\"Get\"] = nil"),
	("X2 고리 검사 생략", I, "\t\tif reaches(list[at]) then", "\t\tif false then"),
	("X3 Restore 를 재귀로", I, curRestore, oldRestore),
	("X4 뭉텅이 선검사가 종류를 탓함", B, "assemble(rec, token, given, true)", "assemble(rec, token, given)"),
	("X5 자기 자신 문구 생략", E, "\tif trait == dep then", "\tif false then"),
]
for label, f, a, b in MUTS:
	base = tempfile.mkdtemp(prefix="stl-mutfix-")
	try:
		for item in ["src", "tests", ".luaurc"]:
			s = os.path.join(REPO, item)
			(shutil.copytree if os.path.isdir(s) else shutil.copy)(s, os.path.join(base, item))
		p = os.path.join(base, f); t = open(p).read()
		assert t.count(a) == 1, (label, t.count(a))
		open(p, "w").write(t.replace(a, b))
		r = subprocess.run(["bash", "-c", "ulimit -v 1048576; timeout 120 /code/.local/share/mise/installs/luau/0.742/luau tests/run.luau"], capture_output=True, text=True, cwd=base)
		out = r.stdout + r.stderr
		caught = r.returncode != 0 or "ALL SUITES PASS" not in out
		msg = next((l for l in out.splitlines() if "rror" in l or "assert" in l.lower()), "")[:160]
		print(("잡힘 " if caught else "생존 ") + label, "rc", r.returncode, "|", msg)
	finally:
		shutil.rmtree(base)
