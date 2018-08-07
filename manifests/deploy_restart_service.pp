####
# oradb_fs::deploy_restart_service
#  author: Matthew Parker
#
# deploys and removes home associated service for starting and stopping databases
#
# variables:
#  String  $home       - home variable set in use (db_#)
#  String  $home_path  - full path to the Oracle home
#  String  $action     - action to perform (deploy, remove)
#
# deploys:
#  /etc/systemd/system/oracle-rdbms_${home_path_short}.service
#
# removes:
#  /etc/systemd/system/oracle-rdbms_${home_path_short}.service
#
####
define oradb_fs::deploy_restart_service (
 String  $home       = undef,
 String  $home_path  = undef,
 String  $action     = undef,
)
{
 $home_path_short = split($home_path,'/')[-1]

 if $action == 'deploy' {
  file { "/etc/systemd/system/oracle-rdbms_${home_path_short}.service":
   ensure  => present,
   content => epp("oradb_fs/oracle-rdbms_home.service.epp",
                 { 'db_home_short'  => $db_name_short,
                   'home_path'      => $home_path}),
   mode    => '0644',
   owner   => 'root',
   group   => 'root'
  }
  exec { "Reload systemd : ${home}" :
   command   => 'systemctl daemon-reload',
   path      => '/bin'
  }
  service { "Start and enable newly added restart service : ${home}" :
   name   => "oracle-rdbms_${home_path_short}",
   enable => true,
   ensure => running
  }
 }
 elsif $action == 'remove' {
  service { "Start and enable newly added restart service : ${home}" :
   name   => "oracle-rdbms_${home_path_short}",
   enable => false,
   ensure => stopped
  }
  file { "/etc/systemd/system/oracle-rdbms_${home_path_short}.service":
   ensure  => absent,
  }
  exec { "Reload systemd : ${home}" :
   command   => 'systemctl daemon-reload',
   path      => '/bin'
  }
 }
 else {
  notify {"action not recognized : oradb_fs::deploy_restart_service : ${home} : ${home_path}":}
 }
}
