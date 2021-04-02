#!/bin/bash
if [ $USER != "root" ]; then
	echo -e "Please run with root privilege"
	exit -1
fi
dir=$(pwd)

# get user name
echo -e "Enter the user name of the client"
read user

cd ~/EasyRSA-3.0.8/
./easyrsa gen-req ${user} nopass
cp pki/private/${user}.key ~/client-configs/keys/
./easyrsa sign-req client ${user}
cp pki/issued/${user}.crt ~/client-configs/keys/

cd ~/client-configs/
cp base.conf.bak base.conf
sed -i "s/\[user\]/${user}/g" base.conf

KEY_DIR=~/client-configs/keys
OUTPUT_DIR=~/client-configs/files
BASE_CONFIG=~/client-configs/base.conf

cat ${BASE_CONFIG} \
	<(echo -e '<ca>') \
	${KEY_DIR}/ca.crt \
	<(echo -e '</ca>\n<cert>') \
	${KEY_DIR}/${user}.crt \
	<(echo -e '</cert>\n<key>') \
	${KEY_DIR}/${user}.key \
	<(echo -e '</key>\n<tls-auth>') \
	${KEY_DIR}/ta.key \
	<(echo -e '</tls-auth>') \
	> ${OUTPUT_DIR}/${user}.ovpn

echo -e "Now the client's ovpn file is created. check the ${OUTPUT_DIR}/${user}.ovpn"
echo -e "The next step is adding the client's ip to allow list of firewall. Find the public ip of the client and run the add_allowed_ip.bash"
