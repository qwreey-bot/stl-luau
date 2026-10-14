--!strict
type Overload = ((number) -> number) & ((string) -> string)
type Target = Overload | nil

local bad: Target = function(x: number): number return x end -- 이게 왜 0건인가?
local bad_str: Target = function(x: string): string return x end -- 이것도 0건인가?
local bad_bool: Target = function(x: boolean): boolean return x end -- 이것은?
local canary: string = 1
