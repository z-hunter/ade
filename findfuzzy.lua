local fuzzel = require("fuzzel")

function findFuzzy2(str, pat)
	
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
	
	local bestSum=10000
	local sum=0
	local Str=convertStrToTable(str)
	local Pat=convertStrToTable(pat)
	
	for _,v in pairs(Str) do
		for _,v2 in pairs(Pat) do
			local sum=sum+fuzzel.FuzzyFindDistance(v1,v2)
			if sum<bestSum then
				bestSum=Sum
			end
		end
	end
	

end



function findFuzzy(str, Pat) --> наиболее _похожую_ строку из Pat, которая найдена в str, или nil, если похожей не найдено
-- Pat должен быть массивом строк. Регистр не различается.
-- Учитывается разбиение на слова. Слова в str состоят из букв, цифр, тире и подчёркиваний, остальные символы это разделители слов.
-- Шаблон ишется начиная с начала слова, не с середины.
-- При оценке вхождения учитываются _все_ символы (перед вызовом надо следить за двойными пробелами и пр. мусором в str)
	
	trashold = 0    --max percent of changes relative to str lenght ( len(str) is 100% )

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


                
