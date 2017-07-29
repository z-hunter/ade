require "findfuzzy"
require "proceed"
local fuzzel = require("fuzzel")
local utf8 = require 'lua-utf8'

function REM(n, m)	    -- debug print (and remark)
	if isDebugMode then
		if m then m =" ::"..m else m = "" end 
		print ("[debug] "..n..m);
	end
 end

s= " Ссанг Йонг Рекстон 2 (09-12) мкпп 5 ступка"


--[[for f,v in pairs(Parts) do
   table.insert(P, f)
   if v ~="" then table.insert(P, f) end 
end]]




print(s)
print (Proceed(s))


  
