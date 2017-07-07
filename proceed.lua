local utf8 = require 'lua-utf8'


function Proceed (a)	
	a = utf8.gsub(a,"%("," ")			-- чистим от скобок
	a = utf8.gsub(a,"%)"," ")			-- чистим от скобок
	a = utf8.gsub(a,"%s+%l(%s+%d%d%d%d%s+)", "%1") 
    a = utf8.gsub(a,"(%d%d%s?)г%. ", "%1 ")  
    a = utf8.gsub(a,"Рэйндж%s+Ровер","Range Rover")
    a = utf8.gsub(a,"Ренжд%sРовер","Range Rover")
    a = utf8.gsub(a,"Лэнд%s+Ровер","Land-Rover")
    a = utf8.gsub(a,"Ленд%s+Ровер","Land-Rover")
    a = utf8.gsub(a,"Рендж%s+Ровер","Range Rover")
    a = utf8.gsub(a,"Грейт%s+Волл","Great-Wall")
    a = utf8.gsub(a,"Мерседес%s+Бенц","Mercedes")
    a = utf8.gsub(a,"Ссанг%s+Йонг","SsangYong")
    a = utf8.gsub(a,"Он%s+До","Он_До")


						         REM (">>>> Proceed", a)
 
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





function Sign()
	return'Ϟ   A-D-Extractor v.0.5 (c) Michael.Voitovich@gmail.com, 2017  '
end
