require "findfuzzy"
local fuzzel = require("fuzzel")
local utf8 = require 'lua-utf8'

s= "Бмв BMW Х1 кузоа F48 (2015-2017) капот страховой"
P={}
dofile "parts.lua"


for f,v in pairs(Parts) do
   table.insert(P, f)
   if v ~="" then table.insert(P, f) end 
end

print (recognizeFuzzyPatterns(s, P))


  
