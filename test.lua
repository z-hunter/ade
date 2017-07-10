local fuzzel = require("fuzzel")
local utf8 = require 'lua-utf8'


function findFuzzy(str, Pat) --> наиболее _похожую_ строку из текст. шаблонов Pat, которая найдена в str, или nil, если похожей не найдено
-- Pat может быть строковой переменной или масивом строк. Регистр не различается.
-- Учитывается разбиение на слова. Слова в str состоят из букв, цифр, тире и подчёркиваний, остальные символы это разделители слов.
-- Шаблон ишется начиная с начала слова, не с середины.

	str=utf8.lower(str)
	local best_match=10000
	local r, ret
	local slen=utf8.len(str)
	for _, pat in pairs(Pat) do													-- Для каждого элемента Pats 
		pat=utf8.lower(pat)
		local plen=utf8.len(pat)
		print(str, pat, plen)
		local best_location, cur_diff
		local k = 1
		while k do																-- Сканирование вдоль строки
			k = utf8.find(str, '[%w%-%_]', k)								-- нацеливаемся на начало следующего слова
			if not k then break end
			r, cur_diff=fuzzel.FuzzyFindDistance(utf8.sub(str, k,k+plen-1), Pat)
			-- print (k, cur_diff, utf8.sub(str, k, k+utf8.len(pat)-1))			
			if (best_match > cur_diff) then
				ret = r
				best_match = cur_diff
			end			
			k=k+1
		end
		if ret then print (best_match, ret) end

	end	
	--local start,ending = math.max(1,best_location), math.min(best_location+#pat-1,#str)
	return ret
	--return utf8.sub(str, start,ending)
end

local a = findFuzzy("Ситроен С4 2 (11-16) фонарь левый", {"фонарь задний левый", "задний левый фонарь" , "мясо", "00" })
print('----\n',a)


                
