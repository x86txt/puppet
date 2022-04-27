## base module to set common settings across all servers
class base_module {

## place our own apt repo
file {'/etc/apt/sources.list':
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  source => "puppet:///modules/base_module/common/${facts['os']['distro']['codename']}.apt.list",
}

# add elasticsearch gpg key
exec {'/usr/bin/wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | /usr/bin/apt-key add -':
  command     => '/usr/bin/wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | /usr/bin/apt-key add -',
  refreshonly => true,
  subscribe   => File['/etc/apt/sources.list.d/elastic-7.x.list'],
}

# add kibana metricbeat and filebeat repos
file {'/etc/apt/sources.list.d/elastic-7.x.list':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  source => 'puppet:///modules/base_module/kibana.list',
}

# make sure we've got a clean apt cache
exec {'apt refresh':
  command     => '/usr/bin/apt clean && /usr/bin/apt update',
  refreshonly => true,
  subscribe   => [ File['/etc/apt/sources.list'], File['/etc/apt/sources.list.d/elastic-7.x.list'] ],
}

## install necessary packages
$base_packages = ['net-tools', 'nano', 'jq', 'git', 'htop', 'gpg', 'tuned-utils-systemtap', 'curl',
                  'mlocate', 'dnsutils', 'whois', 'tuned','traceroute', 'nload',
                  'snmpd', 'lm-sensors', 'xz-utils', 'tuned-utils', 'puppet', 'zsh', 'metricbeat', 'filebeat', 'packetbeat', 'heartbeat-elastic' ]

package { $base_packages:
  ensure  => latest,
  require => [ File['/etc/apt/sources.list'], File['/etc/apt/sources.list.d/elastic-7.x.list'] ],
}

# place kibana conf files
file {'/etc/filebeat/filebeat.yml':
  ensure  => present,
  owner   => 'root',
  group   => 'root',
  mode    => '0600',
  source  => 'puppet:///modules/base_module/common/filebeat.yml',
  require => Package[$base_packages],
}

# place kibana conf files
file {'/etc/packetbeat/packetbeat.yml':
  ensure  => present,
  owner   => 'root',
  group   => 'root',
  mode    => '0600',
  source  => 'puppet:///modules/base_module/common/packetbeat.yml',
  require => Package[$base_packages],
}

# place kibana conf files
file {'/etc/heartbeat/heartbeat.yml':
  ensure  => present,
  owner   => 'root',
  group   => 'root',
  mode    => '0600',
  source  => 'puppet:///modules/base_module/common/heartbeat.yml',
  require => Package[$base_packages],
}

# place kibana conf files
file {'/etc/metricbeat/metricbeat.yml':
  ensure  => present,
  owner   => 'root',
  group   => 'root',
  mode    => '0600',
  source  => 'puppet:///modules/base_module/common/metricbeat.yml',
  require => Package[$base_packages],
}

# configure services for kibana
service {'filebeat':
  ensure    => running,
  enable    => true,
  subscribe => File['/etc/filebeat/filebeat.yml'],
}

# configure services for kibana
service {'heartbeat-elastic':
  ensure    => running,
  enable    => true,
  subscribe => File['/etc/heartbeat/heartbeat.yml'],
}

# configure services for kibana
service {'metricbeat':
  ensure    => running,
  enable    => true,
  subscribe => File['/etc/metricbeat/metricbeat.yml'],
}

# configure services for kibana
service {'packetbeat':
  ensure    => running,
  enable    => true,
  subscribe => File['/etc/packetbeat/packetbeat.yml'],
}

# clear puppet ruby warning
file {'/etc/profile.d/disableRubyPuppetWarn.sh':
  ensure  => present,
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
  content => "#managed by puppet\nexport RUBYOPT='-W0'\n"
}

file_line { '/etc/zsh/zshenv':
  ensure => present,
  match  => "^export RUBYOPT*",
  path   => '/etc/zsh/zshenv',
  line   => 'export RUBYOPT=\'-W0\''
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
  key    => 'AAAAC3NzaC1lZDI1NTE5AAAAIKY0rVQzR8Wu4puq5dJOYPe2pSPNT4kTY1k8UtBzE1Vr',
}

ssh_authorized_key { 'matt_ssh_key2':
  ensure => present,
  user   => 'matt',
  type   => 'ssh-ed25519',
  key    => 'AAAAC3NzaC1lZDI1NTE5AAAAIAjd6bCh+wk7Gksji1Q/73mnSTYEGhLeXzxHkkMhdXWI',
}

file {'/home/matt/.zshrc':
  ensure  => present,
  owner   => 'matt',
  group   => 'matt',
  source  => 'puppet:///modules/base_module/common/.zshrc',
  require => User['matt'],
}

## let's enable passwordless sudo
file { '/etc/sudoers':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0440',
  source => 'puppet:///modules/base_module/common/sudoers',
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
  mode   => '0755',
  source => 'puppet:///modules/base_module/common/screenfetch-dev',
}

# remove landscape info
#file {'/etc/update-motd.d/50-landscape-sysinfo':
#  ensure => absent,
#}

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

# let's make sure our hosts file is correct
file { '/etc/hosts':
    ensure  => present,
    content => "# managed by puppet\n127.0.0.1 localhost localhost.localdomain\n${::ipaddress} ${::hostname}.x86txt.lan ${::hostname}\n",
}

# let's make sure our hostname is correct
file {'/etc/hostname':
    ensure  => present,
    content => "#managed by puppet\n${::hostname}\n"
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

# let's add our x86txt local ca
file {'/usr/local/share/ca-certificates/x86txt-ca.crt':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
  source => 'puppet:///modules/base_module/common/ssl/x86txt.lan.crt',
  notify => Exec['refresh-ca'],
}

# if any ca certs are added. let's refresh our ca keystore
exec {'refresh-ca':
  command     => '/usr/sbin/update-ca-certificates',
  subscribe   => File['/usr/local/share/ca-certificates/x86txt-ca.crt'],
  refreshonly => true,
}

# add our iTerm2 shell integration for zsh
file {'/home/matt/.iterm2_shell_integration.zsh':
  ensure => present,
  owner  => 'matt',
  group  => 'matt',
  mode   => '0600',
  source => 'https://iterm2.com/shell_integration/zsh',
}

# add our iTerm2 shell integration for zsh
file {'/root/.iterm2_shell_integration.zsh':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0600',
  source => 'https://iterm2.com/shell_integration/zsh',
}

} # end base_module
