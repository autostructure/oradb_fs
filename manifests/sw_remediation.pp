####
# oradb_fs::sw_remediation
#  author: Matthew Parker
#
# performs remediation tasks against a single database
#
# variables:
#  String         $home              - home variable set in use (db_#)
#  String         $home_path         - full path of the em agent home
#  Array[String]  $db_list           - flat fact array of information required to build a new database(s) using this module 
#
####
define oradb_fs::sw_remediation (
 String         $home              = undef,
 String         $home_path         = undef,
 String         $patch_path        = undef,
 Array[String]  $db_list           = undef,
)
{
 if $patch_path != 'xx.xx.x' {
  $remediation_fact = $facts['home_remediation_list']
  if $remediation_fact == [ '' ] {
   notify { "No remediation for home : ${home}" : }
  }
  else {
   $home_action_list = return_sid_list($remediation_fact, $home, $home_path)

   $oratab_entries = $facts['home_associated_db_list']
   $oratab_home = return_sid_list($oratab_entries, $home, $home_path)
   $db_home = return_sid_list($db_list, $home, $home_path)

   $ps_entries = $facts['home_associated_running_db_list']
   $ps_home = return_sid_list($ps_entries, $home, $home_path)

   $db_list_in_oratab = compare_arrays($oratab_home, $db_home)
   $db_list_in_running_ps = compare_arrays($ps_home, $db_home)

   if $db_list_in_oratab == 'B' or $db_list_in_oratab == 'C' {
   }
   elsif $db_list_in_oratab == 'S' or $db_list_in_oratab == 'P' or $db_list_in_oratab == 'F' {
    notify{"Oratab does not contain the complete yaml db list for home: ${home}" :}
   }
   else { #elsif $db_list_in_oratab = 'T' {
    if $db_list_in_running_ps == 'B' or $db_list_in_running_ps == 'C' {
    }
    elsif $db_list_in_running_ps == 'S' or $db_list_in_running_ps == 'P' or $db_list_in_running_ps == 'F' {
     notify{"Ps -ef does not contain the complete yaml db list  for home: ${home}" :}
    }
    else { #elsif $db_list_in_running_ps == 'T' {

     $home_action_list.each | String $home_action | {

      if $home_action == 'partitioning' or $home_action == 'all' {
       oradb::listener { "Ensure listener is down before starting home remediation: ${home}" :
        oracle_base   => '/opt/oracle',
        oracle_home   => $home_path,
        user          => 'oracle',
        group         => 'dba',
        action        => 'stop',
        listener_name => 'LISTENER',
       } ->
       oradb_fs::dbactions_loop { "Stop all dbs in home prior to home remediation : ${home}" :
        home           => $home,
        db_list        => $db_list,
        action         => 'stop1',
        home_path      => $home_path,
       } ->
       exec { "Disable partitioning for home: ${home}":
        command  => "${home_path}/bin/chopt disable partitioning",
        user     => 'oracle',
       } ->
       exec { "Relink all for home: ${home}":
        command      => "relink >> /tmp/relink.out",
        user         => 'oracle',
        path         => "${home_path}/bin",
        environment  => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "LD_LIBRARY_PATH=${home_path}/lib:/usr/lib"]
       } ->
       oradb_fs::dbactions_loop { "Start all dbs in home after home remediation : ${home}" :
        home           => $home,
        db_list        => $db_list,
        action         => 'start1',
        home_path      => $home_path,
       } ->
       oradb::listener { "Ensure listener is up after home remediation: ${home}" :
        oracle_base   => '/opt/oracle',
        oracle_home   => $home_path,
        user          => 'oracle',
        group         => 'dba',
        action        => 'start',
        listener_name => 'LISTENER',
       }
      }
      if $home_action == 'none' {
       notify { "Incorrect input for /tmp touch file of home requested for remediation. Home skipped : ${home} " :
        loglevel => 'err'
       }
      }
     }
    }
   }
  }
 }
 else {
  notify{ "Patch path is set to 'xx.xx.x' : remediation skipped : sw_remediation : ${home}" : }
 }
}

