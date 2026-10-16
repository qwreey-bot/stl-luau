import subprocess

tests = [
    ("collection_ofmut_arrread", '''
local stl = require("../src")
local a = stl.Arr.Of(1, 2)
local r: stl.ArrRead<number> = a
local m = stl.Collection.OfMut(r)
''', "stl.Collection.OfMut(arrRead)"),

    ("collection_ofmut_cdread", '''
local stl = require("../src")
local cd = stl.CircularDeque.Of(1, 2)
local r: stl.CircularDequeRead<number> = cd
local m = stl.Collection.OfMut(r)
''', "stl.Collection.OfMut(cdRead)"),

    ("collection_ofmut_ldread", '''
local stl = require("../src")
local ld = stl.LinkedDeque.Of(1, 2)
local r: stl.LinkedDequeRead<number> = ld
local m = stl.Collection.OfMut(r)
''', "stl.Collection.OfMut(ldRead)"),

    ("deque_ofmut_cdread", '''
local stl = require("../src")
local cd = stl.CircularDeque.Of(1, 2)
local r: stl.CircularDequeRead<number> = cd
local m = stl.Deque.OfMut(r)
''', "stl.Deque.OfMut(cdRead)"),

    ("deque_ofmut_ldread", '''
local stl = require("../src")
local ld = stl.LinkedDeque.Of(1, 2)
local r: stl.LinkedDequeRead<number> = ld
local m = stl.Deque.OfMut(r)
''', "stl.Deque.OfMut(ldRead)"),

    ("stack_ofmut_stackread", '''
local stl = require("../src")
local a = stl.Arr.Of(1, 2)
local r: stl.ArrRead<number> = a
local asPeek: <T>(a: stl.ArrRead<T>) -> stl.StackRead<T> = stl.Trait.Converter(stl.Stack, stl.Arr)
local s = asPeek(r)
local m = stl.Stack.OfMut(s)
''', "stl.Stack.OfMut(stackRead)"),

    ("queue_ofmut_queueread", '''
local stl = require("../src")
local cd = stl.CircularDeque.Of(1, 2)
local r: stl.CircularDequeRead<number> = cd
local asQueue: <T>(d: stl.CircularDequeRead<T>) -> stl.QueueRead<T> = stl.Deque.AsQueueRead
local q = asQueue(r)
local m = stl.Queue.OfMut(q)
''', "stl.Queue.OfMut(queueRead)"),
]

for name, code, desc in tests:
    path = f".agy-probes/test_ofmut_{name}.luau"
    full_code = "--!strict\n" + code
    with open(path, "w") as f:
        f.write(full_code)
    res = subprocess.run(["luau-analyze", path], capture_output=True, text=True)
    has_error = (res.returncode != 0)
    print(f"[{name}] {'PASS (Rejected as expected)' if has_error else 'FAIL (Accepted!)'}: {desc}")
    if not has_error:
        print("  WARNING: Zero errors!")
    else:
        first_line = res.stdout.strip().split("\n")[0]
        print(f"  Error: {first_line}")
