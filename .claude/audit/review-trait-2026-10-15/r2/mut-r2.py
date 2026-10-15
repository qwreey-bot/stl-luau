# 리뷰 2라운드: 1라운드 수정분 주변의 돌연변이(메인의 mut-fix.py 열둘과 겹치지 않는 것).
# 사본에서 전체 테스트(-O1)를 돌려 종료 코드로 판정(124/134/137/143·not enough memory = 폭주, 잡힘).
import os, shutil, subprocess, sys, tempfile
REPO = "/code/Projects/stl-luau"
B, I, E, M, N = "src/Trait/Build.luau", "src/Trait/init.luau", "src/Trait/Errors.luau", "src/Traits/Map.luau", "src/Trait/Entry.luau"
MUTS = [
	("R01 다시 짓기 경로가 뭉텅이를 탓하지 않음", B, "assemble(rec, token, given, rec.explicit[token] == nil)", "assemble(rec, token, given)"),
	("R02 의존 목록의 첫째만 고리 검사", I, "\tfor at = 1, #list do\n\t\tif reaches(list[at]) then", "\tfor at = 1, math.min(#list, 1) do\n\t\tif reaches(list[at]) then"),
	("R03 reaches 가 첫 의존의 결과를 그대로 돌려줌", I, "\t\t\t\tif reaches(bdeps[at]) then\n\t\t\t\t\treturn true\n\t\t\t\tend", "\t\t\t\treturn reaches(bdeps[at])"),
	("R04 reaches 가 첫 뭉텅이만 봄", I, "\t\tconst blankets = records[from].blankets\n\t\tfor b = 1, #blankets do", "\t\tconst blankets = records[from].blankets\n\t\tfor b = 1, math.min(#blankets, 1) do"),
	("R05 고리 검사가 직접 의존만", I, "\t\t\t\tif reaches(bdeps[at]) then", "\t\t\t\tif bdeps[at] == trait then"),
	("R06 이미 본 것을 고리로(다이아몬드 거절)", I, "\t\tif seen[from] then\n\t\t\treturn false", "\t\tif seen[from] then\n\t\t\treturn true"),
	("R07 Entry 가 rawget 대신 인덱싱", N, "impls[rawget(self, \"__type\")]", "impls[self.__type]"),
	("R08 ExpectImpl 의 테이블 확인 생략", I, "const impl = if type(value) == \"table\" then rec.impls[rawget(value, TYPE_KEY)] else nil", "const impl = rec.impls[rawget(value, TYPE_KEY)]"),
	("R09 commit 이 같은 표를 고치지 않고 갈아 끼움", B, "\tif existing ~= nil then\n\t\ttable.clear(existing)", "\tif false then\n\t\ttable.clear(existing)"),
	("R10 Restore 가 __type 있는 표만 따라 내려감", I, "if key ~= TYPE_KEY and type(child) == \"table\" and not seen[child] then", "if key ~= TYPE_KEY and type(child) == \"table\" and not seen[child] and rawget(child, TYPE_KEY) ~= nil then"),
	("R11 Restore 가 뿌리만(자식 안 넣음)", I, "\t\t\t\t\ttop += 1\n\t\t\t\t\tstack[top] = child", "\t\t\t\t\tseen[child] = true"),
	("R12 Map.Keys 의 펼친 조회에서 테이블 확인 생략", M, "const ops: any = (if type(map) == \"table\" then mapImpls[rawget(map :: any, \"__type\")] else nil)\n\t\tor expectImpl(MapBase, map, \"Keys\")", "const ops: any = mapImpls[rawget(map :: any, \"__type\")]\n\t\tor expectImpl(MapBase, map, \"Keys\")"),
	("R13 Impls 가 사본을 돌려줌", I, "\treturn rec.impls\nend", "\treturn table.clone(rec.impls)\nend"),
	("R14 Implements 가 TokenOf 대신 raw __type", I, "\tconst token = TokenOf(value)\n\treturn token ~= nil and records[trait].impls[token] ~= nil", "\treturn type(value) == \"table\" and records[trait].impls[rawget(value, TYPE_KEY)] ~= nil"),
	("R15 고리 검사가 onWhere 뒤", I, "\tfor at = 1, #list do\n\t\tif reaches(list[at]) then\n\t\t\tErrors.whereCycle(rec.name, records[list[at]].name)\n\t\tend\n\tend\n\tBuild.onWhere(trait, { deps = list, build = build })", "\tBuild.onWhere(trait, { deps = list, build = build })\n\tfor at = 1, #list do\n\t\tif reaches(list[at]) then\n\t\t\tErrors.whereCycle(rec.name, records[list[at]].name)\n\t\tend\n\tend"),
	("R16 ImplOf 가 TokenOf 대신 raw", I, "\tconst token = TokenOf(value)\n\treturn if token == nil then nil else records[trait].impls[token]", "\treturn if type(value) == \"table\" then records[trait].impls[rawget(value, TYPE_KEY)] else nil"),
	("R17 Of 의 값 갈래가 토큰 확인 없이", I, "elseif type(x) == \"table\" then impls[rawget(x, TYPE_KEY)] else nil", "else impls[if type(x) == \"table\" then rawget(x, TYPE_KEY) else x]"),
]
only = set(sys.argv[1:])
for label, f, a, b in MUTS:
	if only and label.split()[0] not in only:
		continue
	base = tempfile.mkdtemp(prefix="stl-mut-r2-")
	try:
		for item in ["src", "tests", ".luaurc"]:
			s = os.path.join(REPO, item)
			(shutil.copytree if os.path.isdir(s) else shutil.copy)(s, os.path.join(base, item))
		p = os.path.join(base, f); t = open(p).read()
		assert t.count(a) == 1, (label, t.count(a))
		open(p, "w").write(t.replace(a, b))
		res = []
		for opt in ["-O1", "-O2"]:
			r = subprocess.run(["bash", "-c", f"ulimit -v 1048576; timeout 120 /code/.local/share/mise/installs/luau/0.742/luau {opt} tests/run.luau"], capture_output=True, text=True, cwd=base)
			out = r.stdout + r.stderr
			caught = r.returncode != 0 or "ALL SUITES PASS" not in out
			msg = next((l for l in out.splitlines() if "rror" in l or "assert" in l.lower() or "memory" in l), "")[:170]
			res.append((opt, caught, r.returncode, msg))
		caughtAny = any(c for _, c, _, _ in res)
		print(("잡힘 " if caughtAny else "생존 ") + label, " | ".join(f"{o} rc={rc} {m}" for o, _, rc, m in res), flush=True)
	finally:
		shutil.rmtree(base)
