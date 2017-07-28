local fuzzel = require("fuzzel")
local utf8 = require 'lua-utf8'

function recognizeFuzzyPatterns(str, Pat)
	
	local treshold = 30									--max percent of changes relative to str lenght ( len(str) is 100% )
	local treshold2 = 60									--минимальный процент слов образца которые должны быть похожи в строке
	
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

	local function convertStrToTable(str)	--> массив слов из строки str
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

	local function Percent(a, b)			--> сколько процентов a составляет от b
		return(a*100/b)
	end
	
	local function MinOrNil(a,b)
		if not b then
			return nil 
		elseif not a then
			return b
		else
			local r=math.min(a,b)
			if r ~=a  then 
				return r
			else
				return r
			end
		end
	end

	
   local function  isValidE(e, slen, plen)		--> true если дистанция d между строками длниной spen и plen позволяет оценить их как похожие
		tlen = math.max(slen,plen)				
		if Percent(e, tlen) > treshold then
			return false
		else
			return true
		end
	end

	
	local function calcEmin(str, Pat) --> минимальная дистанция среди результатов сравнения str со всеми строками массива Pat
												 --  или nil если, согласно оценке, похожих строк нет
		local min_e, e
		for _,v in pairs(Pat) do
			_,e =  fuzzel.FuzzyFindDistance( utf8.lower(str), utf8.lower(v) )

			--print (e, str, v, isValidE(e, utf8.len(str), utf8.len(v) ) )	-- -
			
			if isValidE(e, utf8.len(str), utf8.len(v) ) then 
				min_e = MinOrNil(min_e, e)
			end	
			
		end
		--print ("min_e", min_e)
		return min_e
	end

	
	local function calcQ(str, pat)  --> количество похожих слов в строках str и pat
		local Str=convertStrToTable(str)
		local Pat=convertStrToTable(pat)
		local q = 0
		for _,v in pairs(Str) do						-- Для каждого слова анализируемой строки
			if calcEmin(v, Pat) then
				q = q+1
			end
		end
		return q				
	end
	
          
	--///////////////////////////////

	
	local max_q, q, max_v = 0
	for _,v in pairs(P) do
	  q = calcQ(s,v)	  
	  print (q, v)
	  if q > max_q then
		 max_q=q
		 max_v=v
	  end
	end
	
	return max_v
end




function findFuzzy(str, Pat) --> наиболее _похожую_ строку из Pat, которая найдена в str, или nil, если похожей не найдено
-- Pat должен быть массивом строк. Регистр не различается.
-- Учитывается разбиение на слова. Слова в str состоят из букв, цифр, тире и подчёркиваний, остальные символы это разделители слов.
-- Шаблон ишется начиная с начала слова, не с середины.
-- При оценке вхождения учитываются _все_ символы (перед вызовом надо следить за двойными пробелами и пр. мусором в str)
	
	local trashold = 0    --max percent of changes relative to str lenght ( len(str) is 100% )

	--str=utf8.lower(str)
	local best_match=10000
	local r, ret
	local slen=utf8.len(str)
	for _, pat in pairs(Pat) do													-- Для каждого элемента Pats 
		--pat=utf8.lower(pat)
		print("---",pat)
		local plen=utf8.len(pat)
		if plen==0 then break end
		--print(">", str, pat, plen)
		local best_location, cur_diff, wlen, tlen, mlen
		local k, e = 1
		while k do																-- Сканирование вдоль строки
			k = utf8.find(str, '[%w%-%_]', k)									-- нацеливаемся на начало следующего слова
			e = utf8.find(str, '[^%w%-%_]', k)
			e = e or slen
			local cur_trashold = plen * trashold / 100
			
			if k then 
				wlen = utf8.len( utf8.sub(str,k,e-1))  			-- считаем длину слова
				tlen = math.max(wlen,plen)          			-- анализируем цепочку длиной в самый длинный элемент									
				--mlen = math.min(wlen,plen)
			else break 
			end
			r, cur_diff=fuzzel.FuzzyFindDistance(utf8.sub(str, k,k+tlen-1), pat)			
			if (best_match > cur_diff) and (cur_diff + cur_trashold  < utf8.len(r)) then				-- не рассматриваем если слишком высока дистанция
				ret = r
				best_match = cur_diff
				print ('///////bingo')
			end	
			print(utf8.sub(str, k,k+tlen-1), tlen, cur_diff, r)
			k=e+1
		end
		if ret then print ('best scan:', best_match, ret) end

	end	
	--local start,ending = math.max(1,best_location), math.min(best_location+#pat-1,#str)
	return ret
	--return utf8.sub(str, start,ending)
end

--local a = findFuzzy("Ситроен С4 2 (11-16) фонарь левый", {"задний фонарь", "бездарная тварь", "мясо", "00"})
--print('----\n',a)


                
