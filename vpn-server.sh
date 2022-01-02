#!/bin/bash

cat << EOF > /etc/docker/daemon.json
{
    "ipv6": false,
    "iptables": false,
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "50m",
        "max-file": "3"
    }
}
EOF

##SSH Security
sed -i -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i -e 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config

##UFW
sed -i -e 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw

echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf && echo net.ipv6.conf.all.forwarding=1 >> /etc/sysctl.conf

usermod -aG docker root

service docker restart

bash -c "$(wget -qO- https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh)"

access_port=$(cat /var/log/cloud-final.out | grep "Access key port" -m 1 | cut -f 5 -d " " | tr -d ,)

management_port=$(cat /var/log/cloud-final.out | grep "Management port" -m 1 | cut -f 4 -d " " | tr -d ,)

ufw allow $management_port/tcp
ufw allow $access_port
ufw allow 22/tcp

ufw --force enable

api_url=$(cat /opt/outline/access.txt | grep "apiUrl:" -m 1 | sed -e 's/apiUrl://g')
cert_sha_256=$(cat /opt/outline/access.txt | grep "certSha256" -m 1 | sed -e 's/certSha256://g')

printf '%s?state=vpn-config&serverId=%s&apiUrl=%s&certSha256=%s' $CALLBACK_URL $CALLBACK_ID $api_url $cert_sha_256 | xargs -n 1 curl --location --request GET

echo "VPN Configuration completed"