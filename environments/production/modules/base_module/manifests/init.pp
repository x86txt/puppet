## base module to set common settings across all servers
class base_module {

## install necessary packages
$base_packages = ['net-tools', 'nano', 'jq', 'git', 'htop', 'gpg', 'curl',
                  'mlocate', 'dnsutils', 'whois', 'traceroute', 'nload',
                  'vnstat', 'snmpd', 'ansible', 'lm-sensors', 'xz-utils']

package { $base_packages:
  ensure  => latest,
}

# add our system-wide alias to execute a puppet run
file_line {'puppet sequence':
  ensure => present,
  path   => '/etc/bash.bashrc',
  line   => 'alias runpup="cd /etc/puppetlabs/code && /usr/bin/git pull && /opt/puppetlabs/bin/puppet apply /etc/puppetlabs/code/manifests/site.pp"',
}

# keep root cron up-to-date
file {'/var/spool/cron/crontabs/root':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0600',
  source => 'puppet:///modules/base_module/common/root_cron',
}

# fix ufw logging to syslog
file {'/etc/rsyslog.d/20-ufw.conf':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  source => 'puppet:///modules/base_module/common/20-ufw.conf',
}

# fix ufw logging to syslog
file {'/etc/rsyslog.d/40-snmp-statfs.conf':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  source => 'puppet:///modules/base_module/common/40-snmp-statfs.conf',
}

service {'rsyslog':
  ensure    => running,
  enable    => true,
  subscribe => File[ ['/etc/rsyslog.d/20-ufw.conf'], ['/etc/rsyslog.d/40-snmp-statfs.conf'] ],
}

# configure snmpd
file { '/etc/snmp/snmpd.conf':
  ensure  => present,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  source  => 'puppet:///modules/base_module/common/snmpd.conf',
  require => Package['snmpd'],
}

service { 'snmpd':
  ensure    => running,
  enable    => true,
  subscribe => File['/etc/snmp/snmpd.conf']
}

## add unprivileged user matt with sudo rights
user { 'matt':
  ensure         => present,
  groups         => 'sudo',
  managehome     => true,
  purge_ssh_keys => '/home/matt/.ssh/authorized_keys',
}

ssh_authorized_key { 'matt_ssh_key':
  ensure => present,
  user   => 'matt',
  type   => 'ssh-ed25519',
  key    => 'AAAAC3NzaC1lZDI1NTE5AAAAIItoYxbDo8abECvF3yRU8EEAY4kL3kCL83GpdTNpcIUz',
}

ssh_authorized_key { 'matt_ssh_rsa_key':
  ensure => present,
  user   => 'matt',
  type   => 'ssh-rsa',
  key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABgQDDhSNRg62NTrHX94+6h1ZQjb+qGEiqLhENe0jY/j0sWB1DKkKeZOVIK37yO4zT//gw6B0quaceL3tax168NYk4VHmkE87R9lYmcFQIJe/dUF24LhcHTEAYlBQAQDPK0sCy0yEd2Ivwd6v3JAOdDBqj7jafMRJQIUE8wKocGsRgD/xySpgxH7o8qxJnPGlZyXQ9a3thwCZeLqc6Hjt2XlXQLx6vdWK8xwjAqWdM4+8wKqFmi/S6kw5kkoeV2ao+9tcbcIwBFg/q5uHJVveoAjb+ia8HCZmg7042XwG5FhOJupE/kuvrIwO7auv7dIia0dc4VnO+mvMGVJiGaBeNMfhvTfHp3Z3ZGgHVkh44Txm44QXWG+1FJBbOEudAsQCPBsCp2tr+awpLNIDqnIY0hEXlzFW9xhJk42Y89jg1LouYwbTw5uNmi97WOJQWWQ41JKx5GlksjMZZGhM8YcI0SGGBqRh1WJr9w5x4Hx0bem42nMiYb7zNWxKMA+HGp+o27Y8=',
}

## let's enable passwordless sudo
file { '/etc/sudoers':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0440',
  source => 'puppet:///modules/base_module/common/sudoers'
}

## Let's customize our motd with screenfetch
# remove execute permissions to existing motd file
file { '/etc/update-motd.d/':
  ensure  => directory,
  recurse => true,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
}

## place new custom motd file
file { '/etc/update-motd.d/01-custom':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
  source => 'puppet:///modules/base_module/common/01-custom',
}

file {'/usr/bin/screenfetch':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0774',
  source => 'puppet:///modules/base_module/common/screenfetch-dev',
}

# remove landscape info
file {'/etc/update-motd.d/50-landscape-sysinfo':
  ensure => absent,
}

# prefer ipv4, since gigamonster is faster than spectrum
file { '/etc/gai.conf':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  source => 'puppet:///modules/base_module/common/gai.conf',
}

# reboot if gai.conf modified
exec { '/sbin/reboot --force':
  subscribe   => File['/etc/gai.conf'],
  refreshonly => true,
}

file { '/etc/hosts':
    ensure  => present,
    content => "# managed by puppet\n127.0.0.1 localhost localhost.localdomain\n${::ipaddress} ${::hostname}.x86txt.lan ${::hostname}\n",
}

# make sure puppet isn't running, since we're masterless
service { 'puppet':
  ensure => stopped,
  enable => false,
}

# fix multipath vmware errors
file {'/etc/multipathd.conf':
  ensure => present,
  source => 'puppet:///modules/base_module/common/multipath.conf',
  notify => Service['multipathd'],
}

service {'multipathd':
  ensure => running,
}

# make sure ufw is running
service { 'ufw':
  ensure => running,
  enable => true,
}

# make sure rc.local is removed
file {'/etc/rc.local':
  ensure => absent,
}

} # end base_module
