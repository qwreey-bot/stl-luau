--!strict
local stl = require("../src")
local Trait = stl.Trait
const Kind = Trait.Struct<<"P5b.Bag">>("P5b.Bag")
local tokOk: stl.TraitToken<"P5b.Bag"> = Kind.Token
const T2 = Trait.NewToken("P5b.Tok")
local tok2: stl.TraitToken<"P5b.Tok"> = T2
local canary: string = 1
return nil
