## base module to set common settings across all servers
class base_module {

## place our own apt repo
file {'/etc/apt/sources.list':
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  source => 'puppet:///modules/base_module/common/focal.apt.list',
}

# make sure we've got a clean apt cache
exec {'apt refresh':
  command     => '/usr/bin/apt clean && /usr/bin/apt update',
  refreshonly => true,
  subscribe   => File['/etc/apt/sources.list'],
}

## install necessary packages
$base_packages = ['net-tools', 'nano', 'jq', 'git', 'htop', 'gpg', 'curl',
                  'mlocate', 'dnsutils', 'whois', 'traceroute', 'nload',
                  'snmpd', 'lm-sensors', 'xz-utils', 'puppet', 'zsh']

package { $base_packages:
  ensure  => latest,
}

# clear puppet ruby warning
file {'/etc/profile.d/disableRubyPuppetWarn.sh':
  ensure  => present,
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
  content => "#managed by puppet\nexport RUBYOPT='-W0'\n"
}

# add our system-wide alias to execute a puppet run
file_line {'puppet sequence':
  ensure => present,
  path   => '/etc/bash.bashrc',
  line   => 'alias runpup="cd /etc/puppetlabs/code && /usr/bin/git pull && /usr/bin/puppet apply /etc/puppetlabs/code/manifests/site.pp"',
}

# keep root cron up-to-date
file {'/etc/cron.d/puppet':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  source => 'puppet:///modules/base_module/common/puppet_cron',
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
  key    => 'AAAAC3NzaC1lZDI1NTE5AAAAIFc6qozK4DqC5hxsi2ifrFsDY64ytgI4xQKQ+Vv6RYRw',
}

ssh_authorized_key { 'matt_ssh_key2':
  ensure => present,
  user   => 'matt',
  type   => 'ssh-ed25519',
  key    => 'AAAAC3NzaC1lZDI1NTE5AAAAIAjd6bCh+wk7Gksji1Q/73mnSTYEGhLeXzxHkkMhdXWI',
}

# let's enable oh-my-zsh, set the shell to zsh, and the theme to gentoo
ohmyzsh::install { ['root', 'matt']: set_sh => true }
ohmyzsh::theme { ['root', 'matt']: theme => 'gentoo' }

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
file { '/etc/update-motd.d/01-screenfetch':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
  source => 'puppet:///modules/base_module/common/01-screenfetch',
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

if ip_in_range($::ipaddress, '192.168.1.0/24') == true {
  file {'/etc/hosts':
    ensure  => present,
    content => "# managed by puppet\n127.0.0.1 localhost localhost.localdomain\n${::ipaddress} ${::hostname}.x86txt.atl ${::hostname}\n",
  }
  file {'/etc/hostname':
    ensure  => present,
    content => "#managed by puppet\n${::hostname}.x86txt.atl\n"
  }
}
else {
  file { '/etc/hosts':
    ensure  => present,
    content => "# managed by puppet\n127.0.0.1 localhost localhost.localdomain\n${::ipaddress} ${::hostname}.x86txt.lan ${::hostname}\n",
  }
  file {'/etc/hostname':
    ensure  => present,
    content => "#managed by puppet\n${::hostname}.x86txt.lan\n"
  }
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

# remove vmware customization files that break dns
file { '/etc/netplan/00-installer-config.yaml.BeforeVMwareCustomization':
  ensure => absent,
  notify => Exec['/usr/sbin/netplan apply'],
}

file { '/etc/netplan/99-netcfg-vmware.yaml':
  ensure => absent,
  notify => Exec['/usr/sbin/netplan apply'],
}

# re-apply netplan if either vmware config file is removed
exec {'/usr/sbin/netplan apply':
  refreshonly => true,
  subscribe   => [File['/etc/netplan/00-installer-config.yaml.BeforeVMwareCustomization'],
                  File['/etc/netplan/99-netcfg-vmware.yaml'] ]
}

/*
# install netdata and attach it to x86txt.lan war room
exec {'install netdata':
  command => '/usr/bin/wget https://my-netdata.io/kickstart.sh && /usr/bin/bash /tmp/kickstart.sh --dont-wait --non-interactive --claim-token cbLiaCjwPrBpvn24clG3R7StfvNnauuGqpZQJBgHUjLuJf9WHhKc9JaIHQvWyKY2Sf6C-G-xX0HdQX6sLnJkquZXuK6ntJ_yJKOrJThhmO-JbhG0ogp3jmF9R95dXvI9WFWLO_4 --claim-rooms 45ccf9dd-4893-4fda-b013-cfe2f37a6459 --claim-url https://app.netdata.cloud',
  cwd     => '/tmp',
  path    => ['/usr/bin', '/usr/sbin'],
  creates => '/usr/sbin/netdata',
}
*/

} # end base_module
