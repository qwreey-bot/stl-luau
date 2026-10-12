--!strict
local function F<T>(x: T, fn: (T, T) -> ()) end
local text: string = "x"
F(text, function(v: number) end) -- expected: error (string is not number)
F(text, function(v: number, _w) end) -- control: error is reported when the parameter is declared
