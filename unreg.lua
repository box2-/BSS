sOCName = SetMan.GetString( 24 ) or "SetMe"; --Bots not enabled in GUI? Change the value after the or.

--[[ fucking clown romanian hacker ]]
function UserConnected( user )
--      if string.find( string.lower(user.sNick) , "moni") ~= nil then
--      if user.iProfile == "-1" then
                Core.Disconnect( user.sNick );
                Core.SendPmToOps( sOCName, user.sNick .. " with IP: " .. user.sIP .. " and " .. user.iProfile .. " was auto-dropped because no unregged users allowed.|" );
--      end
end
