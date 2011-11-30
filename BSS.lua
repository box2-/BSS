--[[

Basic script for custom welcome messages w/ toggle, welcome messages per profile, and basic commands.
Each command's permissions is set it's own table within the tCommandArrivals table.

Scriptname: BSS Edition
Creator: amenay
Date: 2007.13.08

Updated by box2 for fun and profit
Date: since 2007

]]

pxcom = require "scripts/libs/pxcom";
BSS = { };
ChatHistory = { };
tUnconfirmed = { };
tDoubleReq = { };
HistoryLines = 150

do

	sPre = "^[" .. SetMan.GetString( 29 ) .. "]"
	local sPath = "scripts/data/tbl/"
	sLocation = sPath .. "BSS.tbl";
	sOCName = SetMan.GetString( 24 ) or "SetMe"; --Bots not enabled in GUI? Change the value after the or.
	sHBName = SetMan.GetString( 21 ) or "SetMeToo";
	sFromHB = "<" .. sHBName .. "> ";
	sBlockedMsg = "<" .. SetMan.GetString( 21 ) .. "> *** You must be registered to search or download in this hub.|";
	
	
	if os.rename( sPath .. "BSSPermissions.tbl", sPath .. "BSSPermissions.tbl" ) then
		dofile( sPath .. "BSSPermissions.tbl" )
	else
		Core.SendToOps( "*** BSS Permissions table not found, stopping script." )
		ScriptMan.StopScript( "BSS.lua" )
	end
	
	if os.rename( sLocation, sLocation ) then
		dofile( sLocation );
	else
		BSS.GagBot = { tGagged = { }; }
		BSS.GagBot.tTimedGag = { };
		BSS.WlcBot = { tWlc = { }; };
		BSS.WlcBot.tNoWlc = { };
		BSS.ShowHistory = { };
	end
	
	RegOnly = { DownloadKey = { }, TimeOut = { }; };
	
end

tWlcMsg = {

	[0] = "Welcome home nick!|", --Master
	[1] = "Welcome home nick!|", --Operator
	[2] = "Hello nick!|", --VIP
	[3] = nil, --reg


};

tTimeTranslate = {
	s = { 1000, 			" second(s)",	1, 1e+015 },
	m = { 60000, 			" minute(s)", 	2, 16666666666667 },
	h = { 60 * 60000, 		" hour(s)", 	3, 277777777777.78 },
	d = { 1440 * 60000,		" day(s)", 		4, 11574074074.074 },
	w = { 10080 * 60000,	" week(s)", 	5, 1653439153.4392 },
	M = { 43200 * 60000,	" month(s)", 	6, 385802469.1358 },
	y = { 512640 * 60000,	" year(s)", 	7, 32511444.028298 }
};

---
OnStartup = function( )
	UpdateTimedTable( BSS.GagBot.tTimedGag );
	
	setmetatable( tCommandArrivals, { __index = tCommandArrivals.tShortCommands } )
end

function OnError( sErrMsg )
	Announce( sErrMsg )
end

function OnExit( )
	pxcom.SaveToFile( sLocation, BSS, "BSS" );
end

function OnTimer( nTimerId )
	for i, v in pairs( BSS.GagBot.tTimedGag ) do
		if v[1] == nTimerId then
			BSS.GagBot.tTimedGag[ i ] = nil
			TmrMan.RemoveTimer( nTimerId )
			break;
		end
	end
end

RemKey = function( nTimerId )
	if RegOnly.DownloadKey[ RegOnly.TimeOut[ nTimerId ] ] or RegOnly.TimeOut[ nTimerId ] then
		RegOnly.DownloadKey[ RegOnly.TimeOut[ nTimerId ] ], RegOnly.TimeOut[ nTimerId ] = nil, nil;
	end
	TmrMan.RemoveTimer( nTimerId );
end

--[[ fucking clown romanian hacker ]]
function UserConnected( user )
	if string.find( string.lower(user.sNick) , "monica") ~= nil then
		Core.Disconnect( user.sNick );
		Core.SendPmToOps( sOCName, user.sNick .. " was auto-dropped because Nox hates everyone.|" );
	end
end

