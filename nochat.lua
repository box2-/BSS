--[[ nochat.lua
by box2 - 2012-04

If unregistered users try to chat, they are disconnected

]]

sOCName = SetMan.GetString( 24 ) or "SetMe"; --Bots not enabled in conf? Change the value after the or.

function ChatArrival(user, data)
	if user.iProfile < 0 then
		Core.Disconnect( user.sNick );
		Core.SendPmToOps( sOCName, user.sNick .. " with IP: " .. user.sIP .. " tried to chat and was dropped.|" );
	end
end
