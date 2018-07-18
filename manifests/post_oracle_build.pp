define oradb_fs::post_oracle_build(
 $ora_platform  = undef,
)
{
 oradb_fs::full_export_scripts { "Full export scripts RN" :
 } ->
 oradb_fs::sig_file{ "full export signature file" :
  product          => 'Database Full Export',   
  sig_version      => '1.0',
  type             => 'Base Install',
  sig_desc         => 'full export script for all databases',
  sig_file_name    => "ora_db_fullexport_v1.0",
 } 

 oradb_fs::db_maintenance_scripts {"DB maintenance scripts RN" :
  optional_mail_list  => $facts['oradb_fs::optional_mail_list']
 } ->
 oradb_fs::sig_file{ "single instance maintenance signature file" :
  product          => 'DBmaintenance Package',   
  sig_version      => '1.0',
  type             => 'base install',
  sig_desc         => 'DB maintenance scripts for SI databases',
  sig_file_name    => "ora_db_dbmaintSI_v1.0",
 } 

 oradb_fs::bash_profile{ "set up oracle bash_profile" :
  db_name       => $facts['oradb::ora_bash_db_name'],
  db_home       => $facts['oradb::ora_bash_home'],
  ora_owner     => 'oracle',
  ora_group     => 'oinstall',
  ora_platform  => $ora_platform,
  agent_core    => $facts['oradb_fs::agent_core'],
  agent_home    => $facts['oradb_fs::agent_home'],
 }
 exec { "Clean up working direcory":
  command   => "rm -rf /opt/oracle/sw/working_dir/*",
  path      => '/bin',
  logoutput => true,
 }
# tidy {'Clean up working directory.' : 
#  path    => '/opt/oracle/sw/working_dir',
#  recurse => true,
#  rmdirs  => true,
# }
}

