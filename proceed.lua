dofile "findfuzzy.lua"
--local colors = require 'ansicolors'
dofile "models.lua"
dofile "parts.lua"
local utf8 = require 'lua-utf8'


function preparePrice(p)	--  исходную цену преобразуем в нужную валюту и текстовый формат
	p = utf8.gsub(p,"%s","")	    -- пробелы препятствуют tonumber
	p=tonumber(p)
	if not p then return nil end
	p = p * currate 			--	переводим в рубли согласно глобальной currate
	if p < Kn2	then			--  применяем глобальные умножители  Kx1,Kx2,Kx3 и их пороговые значения Kn2, Kn3
		p = p * Kx1
	elseif p < Kn3 then
		p = p * Kx2
	else 
		p = p * Kx3
	end	
	local function round(n, mult) 
		return math.ceil((n + mult/2)/mult) * mult
	end
	p=round(p,5)
	p=tostring(p)
	p = utf8.gsub(p,"%.",",")	    -- десятичную точку в запятую для русского Экселя
	return p
end

function dumpArray(T)
   for k, v in pairs(T) do
	  print (k,v)
   end
end
function defakeLatinLetters(s)
   s=utf8.upper(s)
   local T={ -- rus : lat
	  ["К"]="K",
	  ["Е"]="E",
	  ["Н"]="H",
	  ["Х"]="X",
	  ["В"]="B",
	  ["А"]="A",
	  ["Р"]="P",
	  ["О"]="O",
	  ["С"]="C",
	  ["М"]="M",
	  ["Т"]="T",
   }
   for k,v in pairs(T) do
	  s=utf8.gsub(s,v,k)
   end
   return s
end

for k,v in pairs (Models) do					  -- Автодополнение таблицы Models..
   for k2, v2 in pairs(v) do
      if v2=="" then
	 Models[k][k2]= defakeLatinLetters(k2)			  -- ..вариантами с русскими буквами вместо латинских аналогов
      end
   end
end

--dumpArray(Models["Citroen"])



function detectMark(s,a )
   local P={}
   for f,v in pairs(Models) do
	  table.insert(P, f)
      if  v.nam ~="" then table.insert(P, v.nam) end    
   end
 
   local r = recognizeFuzzyPatterns(s, P) or recognizeFuzzyPatterns(a, P)
   
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

function detectModel(s, a, mark)
   local P={}
   if Models[mark] then
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
    local r = recognizeFuzzyPatterns(s, P) or recognizeFuzzyPatterns(a, P)
    -- print ("-----",r)
    if not Models[mark][r] then
      for f,v in pairs(Models[mark]) do
           --print (f.."|"..v.."|"..r) 		 
           if v == r then
          --print ("--") 	
          return f
           end
      end
    else
      return r
    end
  else return nil
  end
end

function detectPart(s, a)
   local P={}
   for f,v in pairs(Parts) do
	  table.insert(P, f)
      if  v ~="" then table.insert(P, v) end    
   end

   local r = recognizeFuzzyPatterns(s, P) or recognizeFuzzyPatterns(a, P)
   
   if not r then      	  
      	  return ("Прочая запчасть")
   elseif not Parts[r] then
	  for f,v in pairs(Parts) do
		 if v == r then
			return f
		 end
	  end
   else
	  return r
   end
end


local function clearJunk(a)
	a = utf8.gsub(a,"%("," ")			-- чистим от скобок
	a = utf8.gsub(a,"%)"," ")			-- чистим от скобок
	a = utf8.gsub(a,"%s+%l(%s+%d%d%d%d%s+)", "%1") 
    a = utf8.gsub(a,"(%d%d%s?)г%. ", "%1 ")  
    a = utf8.gsub(a,"Рэйндж%s+Ровер","Land-Rover Range Rover")
    a = utf8.gsub(a,"Ренжд%sРовер","Land-Rover Range Rover")
    a = utf8.gsub(a,"Лэнд%s+Ровер","Land-Rover")
    a = utf8.gsub(a,"Ленд%s+Ровер","Land-Rover")
    a = utf8.gsub(a,"Рендж%s+Ровер","Land-Rover Range Rover")
    a = utf8.gsub(a,"Грейт%s+Волл","Great-Wall")
    a = utf8.gsub(a,"Мерседес%s+Бенц","Mercedes")
    a = utf8.gsub(a,"Ссанг%s+Йонг","SsangYong")
	return a
end

local function trimSpaces(s)     --> строку s без пробелов в начале и конце
   return (utf8.match(s, "^%s*(.-)%s*$") )
end

function singleYear(d)		 --> преобразованная в 4 цифры строку d (год или интервал лет через тире)
     d=trimSpaces(d)
     local pos = d:find("-")
     if pos then
	 d = d:sub(1,pos-1) 
     end
	 if d:len() > 4 then
		pos = d:find("%d%d%d%d")
		if pos then 
			d=d:sub(pos,pos+4)
		end
	 end
     if d:len() == 2 then d = "20"..d end
     --d=d:sub(1,4)
     return d
end

