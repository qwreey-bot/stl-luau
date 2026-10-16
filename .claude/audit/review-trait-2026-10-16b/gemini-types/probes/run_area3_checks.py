import subprocess

tests = [
    ("arr_invariant", '''
local stl = require("../src")
local a: stl.Arr<number> = stl.Arr.Of(1, 2)
local wide: stl.Arr<number?> = a
''', True, "Arr<number> assigned to Arr<number?> (should be rejected - invariance)"),

    ("arrread_covariant", '''
local stl = require("../src")
local a: stl.Arr<number> = stl.Arr.Of(1, 2)
local wide: stl.ArrRead<number?> = a
''', False, "Arr<number> assigned to ArrRead<number?> (should pass - covariance)"),

    ("arrconsumed_accepts_arr_covariant", '''
local stl = require("../src")
local a: stl.Arr<number?> = stl.Arr.Of(1, nil, 2)
local c: stl.Arr<number> = stl.Arr.CompactInplace(a)
''', False, "Arr.CompactInplace accepts Arr<number?>"),

    ("arrconsumed_rejects_arrread", '''
local stl = require("../src")
local a: stl.Arr<number?> = stl.Arr.Of(1, nil, 2)
local r: stl.ArrRead<number?> = a
local c = stl.Arr.CompactInplace(r)
''', True, "Arr.CompactInplace rejects ArrRead (should be rejected)"),

    ("map_widen_key_put", '''
local stl = require("../src")
local tm = stl.TreeMap.New<<string, number>>(function(a: string, b: string) return if a < b then -1 elseif a > b then 1 else 0 end)
local function putWide<K, V>(m: stl.Map<K, V>, k: K, v: V)
    stl.Map.Set(m, k, v)
end
putWide<<string | number, number>>(tm, 123, 456)
''', True, "Map with widened key type on put (should be rejected - invariance)"),

    ("map_widen_key_lookup", '''
local stl = require("../src")
local tm = stl.TreeMap.New<<string, number>>(function(a: string, b: string) return if a < b then -1 elseif a > b then 1 else 0 end)
local function getWide<K, V>(m: stl.Map<K, V>, k: K): V?
    return stl.Map.Get(m, k)
end
local x = getWide<<string | number, number>>(tm, 123)
''', True, "Map with widened key type on lookup (should be rejected - invariance)"),

    ("set_widen_item_put", '''
local stl = require("../src")
local hs = stl.HashSet.Of("a", "b")
local function addWide<T>(s: stl.Set<T>, item: T)
    stl.Set.Add(s, item)
end
addWide<<string | number>>(hs, 123)
''', True, "Set with widened item type on add (should be rejected - invariance)"),

    ("set_widen_item_lookup", '''
local stl = require("../src")
local hs = stl.HashSet.Of("a", "b")
local function hasWide<T>(s: stl.Set<T>, item: T): boolean
    return stl.Set.Has(s, item)
end
local x = hasWide<<string | number>>(hs, 123)
''', True, "Set with widened item type on has (should be rejected - invariance)"),
]

for name, code, expect_error, desc in tests:
    path = f".agy-probes/test_area3_{name}.luau"
    full_code = "--!strict\n" + code
    with open(path, "w") as f:
        f.write(full_code)
    res = subprocess.run(["luau-analyze", path], capture_output=True, text=True)
    has_error = (res.returncode != 0)
    status = "PASS" if (has_error == expect_error) else "FAIL"
    print(f"[{name}] {status}: {desc}")
    if has_error != expect_error:
        print("  Stdout:", res.stdout.strip())
