--[[
ragemode.lua

nmap unregistered users on connect
viciously attack unregistered users if they try to chat

because box2 is real fucking mad and sick of this shit

authors: amenay, box2

]]
--[[
tUsers = {};

function ChatArrival( tUser, sData )
	if tUser.iProfile == -1 and not tUsers[ tUser.sNick ] then
		tUsers[ tUser.sNick ] = true;
		local sOutput, sError = io.popen( "screen -d -m echo " .. tUser.sIP .. "> out" );
	end
end
]]

tUsers = {};

sPrefix = "^[" .. ( SetMan.GetString( 29 ):gsub( ( "%p" ), function ( p ) return "%" .. p end ) ) .. "]";

function ChatArrival( tUser, sData )
    local sNick = tUser.sNick;
    if tUser.iProfile == -1 and not tUsers[ sNick ] then
        local sOutput, sError = io.popen( "screen -d -m echo " .. tUser.sIP .. "> out" );
        tUsers[ sNick ] = tUser.sIP;
    end
    local nInitIndex = #sNick + 4;
    if sData:match( sPrefix, nInitIndex ) then
        local cmd = sData:match( "^(%w+)", nInitIndex + 1 );
        if cmd then
            cmd = cmd:lower( );
            if tCommandArrivals[ cmd ] then
                if tCommandArrivals[ cmd ].Permissions[ tUser.iProfile ] then
                    tCommandArrivals[ cmd ]:Action( tUser )
                else
                    return Core.SendToUser( tUser, "<" .. SetMan.GetString( 21 ) .. "> " ..  "*** Permission denied.\124" ), true;
                end
            else
                return false;
            end
        end
    end
end

tCommandArrivals = { Permissions = { getiplist = { 0 = true } } };

function tCommandArrivals.getiplist:Action( tUser )
    sReturn = "<" .. SetMan.GetString( 21 ) .. ">\n\n";
    for i,v in pairs( tUsers ) do
        sReturn = sReturn .. i .. "\t" .. v .. "\n";
    end
    return Core.SendToUser( tUser, sReturn );
end
