function sleep(n)
      if n > 0 then os.execute("ping -n " .. tonumber(n+1) .. " localhost > NUL") end
end

function REM(n, m)	    -- debug print (and remark)
	if isDebugMode then
		if m then m =" ::"..m else m = "" end 
		print ("[debug] "..n..m);
	end
 end


--[[
Harvester
by franciscus  
Documentation: http://software.artiztix.com/harvester/

Copyright (c) 2010 Artiztix Multimedia Inc

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]


-- NOTE: {contains} is deprecated and will be removed in the next release
-- version 105 - Changed to MIT license
-- Version 104 - Added support for {param}
-- Version 103 - Added support for {contains}
-- Version 102 - Added support for {delim}
-- Version 101 - Initial release

function Harvester_Version()
	return 105
end

function newHarvester(pattern)
-- Parses the given pattern
-- Returns:
--   1) a "harvester" object which has three methods
--       harvest(s)
--       setparam(name,value)
--       dump(printfunc)
--   2) an error message (or nil)

	local _syntax
	local _param = {}

	-- Pattern Lexical analyzer ====================================

	local LDELIM = "{";
	local RDELIM = "}";
	local COMMENT = "^{%*.-%*}";
	local DELIMTOKEN = "^{delim (..)}";
	local TOKEN = "^{(%a+)%s+(%a[%a%d_]*)%s*}";
	local TOKENONLY = "^{(%a+)%s*}";
	local ENDTOKENONLY = "^{(/%a+)%s*}";
	local BADTOKEN = "^{(/?.-)}";
	local ENDOFSTRING = "[^{\n]*";

	local function setdelim(ldelim, rdelim)
		LDELIM = ldelim;
		RDELIM = rdelim;
		-- In patterns below, special characters must be escaped
		if string.find("^$()%.[]*+-?", ldelim, 0, true) then
			ldelim = "%" .. ldelim;
		end;
		-- In patterns, special characters must be escaped
		if string.find("^$()%.[]*+-?", rdelim, 0, true) then
			rdelim = "%" .. rdelim;
		end;
		COMMENT = "^" .. ldelim .. "%*.-%*" .. rdelim;
		DELIMTOKEN = "^" .. ldelim .. "delim (..)" .. rdelim;
		TOKEN = "^" .. ldelim .. "(%a+)%s+(%a[%a%d_]*)%s*" .. rdelim;
		TOKENONLY = "^" .. ldelim .. "(%a+)%s*" .. rdelim;
		ENDTOKENONLY = "^" .. ldelim .. "(/%a+)%s*" .. rdelim;
		BADTOKEN = "^" .. ldelim .. "(/?.-)" .. rdelim;
		ENDOFSTRING = "[^" .. ldelim .. "\n]*";
	end;

	local function rtrim(s)
		local p1, p2 = s:reverse():find("^%s+");
		if p1 then
			local p3 = s:len() - p2;
			return s:sub(1,p3);
		else
			return s;
		end;
	end;

	local function getToken(s, pos)
		-- returns:
		--   token: a table containing the following fields:
		--     id: "group" | "repeat" | "contains"
		--         "/group" | "/repeat" | "/contains"
		--         "delim" | "value"
		--		   "literal" | "param" | "regex"
		--         "END" | "ERROR"
		--     name: name of the group|repeat|param or delim chars
		--     value: content of the literal or regex
		--     spacebefore: true if there was some space before this token
		--   nextpos: value of pos for next call

		local startpos = pos;

		-- Find first non-blank and non-comment
		local nonblank_found = false;
		while not nonblank_found do
			-- Skip blank characters, if any
			local p1, p2 = s:find("^%s+", pos);
			if p1 then
				pos = p2 + 1;
			end;
			-- Skip comment if any
			p3, p4 = s:find(COMMENT, pos);
			if p3 then
				pos = p4 + 1;
			else
				nonblank_found = true;
			end;
		end;

		-- Check if we exceeded the length
		if pos > s:len() then
			return { id="END" };
		end;

		local token = {};  -- return value
		token.blanks_skipped = (pos > startpos);

		-- Parse token or string
		if s:sub(pos,pos) == LDELIM then
			-- Token
			local p1, p2, tok, nam;

			-- {delim name}
			p1, p2, nam = s:find(DELIMTOKEN, pos);
			if p1 then
				token.id = "delim";
				token.name = nam;
				return token, p2+1;
			end;

			-- {token name}
			p1, p2, tok, nam = s:find(TOKEN, pos);
			if p1 then
				token.id = tok:lower();
				token.name = nam;
				return token, p2+1;
			end;

			-- {token}
			p1, p2, tok = s:find(TOKENONLY, pos);
			if p1 then
				token.id = tok:lower();
				return token, p2+1;
			end

			-- {/name}
			p1, p2, tok = s:find(ENDTOKENONLY, pos);
			if p1 then
				token.id = tok:lower();
				return token, p2+1;
			end

			p1, p2, tok = s:find(BADTOKEN, pos);
			if p1 then
				token.id = "ERROR";
				token.name = tok;
				return token, p2+1;
			else
				token.id = "ERROR";
				token.name = s:sub(pos+1, pos+20);
				return token, p2+1;
			end

		else
			-- literal string goes until last non-blank before "{" or eol or eof
			local p1, p2 = s:find(ENDOFSTRING, pos);
			token.id = "literal";
			token.value = rtrim(s:sub(pos,p2));
			return token, p2+1;
		end;

	end;

	-- Pattern Parser ========================================================

	function evalString(t)
	-- Evaluates the string by concatenating its components

		if t.value then
			-- was precomputed by parseString
			return t.value
		else
			local s="";  -- return value
			for i, r in ipairs(t.subtree) do
				if r.tokenid == "literal" then
					if t.hasRegex then
						s = s .. stringToRegex(r.value)
					else
						s = s .. r.value
					end
				elseif r.tokenid == "param" then
					local val = _param[r.name]
					if not val then
						val = ""
					end
					if t.hasRegex then
						s = s .. stringToRegex(val)
					else
						s = s .. val
					end
				elseif r.tokenid == "regex" then
					s = s .. r.value
				end
			end
			return s
		end
	end

	function parseString(s, pos)
	-- Parses the given string, starting at the given position, for a continguous
	-- sequence of literal/param/regex tokens.
	-- Returns:
	--   1) a "string" syntax element, whose subtree consists of literal/param/regex tokens
	--      or nil if the next token in s is not a string
	--   2) nextpos

		local token, nextpos = getToken(s, pos);
		if not (token.id == "literal" or token.id == "param" or token.id == "regex") then
			return nil, pos;
		end;

		local t = { tokenid="string", subtree={} };  -- return value
		local r = { tokenid=token.id, name=token.name, value=token.value };
		table.insert(t.subtree, r);

		local nextnextpos;
		token, nextnextpos = getToken(s, nextpos);
		while (not token.blanks_skipped) and
				(token.id == "literal" or token.id == "param" or token.id == "regex") do

			r = { tokenid=token.id, name=token.name, value=token.value };
			table.insert(t.subtree, r);

			if token.id == "param" then
				t.hasParam = true
			elseif token.id == "regex" then
				t.hasRegex = true
			end

			nextpos = nextnextpos;
			token, nextnextpos = getToken(s, nextpos);
		end;

		-- If there is no {param} in this string, then pre-compute its value now
		if not t.hasParam then
			t.value = evalString(t)
		end

		return t, nextpos;
	end;

	function parseBlock(s, pos, endtokenid)
	-- Parses the given string, starting at the given position, until the given token is found
	-- Returns:
	--   1) The syntax table
	--   2) nextpos
	--   3) an error string, if an error occurred

		-- return values
		local t = {};
		local nextpos
		local err;

		local token, nexttoken, nextnextpos;

		token, nextpos = getToken(s, pos);
		while token.id ~= endtokenid and token.id ~= "END" do
			local r = {};
			r.tokenid = token.id;
			if token.id == "delim" then
				if token.name == nil or token.name:len() ~= 2 then
					err = "Two characters must be specified for {delim}";
					break
				end;
				setdelim(token.name:sub(1,1), token.name:sub(2,2));
			elseif token.id == "literal" or token.id == "param" or token.id == "regex" then
				-- Create a compound string of this and all continguous literal/param/regex
				r, nextpos = parseString(s, pos);
			elseif token.id == "value" then
				if token.name == nil then
					err = "Name must be specified for {value}"
					break
				end
				r.name = token.name;
			elseif token.id == "group" or token.id == "repeat" then
				if token.name == nil then
					err = "Name must be specified for {" .. token.id .. "}"
					break
				end;
				r.name = token.name;
				-- DEPRECATED: {contains}
				nexttoken, nextnextpos = getToken(s, nextpos);
				if nexttoken.id == "contains" then
					-- Parse until {/contains}
					local cs;
					cs, nextpos, err = parseBlock(s, nextnextpos, "/contains");
					if err then
						break;
					end;
					-- Must only contain a string
					if #cs ~= 1 or cs[1].tokenid ~= "string" then
						err = "Contents of {contains} must be a string";
						break;
					end;
					r.containstring = cs[1].string1;
				end;
				-- DEPRECATED end
				-- Parse the internals of this group/repeat
				r.subtree, nextpos, err = parseBlock(s, nextpos, "/" .. token.id);
				if err then
					break;
				end;
				-- Default the anchor to be the first element
				r.anchor = 1;
			elseif token.id == "ERROR" then
				err = "Invalid token: {" .. token.name .. "}";
				break;
			elseif token ~= endtoken then
				err = "Invalid token: {" .. token.id .. "}";
				break;
			end;
			-- there must be a cleaner way to skip delim
			if token.id ~= "delim" then
				table.insert(t, r);
			end
			-- Get token for next iteration
			pos = nextpos;
			token, nextpos = getToken(s, pos);
		end;
		if err == nil and token.id ~= endtokenid then
			err = "Missing {" .. endtokenid .. "}";
		end;

		return t, nextpos, err;
	end;

	-- Harvester ============================================================

	local function findString(s, target, startpos, endpos)
	-- Finds the given target (which must be a token with tokenid="string")
	-- In:
	--   startpos: string to be found starts here or later
	--   endpos: string to be found ends before this position
	--           (if nil the search is not bounded)
	-- Returns:
	--   p1: starting position of found string or nil if not found
	--   p2: one beyond the end position of the string
		local p1, p2  -- return values
		local needle = evalString(target)
		local literally = not target.hasRegex
		if endpos then
			p1, p2 = s:sub(startpos, endpos-1):find(needle, 1, literally)
			if p1 then
				p1 = p1 + startpos - 1
				p2 = p2 + startpos
			end
		else
			p1, p2 = s:find(needle, startpos, literally)
			if p2 then
				p2 = p2 + 1
			end
		end
		return p1, p2
	end

	local function harvestBlock(s, syntax, startpos, endpos)
	-- returns
	--   1) a table structured according to the syntax
	--   2) nextpos
	--   3) an error string, if an error occurred

	-- Conventions:
	--  s is the string being parsed
	--  t is a table returned by the current function
	--  r is a row in that table
	--  q is a row in the syntax
	--  p1,p2 etc are positions in s
	--  pos is current position in s

		-- return values
		local t = {};
		local nextpos;
		local err = nil;

		local pos = startpos;
		local r, q, p1, p2;


		local i = 1;
		while syntax[i] ~= nil do
			local q = syntax[i];
			if q.tokenid == "string" then
				p1, p2 = findString(s, q, pos, endpos);
				if p1 then
					pos = p2;
				else
					err = "String not found: " .. evalString(q);
					break;
				end;
			elseif q.tokenid == "value" then
				local nextq = syntax[i+1];
				if nextq and (nextq.tokenid == "string") then
					p1, p2 = findString(s, nextq, pos, endpos)
					if p1 == nil then
						err = "{value " .. q.name .. "} Terminating string not found: " .. evalString(nextq);
						break;
					end;
					t[q.name] = s:sub(pos, p1-1);
					-- Consider the string harvested as well
					pos = p2;
					i = i + 1;
				else
					-- value extends to end of block
					-- TODO: Should have given error message during parsing?
					t[q.name] = s:sub(pos)
					if endpos then
						pos = endpos
					else
						pos = s:len() + 1
					end
				end
			elseif q.tokenid == "group" or q.tokenid == "repeat" then
				local groupendpos = endpos;
				-- If this (sequence of) group/repeat is followed by a string, that string limits the search scope
				-- but it is not harvested in this iteration
				local j = i + 1;
				while syntax[j] and ((syntax[j].tokenid == "group") or (syntax[j].tokenid == "repeat")) do
					j = j + 1;
				end
				local nextq = syntax[j];
				if nextq and (nextq.tokenid == "string") then
					p1, p2 = findString(s, nextq, pos, endpos)
					if p1 then
						groupendpos = p1
					else
						err = "String not found: " .. evalString(nextq);
						break;
					end
				end
				-- See if the anchorstring is present
				local anchorstring
				if q.containstring then
					-- DEPRECATED
					p1, p2 = findString(s, q.containstring, pos, groupendpos);
					if p1 then
						-- Search backwards for start of group/repeat
						local haystack = s:sub(pos,p1-1):reverse();
						local needle = { tokenid="string", value=evalString(q.containstring):reverse() };
						local p3, p4 = findString(haystack, needle, 1, nil)
						if p3 then
							p2 = p1 - p3;
							p1 = p1 - p4;
						else
							err = "String  not found: " .. evalString(q).containstring;
							break
						end;
					end
					-- END DEPRECATED
				else
					-- Look for anchor (currently, this is always the first element)
					-- but don't harvest it yet
					anchorstring = q.subtree[q.anchor];
					if (anchorstring == nil) or (anchorstring.tokenid ~= "string") then
						err = "{" .. q.tokenid .. "} must start with a string"
						break
					end
					p1, p2 = findString(s, anchorstring, pos, endpos)
				end;
				-- If anchor found, harvest the block
				-- TODO: Harvest the anchor here and skip it.  For now it is scanned twice
				if q.tokenid == "group" then
					if p1 then
						local subb;
						subb, pos, err = harvestBlock(s, q.subtree, pos, groupendpos);
						if err then
							break
						end
						t[q.name] = subb;
					end;
				elseif q.tokenid == "repeat" then
					local rpt = {};
					while p1 do
						local subb;
						subb, pos, err = harvestBlock(s, q.subtree, pos, groupendpos);
						if err then
							break;
						end;
						table.insert(rpt, subb);
						p1, p2 = findString(s, anchorstring, pos, groupendpos)
					end;
					t[q.name] = rpt;
				end
			end;
			-- Next iteration
			i = i + 1;
		end;
		return t, pos, err;
	end;

	-- table dump functions ======================================================

	function syntax_dump(t, indent, printfunc)
		for i, r in ipairs(t) do
			if (r.tokenid == "group") or (r.tokenid == "repeat") then
				printfunc( string.rep("  ",indent) .. r.tokenid .. " " .. r.name)
				if r.containstring then
					printfunc(string.rep("  ",indent+1) .. "contains:")
					syntax_dump(r.containstring.subtree, indent+2, printfunc)
				end
				syntax_dump(r.subtree, indent+1, printfunc)
			elseif r.tokenid == "value" then
				local s = string.rep("  ",indent) .. r.tokenid .. " " .. r.name
				printfunc(s)
			elseif r.tokenid == "string" then
				local s = string.rep("  ",indent) .. r.tokenid
				printfunc(s)
				syntax_dump(r.subtree, indent+1, printfunc)
			elseif r.tokenid == "literal" then
				printfunc(string.rep("  ",indent) .. r.tokenid .. " '" .. r.value .. "'")
			elseif r.tokenid == "param" then
				printfunc(string.rep("  ",indent) .. r.tokenid .. " " .. r.name)
			else
				printfunc(string.rep("  ",indent) .. r.tokenid .. " ???")
			end;
		end;
	end;

	function result_dump(t, prefix, printfunc)
		for k, r in pairs(t) do
			local newprefix
			if type(k) == "number" then
				newprefix = prefix .. "[" .. k .. "]"
			elseif prefix then
				newprefix = prefix .. "." .. k
			else
				newprefix = k
			end
			if type(r) == "table" then
				result_dump(r, newprefix, printfunc)
			elseif type(r) ~= "function" then
				printfunc(newprefix .. "='" .. r .. "'")
			end
		end
		return s
	end

	-- MAINLINE ========================================================

	local nextpos, err
    _syntax, nextpos, err = parseBlock(pattern, 1, "END");

	local r = {}

	function r.harvest(webpage)
		-- input: a web page
		-- returns
		--   1) a table structured according to the syntax
		--   2) an error string, if an error occurred

		local t, pos, err = harvestBlock(webpage, _syntax, 1, nil)

		function t.dump(printfunc)
			return result_dump(t, nil, printfunc)
		end

		return t, err
	end

	function r.dump(printfunc)
		syntax_dump(_syntax, 0, printfunc)
	end

	function r.setparam(name, value)
		_param[name] = value
	end

	return r, err

