local stl = require("../src")
local cd = stl.CircularDeque.Of(1, 2)
local x = stl.List.Get(cd, "wrong")
print("x is:", x)
