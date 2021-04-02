#!/bin/bash

# privilege check
if [ $USER != "root" ]; then
	echo "please run with root privilege"
	exit -1
fi

# get user inputs
echo -e "======================="
echo -e " OpenVPN Server Setter"
echo -e "=======================\n"
echo -e "1. Enter your public IP"
read ip
filtered=$(echo ${ip} | grep -Eo "[1-9]{1}[0-9]{0,2}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
while [ ${#filtered} -eq 0 ]; do
	echo -e "ERROR: Enter the valid IP"
	echo -e "1. Enter your public IP"
	read ip
	filtered=$(echo ${ip} | grep -Eo "[1-9]{1}[0-9]{0,2}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
done
echo -e "2. Enter the port that you want to use for VPN server[1194]"
read port
if [ ${#port} -eq 0 ]; then
	port="1194"
fi
echo -e "3. Enter the protocol(tcp or udp) you will use[udp]"
read protocol
if [ ${#protocol} -eq 0 ]; then
	protocol="udp"
fi
echo -e "4. Enter your country[US]"
read country
if [ ${#country} -eq 0 ]; then
	country="US"
fi
echo -e "5. Enter your province[CA]"
read province
if [ ${#province} -eq 0 ]; then
	province="CA"
fi
echo -e "6. Enter your city[SanFrancisco]"
read city
if [ ${#city} -eq 0 ]; then
	city="SanFrancisco"
fi
echo -e "7. Enter your organization[Fort-Funston]"
read org
if [ ${#org} -eq 0 ]; then
	org="Fort-Funston"
fi
echo -e "8. Enter your email[me@myhost.mydomain]"
read email
if [ ${#email} -eq 0 ]; then
	email="me@myhost.mydomain"
fi
echo -e "9. Enter your organization unit[MyOrganizationUnit]"
read ou
if [ ${#ou} -eq 0 ]; then
	ou="MyOrganizationUnit"
fi
echo -e "10. Enter the key name you want[EasyRSA]"
read name
if [ ${#name} -eq 0 ]; then
	name="EasyRSA"
fi
echo -e "11. What is your ISP provider?[KT]"
read isp
if [ ${#isp} -eq 0 ]; then
	isp="KT"
fi
if [ ${isp} == "SKT" ] || [ ${isp} == "skt" ]; then
	isp="SKT"
	dns1="219.250.36.130"
	dns2="210.220.163.82"
elif [ ${isp} == "KT" ] || [ ${isp} == "kt" ]; then
	isp="KT"
	dns1="168.126.63.1"
	dns2="168.126.63.2"
elif [ ${isp} == "LG" ] || [ ${isp} == "lg" ]; then
	isp="LG"
	dns1="164.124.101.2"
	dns2="203.248.252.2"
else
	isp="other"
	dns1="8.8.8.8"
	dns2="8.8.4.4"
fi

# install openvpn & easyrsa
apt update -y
apt install openvpn ufw openssh-server wget git -y
wget -P ~/ https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz
tar xvf ~/EasyRSA-3.0.8.tgz -C ~/

# make required dirs
mkdir -p ~/client-configs/keys
mkdir -p ~/client-configs/files

# copy setting files to destination
cp vars ~/EasyRSA-3.0.8/vars
cp server.conf /etc/openvpn/server.conf
cp base.conf ~/client-configs/base.conf.bak

# set add_allowed_ip.bash
cp add_allowed_ip.bash.bak add_allowed_ip.bash
sed -i "s/\[port\]/${port}/g" add_allowed_ip.bash
sed -i "s/\[protocol\]/${protocol}/g" add_allowed_ip.bash

# set vars(key's information)
cd ~/EasyRSA-3.0.8/
sed -i "s/\[country\]/${country}/g" vars
sed -i "s/\[province\]/${province}/g" vars
sed -i "s/\[city\]/${city}/g" vars
sed -i "s/\[org\]/${org}/g" vars
sed -i "s/\[email\]/${email}/g" vars
sed -i "s/\[ou\]/${ou}/g" vars
sed -i "s/\[name\]/${name}/g" vars

# set base.conf(client's config)
cd ~/client-configs/
sed -i "s/\[ip\]/${ip}/g" base.conf.bak
sed -i "s/\[port\]/${port}/g" base.conf.bak
sed -i "s/\[protocol\]/${protocol}/g" base.conf.bak

# set server.conf
cd /etc/openvpn/
sed -i "s/\[port\]/${port}/g" server.conf
sed -i "s/\[protocol\]/${protocol}/g" server.conf
sed -i "s/\[dns1\]/${dns1}/g" server.conf
sed -i "s/\[dns2\]/${dns2}/g" server.conf
if [ ${protocol} == "udp" ]; then
	sed -i "s/\[mode\]/1/g" server.conf
elif [ ${protocol} == "tcp" ]; then
	sed -i "s/\[mode\]/0/g" server.conf
else
	echo "ERROR: protocol is invalid"
fi

cd $dir

# firewall settings
echo -e "*nat\n:POSTROUTING ACCEPT \[0:0\]\n-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE\nCOMMIT" >> /etc/ufw/before.rules
sed -i "s/DEFAULT_FORWARD_POLICY=\"DENY\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g" /etc/default/ufw
ufw enable

# set securetty
cp /usr/share/doc/util-linux/examples/securetty /etc/securetty

# set sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf
sed -i "s/# net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf
sysctl -p

# ip forwarding
iptables -A INPUT -i tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -j ACCEPT

# generate cert & keys
cd ~/EasyRSA-3.0.8/
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa gen-req server nopass
cp pki/private/server.key /etc/openvpn/
./easyrsa sign-req server server
cp pki/issued/server.crt /etc/openvpn/
cp pki/ca.crt /etc/openvpn/
./easyrsa gen-dh
openvpn --genkey --secret ta.key
cp ta.key /etc/openvpn/
cp pki/dh.pem /etc/openvpn/

# start openvpn server
systemctl start openvpn@server
systemctl enable openvpn@server
echo -e "\n----------------------------"
echo -e " The VPN server is started\n"

# prepare to add client
chmod -R 700 ~/client-configs
cp ta.key ~/client-configs/keys/
cp /etc/openvpn/ca.crt ~/client-configs/keys/
cp ~/client-configs/keys/ta.key ~/client-configs/files/
chmod 644 ~/client-configs/files/ta.key
ufw allow from any
ufw deny ${port}/${protocol}
# announce
echo -e "Next step is adding clients ovpn files.\nRun the add_client.bash."
