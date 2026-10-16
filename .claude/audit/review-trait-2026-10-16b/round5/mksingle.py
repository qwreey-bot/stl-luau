import sys, re, os
sp, outdir = sys.argv[1], sys.argv[2]
base = open(sp).read().replace('require("../../../../src")', 'require("../src")')
n = 0
for path in sys.argv[3:]:
    t = open(path).read()
    a = t.index("return table.freeze({") + len("return table.freeze({")
    bend = t.index("\t\t})\n\tend)", a)
    block = t[a:bend]
    # 칸 단위로 자르기: 탭 셋으로 시작하는 "이름 = Trait." 줄에서
    parts = re.split(r"(?m)^(?=\t\t\t\w+ = Trait\.)", block)
    body = t[t.index("local b: MyBag<number>"):].split("\n")[1:]
    calls = []
    for line in body:
        if line.startswith("return"): break
        calls.append(line)
    tag = os.path.basename(path).split("-")[0]
    for part in parts:
        m = re.match(r"\t\t\t(\w+) = Trait\.", part)
        if not m or m.group(1) in ("ToList", "AddAll"): continue
        name = m.group(1)
        my = [c for c in calls if re.search(rf"\bBag\.{name}\b", c)]
        # 이어지는 지역 변수 참조(rw, m) 줄
        if name == "RetRw": my += [c for c in calls if "rw[1]" in c]
        if name == "RetMap": my += [c for c in calls if re.match(r"(local m\d|m\.a)", c)]
        my = [re.sub(r"\bBag\.", "Bag.", c) for c in my]
        s = base.replace("\t\t\t\tBucket = Trait.Fn", part.replace("\n\t\t\t", "\n\t\t\t\t").replace("\t\t\t" + name, "\t\t\t\tX" + name, 1).rstrip() + "\n\t\t\t\tBucket = Trait.Fn", 1)
        extra = "local arrS = stl.Arr.Of(\"a\")\nlocal w = { 1, 2 }\n" + "\n".join(c.replace("Bag." + name, "Bag.X" + name) for c in my) + "\n"
        s = s.replace("local canary: string = 1", extra + "local canary: string = 1")
        open(os.path.join(outdir, f"s-{tag}-{name}.luau"), "w").write(s); n += 1
print(n)
