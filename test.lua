require "findfuzzy"
local utf8 = require 'lua-utf8'

s= "Мама мыла Раму, Кришну и Вишну"
P={
   "мыла мама Кришну и Раму",
   "Лада седан Баклажан",
   "Стив Балмер попал в ад к Стиву Джобсу",
   "Хари Кришна, хари Рама",
}

print (recognizeFuzzyPatterns(s, P))

   treshold = 50

	local function retWordN(str, n) --> слово номер n из строки str
		local e,b = 0
		local i=0
		repeat	
			b=e+1
			b = utf8.find(str, '[%w%-%_]', b)									-- нацеливаемся на начало следующего слова
			if not b then return nil end
			e = utf8.find(str, '[^%w%-%_]', b+1)
			e = e or utf8.len(str)+1
			i=i+1
		until (i==n)
		return(utf8.sub(str,b,e-1))
	end

   local function Percent(a, b)			--> сколько процентов a составляет от b
		return(a*100/b)
	end	

	local function MinOrNil(a,b ,vold, vnew)
		if not b then
			return nil, vold 
		elseif not a then
			return b, vnew
		else
			local r=math.min(a,b)
			if r ~=a  then 
				return r, vnew
			else
				return r, vold
			end
		end
	end


   local function  isValidE(e, slen, plen)		--> true если дистанция d между строками длниной spen и plen позволяет оценить их как похожие
		tlen = math.max(slen,plen)		
		
		print ( Percent(e, tlen),  treshold )
		if Percent(e, tlen) > treshold then
			return false
		else
			return true
		end
	end

--	print( MinOrNil(nil,2, "старый", "новый") )
