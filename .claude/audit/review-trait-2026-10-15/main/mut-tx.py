# 리뷰 4라운드 뒤의 묶음(되돌리기) 돌연변이 — 사본에서 전체 테스트를 -O1·-O2 로, 종료 코드로 판정.
import os, shutil, subprocess, tempfile
REPO = "/code/Projects/stl-luau"
C, B, I = "src/Common.luau", "src/Trait/Build.luau", "src/Trait/init.luau"
MUTS = [
	("T1 되돌리기 없음", B, "\t\tfor at = #undo, 1, -1 do\n\t\t\tundo[at]()\n\t\tend", "\t\tlocal _ = undo"),
	("T2 놓였던 표의 옛 내용을 안 되돌림", B, "\t\tnote(function()\n\t\t\ttable.clear(existing)", "\t\tlocal _ = (function()\n\t\t\ttable.clear(existing)"),
	("T3 토큰을 안 되돌림", I, "\t\tBuild.note(function()\n\t\t\tRegistry.byName[name] = nil", "\t\tlocal _ = (function()\n\t\t\tRegistry.byName[name] = nil"),
	("T4 미루지 않음", C, "\t\t\tif deferring > 0 and source == \"[C]\" then", "\t\t\tif false then"),
	("T5 미룬 에러를 위치 없이 다시 던짐", C, "\t\texports.raise(rawget(err :: any, DEFERRED))", "\t\texports.rethrow(rawget(err :: any, DEFERRED))"),
	("T6 C 프레임이 아니어도 미룸", C, "\t\t\tif deferring > 0 and source == \"[C]\" then", "\t\t\tif deferring > 0 then"),
	("T7 뭉텅이 기록을 안 되돌림", B, "\tnote(function()\n\t\tremoveValue(rec.blankets, blanket)", "\tlocal _ = (function()\n\t\tremoveValue(rec.blankets, blanket)"),
	("T8 명시 기록을 안 되돌림", B, "\tnote(function()\n\t\trec.explicit[token] = nil", "\tlocal _ = (function()\n\t\trec.explicit[token] = nil"),
	("T9 새 표를 안 지움", B, "\t\tnote(function()\n\t\t\trec.impls[token] = nil", "\t\tlocal _ = (function()\n\t\t\trec.impls[token] = nil"),
	("T10 ImplFor 를 묶지 않음", I, "\tBuild.transact(function()\n\t\tBuild.onFor(trait, token, impl)\n\tend)", "\tBuild.onFor(trait, token, impl)"),
	("T11 ImplWhere 를 묶지 않음", I, "\tBuild.transact(function()\n\t\tBuild.onWhere(trait, { deps = list, build = build })\n\tend)", "\tBuild.onWhere(trait, { deps = list, build = build })"),
	("T12 의존 기록을 안 되돌림", B, "\t\t\tnote(function()\n\t\t\t\tdepRec.dependentSet[trait] = nil", "\t\t\tlocal _ = (function()\n\t\t\t\tdepRec.dependentSet[trait] = nil"),
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
