--[[ unreg.lua
by box2 - 2011-12

Do not allow unregistered users to participate in the hub
Turn this on in times of proxy abusing romanains

NOTE:  These .ro clowns usually are accompanied by DDoS attacks
so this only stops them from gloating in hub.

To reduce DDoS effectiveness by 70% or more, add these iptables rules:

# DROP ip if more than 3 connection attempts within 100 seconds
SECONDS=100
BLOCKCOUNT=3

iptables -A INPUT -p tcp --dport 411 -i eth0 -m state --state NEW -m recent --set --name 411
iptables -A INPUT -p tcp --dport 411 -i eth0 -m state --state NEW -m recent --update --seconds ${SECONDS} --hitcount ${BLOCKCOUNT} --name 411 -j DROP
]]

sOCName = SetMan.GetString( 24 ) or "SetMe"; --Bots not enabled in GUI? Change the value after the or.

function UserConnected( user )
	-- enable this if they are sticking to a similar nick trend
--      if string.find( string.lower(user.sNick) , "moni") ~= nil then
                Core.Disconnect( user.sNick );
                Core.SendPmToOps( sOCName, user.sNick .. " with IP: " .. user.sIP .. " and " .. user.iProfile .. " was auto-dropped because no unregged users allowed.|" );
--      end
end
