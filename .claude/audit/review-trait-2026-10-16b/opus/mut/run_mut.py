# 돌연변이 하네스: 사본(base)을 매번 새 임시 폴더로 복사 → 정확히 한 군데 바꿈 → check.sh(스스로 4GB·300초 상한) → 종료 코드와 실패 게이트
import json, os, re, shutil, subprocess, sys, tempfile
BASE = sys.argv[1]
MUTS = json.load(open(sys.argv[2]))
only = set(sys.argv[3:])
for m in MUTS:
    if only and m["id"] not in only:
        continue
    d = tempfile.mkdtemp(prefix="mut-" + m["id"] + "-", dir=os.path.dirname(sys.argv[2]))
    for name in os.listdir(BASE):
        if name == "probes":
            continue
        s = os.path.join(BASE, name)
        (shutil.copytree if os.path.isdir(s) else shutil.copy2)(s, os.path.join(d, name))
    ok = True
    for edit in m["edits"]:
        p = os.path.join(d, edit["file"])
        src = open(p, encoding="utf-8").read()
        n = src.count(edit["old"])
        if n != 1:
            print(f"{m['id']}\tPATCH-FAIL({n})\t{edit['file']}")
            ok = False
            break
        open(p, "w", encoding="utf-8").write(src.replace(edit["old"], edit["new"]))
    if not ok:
        continue
    r = subprocess.run(["bash", "-c", "./scripts/check.sh"], cwd=d, capture_output=True, text=True, timeout=900)
    out = r.stdout + r.stderr
    gates = []
    m2 = re.search(r"총 (\d+)건", out)
    if m2 and m2.group(1) != "0":
        gates.append("type:" + m2.group(1))
    fails = [l for l in out.splitlines() if l.startswith("  →") or l.lstrip().startswith("FAIL") or "spikes/" in l and ("기대" in l or "줄" in l)][:4]
    print(f"{m['id']}\trc={r.returncode}\t{','.join(gates)}\t{' | '.join(x.strip()[:160] for x in fails)}")
    open(os.path.join(d, "check.log"), "w").write(out)
    sys.stdout.flush()
