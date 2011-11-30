-------------------------------------------------------------------------------------
-- PtokaX Common Script Functions Module (Compiled by St0ne_db)
--
-- These code bits where compiled from these two thread:
-- 	http://luaboard.sytes.net/index.php?topic=6419.0  -- Lua 5.1 Code Bits
-- 	http://luaboard.sytes.net/index.php?topic=2332.0  -- Scripting:Utilities:Central
-------------------------------------------------------------------------------------
--External dependencies
local base = _G
--
module( ... )

--Mutor
--// Profile Counter
cProfile = function( iProfile )
	local tbl, tbl2 = #base.RegMan.GetRegsByProfile( iProfile ), #base.Core.GetOnlineUsers( iProfile );
	local on, off = tbl2, ( tbl - tbl2 );
	return on, off;
end

--amenay
--// Get amount of Online users by Profile Name --New API
pOnline = function( sProfName )
   return #base.Core.GetOnlineUsers( base.ProfMan.GetProfile( sProfName ).iProfileNumber )
end

--NotRabidWombat
GetByteUnit = function(intSize)
	local tUnits = { "Bytes", "KiB", "MiB", "GiB", "TiB" }
	intSize = base.tonumber(intSize);
	local sUnits;
	for index = 1, #tUnits do
		if(intSize < 1024) then
			sUnits = tUnits[index];
			break;
		else
			intSize = intSize / 1024;
		end
	end
	return base.string.format("%0.2f %s",intSize, sUnits);
end

--dragos_sto
GetTime = function()
	local Time = base.os.date("%H")..":"..base.os.date("%M")..":"..base.os.date("%S")
	return Time
end

--dragos_sto
GetDate = function()
	local Date = base.os.date("%a").."."..base.os.date("%d").."."..base.os.date("%b").."."..base.os.date("%y")
	return Date
end

--Mutor
--Returns UTC timezone as a string	by Mutor
TimeZone = function()
	local h,m = base.math.modf((base.os.time()-base.os.time(base.os.date"!*t"))/ 3600)
	return base.string.format("%+d UTC",(h + (60 * m)))
end

--Mutor
--Check for file, returns string and filesize by Mutor
--Usage: local f,s = FileSpecs("Path/filename.ext")
FileSpecs = function(pathfile)
	local size = 0
	local file,error = base.io.open(pathfile, "rb")
	if file then
		local current = file:seek()
		size = file:seek("end")
		file:seek("set", current)
		file:close()
		pathfile = pathfile.." does exist. "
	else
		pathfile = base.string.sub(error,1,-2)
	end
	if size < 1024 then
	        size = base.string.format("%.2f Bytes",size)
	else
		size = base.string.format("%.2f Kb.",(size/1024))
	end
	return pathfile,"Filesize: "..size
end

-- Serialize by nErBoS
SaveToFile = function(file , table , tablename, table2, tablename2)
	local handle = base.io.open(file,"w+")
	handle:write(Serialize(table, tablename))
	if table2 and tablename2 then
		handle:write(Serialize(table2,tablename2))
	end
	handle:flush()
	handle:close()
end

-- Serialize by nErBoS
Serialize = function(tTable, sTableName, sTab)
	base.assert(tTable, "tTable equals nil");
	base.assert(sTableName, "sTableName equals nil");
	base.assert(base.type(tTable) == "table", "tTable must be a table!");
	base.assert(base.type(sTableName) == "string", "sTableName must be a string!");
	sTab = sTab or "";
	sTmp = ""
	sTmp = sTmp..sTab..sTableName.." = {\n"
	for key, value in base.pairs(tTable) do
		local sKey = (base.type(key) == "string") and base.string.format("[%q]",key) or base.string.format("[%d]",key);
		if(base.type(value) == "table") then
			sTmp = sTmp..Serialize(value, sKey, sTab.."\t");
		else
			local sValue = (base.type(value) == "string") and base.string.format("%q",value) or base.tostring(value);
			sTmp = sTmp..sTab.."\t"..sKey.." = "..sValue
		end
		sTmp = sTmp..",\n"
	end
	sTmp = sTmp..sTab.."}"
	return sTmp
end

--bastya_elvtars
--- use it like : cmd = string.match( string.sub( data, 1, -2 ) ,"%b<>%s+"..GetHubPrefixes().."(%S+)")
-- command prefix use prefix hubs
GetHubPrefixes = function()
	local s = ''
	for i, pref in base.pairs(base.frmHub:GetPrefixes()) do
		s = s.."%"..pref
	end
	return '['..s..']'
end


--amenay
Display = function(table,val)
	local disp = ""
	for i,v in base.pairs(table) do
		if not val then
			line = i
		else 
			line = v.." \t\t~\t "..i
		end
		disp = disp.."\t\t\t\t\t • \t"..line.."\r\n"
	end
	return disp
end

--amenay
DeMagic = function(s)
	s = s:gsub(("%p"), function (p) return "%"..p end) 
	return s 
end

do	---[[By Chill
	local default_fcompval = function( value ) return value end
	local fcompf = function( a,b ) return a < b end
	local fcompr = function( a,b ) return a > b end
	function binsearch( t,value,fcompval,reversed )
		local fcompval = fcompval or default_fcompval
		local fcomp = reversed and fcompr or fcompf
		local iStart,iEnd,iMid = 1,#t,0
		while iStart <= iEnd do
			iMid = base.math.floor( (iStart+iEnd)/2 )
			local value2 = fcompval( t[iMid] )
			if value == value2 then
				local tfound,num = { iMid,iMid },iMid - 1
				while value == fcompval( t[num] ) do
					tfound[1],num = num,num - 1
				end
				num = iMid + 1
				while value == fcompval( t[num] ) do
					tfound[2],num = num,num + 1
				end
				return tfound
			elseif fcomp( value,value2 ) then
				iEnd = iMid - 1
			else
				iStart = iMid + 1
			end
		end
	end --]]
end