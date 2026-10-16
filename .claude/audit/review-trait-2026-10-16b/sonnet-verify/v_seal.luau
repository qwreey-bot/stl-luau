local stl = require("../src")
print(table.isfrozen(stl.Arr), table.isfrozen(stl.CircularDeque), table.isfrozen(stl.List), table.isfrozen(stl.Trait))
print(pcall(function() (stl.Arr :: any).At = nil end))
print(stl.Arr.At)
