# include ufw module
#include ufw

## base module to set firewall settings across all servers
class firewall {

# generic settings for all servers
ufw::allow { 'ssh':
  port => '22',
}

ufw::allow { 'ssh-lan':
  ensure => absent,
  port   => '22',
  from   => '10.5.22.0/24',
}

ufw::allow { 'netdata-lan':
  port   => '19999',
}

# gitlab rules
if ($::hostname == gitlab) {

  ufw::allow { 'gitlab-http':
  port => '80',
  }

  ufw::allow { 'gitlab-https':
  port => '443',
  }

} # end gitlab


# monerod rules
if ($::hostname == monerod) {

  ufw::allow { 'monero-18080':
  port => '18080',
  }

  ufw::allow { 'monero-18089':
  port => '18089',
  }

} # end monerod

# nfs rules
if ($::hostname == nfs) {

  ufw::allow { 'nfs-tcp':
  port  => '2049',
  proto => 'tcp',
  }

  ufw::allow { 'nfs-udp':
  port  => '2049',
  proto => 'udp',
  }

} # end nfs

# nginx rules
if ($::hostname == nginx) {

  ufw::allow { 'nginx-http':
  port => '80',
  }

  ufw::allow { 'nginx-https':
  port => '443',
  }

} # end nginx

# openvpn rules
if ($::hostname == openvpn) {

  ufw::allow { 'openvpn-admin':
  port => '943',
  }

  ufw::allow { 'openvpn-traffic1':
  port  => '1194',
  proto => 'tcp',
  }

  ufw::allow { 'openvpn-traffic2':
  port  => '1194',
  proto => 'udp',
  }

} # end openvpn

# plex rules
if ($::hostname == plex1) or ($::hostname == plex) {

  ufw::allow { 'plex1-media':
  port => '32400',
  }

  ufw::allow { 'plex1-2':
  port => '32469',
  }

  ufw::allow { 'plex1-3':
  port => '8324',
  }

  ufw::allow { 'plex1-4':
  port  => '32410:32414',
  proto => 'udp',
  }

  ufw::allow { 'plex1-5':
  port  => '1900',
  proto => 'udp',
  }

  ufw::allow { 'plex-tautulli':
  port  => '8181',
  proto => 'tcp',
  }

} # end plex

# qbt rules
if ($::hostname == qbt) {

  ufw::allow { 'qbt-8080':
  port => '8080',
  }

  ufw::allow { 'qbt-22288':
  port => '22288',
  }

} # end qbt

# tor relay rules
if ($::hostname == tor) {

  ufw::allow { 'tor-9050':
  port => '9050',
  }

} # end tor

# unifi rules
if ($::hostname == unifi) {

  ufw::allow { 'unifi-8080':
  port => '8080',
  }

  ufw::allow { 'unifi-8443':
  port => '8443',
  }

  ufw::allow { 'unifi-3478':
  port  => '3478',
  proto => 'udp',
  }

  ufw::allow { 'unifi-27117':
  port => '27117',
  }

  ufw::allow { 'unifi-10001':
  port  => '10001',
  proto => 'udp',
  }

  ufw::allow { 'unifi-1900':
  port  => '1900',
  proto => 'udp',
  }

} # end unifi

}