local function parseStr (a)							REM (">>> parseStr", a)						         
 
    local Mk, Md, Vs, Yr = ""
    
    Mk,a = utf8.match(a, "([%w-]+)(.+)")		REM ("вырезаем марку (первое слово)", Mk)

    local pb, pe = utf8.find(a, " %d%d%d?%d?-?%d%d%d?%d?%+? ")   REM ("ищем год")

    if pb then						REM ("год найден", utf8.sub(a,pb,pe))
	Md = utf8.sub(a,1,pb-1)				-- вырезаем модель и год
	Yr = utf8.sub(a,pb,pe)
	a = utf8.sub(a,pe+1)    
    else						REM ("год не найден")
	pb, pe = utf8.find(a, " %a?%a?рест%a* ")	    
	if pb then					REM ("найдено рестайл/дорестайл")
	    Md = utf8.sub(a,1,pe)
	    a = utf8.sub(a,pe+1)
	else						
	    pb, pe = utf8.find(a, "%s?%-?%d%s+")
	    if pb then					REM ("найдена одиночная цифра в середине строки")
		Md = utf8.sub(a,1,pe)			REM ("считаем это номером Модели", Md) 
		a = utf8.sub(a,pe+1)
	    else
		pb, pe = utf8.find(a, "[qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM-/]+%s+%d?%d?%d?")			
		  if pb  then				REM ("найдено английское слово в середине строки")
		  Md = utf8.sub(a,1,pe)			REM ("считаем это Моделью", Md)
		  a = utf8.sub(a,pe+1)  
		else					
		    --local fu1, fu2 = utf8.find(a, "[%w-/]+% ")
		    --debp(fu1, utf8.sub(a, fu1, fu2))
		    Md,a = utf8.match(a, "([%w-/]+ )(.+)"); 	REM ("за неимением Модели вырезаем первое слово", Md)
		end
	    end
	end
    end
    
    if a== "" then					    REM ("нет текста описания, выдираем из Md")
	local Md2 = utf8.reverse(Md)
	a,Md2 = utf8.match(Md2, "([%dйцукенгшщзхъфывапролджэячсмитьбюЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ ]+)(.+)")
	-- print (Md, a, Md2)
	if a then a = utf8.reverse(a) end
	Md = utf8.reverse(Md2)
    end
    
    if a == nil then								REM ("Описания детали не найдено, обработке не подлежит")
		return nil, nil, nil, nil, nil
	end				    
    
    --print (Mk, Md, Vs, Yr, a)
    if utf8.find(a,"^%s*%w?%d%d?%d?%w? ") then		    REM ("получилось, что описание начинается цифрово-букв. индексом (напр. T100)")
	--print( utf8.sub(a, utf8.find(a,"^%s+%w?%d%d?%d?%w? ")) )
	pb, pe = utf8.find(a,"^%s*%w?%d%d?%d?%w? ")
	Vs = utf8.sub(a, pb,pe)				     REM("считаем это версией", Vs)
	a = utf8.sub(a, pe+1)
    end
    if utf8.find(a,"^%s*%u ") then			    REM ("получилось, что описание начинается одиночной заглавной буквой)")
	--print( utf8.sub(a, utf8.find(a,"^%s+%w?%d%d?%d?%w? ")) )
	pb, pe = utf8.find(a,"^%s*%u ")
	Vs = utf8.sub(a, pb,pe)				    REM ("считаем это версией", Vs)
	a = utf8.sub(a, pe+1)
    end

    if Md == "" then					    REM ("модель не определена")
	if utf8.find(Yr,"%s*%d00%d") then		    REM ("видимо то, что мы посчитали годом, это цифровое обознач. модели (напр. 3008)",Yr)
	    Md = Yr; Yr=""
	    if Vs and utf8.find(Vs,"^%s*%d+") then	    REM("видимо то, что мы посчитали версией, это год")
		Yr = Vs; Vs =""
	    end
	    if Yr=="" then				    REM ("год не определён")					    
		local pb, pe = utf8.find(a, "^%s*%d%d%d?%d?-?%d%d%d?%d?%+? ") 
		if pb then						
		    Yr = utf8.sub(a,pb,pe)		    REM ("год найден", Yr)
		    a = utf8.sub(a,pe+1)    
		end
	    end
	end
    end

    return Mk,Md, Vs, Yr, a
end



function Proceed(a) 							REM (">> Proceed", a)
	a=clearJunk(a)	
	local Mk, Md, Vs, Yr, Dt = parseStr (a)	
	local Mk2=detectMark(Mk, a)
	if not Mk2 then
	    print(a, colors("%{redbg}Mark is not recognized"), Mk)
	    return nil
	end

	local Md2=detectModel(Md,a,Mk2)
	
	if not Md2 then
	    print(a, colors("%{redbg}Model is not recognized"))
	    Md2 = Md
	end
	
	local Dt2=detectPart(Dt, a)
	
	if not Yr then
	    Yr=2015
	else
	    Yr=singleYear(Yr)
	end


	return Mk2, Md2, Vs, Yr, Dt2
end








function Sign()
	return(colors('░▒▓█%{reverse} A-D-E  %{reset}  v.2.0.0 © Michael.Voitovich@gmail.com, 2017-2018'))
end


