local utf8 = require 'lua-utf8'
os.execute("chcp 65001")
local fuzzel = require 'fuzzel'


 --A couple of options
        local options = {
            "Жирный кот",
	    "Жирный шрифт",
            "Lazy Dog",
            "Brown Fox",
        }

        --And use it, to see what option closest matches "Lulzy Cat"
        local close,distance = fuzzel.FuzzyFindDistance("мирный кот", options)
        print("\"мирный кот\" is close to \"" .. close .. "\", distance:" .. distance)

        --Sort the options to see the order in which they most closely match "Frag God"
        print("\"Frag God\" is closest to:")
        for k,v in ipairs(fuzzel.FuzzySortRatio("Frag God",options)) do
            print(k .. "\t:\t" .. v)
        end

---------------------------------------------------------------------------

function string.findFuzzy(str, t)
  
end


function string.trimSpaces(s)
   return (utf8.match(s, "^%s*(.-)%s*$") )
end


function string.translitRuEn(s)
   local t={
      ['a']   =  ' Z-',
      ['b']     =  '',
      ['c']     =  '',
      ['d']     =  '',
      ['e']     =  '',
      ['f']     =  '',
      
      ['']     =  '',
   }

   for k,v in pairs(t) do
      s = utf8.gsub(s, k, v)      
   end
   return(s)
end

a = string.translitRuEn("  Абв")
a = string.trimSpaces(a)
a= utf8.upper(a)

print(a)

print(utf8.len('Барсик'))
print(utf8.byte('Барсик',1))

