local url = "https://www.avito.ru/avtofortune"
local urlroot = "https://www.avito.ru"
local urlpost = "/rossiya?p="
local urladepics = "http://d0009440.atservers.net/adepics/"										-- http путь до картинок, должен оканчиватся "/adepics/"
local Kx1 = 1						-- Ценовой умножитель 1
local Kx2 = 1.1						-- Ценовой умножитель 2
local Kn = 200						-- Порог цены, ниже которого умножается на Kx1 а с него и выше на Kx2

require 'proceed'
os.execute("cls")  print(Sign())  os.execute("chcp 65001 >nul")
colors = require 'ansicolors'
require 'luacurl'
require 'harvester'
utf8 = require 'lua-utf8'
require 'sha1'

-- Шаблон парсинга страниц 
harvester = newHarvester[[		
	 {repeat e}
        <div class="item_table-header">
        <h3 class="title item-description-title"> <a class="item-description-title-link" href="{value link}"
		title="
		">{value title} </a>
		<div class="about">{value price}руб.
		</div> </div> </div> </div>
     {/repeat}
]]										
-- Шаблон парсинга подстраниц на предмет картинок
harvester2 = newHarvester[[
		{repeat e}
		<meta property="og:image" content="{value piclink}"
		{/repeat} 
]]

--isDebugMode = true						
 

function getCurrate()			    --> стоимость одного российского рубля в белорусских
    local harvester3=newHarvester[[
      <td><a href="/currency/rub">Российский рубль
      <span class="bl_rub_ex">{value currate}</span>
    ]]
    local page = get("https://myfin.by/currency/rub/")
    local tmp = harvester3.harvest(page)
    local ret = tmp.currate
    ret = utf8.gsub(ret,"%s","")
    return tonumber(ret)/100
end

outLog = {}

outLog.doInput = function ()						--> Parts table or nil if no file
	--isDebugMode=true
	local function parseCSVLine (line) 
		local res = {}
		local pos = 1
		sep = ';'
		while true do 
			local c = string.sub(line,pos,pos)
			if (c == "") then break end
			if (c == '"') then
				-- quoted value (ignore separator within)
				local txt = ""
				repeat
					local startp,endp = string.find(line,'^%b""',pos)
					txt = txt..string.sub(line,startp+1,endp-1)
					pos = endp + 1
					c = string.sub(line,pos,pos) 
					if (c == '"') then txt = txt..'"' end 
					-- check first char AFTER quoted string, if it is another
					-- quoted string without separator, then append it
					-- this is the way to "escape" the quote char in a quote. example:
					--   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
				until (c ~= '"')
				table.insert(res,txt)
				assert(c == sep or c == "")
				pos = pos + 1
			else	
				-- no quotes used, just look for the first separator
				local startp,endp = string.find(line,sep,pos)
				if (startp) then 
					table.insert(res,string.sub(line,pos,startp-1))
					pos = endp + 1
				else
					-- no separator found -> use rest of string and terminate
					table.insert(res,string.sub(line,pos))
					break
				end 
			end
		end
		return res
	end
		
	local f, err = io.open("out/data.csv", 'r')   
	if not f then return nil; end
	print ("Previos out\data.csv found, reading...")
	local tParts = {}
	local num = 1
	for line in f:lines() do
		--*1МАРКА	*2МОДЕЛЬ	3ВЕРСИЯ	*4ГОД	5ТОПЛИВО	6ОБЪЕМ	7ТИП_ДВИГ	8КОРОБКА	9ТИП_КУЗОВА	*10ЗАПЧАСТЬ	11ОПИСАНИЕ
		--12ОРИГ_НОМЕР	13СКЛАДСК_ИНФ 14ЦЕНА	15ВАЛЮТА	16СКИДКА	17ГОРОД	18ТЕЛЕФОНЫ	19EMAIL	20ИМЯ	21ФОТО	22ID_ABW	*23ID_EXT		
		local t=parseCSVLine(line) 
		tParts[t[23]] = {}										REM(t[23])
		local T = tParts[t[23]]		
		T.num = num
		T.Mk, T.Md, T.Vs, T.Yr = t[1], t[2], t[3], t[4]
		T.Dt, T.De, T.Url, T.Pr, T.Pics = t[10], t[11], t[13], t[14], t[21]
		REM ("Mk="..tParts[t[23]].Mk.." Md="..tParts[t[23]].Md.." Yr="..tParts[t[23]].Yr.." Dt="..tParts[t[23]].Dt)	    

		-- отрезаем urladepics и превращаем строку в таблицу с именами файлов
		local picst = T.Pics												REM("Превращаем строку urls в таблицу", picst)
		T.Pics = {} 
		local pe, pb = 1,1
		
		if utf8.find(picst, ",") then 											REM("  в строке запятые, значит несколько url")
			while utf8.find(picst, ",", pe) do
				_, pe = utf8.find(picst, ",", pe)
				table.insert(T.Pics, utf8.sub(picst, pb, pe-1))
				pe = pe+1; pb=pe
			end 
			table.insert(T.Pics, utf8.sub(picst, pe))
		else																	REM("  тут один url")
			table.insert(T.Pics, picst)
		end
		for k2, v2 in pairs(T.Pics) do												
				local _, p = utf8.find (v2, "/adepics/")							
				v2 = utf8.sub(v2, p+1)
				T.Pics[k2] =  v2; REM(k2, T.Pics[k2])
		end

		num = num+1
	end
	print (">>> Previous records loaded from out/data.csv: "..num-1)
	
	f:close()
	return tParts
