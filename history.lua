--[[ history.lua
Ripped from lua (by amenay)

When joining the hub, `!history` to see the last 150 lines of public chat.
`!history onjoin` to automatically do this every time you connect to the hub.

Command Permissions are set in: scripts/data/tbl/history.tbl
]]

ChatHistory = { };
ShowHistory = { };
HistoryLines = 150

-- Primary Bot name
sOCName = SetMan.GetString( 24 ) or "SetMe"; --Bots not enabled in GUI? Change the value after the or.
-- Hoobi name
sHBName = SetMan.GetString( 21 ) or "SetMeToo";
-- Chat coming from... who is this again?
sFromHB = "<" .. sHBName .. "> ";

function ChatArrival( user, data )
	-- Save chat line
	table.insert( ChatHistory, 1, { os.time( ), data:sub( 1, -2 ) } )
	if #ChatHistory == HistoryLines + 1 then
		table.remove( ChatHistory, HistoryLines + 1 )
	end

--[[ DEPENDENCIES OF THIS AREA NEED TO BE MET ]]
	if tCommandArrivals[ cmd ] then		-- Listen for incoming command
		if tCommandArrivals[ cmd ].Permissions[ user.iProfile ] then	-- Does this profile have permission?
			local msg;
			if ( nInitIndex + #cmd ) <= #data + 1 then msg = data:sub( nInitIndex + #cmd + 2 ) end
			return ExecuteCommand( user, msg, cmd, "Main" );
		else
			return Core.SendToUser( user, sFromHB ..  "*** Permission denied.|" ), true;
		end
	else
		return false;
	end
--[[]]
end

-- Save action line
function tCommandArrivals.me:Action( user, sMsg )
        table.insert( ChatHistory, 1, { os.time( ), "* " .. user.sNick .. " " .. ( sMsg:sub( 1, -2 ) ) } );
        if #ChatHistory == HistoryLines + 1 then
                table.remove( ChatHistory, HistoryLines + 1 );
        end
end

-- Command Arrival (PROFILE PERMISSIONS SET IN scripts/data/tbl/history.tbl)
function tCommandArrivals.history:Action( user, sMsg )
        if sMsg and sMsg:sub( 1, -2 ) == "onjoin" then
                if ShowHistory[ user.sNick ] then
                        ShowHistory[ user.sNick ] = nil;
                        return true, "*** You will no longer receive history onjoin.|";
                else
                        ShowHistory[ user.sNick ] = true;
                        return true, "*** You will now receive history automatically upon rejoining the hub.|"
                end
        end
        return true, doHistory( );
end

-- Print History
function doHistory( )
	local ret = "The last " .. #ChatHistory .. " lines of chat\r\n\r\n";
	for i = #ChatHistory, 1, -1 do
		ret = ret .. "[" .. os.date( "%x %X", ChatHistory[ i ][1] ) .. "] " .. ChatHistory[ i ][2] .. "\r\n";
	end
	return ret;
end

-- Auto Print for Regs
function RegConnected( user )
	Core.SendToUser( user, "Type !history to see the last " .. #ChatHistory .. " lines of chat. (Type \"!history onjoin\" to receive automatically.)|" );
	if ShowHistory[ user.sNick ] then Core.SendToUser( user, sFromHB .. doHistory( ) ) end;
end

-- Auto Print for Ops
function OpConnected( user )
	Core.SendToUser( user, "Type !history to see the last " .. #ChatHistory .. " lines of chat. (Type \"!history onjoin\" to receive automatically.)|" );
	if ShowHistory[ user.sNick ] then Core.SendToUser( user, sFromHB .. doHistory( ) ) end;
end
