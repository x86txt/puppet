#!/bin/zsh

# stop services for cleanup
sudo service rsyslog stop

# clear audit logs
if [ -f /var/log/wtmp ]; then
    truncate -s0 /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
    truncate -s0 /var/log/lastlog
fi

# cleanup /tmp directories
rm -rf /tmp/*
rm -rf /var/tmp/*

# cleanup cron logs
rm -f /var/log/chrony/*

# cleanup current ssh keys
rm -f /etc/ssh/ssh_host_*

# remove machine-id and create blank one
rm -f /etc/machine-id ; touch /etc/machine-id

# clear all mailboxes
rm -f /var/mail/*
rm -f /var/spool/mail/*

# add check for ssh keys on reboot...regenerate if neccessary
# execute a puppet run on first boot
# make sure the date is synchronized with ntp
cat << 'EOL' | sudo tee /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
test -f /etc/ssh/ssh_host_rsa_key || ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N "" && \
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
cd /etc/puppet/code && /usr/bin/git pull && /usr/bin/puppet apply /etc/puppet/code/manifests/site.pp
/usr/sbin/ntpdate -u us.pool.ntp.org
/usr/bin/apt update &> /dev/null &
exit 0
EOL

# make sure the script is executable
chmod +x /etc/rc.local

# cleanup apt
apt clean

# cleans out all of the cloud-init cache / logs - this is mainly cleaning out networking info
sudo cloud-init clean --logs

# cleanup shell history
history -p && rm -f /root/.zsh_history ; rm -f /home/matt/.zsh_history

# final apt update
apt update

# shutdown
#shutdown -h now
