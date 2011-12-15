--[[
Do not allow unregistered users to participate in the hub
Turn this on in times of proxy abusing romanains
]]

sOCName = SetMan.GetString( 24 ) or "SetMe"; --Bots not enabled in GUI? Change the value after the or.

function UserConnected( user )
	-- enable this if they are sticking to a similar nick trend
--      if string.find( string.lower(user.sNick) , "moni") ~= nil then
                Core.Disconnect( user.sNick );
                Core.SendPmToOps( sOCName, user.sNick .. " with IP: " .. user.sIP .. " and " .. user.iProfile .. " was auto-dropped because no unregged users allowed.|" );
--      end
end
