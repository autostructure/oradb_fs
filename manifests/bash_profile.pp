define oradb_fs::bash_profile (
 String     $db_name       = undef,
 String     $db_home       = undef,
 String     $ora_owner     = undef,
 String     $ora_group     = undef,
 String     $ora_platform  = undef, 
 String     $agent_core    = undef,
 String     $agent_home    = undef,
)
{
 if $ora_platform == 'db' {
  if $agent_core == '' {
   file { "/home/oracle/.bash_profile":
    ensure  => present,
    content => epp("oradb_fs/db_12c_bash_profile.epp",
                  { 'db_name'             => $db_name,
                    'db_home'             => $db_home,
                    'agent_home'          => $agent_home}),
    mode    => '0755',
    owner   => $ora_owner,
    group   => $ora_group,
    backup  => ".${facts['the_date']}",
   }
  }
  else {
   file { "/home/oracle/.bash_profile":
    ensure  => present,
    content => epp("oradb_fs/db_13c_bash_profile.epp",
                  { 'db_name'             => $db_name,
                    'db_home'             => $db_home,
                    'agent_core'          => $agent_core,
                    'agent_home'          => $agent_home}),
    mode    => '0755',
    owner   => $ora_owner,
    group   => $ora_group,
    backup  => ".${facts['the_date']}",
   }
  } 
 }
 elsif $ora_platform == 'oem' {
  file { "/home/oracle/.bash_profile":
   ensure  => present,
   source  => "puppet:///modules/oradb_fs/oem_bash_profile",
   mode    => '0755',
   owner   => $ora_owner,
   group   => $ora_group,
   backup  => ".${facts['the_date']}",
  }
 }
}

