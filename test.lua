local fuzzel = require("fuzzel")
local utf8 = require 'lua-utf8'


function findFuzzy(str, pat)
	print(str, pat)
	local best_match=1000
	local best_location
	for k=1,#str-#pat+1 do
        local cur_diff=fuzzel.LevenshteinDistance(utf8.sub(k,k+#pat-1),pat)
        if  cur_diff < best_match then
            best_location = k
            best_match = cur_diff
        end
	end
	local start,ending = math.max(1,best_location), math.min(best_location+#pat-1,#str)
	print (best_match)
	return start,ending,utf8.sub(str, start,ending)
end


print (findFuzzy("Мама мыла раму", "Рама"))
                
