# OpenVPN_Setter
help setting OpenVPN Server  
** it's Debain based script.  
** I failed to set protocol as tcp in previous version. I'll check it soon.  

## setting server
1. run set_server.bash with root privilege  
2. enter the server information(the questions are numbered.)
3. just click enter when the default value is set (it's in [ ])
4. when the question "Confirm request details" shown, enter "yes"
5. the server is automatically set & started

## add client
1. run add_client.bash with root privilege
2. enter the client information
3. just click enter when the default value is set (it's in [ ])
4. when the question "Confirm request details" shown, enter "yes"
5. the ovpn setting file is at /root/client-configs/files/

## add client ip to firewall's allow list
1. run add_allowed_ip.bash with root privilege
2. enter the client's public ip to allow
3. done!

## if you want to allow from any ip
1. I don't recommend this option since it can make your system vulunerable.
2. <code>ufw status numbered</code>
3. find the index of "<code>deny [port]/[protocol]</code>"
4. <code>ufw delete [index]</code>

## if you want to allow using ovpn file on multiple device
1. I don't recommend this option since it can make your system vulunerable.
2. open the /etc/openvpn/server.conf
3. uncomment "duplicate-cn"
4. restart openvpn@server : "<code>systemctl restart openvpn@server</code>"
