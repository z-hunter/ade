local fuzzel = require("fuzzel")
local utf8 = require 'lua-utf8'


function findFuzzy(str, Pat) --> наиболее _похожую_ строку из текст. шаблонов Pat, которая найдена в str, или nil, если похожей не найдено
-- Pat может быть строковой переменной или масивом строк. Регистр не различается.
-- Учитывается разбиение на слова. Слова в str состоят из букв, цифр, тире и подчёркиваний, остальные символы это разделители слов.
-- Шаблон ишется начиная с начала слова, не с середины.
-- При оценке вхождения учитываются _все_ символы (перед вызовом надо следить за двойными пробелами и пр. мусором в str)

	str=utf8.lower(str)
	local best_match=10000
	local r, ret
	local slen=utf8.len(str)
	for _, pat in pairs(Pat) do													-- Для каждого элемента Pats 
		pat=utf8.lower(pat)
		local plen=utf8.len(pat)
		print(str, pat, plen)
		local best_location, cur_diff, wlen, tlen, mlen
		local k, e = 1
		while k do																-- Сканирование вдоль строки
			k = utf8.find(str, '[%w%-%_]', k)									-- нацеливаемся на начало следующего слова
			e = utf8.find(str, '[^%w%-%_]', k)
			e = e or slen
			if k then 
				wlen = utf8.len( utf8.sub(str,k,e-1))  			-- считаем длину слова
				tlen = math.max(wlen,plen)          	-- анализируем цепочку длиной в самый длинный элемент									
				--mlen = math.min(wlen,plen)
			else break 
			end
			r, cur_diff=fuzzel.FuzzyFindDistance(utf8.sub(str, k,k+tlen-1), Pat)			
			if (best_match > cur_diff) and (cur_diff <= tlen) then				-- не рассматриваем если нет хотя бы одного общего символа
				ret = r
				best_match = cur_diff
				print ('bingo')
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

local a = findFuzzy("Ситроен С4 2 (11-16) фонарь левый", {"фонарь задний левый", "задний левый фонарь" , "мясо", "00" })
print('----\n',a)


                
