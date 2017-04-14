#
# java alternatives for rhel, debian
#
define jdk7::config::alternatives(
  String $java_home_dir = undef,
  String $full_version  = undef,
  Integer $priority     = undef,
  String $user          = lookup('jdk7::user'),
  String $group         = lookup('jdk7::group'),
)
{
  $alt_command = lookup('jdk7::alternatives')
  $path = lookup('jdk7::exec_path')

  if $title == 'java_sdk' {
    exec { "java alternatives ${title}":
      command   => "${alt_command} --install /etc/alternatives/{title} ${title} ${java_home_dir}/${full_version} ${priority}",
      unless    => "${alt_command} --display ${title} | grep -v best  | /bin/grep -v priority | /bin/grep ${full_version}",
      path      => $path,
      logoutput => true,
      user      => $user,
      group     => $group,
      cwd       => lookup('jdk7::tmp_dir'),
    }
  }
  else {
    exec { "java alternatives ${title}":
      command   => "${alt_command} --install /usr/bin/${title} ${title} ${java_home_dir}/${full_version}/bin/${title} ${priority}",
      unless    => "${alt_command} --display ${title} | grep -v best  | /bin/grep -v priority | /bin/grep ${full_version}",
      path      => $path,
      logoutput => true,
      loglevel  => verbose,
      user      => $user,
      group     => $group,
      cwd       => lookup('jdk7::tmp_dir'),
    }
  }
}
