####
# oradb_fs::post_rollback_tree
#  author: Matthew Parker
#
# runs post rollback scripts against all databases associated to the home being worked on after roll back a patch in the home
#
# variables:
#  String         $home               - home variable set in use (db_#)
#  String         $home_path          - full path to the Oracle home
#  Array[String]  $db_list            - flat fact array of information required to build a new database(s) using this module
#  String         $db_patch_number    - not in use. to be depricated
#  String         $ojvm_patch_number  - not in use. to be depricated
#  String         $short_version      - major minor version of the Oracle home (12.2)
#  String         $type               - component name being rolled back (db, ojvm)
#  String         $patch_path         - patch version the Oracle home is supposed to be patched to in Oracle 18c version format (12_2.xx.x, 18.xx.x, ...)
#
# deploys:
#  /opt/oracle/sw/working_dir/${home}/post_${type}_rollback_utlrp_${holding[0]}.sql - transient file
#
####
define oradb_fs::post_rollback_tree (
 String         $home               = undef,
 String         $home_path          = undef,
 Array[String]  $db_list            = undef, 
 String         $db_patch_number    = undef,
 String         $ojvm_patch_number  = undef,
 String         $short_version      = undef,
 String         $type               = undef,
 String         $patch_path         = undef,
)
{
 $db_list.each | String $db_name | {
  $holding = $db_name.split(':')

  file { "/opt/oracle/sw/working_dir/${home}/post_${type}_rollback_utlrp_${holding[0]}.sql" :
   ensure  => present,
   content => epp("oradb_fs/run_utlrp.sql.epp",
               { 'home_path'             => $home_path,
               }),
   mode    => '0755',
   owner   => 'oracle',
   group   => 'dba',
  }

  if $short_version == '12.2' {
   exec { "Run datapatch after rollback: ${home} : ${holding[0]} : ${type}":
    command     => "datapatch -verbose",
    user        => 'oracle',
    path        => "${home_path}/OPatch",
    environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${holding[0]}", "LD_LIBRARY_PATH=${home_path}/lib"]
   }
  }
  else {
   fail('Short version not recognized : post_rollback_tree')
  }
  exec {"UTLRP post ${type} rollback precautionary run: ${home} : ${holding[0]}":
   command => "sqlplus /nolog @/opt/oracle/sw/working_dir/${home}/post_rollback_utlrp_${holding[0]}.sql",
   user    => 'oracle',
   path    => "${home_path}/bin",
   environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${holding[0]}", "LD_LIBRARY_PATH=${home_path}/lib"]
  }
 }
}