end

outLog.init = function()		    -- подготовить выходной каталог и создать/обнулить файл данных
   os.execute("copy /Y out\\data.csv *.bak >nul")  
   local f = io.open('out/TEST.txt', 'w')
   if not f then
	os.execute('mkdir out')
    else
        f:close()
	os.remove('out/TEST.txt')
   end
   local f, ermsg = io.open("out/data.csv", 'w')   -- Открываем на перезапись
   print ("Output file: out/data.csv", ermsg or '')
   f:close()
end
outLog.doOutput = function (Parts)	    -- Добавляет в data.csv записи Parts 
    local f = io.open("out/data.csv", 'a')   
    local excel=""													-- буфер 
	local count = 0
	for k, v in pairs(Parts) do                							REM ("Пишем в csv деталь", v.Mk..v.Md..v.Dt)		
		local tmp = '"Mk";"Md";"Vs";"Yr";;;;;;"Dt";"De";;"Url";"Pr";"BYR";;;;;;"Pic";;"Id";'
		--*1МАРКА	*2МОДЕЛЬ	3ВЕРСИЯ	*4ГОД	5ТОПЛИВО	6ОБЪЕМ	7ТИП_ДВИГ	8КОРОБКА	9ТИП_КУЗОВА	*10ЗАПЧАСТЬ	11ОПИСАНИЕ
		--12ОРИГ_НОМЕР	13СКЛАДСК_ИНФ 14ЦЕНА	15ВАЛЮТА	16СКИДКА	17ГОРОД	18ТЕЛЕФОНЫ	19EMAIL	20ИМЯ	21ФОТО	22ID_ABW	*23ID_EXT
		
		for k2, v2 in pairs(v) do										-- подменяем в шаблоне названия полей записи Parts их содержимым
			tmp = utf8.gsub(tmp, k2, v2)
		end
		tmp = utf8.gsub(tmp, "Id", k)									-- хэш в качестве Id
		local pic = ""
		for k2, v2 in pairs (v.Pics) do
			pic = pic..urladepics..v2
			if v.Pics[k2+1] then pic = pic..","; end
		end
		tmp = utf8.gsub(tmp, "Pic", pic)	
		excel=(excel..tmp.."\n")										-- добавляем получившуюся строку в буфер
		count = count+1
	end
    assert(f:write(excel))												-- добавляем буфер к файлу
	print ("Saved "..count.." items in file")
	f:flush()
	f:close()
