import subprocess, sys, collections, re
tsv = {}
for line in open("scripts/spike-expectations.tsv", encoding="utf-8"):
    if line.startswith("#") or not line.strip(): continue
    parts = line.rstrip("\n").split("\t")
    if len(parts) >= 3: tsv[parts[1]] = parts[2]
for path in sys.argv[1:]:
    out = subprocess.run(["bash", "-c", f"ulimit -v 2097152; timeout 120 luau-analyze {path}"], capture_output=True, text=True).stderr
    errs = collections.defaultdict(list)
    for l in out.splitlines():
        m = re.search(r"\((\d+),\d+\): TypeError: (.*)", l)
        if m and path.split("/")[-1] in l: errs[int(m.group(1))].append(m.group(2)[:200])
    want = collections.Counter(int(x) for x in tsv.get(path, "").split(",") if x)
    got = collections.Counter({k: len(v) for k, v in errs.items()})
    print("==", path)
    src = open(path, encoding="utf-8").read().split("\n")
    for ln in sorted(set(want) | set(got)):
        if want[ln] != got[ln]:
            print(f"  {ln}: want {want[ln]} got {got[ln]} | {src[ln-1].strip()[:110]}")
            for e in errs.get(ln, [])[:2]: print("       ", e[:200])