function RegConnected( user )
	Core.SendToUser( user, "Type !history to see the last " .. #ChatHistory .. " lines of chat. (Type \"!history onjoin\" to receive automatically.)|" );
	if BSS.ShowHistory[ user.sNick ] then Core.SendToUser( user, sFromHB .. doHistory( ) ) end;
	if not BSS.WlcBot.tNoWlc[ user.sNick ] then
		local nick = user.sNick;
		if BSS.WlcBot.tWlc[ nick ] then
			return Core.SendToAll( sFromHB .. BSS.WlcBot.tWlc[ nick ] ), Core.SendToUser( user, sFromHB .. BSS.WlcBot.tWlc[ nick ] );
		elseif tWlcMsg[ user.iProfile ] then
			local sWlcMsg = tWlcMsg[ user.iProfile ]:gsub( "nick", nick );
			return Core.SendToAll( sFromHB .. sWlcMsg ), Core.SendToUser( user, sFromHB .. sWlcMsg );
		end
	end
end

function OpConnected( user )
	Core.SendToUser( user, "Type !history to see the last " .. #ChatHistory .. " lines of chat. (Type \"!history onjoin\" to receive automatically.)|" );
	if BSS.ShowHistory[ user.sNick ] then Core.SendToUser( user, sFromHB .. doHistory( ) ) end;
	if not BSS.WlcBot.tNoWlc[ user.sNick ] then
		local nick = user.sNick;
		if BSS.WlcBot.tWlc[ nick ] then
			return Core.SendToAll( sFromHB .. BSS.WlcBot.tWlc[ nick ] ), Core.SendToUser( user, sFromHB .. BSS.WlcBot.tWlc[ nick ] );
		else
			local sWlcMsg = tWlcMsg[ user.iProfile ]:gsub( "nick", nick );
			return Core.SendToAll( sFromHB .. sWlcMsg ), Core.SendToUser( user, sFromHB .. sWlcMsg );
		end
	end
end

function OpDisconnected( user )
	if not BSS.WlcBot.tNoWlc[ user.sNick ] then
		Core.SendToAll( sFromHB .. "See you next time, " .. user.sNick .. "!|" );
	end
--	RegDisconnected( user )
end

--[[
function RegDisconnected( user )
	if tUnconfirmed[ user.sNick:lower() ] then
		Announce( "*** " .. user.sNick .. " didn't confirm their pass before disconnecting, removing account. . ." );
		tUnconfirmed[ user.sNick:lower() ] = nil;
		RegMan.DelReg( user.sNick );
	end
end
]]

function SearchArrival( user, data )
	if user.iProfile == -1 then
		return Core.SendToUser( user,  sBlockedMsg ), true;
	end
end

OnError = function( msg )
	Core.SendToProfile( 0, msg )
end

function ConnectToMeArrival( user, data )
	if user.iProfile == -1 then
		local remnick = data:match( "^(%S+)", 14 );
		if RegOnly.DownloadKey[ user.sNick ] ~= remnick then
			return Core.SendToUser( user, sBlockedMsg ), true;
		end
	end
end

function RevConnectToMeArrival( user, data )
	local sendnick = data:sub( #user.sNick + 18, -2 )
	if user.iProfile ~= -1 then
		RegOnly.DownloadKey[ sendnick ], RegOnly.TimeOut[ TmrMan.AddTimer( 60000, "RemKey" ) ] = user.sNick, sendnick; --Remote user will only have one user with key to connect..
		return false;
	else
		return Core.SendToUser( user,  sBlockedMsg ), true;
	end
end

function ChatArrival( user, data )
	if BSS.GagBot.tGagged[ user.sNick ] or BSS.GagBot.tTimedGag[ user.sNick ] then
		return true;
	end
	local nInitIndex = #user.sNick + 4
	if user.iProfile == -1 and ( data:match( "http%:%/%/", nInitIndex ) or data:match( "www%.", nInitIndex ) or data:match( "dchub://", nInitIndex ) ) then
		Core.SendToUser( user, sFromHB .. "All messages from unregistered users which contain URLs are blocked then forwarded to our operators." );
		Announce( user.sNick .. ", an unregistered user, sent a message in main which contained the following URL: " .. data:sub( nInitIndex ) );
		return true;
	end
	if data:match( sPre, nInitIndex ) then
		local cmd = data:match( "^(%w+)", nInitIndex + 1 );
		if cmd then
			cmd = cmd:lower( )
			if tCommandArrivals[ cmd ] then --Add everything up from here on to ExecuteCommand
				if tCommandArrivals[ cmd ].Permissions[ user.iProfile ] then
					local msg;
					if ( nInitIndex + #cmd ) <= #data + 1 then msg = data:sub( nInitIndex + #cmd + 2 ) end
					return ExecuteCommand( user, msg, cmd, "Main" );
				else
					return Core.SendToUser( user, sFromHB ..  "*** Permission denied.|" ), true;
				end
			else
				return false;
			end
		end
	end
	if data:match( "^is kicking %S+ because:", nInitIndex ) or data:match( "^is kicking %S+ because:", nInitIndex + #user.sNick + 1 ) then 
		return false; --look at me later.
	else	
		table.insert( ChatHistory, 1, { os.time( ), data:sub( 1, -2 ) } )
		if #ChatHistory == HistoryLines + 1 then
			table.remove( ChatHistory, HistoryLines + 1 )
		end
	end
end

ToArrival = function( user, data )
	local sToUser = data:match( "^(%S+)", 6 );
	local nInitIndex = #sToUser + 18 + #user.sNick * 2;
	if data:match( sPre, nInitIndex ) then
		local cmd = data:match( "^(%w+)", nInitIndex + 1 )
		if cmd then
			cmd = cmd:lower( )
			if tCommandArrivals[ cmd ] then
				if tCommandArrivals[ cmd ].Permissions[ user.iProfile ] then
					local msg;
					if ( nInitIndex + #cmd + 2 ) <= #data - 1 then msg = data:sub( nInitIndex + #cmd + 2 ) end
					return ExecuteCommand( user, msg, cmd, "PM" );
				else
					return Core.SendPmToUser( user, sHBName,  "*** Permission denied.|" ), true;
				end
			end
		end
	end
	if user.iProfile == -1 then
		if data:match( "http%:%/%/", nInitIndex ) or ( data:match( "www%.", nInitIndex ) or data:match( "dchub://", nInitIndex ) ) then
			Core.SendPmToUser( user, sHBName, "All messages from unregistered users which contain URLs are blocked then forwarded to our operators." );
			Announce( user.sNick .. ", an unregistered user, sent a PM to " .. sToUser .. " which contained the URL: " .. data:sub( nInitIndex ) );
			return true;
		end
	end
end;
--------
ExecuteCommand = function( user, msg, cmd, where )
	local bRet, sMsg, sWhere, sFrom = tCommandArrivals[ cmd ]:Action( user, msg );
	if sWhere then
		where = sWhere
	end
	if sMsg then
		if where == "PM" then
			if sFrom then
				return Core.SendPmToUser( user, sFrom, sMsg ), true;
			else
				return Core.SendPmToUser( user, sHBName, sMsg ), true;
			end
		else
			if sFrom then
				return Core.SendToUser( user, "<" .. sFrom .. "> " .. sMsg ), true;
			else
				return Core.SendToUser( user, sFromHB .. sMsg ), true;
			end
		end
	else
		return bRet;
	end
end
--------
UpdateTimedTable = function( TimedTable )
	for i, v in pairs( TimedTable ) do
		TimedTable[ i ][1], TimedTable[ i ][2], TimedTable[ i ][3] = TmrMan.AddTimer( TimedTable[ i ][2] ), TimedTable[ i ][2] - ( os.difftime( os.time( ), TimedTable[ i ][ 3 ] ) * 1000 ), os.time( );
	end
end

TimeUnits = function( inms )
	local ints = {}
	for i, v in pairs( tTimeTranslate ) do table.insert( ints, v[3], v ) end
	for i = #ints, 1, -1 do
		if inms >= ints[i][1] then
			return string.format( "%.5f", inms / ints[i][1] ) .. ints[i][2]
		end
	end
	return string.format( "%.5f", inms ) .. " milisecond(s)"
end	
--------
Announce = function( sMsg )
	if SetMan.GetBool( 29 ) then
		if SetMan.GetBool( 30 ) then
			Core.SendPmToOps( sHBName, sMsg )
		else
			Core.SendToOps( sFromHB .. sMsg )
		end
	end
end
-------
CanReg = function( iProfile )
	local Profiles, AvailProfs = ProfMan.GetProfiles( ), ""; 
	for i = 1, #Profiles, 1 do
		if Profiles[ i ].iProfileNumber >= iProfile then
			AvailProfs = AvailProfs .. Profiles[ i ].sProfileName .. ", ";
		end
	end
	return AvailProfs;
end
-------
function doHistory( )
	local ret = "The last " .. #ChatHistory .. " lines of chat\r\n\r\n";
	for i = #ChatHistory, 1, -1 do
		ret = ret .. "[" .. os.date( "%x %X", ChatHistory[ i ][1] ) .. "] " .. ChatHistory[ i ][2] .. "\r\n";
	end
	return ret;
end
--------
tCommandArrivals.tShortCommands = { 
	js = tCommandArrivals.joinstatus,
	chjm = tCommandArrivals.chjoinmsg,
	br = tCommandArrivals.banreason;
};
--

--Welcome Bot commands
function tCommandArrivals.joinmsg:Action ( user, sMsg )
	if sMsg and Core.GetUserValue( user, 11 ) then
		local sMsg = sMsg:sub( 1, -2 )
		if RegMan.GetReg( sMsg ) then
			if BSS.WlcBot.tNoWlc[ sMsg ] then
				BSS.WlcBot.tNoWlc[ sMsg ] = nil;
				return true, "*** " .. sMsg .. "'s joins/parts announcements have been turned *ON*|", "PM", sHBName;
			else
				BSS.WlcBot.tNoWlc[ sMsg ] = true;
				return true, "*** " .. sMsg .. "'s joins/parts announcements have been turned *OFF*|", "PM", sHBName;
			end
		else
			return true, "*** The username " .. sMsg .. " is not registered.|";
		end
	elseif BSS.WlcBot.tNoWlc[ user.sNick ] then
		BSS.WlcBot.tNoWlc[ user.sNick ] = nil;
		return true, "*** Your joins/parts announcements have been turned *ON*|", "PM", sHBName;
	else	
		BSS.WlcBot.tNoWlc[ user.sNick ] = true;
		return true, "*** Your joins/parts announcements have been turned *OFF*|", "PM", sHBName;
	end
end

function tCommandArrivals.chjoinmsg:Action ( user, sMsg )
	if sMsg then
		BSS.WlcBot.tWlc[ user.sNick ] = sMsg;
		local sMsg = sMsg:sub( 1, -2 )
		return true, "*** Your join announcement message has been changed to: " .. sMsg .. ", to reset it to default type !chjoinmsg without parameters.|", "PM", sHBName;
	elseif BSS.WlcBot.tWlc[ user.sNick ] then
		BSS.WlcBot.tWlc[ user.sNick ] = nil;
		return true, "*** Your join announcement is now set to default.|", "PM", sHBName;
	else
		return true, "*** Your join announcement is already set to default!|", "PM", sHBName;
	end
end

function tCommandArrivals.joinstatus:Action ( )
	local disp = "";
	for i, v in pairs( BSS.WlcBot.tNoWlc ) do
		local curEntry = "";
		if BSS.WlcBot.tWlc[ i ] then
			curEntry = "\r\n\t\t Username: " .. i .. "\r\n\t\t Message: " .. BSS.WlcBot.tWlc[ i ]:sub( 1, -2 ) .. "\r\n\t\t Status: Off\r\n";
		else
			curEntry = "\r\n\t\t Username: " .. i .. "\r\n\t\t Message: Default.\r\n\t\t Status: Off\r\n";
		end
		disp = disp .. curEntry;
	end
	for i, v in pairs( BSS.WlcBot.tWlc ) do
		local curEntry = "";
		if not BSS.WlcBot.tNoWlc[ i ] then
			curEntry = "\r\n\t\t Username: " .. i .. "\r\n\t\t Message: " .. v:sub( 1, -2 ) .. "\r\n\t\t Status: On\r\n";
		end
		disp = disp .. curEntry;
	end
	return true, "\r\n\r\n\t\t\t\t\t*-**-*-Join status-*-**-*\r\n\r\n" .. disp, "PM", sHBName;
end

--Misc Basic
function tCommandArrivals.history:Action( user, sMsg )
	if sMsg and sMsg:sub( 1, -2 ) == "onjoin" then
		if BSS.ShowHistory[ user.sNick ] then
			BSS.ShowHistory[ user.sNick ] = nil;
			return true, "*** You will no longer receive history onjoin.|";
		else
			BSS.ShowHistory[ user.sNick ] = true;
			return true, "*** You will now receive history automatically upon rejoining the hub.|"
		end
	end
	return true, doHistory( );
end

function tCommandArrivals.rules:Action ( )
	Core.SendToAll( sFromHB .. "\r\n\n*** Rules for this hub are simple ***\r\n" ..
	"1) Share some anime / manga / anything from Japan\r\n" ..
	"2) Don't be in more than 20 hubs\r\n" ..
	"3) Have a good time!|" )
	return true;
end

function tCommandArrivals.time:Action ( )
	Core.SendToAll( sFromHB .. "*** Local server time: " .. pxcom.GetDate( ) .. " @ " .. pxcom.GetTime( ) .. " (" .. pxcom.TimeZone( ) ..")|" )
	return true;
end

function tCommandArrivals.showtopic:Action ( )
	sTopic = SetMan.GetString( 10 ) or "..but there is no topic. :( Any ideas?|";
	Core.SendToAll( sFromHB .. "*** Current topic: " .. sTopic );
	return true;
end

function tCommandArrivals.warn:Action ( user, sMsg )
	if sMsg then
		local victim, reason = sMsg:match( "(%S+)%s+(.*)" )
		if victim then
			Core.SendToAll( sFromHB .. victim .. " was warned by " .. user.sNick .. " because: " .. reason )
			Core.SendPmToNick( victim, user.sNick, "Watch out you're being warned because: " .. reason );
			return true;
		else
			return true, "*** Syntax error, type: !warn <nick> <reason>.|";
		end
	else
		--Syntax error
	end
end

-- Kick command with no temporary ban
function tCommandArrivals.kick:Action ( user, sMsg )
	if sMsg then
		local victim = sMsg:match( "(%S+)%s?" ) -- match until space or end
		local reason = sMsg:match( "%S+%s+(.*)" ) -- try to match after name and space (reason is optional)
		if victim then
			if reason == nil then
				victim = victim:sub( 1, -2 ) -- remove line end character
				-- dont care if reason has line-end because it will be the last part of output messages anyway
			end
			vic = Core.GetUser( victim ) -- pull user object to verify they are connected
			if vic then
				if reason then
					Core.SendPmToNick( victim, sHBName, user.sNick .. " kicked you from the hub because: " .. reason )
					Core.SendToAll( sFromHB .. user.sNick .. " kicked " .. vic.sNick .. " because: " .. reason )
					Core.Disconnect( victim )
					return true
				else
					Core.SendPmToNick( victim, sHBName, user.sNick .. " kicked you from the hub.|" )
					Core.SendToAll( sFromHB .. user.sNick .. " kicked " .. vic.sNick .. " from the hub.|" )
					Core.Disconnect( victim )
					return true
				end
			else
				return true, "*** User " .. victim .. " does not appear to be online.|"
			end
		else
			return true, "*** Syntax error, use: !kick <nick> [reason]|"
		end
	else
--		if i am here it is because i hate amenay
	end
--[[
	if sMsg then
		sMsg = sMsg:sub( 1, -2 )
		local vic = Core.GetUser( sMsg )
		if vic then
			Core.Disconnect( vic );
			Core.SendPmToOps( sOCName, user.sNick .. " kicked " .. sMsg:sub( 1, -1 ) .. " from the hub.|" );
			return true;
		else
			return true, "*** User is offline.|";
		end
	else
		return true, "*** Command use: !go <nick>|";
	end
]]--
end

-- Disconnect users quickly
function tCommandArrivals.go:Action ( user, sMsg )
	if sMsg then
		local vic = Core.GetUser( sMsg:sub( 1, -2 )  )
		if vic then
			Core.Disconnect( vic );
			Core.SendPmToOps( sOCName, user.sNick .. " dropped " .. vic.sNick .. " because they were being dumb.|" );
			return true;
		else
			return true, "*** User is offline.|";
		end
	else
		return true, "*** Command use: !go <nick>|";
	end
end

-- Super Silent user disconnect (Masters only)
function tCommandArrivals.ssgo:Action ( user, sMsg )
	if sMsg then
		local vic = Core.GetUser( sMsg:sub( 1, -2 ) )
		if vic then
			Core.Disconnect( vic );
			return true, "*** " .. vic.sNick .. " with IP:  " .. vic.sIP .. " dropped! :D|";
		else
			return true, "*** User is offline.|";
		end
	else
		return true, "*** Please specify the nick parameter !ssgo <nick>|";
	end
end

-- No idea
function tCommandArrivals.mmreg:Action ( user, sMsg )
	if sMsg then
		sMsg = sMsg:sub( 1, -2 )
		for i = 0, ProfMan.GetProfile( #ProfMan.GetProfiles( ) - 1 ).iProfileNumber do
			Core.SendPmToProfile( i, SetMan.GetString( 21 ), sMsg .. " //" .. user.sNick );
		end
		return true;
	else
		return true, "*** No message parameter provided.|";
	end
end

-- Imporsonate other users in hub chat
function tCommandArrivals.say:Action ( user, sMsg )
	if sMsg then
		local nick, msg = sMsg:match( "(%S+)%s+(.*)" );
		if msg then
			Core.SendToAll( "<" .. nick .. "> " .. msg );
			return true;
		else
			return true, "Syntax error, try using " .. SetMan.GetString( 29 ):sub( 1, 1 ) .. "say <nick> <message>|";
		end
	else
		--Syntax Error
	end
end

-- Impersonate other user actions in hub chat (Masters only)
function tCommandArrivals.mimic:Action ( user, sMsg )
	if sMsg then
		Core.SendToAll( sMsg );
		return true;
	else
		--Syntax error
	end
end

-- Imporsonate other users sending private messages
function tCommandArrivals.saypm:Action ( user, sMsg )
	if sMsg then
		to, from, msg = sMsg:match( "(%S+)%s+(%S+)%s+(.*)" );
		if msg then
			Core.SendPmToNick( to, from, msg );
			return true;
		else
			--Syntax error
		end
	else
		--Syntax error
	end
end

-- No idea
function tCommandArrivals.banreason:Action ( user, sMsg )
	if sMsg then
		local sIP, nick = sMsg:sub( 1, -2 ):match( "^(%d+%.%d+%.%d+%.%d+)$" ), sMsg:sub( 1, -2 ):match( "^([^%d+%.%d+%.%d+%.%d+]%S+)$" );
		local Item = nick or sIP;
		local Result;
		local tBanned = BanMan.GetBan( Item ); 
		if tBanned then
			if nick then
				local sUsersIP, sReason, sExpires  = tBanned.sIP or "N/A", tBanned.sReason or "No reason given, ask " .. tBanned.sBy .. "?	";
				if tBanned.iExpireTime then sExpires = os.date( "%H:%M - %x", tBanned.iExpireTime ) else sExpires = "Permanent" end;
				Result =
				"\r\n\r\n\t\t Username:\t " .. tBanned.sNick
				.. "\r\n\t\t IP:\t\t " .. sUsersIP
				.. "\r\n\t\t Reason:\t " .. sReason
				.. "\r\n\t\t Banned By:\t " .. tBanned.sBy
				.. "\r\n\t\t Expires:\t " .. sExpires .. "\r\n|";
			else
				Result = ""
				for i = 1, #tBanned, 1 do
					local sNick, sReason, sExpires = tBanned[ i ].sNick or "N/A", tBanned[ i ].sReason or "No reason given, ask " .. tBanned[ i ].sBy .. "?";
					if tBanned.iExpireTime then sExpires = os.date( "%H:%M - %x", tBanned.iExpireTime ) else sExpires = "Permanent" end;
					local Item =
					"\r\n\r\n\t\t Username:\t" .. sNick
					.. "\r\n\t\t IP:\t\t" .. tBanned[ i ].sIP
					.. "\r\n\t\t Reason:\t" .. sReason
					.. "\r\n\t\t Banned By:\t" .. tBanned[ i ].sBy
					.. "\r\n\t\t Expires:\t" .. sExpires .. "\r\n|";
					Result = Item;
				end
			end
		elseif sIP then
			Result = "*** The IP supplied (" .. sIP .. ") is not banned! Have a nick?|";
		else
			Result = "*** The nick supplied (" .. nick .. ") is not banned! Have an IP?|";
		end
		return true, Result;
	else
		--Syntax error
	end
end

--Gag Commands
function tCommandArrivals.gag:Action ( user, sMsg )
	if sMsg then
		local victim = sMsg:sub( 1, -2 );
		if victim then
			if not BSS.GagBot.tGagged[ victim ] then 
				local iVicProfNum = ( RegMan.GetReg( victim ) or {} ).iProfile or -1;
				if self.Permissions[ user.iProfile ][ iVicProfNum ] then
					BSS.GagBot.tGagged[ victim ] = true;
					Core.SendToAll( "* " .. user.sNick .. " puts " .. victim .. " in Time Out *|" );
					return true;
				else
					local sVicProfName = ProfMan.GetProfile( iVicProfNum ).sProfileName or "unregistered user";
					return true, "*** Error, You cannot gag " .. sVicProfName .. "s!|";
				end
			else
				return true, "*** " .. victim .. " is already gagged. Check getgags.|";
			end
		end
	else
		--Syntax error
	end
end

function tCommandArrivals.ungag:Action ( user, sMsg )
	if sMsg then
		local victim = sMsg:sub( 1, -2 );
		if not BSS.GagBot.tGagged[ victim ] and not BSS.GagBot.tTimedGag[ victim ] then
			return true, "*** "..victim.." isn't currently gagged.|";
		else
			local iVicProfNum = ( RegMan.GetReg( victim ) or {} ).iProfile or -1;
			if self.Permissions[ user.iProfile ][ iVicProfNum ] then
				if BSS.GagBot.tGagged[ victim ] then 
					BSS.GagBot.tGagged[ victim ] = nil;
				else
					BSS.GagBot.tTimedGag[ victim ] = nil, nil;
				end
				Core.SendToAll( "* " .. user.sNick .. " ungags " .. victim .. " *|" );
				return true;
			else
				local sVicProfName = ProfMan.GetProfile( iVicProfNum ).sProfileName or "unregistered user";
				return true, "*** Error, You cannot ungag " .. sVicProfName .. "s!";
			end
		end
	else
		--Syntax error
	end
end

function tCommandArrivals.getgags:Action ( )
	local disp = "";
	for i in pairs( BSS.GagBot.tGagged ) do
		local line = i;
		disp = disp.."\t  " .. line .. "\t Time remaining: Until ungag command ;p\r\n";
	end
	UpdateTimedTable( BSS.GagBot.tTimedGag )
	for i, v in pairs( BSS.GagBot.tTimedGag ) do
		local line = i;
		disp = disp.."\t  " .. line .. "\t Time remaining: " .. TimeUnits( v[2] ) .. "\r\n";
	end
	return true, "\r\n\r\n\t\t\t\t\t*-**-* Gagged Users *-**-* \r\n\r\n" .. disp;
end

function tCommandArrivals.tempgag:Action ( user, sMsg ) 
	if sMsg then
		local victim, iAmount, sFormat = sMsg:match( "^(%S+)%s+(%d+)(%w)" );
		if victim then
			if not BSS.GagBot.tTimedGag[ victim ] then
				if tTimeTranslate[ sFormat ][4] < tonumber( iAmount ) then
					return true, "*** You cannot gag for longer than " .. tTimeTranslate[ sFormat ][4] .. tTimeTranslate[ sFormat ][2];
				else
					local iVicProfNum = ( RegMan.GetReg( victim ) or {} ).iProfile or -1;
					if self.Permissions[ user.iProfile ][ iVicProfNum ] then
						BSS.GagBot.tTimedGag[ victim ] = { TmrMan.AddTimer( tTimeTranslate[ sFormat ][1] * iAmount ), tTimeTranslate[ sFormat ][1] * iAmount, os.time( ) }
						Core.SendToAll( "* " .. user.sNick .. " gags " .. victim .. " for " .. iAmount .. tTimeTranslate[ sFormat ][2] .. " *|" );
						return true;
					else
						local sVicProfName = ProfMan.GetProfile( iVicProfNum ).sProfileName or "unregistered user";
						return true, "*** Error, You cannot gag " .. sVicProfName .. "s!|";
					end
				end
			else
				return true, "*** " .. victim .. " is already gagged.|";
			end
		else
			return true, "*** Error in syntax, <Nick> <Amount><TimeFormat> arguments required.";
		end
	else
		--Syntax error
	end
end;

--RegBot Commands
function tCommandArrivals.regme:Action ( user )
	if tDoubleReq[ user.uptr ] then
--		Core.Disconnect( user );
		local sRegMsg = [[Don't spam the !regme button, or we will ban you.|]];
		return true, sRegMsg;
	else
		tDoubleReq[ user.uptr ] = true;
		
		local sRegMsg = [[Your request has been sent to the ops.  If you send more than one request (spaming) you will be disconnected, so please be patient until an op can come register you!\r\n\nPlease Read the !rules while you wait.|]];
--		local sRegMsg = [[Sorry, registration is currently closed.|]];

--		Announce( user.sNick .. " wants to be registered. Read " .. SetMan.GetString( 29 ):sub( 1, 1 ) .. "opfaq (broken :/ ) if you're a jerk.  DON'T BE LAZY!|" );
		Announce( "\r\n" .. user.sNick .. " has asked to be registered.  Use !getinfo <username> to check their stats.\r\n" ..  
		"Use !addreguser <username> generatepass <reg/vip>. \r\n" .. 
		"Using generatepass will create a random password for them.  Make them vip if they share lots good stuff or are a hub friend.|");

--		Announce( user.sNick .. " has hit the !regme button.  Would an operator please kindly help them?|");

		return true, sRegMsg;
	end
end


function tCommandArrivals.passwd:Action( user )
	if tUnconfirmed[ user.sNick:lower() ] then
		return true, "*** You cannot use this command until you've confirmed the password sent to you by " .. sHBName .. ". Use the " .. SetMan.GetString( 29 ):sub( 1, 1 ) .. "confirmreg <password> command.";
	end
end

--[[
function tCommandArrivals.confirmreg:Action( user, sMsg )
	if sMsg then
		if tUnconfirmed[ user.sNick:lower() ] then
			local tRegUser = RegMan.GetReg( user.sNick );
			if tRegUser and sMsg:sub( 1, -2 ) == tRegUser.sPassword then
				Announce( user.sNick .. " has confirmed his or her password.|" );
				tUnconfirmed[ user.sNick:lower() ] = nil;
				return true, "*** You've confirmed your password, you can now use !passwd <newpassword> if you want to change it.|";
			else
				return true, "*** The password you typed did not match the one given to you by " .. sHBName .. ". Try again.|";
			end
		else
			return true, "*** You're currently unregistered.  Please try " .. SetMan.GetString( 29 ):sub( 1, 1 ) .. "regme again or talk to an op for help.|";
		end
	else
		return true, "*** Syntax error, try typing " .. SetMan.GetString( 29 ):sub( 1, 1 ) .. "confirmreg <password> (password is the one you received from " .. sHBName .. " without the < >).|";
	end
end
]]

function tCommandArrivals.addreguser:Action( user, sMsg )
	if sMsg then
		local sNick, sPass, sProfile = sMsg:sub( 1, -2 ):match( "^(%S+)%s+(%S+)%s+(%S+)$" )
		if sNick then
			if RegMan.GetReg( sNick ) then
				return true, "*** " .. sNick .. " is already registered.|";
			elseif sNick:match( "[^$|<>:?*\"/\\]" ) and #sNick <= 64 then
				if sPass:match( "[^$|]" ) and #sPass <= 64 then
					local nProfileNumber = ( ProfMan.GetProfile( sProfile ) or { } ).iProfileNumber;
					if nProfileNumber then
						if user.iProfile <= nProfileNumber then
							if sPass == "generatepass" then
								---[[ By Mutor
								local t = {{48,57},{65,90},{97,122}}
								math.randomseed(os.time())
								sPass = ""
								for i = 1, math.random( 7, 12 ) do
									local r = math.random(1,#t)
									sPass = sPass..string.char(math.random(t[r][1],t[r][2]))
								end
								--]]
							end
							RegMan.AddReg( sNick, sPass, nProfileNumber );
							local NewReg = Core.GetUser( sNick );
							if NewReg then
--								tUnconfirmed[ sNick:lower() ] = true;
								Core.SendPmToUser( NewReg, sHBName, "*** " .. user.sNick .. " has registered you at " .. SetMan.GetString( 0 ) .. "!\r\n\nYour info: " ..
									"\r\n\n\t\t Nickname: " .. sNick ..
									"\r\n\t\t Password: " .. sPass ..
									"\r\n\t\t Profile: " .. sProfile ..
									"\r\n\n\t Use !help to see all the commands available to you." ..
									"\r\n\n\t Remember to /fav our hub! ^_^|" 
								);
							end
							Announce( "*** We have a new " .. sProfile .. ". Welcome, " .. sNick .. "!|" );
							return true;
						else
							return true, "*** " .. ProfMan.GetProfile( user.iProfile ).sProfileName .. "s are not allowed to register " .. sProfile .. "s.|";
						end
					else
						return true, "*** " .. sProfile .. " is not a valid profile. Use one of the following profile names: " .. CanReg( user.iProfile ):sub( 1, -3 );
					end
				else
					return true, "*** " .. sPass .. " contains one or more of the following invalid characters: |$";
				end
			else
				return true, "*** " .. sNick .. " contains one more more of the following invalid characters: |$";
			end
		else
			return true, "*** Syntax error in command, use " .. SetMan.GetString( 29 ):sub( 1, 1 ) .. "addreguser <nick> <password> <profilename>. Bad parameters given!|";
		end
	else
		return true, "*** Syntax error in command, use " .. SetMan.GetString( 29 ):sub( 1, 1 ) .. "addreguser <nick> <password> <profilename>. Bad parameters given!|";
	end
end

function tCommandArrivals.delreguser:Action( user, sMsg )
	if sMsg then
		local sNick = sMsg:sub( 1, -2 )
		if sNick then
			local usr = RegMan.GetReg( sNick );
			if usr then
				if usr.iProfile >= user.iProfile then
					RegMan.DelReg( sNick );
					tUnconfirmed[ sNick:lower() ] = nil;
					Core.SendPmToNick( sNick, sHBName, "*** Your nickname has been unregistered by " .. user.sNick .. ".|" );
					Announce( "*** " .. user.sNick .. " removed " .. sNick .. " from the regged list.|" );
					return true;
				else
					return true, "*** Account deletion failed, " .. sNick .. " is registered as a higher profile. Use one of the following profile names: " .. CanReg( user.iProfile ):sub( 1, -3 );
				end
			else
				return true, "*** Error " .. sNick .. " is not registered!|";
			end
		end
	else
		--Syntax error
	end
end

function tCommandArrivals.chuserprof:Action( user, sMsg )
	if sMsg then
		local sNick, sProfile = sMsg:sub( 1, -2 ):match( "^(%S+)%s+(%S+)$" )
		if sNick then
			local usr = RegMan.GetReg( sNick )
			if usr then
				local nProfileNumber = ( ProfMan.GetProfile( sProfile ) or { } ).iProfileNumber;
				if nProfileNumber then
					if nProfileNumber >= user.iProfile and usr.iProfile >= user.iProfile then
						Core.SendPmToNick( sNick, sHBName, "*** " .. user.sNick .. " has changed your profile from " .. ProfMan.GetProfile( usr.iProfile ).sProfileName .. " to " .. sProfile .. ".|" );
						Announce( "*** " .. user.sNick .. " changed " .. sNick .. "'s profile from " .. ProfMan.GetProfile( usr.iProfile ).sProfileName .. " to " .. sProfile .. ".|" );
						RegMan.ChangeReg( sNick, usr.sPassword, nProfileNumber );
						return true;
					else
						return true, "*** Account changes failed, you cannot alter higher profiles. You can change the following profiles: " .. CanReg( user.iProfile ):sub( 1, -3 );
					end
				else
					return true, "*** " .. sProfile .. " is not a valid profile. Use one of the following profile names: " .. CanReg( user.iProfile ):sub( 1, -3 );
				end
			else
				return true, "*** " .. sNick .. " is not registered.|";
			end
		else
			return true, "*** Syntax error in command, use " .. SetMan.GetString( 29 ):sub( 1, 1 ) .. "chuserprof <nick> <profilename>. Bad parameters given!|";
		end
	end
end

function tCommandArrivals.showreg:Action( )
	local tProfs, tResults, ret = { 0, 1, 2, 3 }, { }, "";
	for i = 1, #tProfs do
		local sProfName, tProfUsers = ProfMan.GetProfile( tProfs[ i ] ).sProfileName, RegMan.GetRegsByProfile( tProfs[ i ] );
		tResults[ sProfName ] = { };
		for ind = 1, #tProfUsers do
			table.insert( tResults[ sProfName ], tProfUsers[ ind ].sNick );
			table.sort( tResults[ sProfName ] )
		end
		ret = ret .. "\t\t\tThere are currently " .. #tResults[ sProfName ] .. " " ..  sProfName .. "s (Profile #" .. tProfs[ i ] .. ") registered:\r\n\r\n\t\t\t" ..  table.concat( tResults[ sProfName ], "\r\n\t\t\t", 1, #tResults[ sProfName ] ) .. "\r\n\r\n"
	end
	return true, "\r\n\r\n\t" .. SetMan.GetString( 0 ) .. "'s Reglist:\r\n\r\n" .. ret;
end

function tCommandArrivals.me:Action( user, sMsg )
	table.insert( ChatHistory, 1, { os.time( ), "* " .. user.sNick .. " " .. ( sMsg:sub( 1, -2 ) ) } );
	if #ChatHistory == HistoryLines + 1 then
		table.remove( ChatHistory, HistoryLines + 1 );
	end
end

function tCommandArrivals.scriptstat:Action( )
	local tScr = ScriptMan.GetScripts();
	local sO = "";
	for i, v in ipairs( tScr ) do
		if v.bEnabled then
			sO = sO .. "\t[" .. i .. "] " .. v.sName .. " is using " .. v.iMemUsage .. " kB.\r\n";
		end
	end
	return true, "Script stats:\r\n\r\n" .. sO;
end
