fuzzel = require("fuzzel")
utf8 = require 'lua-utf8'
require "findfuzzy"
require "proceed"

function REM(n, m)	    -- debug print (and remark)
	if isDebugMode then
		if m then m =" ::"..m else m = "" end 
		print ("[debug] "..n..m);
	end
 end

s= "Ситроен С4 1  05-11  решетка радиатора"


--[[for f,v in pairs(Parts) do
   table.insert(P, f)
   if v ~="" then table.insert(P, f) end 
end]]




print(Proceed(s))


