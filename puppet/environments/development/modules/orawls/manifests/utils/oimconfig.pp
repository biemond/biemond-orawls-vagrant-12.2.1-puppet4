# == Define: orawls::utils::oimconfig
#
# does all the Oracle Identity Management configuration
#
define orawls::utils::oimconfig(
  Integer $version                                        = undef,
  String $oim_home                                        = undef,
  Boolean $server_config                                  = false,
  String $oim_password                                    = undef,
  Boolean $remote_config                                  = false,
  String $keystore_password                               = undef,
  Boolean $design_config                                  = false,
  String $oimserver_hostname                              = undef,
  Integer $oimserver_port                                 = 14000,
  String $soaserver_name                                  = 'soa_server1',
  String $oimserver_name                                  = 'oim_server1',
  Boolean $bi_enabled                                     = false, # only when you got a BI cluster
  Optional[String] $bi_cluster_name                       = undef,
  String $repository_database_url                         = undef, #jdbc:oracle:thin:@192.168.50.5:1521:XE
  String $repository_prefix                               = 'DEV',
  String $repository_password                             = undef,
  String $weblogic_home_dir                               = $::orawls::weblogic::weblogic_home_dir,
  String $middleware_home_dir                             = $::orawls::weblogic::middleware_home_dir,
  String $jdk_home_dir                                    = $::orawls::weblogic::jdk_home_dir,
  Optional[String] $wls_domains_dir                       = $::orawls::weblogic::wls_domains_dir,
  String $domain_name                                     = undef,
  String $adminserver_name                                = 'AdminServer',
  String $adminserver_address                             = 'localhost',
  Integer $adminserver_port                               = 7001,
  Integer $nodemanager_port                               = 5556,
  String $weblogic_user                                   = 'weblogic',
  String $weblogic_password                               = undef,
  String $os_user                                         = $::orawls::weblogic::os_user,
  String $os_group                                        = $::orawls::weblogic::os_group,
  String $download_dir                                    = $::orawls::weblogic::download_dir,
  Boolean $log_output                                     = $::orawls::weblogic::log_output,
)
{

  if ( $wls_domains_dir == undef or $wls_domains_dir == '') {
    $domains_dir = "${middleware_home_dir}/user_projects/domains"
  } else {
    $domains_dir =  $wls_domains_dir
  }

  $domain_dir = "${domains_dir}/${domain_name}"
  $exec_path = "${jdk_home_dir}/bin:${lookup('orawls::exec_path')}"

  if ( $remote_config == true ) {
    file { "${download_dir}/${title}config_oim_remote.rsp":
      ensure  => present,
      content => template('orawls/oim/oim_remote.rsp.erb'),
      mode    => '0775',
      owner   => $os_user,
      group   => $os_group,
      backup  => false,
    }

    exec { "config oim remote ${title}":
      command   => "${oim_home}/bin/config.sh -silent -response ${download_dir}/${title}config_oim_remote.rsp -waitforcompletion",
      timeout   => 0,
      onlyif    => "${remote_config} == true",
      require   => File["${download_dir}/${title}config_oim_remote.rsp"],
      path      => $exec_path,
      user      => $os_user,
      group     => $os_group,
      logoutput => true,
    }
  }

  if ( $design_config == true  ) {
    file { "${download_dir}/${title}config_oim_design.rsp":
      ensure  => present,
      content => template('orawls/oim/oim_design.rsp.erb'),
      mode    => '0775',
      owner   => $os_user,
      group   => $os_group,
      backup  => false,
    }

    exec { "config oim design ${title}":
      command   => "${oim_home}/bin/config.sh -silent -response ${download_dir}/${title}config_oim_design.rsp -waitforcompletion",
      timeout   => 0,
      require   => File["${download_dir}/${title}config_oim_design.rsp"],
      path      => $exec_path,
      user      => $os_user,
      group     => $os_group,
      logoutput => true,
    }
  }

  if ( $server_config ) {

    ##if these params are empty always continue
    if $domain_dir != undef  {
      # check if oim is already configured in this weblogic domain
      $oimValue = oim_configured( $domain_dir )
    } else {
      fail('domain parameters are empty ')
    }
    #$oimValue = false
    if ( $oimValue == false ) {
      file { "${download_dir}/${title}config_oim_server.rsp":
        ensure  => present,
        content => template('orawls/oim/oim_server.rsp.erb'),
        mode    => '0775',
        owner   => $os_user,
        group   => $os_group,
        backup  => false,
      }
      exec { "config oim server ${title}":
        command   => "/bin/sh -c 'unset DISPLAY;${oim_home}/bin/config.sh -silent -response ${download_dir}/${title}config_oim_server.rsp -waitforcompletion -debug -logLevel fine'",
        timeout   => 0,
        require   => File["${download_dir}/${title}config_oim_server.rsp"],
        path      => $exec_path,
        user      => $os_user,
        group     => $os_group,
        logoutput => true,
      }

      if( $bi_enabled == true ) {
        # the py script used by the wlst
        file { "${download_dir}/bi-createUDD${title}.py":
          ensure  => present,
          content => template('orawls/wlst/wlstexec/fmw/bi-createUDD.py.erb'),
          backup  => false,
          replace => true,
          mode    => '0775',
          owner   => $os_user,
          group   => $os_group,
        }

        $javaCommand = "${lookup('orawls::java')} -Dweblogic.security.SSL.ignoreHostnameVerification=true weblogic.WLST -skipWLSModuleScanning "
        # execute WLST script
        exec { "execwlst bi-createUDD.py ${title}":
          command     => "${javaCommand} ${download_dir}/bi-createUDD${title}.py ${weblogic_password}",
          environment => ["CLASSPATH=${weblogic_home_dir}/server/lib/weblogic.jar",
                          "JAVA_HOME=${jdk_home_dir}"],
          path        => $exec_path,
          user        => $os_user,
          group       => $os_group,
          logoutput   => $log_output,
          require     => [File["${download_dir}/bi-createUDD${title}.py"],
                          Exec["config oim server ${title}"]],
          before      => Orawls::Control['stopOIMOimServer1AfterConfig']
        }
      }

      orawls::control{'stopOIMOimServer1AfterConfig':
        weblogic_home_dir   => $weblogic_home_dir,
        jdk_home_dir        => $jdk_home_dir,
        wls_domains_dir     => $domains_dir,
        domain_name         => $domain_name,
        server_type         => 'managed',
        target              => 'Server',
        server              => $oimserver_name,
        adminserver_address => $adminserver_address,
        adminserver_port    => $adminserver_port,
        nodemanager_port    => $nodemanager_port,
        action              => 'stop',
        weblogic_user       => $weblogic_user,
        weblogic_password   => $weblogic_password,
        os_user             => $os_user,
        os_group            => $os_group,
        download_dir        => $download_dir,
        log_output          => $log_output,
        require             => Exec["config oim server ${title}"],
      }

      orawls::control{'stopOIMSoaServer1AfterConfig':
        weblogic_home_dir   => $weblogic_home_dir,
        jdk_home_dir        => $jdk_home_dir,
        wls_domains_dir     => $domains_dir,
        domain_name         => $domain_name,
        server_type         => 'managed',
        target              => 'Server',
        server              => $soaserver_name,
        adminserver_address => $adminserver_address,
        adminserver_port    => $adminserver_port,
        nodemanager_port    => $nodemanager_port,
        action              => 'stop',
        weblogic_user       => $weblogic_user,
        weblogic_password   => $weblogic_password,
        os_user             => $os_user,
        os_group            => $os_group,
        download_dir        => $download_dir,
        log_output          => $log_output,
        require             => [Orawls::Control['stopOIMOimServer1AfterConfig'],
                                Exec["config oim server ${title}"],],
      }

      orawls::control{'stopOIMAdminServerAfterConfig':
        weblogic_home_dir   => $weblogic_home_dir,
        jdk_home_dir        => $jdk_home_dir,
        wls_domains_dir     => $domains_dir,
        domain_name         => $domain_name,
        server_type         => 'admin',
        target              => 'Server',
        server              => $adminserver_name,
        adminserver_address => $adminserver_address,
        adminserver_port    => $adminserver_port,
        nodemanager_port    => $nodemanager_port,
        action              => 'stop',
        weblogic_user       => $weblogic_user,
        weblogic_password   => $weblogic_password,
        os_user             => $os_user,
        os_group            => $os_group,
        download_dir        => $download_dir,
        log_output          => $log_output,
        require             => [Orawls::Control['stopOIMOimServer1AfterConfig'],
                                Orawls::Control['stopOIMSoaServer1AfterConfig'],
                                Exec["config oim server ${title}"],],
      }

      orawls::control{'startOIMAdminServerAfterConfig':
        weblogic_home_dir   => $weblogic_home_dir,
        jdk_home_dir        => $jdk_home_dir,
        wls_domains_dir     => $domains_dir,
        domain_name         => $domain_name,
        server_type         => 'admin',
        target              => 'Server',
        server              => $adminserver_name,
        adminserver_address => $adminserver_address,
        adminserver_port    => $adminserver_port,
        nodemanager_port    => $nodemanager_port,
        action              => 'start',
        weblogic_user       => $weblogic_user,
        weblogic_password   => $weblogic_password,
        os_user             => $os_user,
        os_group            => $os_group,
        download_dir        => $download_dir,
        log_output          => $log_output,
        require             => [Orawls::Control['stopOIMOimServer1AfterConfig'],
                                Orawls::Control['stopOIMAdminServerAfterConfig'],
                                Orawls::Control['stopOIMSoaServer1AfterConfig'],
                                Exec["config oim server ${title}"],],
      }
    }
  }
}