end



function log(...)
	--if verbose then
		print(...)
	--end
end

-- HTTP Downloading
	local c=curl.new and curl.new() or curl.easy_init()

	local filters = {}
	function addFilter(f) table.insert(filters, f) end
	function clearFilters() filters = {} end

	do
		local f = io.open('cache/TEST.txt', 'w')
		if not f then
			os.execute('mkdir cache')
		else
			f:close()
			os.remove('cache/TEST.txt')
		end
	end
	
	local function open(fn, mode)
		return bz2 and bz2.open(fn, mode, 9) or io.open(fn, mode)
	end

	local function getlocal(url)
		local path = url:gsub('[^%a%d]', '_')
		local f, e = io.open('cache/'..path, "rb")
		if f then
			local ret = f:read('*a')
			f:close()
			return ret
		end
	end

	local function writelocal(url, s)
		local path = url:gsub('[^%a%d]', '_')
		local f = assert(open('cache/'..path, 'wb'))
		f:write(s)
		f:close()
	end

	function get(url, delay)
		
		local delt = ""
		if delay then delt = "delay "..tostring(delay) end	
		log('[http]', 'get', url, delt)

		local cache = getlocal(url)
		if cache then
			log('[http]', 'cached file used')
			return cache			
		end

		if delay then sleep(delay) end

		local tryCount = 6							-- число попыток скачать файл
		local success = true
		local ret, t = nil
		repeat			
			tryCount = tryCount-1					
			if tryCount <0 then 				REM ("число попыток запроса исчерпано" )
				break
			end	
			
			c:setopt(curl.OPT_URL, url)
			c:setopt(curl.OPT_HEADER, false);    -- получать заголовки
			c:setopt(curl.OPT_SSL_VERIFYPEER, false)
			c:setopt(curl.OPT_USERAGENT,"Chrome/33.0.1750.153");	
			--c:setopt(curl.OPT_RETURNTRANSFER, true);
			--c:curl_setopt(curl.OPT_COOKIEFILE,$_SERVER['DOCUMENT_ROOT'].'/cookiefile.txt');
			c:setopt(curl.OPT_FOLLOWLOCATION, true);     -- Говорим скрипту, чтобы он следовал за редиректами
			c:setopt(curl.OPT_SSL_VERIFYHOST, 1);
			if isDebigMode then c:setopt(curl.OPT_VERBOSE, true) end
			t = {}
			c:setopt(curl.OPT_WRITEFUNCTION, function (a, b)
				local s
				-- luacurl and Lua-cURL friendly
				if type(a) == "string" then s = a else s = b end
				table.insert(t, s)
				return #s
			end)
				
		    local ermsg
			success, ermsg = c:perform()									--REM( "Запрашиваем файл по HTTP", url  )

		    if not success  then
				log('[http]', ermsg, url, 'Retrying after 10 sec...')	
				sleep(10)
		    end		
		until success
		
		if success then														--REM ("файл успешно получен");
			ret = table.concat(t)
			for _,f in ipairs(filters) do
				ret = f(ret)
			end
			writelocal(url, ret)
		end


		return ret
	end

	function ftpUpload()
	    c:setopt_url("ftp://lua:3150921@d0009440.atservers.net/www/d0009440.atservers.net/pics/file.dat") 
	    c:setopt_upload(1) 
	    count=0 
	    c:perform({readfunction=function(n) 
                count = count + 1 
                if (count < 10)  then 
                   return "Line " .. count .. "\n" 
                end 
                return nil 
             end}) 
	    print("Fileupload done") 	
	 end

-- String conversion for cyrillic letters correct console output

function toCp866 (s)
    local ret = ""
    local i = 0
    local c1, c2, C
    while i < string.len(s) do 
	i = i+1
	c1 =  string.byte(string.sub(s,i,i))
	if c1 == 208 then
	    i = i+1
	    c2 = string.byte(string.sub(s,i,i))
	    C = c2-16
	    if C==113 then C=240 end
	elseif c1 == 209 then
	    i = i+1
	    c2 = string.byte(string.sub(s,i,i))
	    C = c2+96
	else
	    c2 = ""
	    C = string.byte(string.sub(s,i,i))	    
	end    
	--print (i..":"..c1.."-"..c2)
	ret = ret..string.char(C)
    end
    return ret
end


