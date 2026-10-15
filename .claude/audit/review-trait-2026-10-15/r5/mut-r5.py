# 리뷰 5라운드 — 묶음(da9d52c) 돌연변이. 사본에서 전체 테스트를 -O1·-O2 로, 종료 코드로 판정. (상한: ulimit -v 1GB, timeout 120)
# 추가로 프로브 p04(같은 표 두 번 → 가장 옛 내용)를 같은 사본에서 돌려 "프로브가 잡는가" 도 적음.
import os, shutil, subprocess, tempfile, sys
REPO = "/code/Projects/stl-luau"
C, B, I = "src/Common.luau", "src/Trait/Build.luau", "src/Trait/init.luau"
LUAU = "/code/.local/share/mise/installs/luau/0.742/luau"
MUTS = [
	("R1 일지를 앞에서부터 되돌림", B, "\t\tfor at = #undo, 1, -1 do", "\t\tfor at = 1, #undo do"),
	("R2 deferring 을 내리지 않음", C, "\tdeferring -= 1\n", "\n"),
	("R3 성공한 뒤 journal 을 안 비움", B, "\tend)\n\tjournal = nil\nend", "\tend)\nend"),
	("R4 되돌릴 때 journal 을 안 비움", B, "\t\tconst undo = journal :: { () -> () }\n\t\tjournal = nil\n", "\t\tconst undo = journal :: { () -> () }\n"),
	("R5 중첩도 새 일지(바깥 일지를 버림)", B, "\tif journal ~= nil then\n\t\tfn()\n\t\treturn\n\tend\n\tjournal = {}", "\tjournal = {}"),
	("R6 표식 판별이 테이블이면 다", C, "if type(err) == \"table\" and rawget(err :: any, DEFERRED) ~= nil then", "if type(err) == \"table\" then"),
	("R7 토큰 되돌리기가 tokens 목록을 안 고침", I, "\t\t\tif at ~= nil then\n\t\t\t\ttable.remove(Registry.tokens, at)\n\t\t\tend\n", "\t\t\tlocal _ = at\n"),
	("R8 토큰 되돌리기가 isToken 을 안 고침", I, "\t\t\tisToken[token] = nil\n", ""),
	("R9 옛 내용을 고친 뒤에 떠 둠", B, "\t\tconst saved = table.clone(existing)\n\t\tnote(function()\n\t\t\ttable.clear(existing)\n\t\t\tfor key, fn in saved do\n\t\t\t\texisting[key] = fn\n\t\t\tend\n\t\tend)\n\t\ttable.clear(existing)\n\t\tfor key, fn in full do\n\t\t\texisting[key] = fn\n\t\tend",
	 "\t\ttable.clear(existing)\n\t\tfor key, fn in full do\n\t\t\texisting[key] = fn\n\t\tend\n\t\tconst saved = table.clone(existing)\n\t\tnote(function()\n\t\t\ttable.clear(existing)\n\t\t\tfor key, fn in saved do\n\t\t\t\texisting[key] = fn\n\t\t\tend\n\t\tend)"),
	("R10 미룬 에러는 되돌리지 않음", C, "\tundo()\n\tif type(err) == \"table\" and rawget(err :: any, DEFERRED) ~= nil then\n\t\texports.raise(rawget(err :: any, DEFERRED))\n\tend",
	 "\tif type(err) == \"table\" and rawget(err :: any, DEFERRED) ~= nil then\n\t\texports.raise(rawget(err :: any, DEFERRED))\n\tend\n\tundo()"),
	("R11 사용자 에러는 되돌리지 않음", C, "\tundo()\n\tif type(err) == \"table\" and rawget(err :: any, DEFERRED) ~= nil then\n\t\texports.raise(rawget(err :: any, DEFERRED))\n\tend\n\texports.rethrow(err)",
	 "\tif type(err) == \"table\" and rawget(err :: any, DEFERRED) ~= nil then\n\t\tundo()\n\t\texports.raise(rawget(err :: any, DEFERRED))\n\tend\n\texports.rethrow(err)"),
	("R12 미루기를 표식 없이 문자열로", C, "\t\t\t\treturn exports.rethrow({ [DEFERRED] = message })", "\t\t\t\treturn exports.rethrow(message)"),
	("R13 뭉텅이 되돌리기가 맨 끝을 뺌", B, "\tnote(function()\n\t\tremoveValue(rec.blankets, blanket)", "\tnote(function()\n\t\ttable.remove(rec.blankets)"),
	("R14 NewToken 을 묶지 않음", I, "\tBuild.transact(function()\n\t\tRegistry.byName[name] = token", "\tlocal _tx = (function(f: any) f() end)(function()\n\t\tRegistry.byName[name] = token"),
	("R15 byName 만 안 되돌림", I, "\t\t\tRegistry.byName[name] = nil\n", ""),
]
only = sys.argv[1:] 
for label, f, a, b in MUTS:
	if only and label.split()[0] not in only: continue
	base = tempfile.mkdtemp(prefix="stl-mutr5-")
	try:
		for item in ["src", "tests", ".luaurc", ".claude/audit/review-trait-2026-10-15/r5"]:
			s = os.path.join(REPO, item)
			d = os.path.join(base, item)
			os.makedirs(os.path.dirname(d), exist_ok=True)
			(shutil.copytree if os.path.isdir(s) else shutil.copy)(s, d)
		p = os.path.join(base, f); t = open(p).read()
		assert t.count(a) == 1, (label, t.count(a))
		open(p, "w").write(t.replace(a, b))
		if t.count("\t") and f.endswith(".luau") and False: pass
		res = []
		for o in ["-O1", "-O2"]:
			r = subprocess.run(["bash", "-c", f"ulimit -v 1048576; timeout 120 {LUAU} {o} tests/run.luau"], capture_output=True, text=True, cwd=base)
			out = r.stdout + r.stderr
			caught = r.returncode != 0 or "ALL SUITES PASS" not in out
			msg = next((l for l in out.splitlines() if "rror" in l), "")[:140]
			res.append((caught, o, r.returncode, msg))
		pd = os.path.join(base, ".claude/audit/review-trait-2026-10-15/r5")
		pr = subprocess.run(["bash", "-c", f"ulimit -v 1048576; timeout 60 {LUAU} p04-double-touch-undo.luau"], capture_output=True, text=True, cwd=pd)
		p04 = "p04 잡음" if "D 가 가장 옛 내용?\ttrue" not in pr.stdout else "p04 통과"
		pr5 = subprocess.run(["bash", "-c", f"ulimit -v 1048576; timeout 60 {LUAU} p05-builder-table-error.luau"], capture_output=True, text=True, cwd=pd)
		p04 += ", p05 잡음" if "같은 값:\ttrue" not in pr5.stdout else ", p05 통과"
		print(("잡힘 " if all(c for c, *_ in res) else "생존 ") + label, "|", p04, "|", " | ".join(f"{o} rc={rc} {m}" for _, o, rc, m in res), flush=True)
	finally:
		shutil.rmtree(base)
