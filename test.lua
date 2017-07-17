utf8 = require 'lua-utf8'
colors = require 'ansicolors'
require 'luacurl'
require 'harvester'
require "proceed"

--print(Proceed("Мерседес Бенц А-класс W169 фара правая"))


local function retWordN(str, n)
		local e,b = 0
		local i=0
		repeat	
			b=e+1
			b = utf8.find(str, '[%w%-%_]', b)									-- нацеливаемся на начало следующего слова
			if not b then return nil end
			e = utf8.find(str, '[^%w%-%_]', b+1)
			e = e or utf8.len(str)
			i=i+1
		until (i==n)
		return(utf8.sub(str,b,e-1))
end

local function convertStrToTable(str)
		local T={}
		local wn=1
		while true do
			w = retWordN(str, wn)
			if not w then break end
			table.insert(T, w)
			wn=wn+1
		end
		return T
end


local T = convertStrToTable('Мама мыла Раму, и Кришну и Вишну')
print(T[5])

