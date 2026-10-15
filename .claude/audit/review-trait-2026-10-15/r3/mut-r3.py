# 리뷰 3라운드: Trait.Every·2라운드 수정분 주변 + 아직 안 돌린 시스템 자리의 돌연변이(r1 mutations_rt.py·main mut-fix.py·r2 mut-r2.py 와 겹치지 않게).
# 사본에서 전체 테스트(-O1·-O2)를 돌려 종료 코드로 판정(124/134/137/143·not enough memory = 폭주, 잡힘).
import os, shutil, subprocess, sys, tempfile
REPO = "/code/Projects/stl-luau"
B, I, E, N = "src/Trait/Build.luau", "src/Trait/init.luau", "src/Trait/Errors.luau", "src/Trait/Entry.luau"
MUTS = [
	("E01 빈 목록 검사 생략({}·{nil} 이 다시 모든 종류)", [(I, "if deps ~= Every and (type(deps) ~= \"table\" or rawlen(deps) == 0) then", "if deps ~= Every and type(deps) ~= \"table\" then")]),
	("E02 Every 를 목록 검사에서 빼지 않음(Every 가 에러)", [(I, "if deps ~= Every and (type(deps) ~= \"table\" or rawlen(deps) == 0) then", "if type(deps) ~= \"table\" or rawlen(deps) == 0 then")]),
	("E03 onToken 이 Every 뭉텅이를 안 지음", [(B, "\t\t\tif #blankets[b].deps == 0 then", "\t\t\tif #blankets[b].deps == 0 and false then")]),
	("E04 onToken 의 break 생략", [(B, "\t\t\t\trefresh(trait, token)\n\t\t\t\tbreak", "\t\t\t\trefresh(trait, token)")]),
	("E05 루프 끝이 Every 를 안 가림", [(I, "for at = 1, if deps == Every then 0 else rawlen(deps) do", "for at = 1, rawlen(deps) do")]),
	("E06 Every 를 얼리지 않음", [(I, "const Every: EveryKind = table.freeze({}) :: any", "const Every: EveryKind = {} :: any")]),
	("E07 Restore 가 다시 __iter 로 걸음", [(I, "for key, child in next, node do", "for key, child in node do")]),
	("E08 목록 검사에서 type 확인 생략", [(I, "(type(deps) ~= \"table\" or rawlen(deps) == 0)", "(rawlen(deps) == 0)")]),
	("E15 commit 이 놓기 전에 위로 번짐", [
		(B, "\tconst existing = rec.impls[token]\n\tif existing ~= nil then", "\tfor at = 1, #rec.dependents do\n\t\trefresh(rec.dependents[at], token)\n\tend\n\tconst existing = rec.impls[token]\n\tif existing ~= nil then"),
		(B, "\tconst dependents = rec.dependents\n\tfor at = 1, #dependents do\n\t\trefresh(dependents[at], token)\n\tend\n", ""),
	]),
	("E17 dependents 중복 기록", [(B, "\t\tif not depRec.dependentSet[trait] then", "\t\tif true then")]),
	("E24 Expose 가 진입점 이름과 겹쳐도 덮어씀", [(I, "if type(entryName) ~= \"string\" or RESERVED[entryName] or rawget(trait :: any, entryName) ~= nil then", "if type(entryName) ~= \"string\" or RESERVED[entryName] then")]),
	("E27 ImplFor 토큰 검사 생략", [(I, "\tif not isToken[token] then\n\t\tErrors.notToken(`{rec.name}.ImplFor`, token)", "\tif false then\n\t\tErrors.notToken(`{rec.name}.ImplFor`, token)")]),
	("E28 ImplFor 표 검사 생략", [(I, "\tif type(impl) ~= \"table\" then\n\t\tErrors.implNotTable", "\tif false then\n\t\tErrors.implNotTable")]),
	("E29 Stamp 토큰 검사 생략", [(I, "\tif not isToken[token] then\n\t\tErrors.notToken(\"Stamp\", token)", "\tif false then\n\t\tErrors.notToken(\"Stamp\", token)")]),
	("E30 NewToken 이름 검사 생략", [(I, "\tif type(name) ~= \"string\" then\n\t\tErrors.tokenName(name)", "\tif false then\n\t\tErrors.tokenName(name)")]),
	("E31 기본 구현 고리 검사 생략", [(B, "\t\t\tif building[fnName] then\n\t\t\t\tErrors.defaultCycle", "\t\t\tif false then\n\t\t\t\tErrors.defaultCycle")]),
	("E36 Implements 가 불리언 대신 표", [(I, "\treturn token ~= nil and records[trait].impls[token] ~= nil", "\treturn (token and records[trait].impls[token]) :: any")]),
	("E38 Impls 트레이트 검사 생략", [(I, "\tif rec == nil then\n\t\tErrors.notTrait(\"Impls\", trait)", "\tif false then\n\t\tErrors.notTrait(\"Impls\", trait)")]),
	("E40 entryMiss 의 이 사본 토큰 갈래 뒤집음", [(E, "\t\t\tif Registry.isToken[raw] then", "\t\t\tif not Registry.isToken[raw] then")]),
	("E41 onWhere 뒤 번짐 루프가 명시 구현 종류도 다시 지음", [(B, "\t\tif rec.explicit[token] == nil and depsOf(blanket.deps, token) ~= nil then\n\t\t\trefresh(trait, token)", "\t\tif depsOf(blanket.deps, token) ~= nil then\n\t\t\trefresh(trait, token)")]),
	("E42 Restore 의 이름이 문자열인지 안 봄", [(I, "const real = if type(tokenName) == \"string\" then Registry.byName[tokenName] else nil", "const real = Registry.byName[tokenName :: any]")]),
]
only = set(sys.argv[1:])
for label, edits in MUTS:
	if only and label.split()[0] not in only:
		continue
	base = tempfile.mkdtemp(prefix="stl-mut-r3-")
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