end


function procParts(Parts)					--удалить из базы неактуальные записи, стереть картинки, посчитать статистику
	--isDebugMode=true
	local sok, snew, sdel = 0,0,0			REM(">>> procParts()")
	for k, v in pairs(Parts) do				REM( "Проверяем", _)
		if v.status == "new" then			REM("- новый")
			v.status = "done"
			snew=snew+1
		elseif v.status == "ok" then			REM("- старый подтвержденный")
			v.status = "done"  
			sok=sok+1
		elseif not v.status  then			REM("- старый не подтвержденный")
			sdel=sdel+1
			for _, v2 in pairs(v.Pics) do	
				err = os.remove('out/'..v2);	
				print ("Deleting file "..v2, err or '' )
			end
			Parts[k] = nil							--гуд бай, запись
		end
	end
	return sok, snew, sdel
end

function getParts(Parts, page)				-- page =текст страницы --> table Parts: .Mk, .Md, .Vs, .Yr, .Pr, .Dt, Pics{}, status
																										-- Марка, Модель, Версия, Год, Цена, Название, Картинки
	
	--isDebugMode=true
    local cooldownCount = 12		    	-- сколько подстраниц запрашивать до тайм-аута
    local cooldownTime = 10		    		-- длительность тайм-аута, сек.
    local CC = cooldownCount
    local CT = cooldownTime


    local data = harvester.harvest(page)

	local loadedQ, serrors = 0, 0						-- счётчики загруженных из сети позиций и пропущенных из-за ошибки
	for _, v in pairs(data.e) do						-- проход по улову, состоящему из полей: .link, .title, .price 
			
		v.title = utf8.gsub(v.title,"\n","")			-- чистим текст от переводов строк
		v.title = utf8.gsub(v.title,"  "," ")			-- и от двойных пробелов
		
		if not v.price then 						-- если не выловлено строки с ценой, то не допускаем чтобы gsub выдал на ней ошибку
			print ("No price found, skipping item ", v.title);
			serrors = serrors+1
			break
		else										-- строка есть
			v.price = utf8.gsub(v.price,"%s","")	    -- пробелы препятствуют tonumber 
			v.price = tonumber(v.price)
			if not v.price then 						-- строка не переводится в число
				print (v.price, " : Not numeric in price str, skipping item ", v.title)
				serrors=serrors+1
				break
			end	
		end	
				
		local Mk, Md, Vs, Yr, Dt = Proceed(v.title)	   				-- парсим текст, получаем: Марку,Модель,Версию,Год,Название (остальное извлекли выше)
		if not Dt then 
			print ("Item Dt is not found, skipping item ", v.title);
			serrors = serrors+1
			break
		end		
										
	    local suburl=urlroot..v.link		-- ссылка на подстраницу с фото     
		local subpage						-- для текста подстраницы 
		local i = sha1(suburl)							REM( "Хэш", i)
		if not Parts[i] then												-- определяем, есть ли такая запись в базее
			Parts[i]={}									REM( "Cоздаём новую запись в Parts", Mk..Md..Dt)
			Parts[i].status="new"
			subpage=get(suburl, CT)		--									: subpage
			loadedQ=loadedQ+1
			if not subpage then
				print ("Cannot get subpage of item, skipping item ", v.title)	
				serrors=serrors+1
				break
			end
		else 											REM( "Подтверждена уже имеющаяся в Parts запись", Mk..Md..Dt)
			Parts[i].status="ok"
		end
		
		--Parts[i].num = num2
		--num2=num2+1
		Parts[i].De = v.title
	    Parts[i].Mk = Mk
	    Parts[i].Md = Md
	    Parts[i].Vs = Vs or ""
	    Parts[i].Yr = Yr or ""
		v.price = tostring(v.price * currate) --	переводим в рубли	    		
		v.price = utf8.gsub(v.price,"%.",",")	    -- десятичную точку в запятую для русского Экселя
	    Parts[i].Pr = v.price
	    Parts[i].Dt = Dt
	    print (v.title,"->"..Parts[i].Mk.."|"..Parts[i].Md.."|"..Parts[i].Vs.."|"..Parts[i].Yr.."|"..Parts[i].Pr.."|"..Parts[i].Dt)	    
	    if CC == 0 then
		CC = cooldownCount; CT = cooldownTime
	    else
		CC = CC-1; CT = nil
	    end
    
	    if Parts[i].status == "new" then 											REM("Это новая запись")
			Parts[i].Url = suburl
			local data2 = harvester2.harvest(subpage)
			data2.e[#data2.e] = nil			-- последняя ссылка на фото та-же что первая		

			if not data2.e[1] then 
				print ("Picture link is not found, skipping item.")
				serrors=serrors+1
				Parts[i]=nil; break
			end
		
			Parts[i].Pics ={}
			for j, w in pairs(data2.e) do
				local pic = get(w.piclink)    	
				if pic then
					local filename = i..'_'..j..'.jpg'
					do
						local f = io.open("out/"..filename, 'w+b')
						if f then 
							f:write(pic)
							--f:flush ()
							f:close()	
							REM (filename)
						else
							print ("Cannot create a file "..filename)
						end
					end
					table.insert (Parts[i].Pics, filename)
				end
				if not Parts[i].Pics[1] then
					print ("No pictures downloaded, skippig item")
					Parts[i]=nil; break
				end
			end
		end
    end
    return Parts, loadedQ, serrors	
end

function getNotEmpty(page, delay)
    local ret = get(page, delay)
	if ret == '' or utf8.find(ret,'заблокирован</title>')  then
		print (ret)
		print("Server disallow us. Game Over :(")  os.exit()
	end
    return ret
end;


-- --- -- -- -- -- -- -- --- -- -- -- -- -- -- --- -- -- -- -- -- 

-->>>> Start:
print (string.rep("-", string.len(Sign())))
local Hour1 = os.date("%H")
local Min1 = os.date("%M")
currate = getCurrate()
print ("1 RUB / 1 BYR = "..tostring(currate))

local page = getNotEmpty(url)				
local harvester = newHarvester[[ 
      <a class="pagination-page" href="/avtofortune/rossiya/zapchasti_i_aksessuary?p={value e}">Последняя</a>  
]]
local pq = harvester.harvest(page)	    -- ищем кол-во страниц
if not pq.e then
    --print (page)
    print ("Pages not found.")
    return
else
    pq = tonumber(utf8.match(pq.e,"=(%d+)$"))
    print ("Pages found:", pq)
end

local Parts = outLog.doInput() or {}
local loadedQ
local serrors=0
Parts, loadedQ, serrors = getParts(Parts, page)			-- обрабатываем первую отдельно (она уже загружена в page)
outLog.init()
outLog.doOutput(Parts)

for i=2, pq do					-- проходим по остальным страницам 
    local sertmp=0
	local newurl=url..urlpost..tostring(i)
    print( colors('%{redbg}Processing page #'..tostring(i)..' of '..tostring(pq)) )
	local delay 
	if loadedQ <9 then delay = nil
	else delay=300
	end
	page = getNotEmpty(newurl, delay)
    Parts,loadedQ,sertmp = getParts(Parts,page)					-- обрабатываем очередную
    if sertmp >0 then
		serrors=serrors+sertmp
		print ("errors: "..sertmp)
	end
	outLog.init()
	outLog.doOutput(Parts)
end


print ("Extraction finished. Finalysing output...")
outLog.init()
local sok, snew, sdel = procParts(Parts)
outLog.doOutput(Parts)
local Hour2 = os.date("%H")
local Min2 = os.date("%M")
print ("\n    TOTAL:\n    ------")
print (colors("%{redbg}New: "..snew.."  Confirmed: "..sok.."  Deleted: "..sdel.."  Errors: "..serrors))
print ("Elapsed time is "..tostring(Hour2-Hour1)..":"..tostring(Min2-Min1))




