require "findfuzzy"
local fuzzel = require("fuzzel")
local utf8 = require 'lua-utf8'

s= " Мерседес Е-бург W210 (02-09) крыло заднее левое"
dofile "parts.lua"
dofile "models.lua"

--[[for f,v in pairs(Parts) do
   table.insert(P, f)
   if v ~="" then table.insert(P, f) end 
end]]

function dumpArray(T)
   for k, v in pairs(T) do
	  print (k,v)
   end
end

function detectMark(s)
   local P={}
   for f,v in pairs(Models) do
	  table.insert(P, f)
      if  v.nam ~="" then table.insert(P, v.nam) end    
   end

   local r = recognizeFuzzyPatterns(s, P)
   
   if not Models[r] then
	  for f,v in pairs(Models) do
		 if v.nam == r then
			return f
		 end
	  end
   else
	  return r
   end
end

function detectModel(s, mark)
   local P={}
   for f,v in pairs(Models[mark]) do
	  if f ~="nam" then		 
		 table.insert(P, f)
		 if  v ~="" then
			table.insert(P, v)
		 end    
	  end
   end
   --dumpArray(P)
   --print()
  local r = recognizeFuzzyPatterns(s, P)
   -- print (r)
  if not Models[mark][r] then
	  for f,v in pairs(Models[mark]) do
		 if v == r then
			return f
		 end
	  end
  else
	  return r
  end
end


mk=detectMark(s)
print "-----"
md=detectModel(s,mk)
print (s,"=",mk, md)


  
