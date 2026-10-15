import sys, runpy, os, shutil, tempfile, subprocess
REPO="/code/Projects/stl-luau"
muts = {m[0].split()[0]: m for m in runpy.run_path(sys.argv[1])["MUTATIONS"]}
for key in sys.argv[3:]:
    label, f, old, new = muts[key]
    base = tempfile.mkdtemp(prefix="stl-mutrt-")
    for item in ["src", ".luaurc", ".claude"]:
        s=os.path.join(REPO,item); (shutil.copytree if os.path.isdir(s) else shutil.copy)(s, os.path.join(base,item))
    p=os.path.join(base,f); t=open(p).read(); assert t.count(old)==1; open(p,"w").write(t.replace(old,new))
    probe=os.path.join(base,".claude/audit/review-trait-2026-10-15/r1",sys.argv[2])
    r=subprocess.run(["bash","-c",f"ulimit -v 1048576; timeout 60 /code/.local/share/mise/installs/luau/0.742/luau {os.path.basename(probe)}"],capture_output=True,text=True,cwd=os.path.dirname(probe))
    print(key, "rc", r.returncode, " | ".join(l for l in (r.stdout+r.stderr).splitlines() if "FAIL" in l or "fails" in l or "rror" in l)[:300])
    shutil.rmtree(base)
