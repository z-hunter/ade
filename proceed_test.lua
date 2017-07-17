local utf8 = require 'lua-utf8'
require 'proceed'

--a = "Ремонт бамперов, фар, пластика"
a = "Ивеко Стралис stralis топливный бак на 800 литров"
print (a)

local Mk, Md, Mv, Yr, Dt = Proceed(a)

print ("Итоговый вывод:")
print ("МОДЕЛЬ:",Mk,"МАРКА:",Md,"ВЕРСИЯ:",Mv,"ГОД ВЫПУСКА:",Yr,"ОПИСАНИЕ:",Dt)

