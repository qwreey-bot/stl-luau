import subprocess
import tempfile
import os

cases = [
    # (name, code, expect_error, description)
    ("map_get_wrong_key", '''
local stl = require("../src")
local tm = stl.TreeMap.New<<string, number>>(function(a: string, b: string) return if a < b then -1 elseif a > b then 1 else 0 end)
local x = stl.Map.Get(tm, 123)
''', True, "Map.Get with number key on TreeMap<string, number>"),

    ("map_set_wrong_key", '''
local stl = require("../src")
local tm = stl.TreeMap.New<<string, number>>(function(a: string, b: string) return if a < b then -1 elseif a > b then 1 else 0 end)
stl.Map.Set(tm, 123, 456)
''', True, "Map.Set with number key on TreeMap<string, number>"),

    ("map_set_wrong_val", '''
local stl = require("../src")
local tm = stl.TreeMap.New<<string, number>>(function(a: string, b: string) return if a < b then -1 elseif a > b then 1 else 0 end)
stl.Map.Set(tm, "key", "wrong")
''', True, "Map.Set with string val on TreeMap<string, number>"),

    ("set_has_wrong_item", '''
local stl = require("../src")
local hs = stl.HashSet.Of("a", "b")
local x = stl.Set.Has(hs, 123)
''', True, "Set.Has with number item on HashSet<string>"),

    ("set_add_wrong_item", '''
local stl = require("../src")
local hs = stl.HashSet.Of("a", "b")
stl.Set.Add(hs, 123)
''', True, "Set.Add with number item on HashSet<string>"),

    ("list_get_wrong_idx", '''
local stl = require("../src")
local arr = stl.Arr.Of(1, 2)
local x = stl.List.Get(arr, "wrong")
''', True, "List.Get with string idx on Arr<number>"),

    ("list_indexof_wrong_elem", '''
local stl = require("../src")
local arr = stl.Arr.Of(1, 2)
local x = stl.List.IndexOf(arr, "wrong")
''', True, "List.IndexOf with string item on Arr<number>"),

    ("deque_pushback_wrong_elem", '''
local stl = require("../src")
local cd = stl.CircularDeque.Of(1, 2)
stl.Deque.PushBack(cd, "wrong")
''', True, "Deque.PushBack with string elem on CircularDeque<number>"),

    ("deque_pushback_borrowed", '''
local stl = require("../src")
local cd = stl.CircularDeque.Of(1, 2)
local r: stl.CircularDequeRead<number> = cd
stl.Deque.PushBack(r, 3)
''', True, "Deque.PushBack on CircularDequeRead"),

    ("deque_popback_borrowed", '''
local stl = require("../src")
local cd = stl.CircularDeque.Of(1, 2)
local r: stl.CircularDequeRead<number> = cd
local x = stl.Deque.PopBack(r)
''', True, "Deque.PopBack on CircularDequeRead"),

    ("collection_clear_arrread", '''
local stl = require("../src")
local a = stl.Arr.Of(1, 2)
local r: stl.ArrRead<number> = a
stl.Collection.Clear(r)
''', True, "Collection.Clear on ArrRead"),

    ("collection_clear_cdread", '''
local stl = require("../src")
local cd = stl.CircularDeque.Of(1, 2)
local r: stl.CircularDequeRead<number> = cd
stl.Collection.Clear(r)
''', True, "Collection.Clear on CircularDequeRead"),

    ("collection_clear_ldread", '''
local stl = require("../src")
local ld = stl.LinkedDeque.Of(1, 2)
local r: stl.LinkedDequeRead<number> = ld
stl.Collection.Clear(r)
''', True, "Collection.Clear on LinkedDequeRead"),

    ("stack_push_borrowed", '''
local stl = require("../src")
local a = stl.Arr.Of(1, 2)
local r: stl.ArrRead<number> = a
local asPeek: <T>(a: stl.ArrRead<T>) -> stl.StackRead<T> = stl.Trait.Converter(stl.Stack, stl.Arr)
local s = asPeek(r)
stl.Stack.Push(s, 3)
''', True, "Stack.Push on StackRead"),

    ("stack_pop_borrowed", '''
local stl = require("../src")
local a = stl.Arr.Of(1, 2)
local r: stl.ArrRead<number> = a
local asPeek: <T>(a: stl.ArrRead<T>) -> stl.StackRead<T> = stl.Trait.Converter(stl.Stack, stl.Arr)
local s = asPeek(r)
local x = stl.Stack.Pop(s)
''', True, "Stack.Pop on StackRead"),
]

for name, code, expect_error, desc in cases:
    path = f".agy-probes/test_{name}.luau"
    full_code = "--!strict\n" + code
    with open(path, "w") as f:
        f.write(full_code)
    res = subprocess.run(["luau-analyze", path], capture_output=True, text=True)
    has_error = (res.returncode != 0)
    print(f"[{name}] {'PASS' if has_error == expect_error else 'FAIL'}: {desc}")
    if has_error:
        print("  Error:", res.stdout.strip().replace("\n", "\n  "))
    else:
        print("  Zero errors!")
