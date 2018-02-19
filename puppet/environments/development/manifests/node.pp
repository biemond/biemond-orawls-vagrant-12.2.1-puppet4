#
# one machine setup with weblogic 12.1.3
# creates an WLS Domain with JAX-WS (advanced, soap over jms)
# needs jdk7, orawls, orautils, fiddyspence-sysctl, erwbgy-limits puppet modules
#
Package{allow_virtual => false,}

node 'node1.example.com', 'node2.example.com' {

  include os, ssh, java, orawls::weblogic, orautils, jdk7::urandomfix, bsu, copydomain, nodemanager

  Class['java'] -> Class['orawls::weblogic']
}

# operating settings for Middleware
class os {

  $default_params = {}
  $host_instances = hiera('hosts', {})
  create_resources('host',$host_instances, $default_params)

  service { iptables:
    enable    => false,
    ensure    => false,
    hasstatus => true,
  }

  group { 'dba' :
    ensure => present,
  }

  # http://raftaman.net/?p=1311 for generating password
  user { 'oracle' :
    ensure     => present,
    groups     => 'dba',
    shell      => '/bin/bash',
    password   => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home       => "/home/oracle",
    comment    => 'Oracle oracle user created by Puppet',
    managehome => true,
    require    => Group['dba'],
  }

  $install = [ 'binutils.x86_64','unzip.x86_64']

  # package { $install:
  #   ensure  => present,
  # }

  class { 'limits':
    config => {
               '*'       => {  'nofile'  => { soft => '2048'   , hard => '8192',   },},
               'oracle'  => {  'nofile'  => { soft => '65536'  , hard => '65536',  },
                               'nproc'   => { soft => '2048'   , hard => '16384',   },
                               'memlock' => { soft => '1048576', hard => '1048576',},
                               'stack'   => { soft => '10240'  ,},},
               },
    use_hiera => false,
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}
}

class ssh {
  require os

  file { "/home/oracle/.ssh/":
    owner  => "oracle",
    group  => "dba",
    mode   => "700",
    ensure => "directory",
    alias  => "oracle-ssh-dir",
  }

  file { "/home/oracle/.ssh/id_rsa.pub":
    ensure  => present,
    owner   => "oracle",
    group   => "dba",
    mode    => "644",
    source  => "/vagrant/ssh/id_rsa.pub",
    require => File["oracle-ssh-dir"],
  }

  file { "/home/oracle/.ssh/id_rsa":
    ensure  => present,
    owner   => "oracle",
    group   => "dba",
    mode    => "600",
    source  => "/vagrant/ssh/id_rsa",
    require => File["oracle-ssh-dir"],
  }

  file { "/home/oracle/.ssh/authorized_keys":
    ensure  => present,
    owner   => "oracle",
    group   => "dba",
    mode    => "644",
    source  => "/vagrant/ssh/id_rsa.pub",
    require => File["oracle-ssh-dir"],
  }
}


class java {
  require os

  $remove = [ "java-1.7.0-openjdk.x86_64", "java-1.6.0-openjdk.x86_64" ]

  # package { $remove:
  #   ensure  => absent,
  # }

  include jdk7

  $jdk_version  = hiera('wls_jdk_version')
  $jdk_full_version  = hiera('wls_jdk_full_version')

  jdk7::install7{ "jdk-$jdk_version-linux-x64":
      version                     => $jdk_version,
      full_version                => $jdk_full_version,
      alternatives_priority       => 18001,
      x64                         => true,
      download_dir                => "/var/tmp/install",
      urandom_java_fix            => true,
      rsa_key_size_fix            => true,
      cryptography_extension_file => "jce_policy-8.zip",
      source_path                 => "/software",
  }

}

class bsu {
  require orawls::weblogic
  $default_params = {}
  $bsu_instances = hiera('bsu_instances', {})
  create_resources('orawls::bsu',$bsu_instances, $default_params)
}

class copydomain {
  require orawls::weblogic, bsu
  $default_params = {}
  $copy_instances = hiera('copy_instances', {})
  create_resources('orawls::copydomain',$copy_instances, $default_params)
}

class nodemanager {
  require orawls::weblogic, bsu, copydomain
  $default_params = {}
  $nodemanager_instances = hiera('nodemanager_instances', {})
  create_resources('orawls::nodemanager',$nodemanager_instances, $default_params)

  if (hiera('orautils_nodemanagerautostart_enabled')) {
    $str_wls_partial_version  = hiera('wls_partial_version')
    $domains_path = hiera('wls_domains_dir')
    $domain_name  = hiera('domain_name')

    orautils::nodemanagerautostart{"autostart weblogic":
      version                   => $str_wls_partial_version,
      domain                    => $domain_name,
      domain_path               => "${domains_path}/${domain_name}",
      wl_home                   => hiera('wls_weblogic_home_dir'),
      user                      => hiera('wls_os_user'),
      jsse_enabled              => hiera('wls_jsse_enabled'             ,false),
      custom_trust              => hiera('wls_custom_trust'             ,false),
      trust_keystore_file       => hiera('wls_trust_keystore_file'      ,undef),
      trust_keystore_passphrase => hiera('wls_trust_keystore_passphrase',undef),
    }
  }

}
