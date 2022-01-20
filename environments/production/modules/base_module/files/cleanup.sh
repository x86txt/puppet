#!/bin/zsh

#Stop services for cleanup
sudo service rsyslog stop

#clear audit logs
if [ -f /var/log/wtmp ]; then
    truncate -s0 /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
    truncate -s0 /var/log/lastlog
fi

#cleanup /tmp directories
rm -rf /tmp/*
rm -rf /var/tmp/*

#cleanup current ssh keys
rm -f /etc/ssh/ssh_host_*

# remove machine-id for proper dhcp
rm -fr /etc/machine-id

#add check for ssh keys on reboot...regenerate if neccessary
cat << 'EOL' | sudo tee /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
test -f /etc/ssh/ssh_host_rsa_key || dpkg-reconfigure openssh-server
cd /etc/puppet/code && /usr/bin/git pull && /usr/bin/puppet apply /etc/puppet/code/manifests/site.pp
test -f /etc/machine-id || systemd-machine-id-setup && reboot && rm -f /etc/rc.local
exit 0
EOL

# make sure the script is executable
chmod +x /etc/rc.local

#cleanup apt
apt clean

# cleans out all of the cloud-init cache / logs - this is mainly cleaning out networking info
sudo cloud-init clean --logs

#cleanup shell history
omz_history -c

# final apt update
apt update

#shutdown
#shutdown -h now
