import sys, re
sp, out = sys.argv[1], sys.argv[2]
srcs = sys.argv[3:]
s = open(sp).read().replace('require("../../../../src")', 'require("../src")')
slots_all, calls_all = [], []
for k, path in enumerate(srcs):
    pfx = f"Z{k}"
    t = open(path).read()
    a = t.index("return table.freeze({") + len("return table.freeze({")
    bend = t.index("\t\t})\n\tend)", a)
    block = t[a:bend]
    names = re.findall(r"^\t\t\t(\w+) = Trait\.", block, re.M)
    for n in names:
        block = re.sub(rf"^(\t\t\t){n} = ", rf"\g<1>{pfx}{n} = ", block, flags=re.M)
    slots_all.append(block.replace("\n\t\t\t", "\n\t\t\t\t"))
    body = t[t.index("local b: MyBag<number>"):].split("\n")[1:]
    for line in body:
        if line.startswith("return"): break
        if re.match(r"local (arr|arrS|w) = ", line): continue
        for n in names:
            line = re.sub(rf"\bBag\.{n}\b", f"Bag.{pfx}{n}", line)
        line = re.sub(r"\blocal (\w+)", lambda m: f"local {pfx}_{m.group(1)}", line) if "-- " in line or line.startswith("local") else line
        calls_all.append(line)
# 이름 바꾼 지역 변수 참조도: rw, m 같은 것
s = s.replace("\t\t\t\tBucket = Trait.Fn", "".join(slots_all).rstrip() + "\n\t\t\t\tBucket = Trait.Fn", 1)
extra = "local arrS = stl.Arr.Of(\"a\")\nlocal w = { 1, 2 }\n" + "\n".join(calls_all) + "\n"
s = s.replace("local canary: string = 1", extra + "local canary: string = 1")
open(out, "w").write(s)
