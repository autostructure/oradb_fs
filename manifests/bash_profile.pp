####
# oradb_fs::bash_profile
#  author: Matthew Parker
#
# deploys a .bash_profile for the Oracle user based on the value of $ora_platform
#
# variables
#  String  $db_name       - value to set ORACLE_SID to in the .bash_profile
#  String  $db_home       - value to set ORACLE_HOME to in the .bash_profile
#  String  $ora_platform  - value of the ora_platform variable from the fqdn.yaml deployed from artifactory
#  String  $agent_core    - value to set AGENT_CORE to in the .bash_profile
#  String  $agent_home    - value to set AGENT_HOME to in the .bash_profile
#
# deploys:
#  /home/oracle/.bash_profile
#
####
define oradb_fs::bash_profile (
 String  $db_name       = undef,
 String  $db_home       = undef,
 String  $ora_platform  = undef,
 String  $agent_core    = undef,
 String  $agent_home    = undef,
)
{
 if $ora_platform == 'db' {
  $holding = split($facts['networking']['fqdn'],'[.]')
  $rman_schema = "rcat_${holding[1]}_${holding[0]}"

  if $agent_core == '' {
   file { '/home/oracle/.bash_profile':
    ensure  => present,
    content => epp('oradb_fs/db_12c_bash_profile.epp',
                  { 'db_name'    => $db_name,
                    'db_home'    => $db_home,
                    'agent_home' => $agent_home,
                    'rman_schema' => $rman_schema}),
    mode    => '0755',
    owner   => 'oracle',
    group   => 'oinstall',
    backup  => ".${facts['the_date']}",
   }
  }
  else {
   file { '/home/oracle/.bash_profile':
    ensure  => present,
    content => epp('oradb_fs/db_13c_bash_profile.epp',
                  { 'db_name'     => $db_name,
                    'db_home'     => $db_home,
                    'agent_core'  => $agent_core,
                    'agent_home'  => $agent_home,
                    'rman_schema' => $rman_schema}),
    mode    => '0755',
    owner   => 'oracle',
    group   => 'oinstall',
    backup  => ".${facts['the_date']}",
   }
  }
 }
 elsif $ora_platform == 'oem' {
  file { '/home/oracle/.bash_profile':
   ensure => present,
   source => 'puppet:///modules/oradb_fs/oem_bash_profile',
   mode   => '0755',
   owner  => 'oracle',
   group  => 'oinstall',
   backup => ".${facts['the_date']}",
  }
 }
}

