####
# oradb_fs::configure_rman_repo
#  author: Matthew Parker
#
# Creates users in the RMAN repo database to host RMAN catalog information
#
# variables
#  String         $home         - home variable set in use (db_#)
#  String         $home_path    - full path to the Oracle home
#  Array[String]  $db_info_list - flat fact array of database information
#  String         $sid          - array from the rman_repo_setup_list fact
#
# inside REPO DB
#  creates fs_service_acct profile
#  creates a repo user for each entry in the oradb_fs::rman_schemas fact from the artifactory yaml file
#   Usename is in the format 'rcat_[WORK_AREA]_[HOSTNAME]'
#   I.e An FQDN of fsxopsx0946.wrk.fs.usda.gov becomes rcat_wrk_fsxopsx0946
#  grants new user profile/rights to host the RMAN catalog for a given server FQDN
#
####
define oradb_fs::configure_rman_repo (
 String         $home         = undef,
 String         $home_path    = undef,
 Array[String]  $db_info_list = undef,
 String         $sid          = undef,
)
{

 $oratab_home = return_sid_list($facts['home_associated_db_list'], $home, $home_path)
 $ps_home = return_sid_list($facts['home_associated_running_db_list'], $home, $home_path)
 $db_home = return_sid_list($db_info_list, $home, $home_path)

 $sid_in_yaml = compare_arrays($db_home, any2array($sid))
 $sid_in_oratab = compare_arrays($oratab_home, any2array($sid))
 $sid_in_running_ps = compare_arrays($ps_home, any2array($sid))

 if $sid_in_yaml == 'B' or $sid_in_yaml == 'C' {
 }
 elsif $sid_in_yaml == 'S' or $sid_in_yaml == 'F' {
  notify{"ora_db_info_list does not contain the complete sid list requested for RMAN repo setup: ${home}" :
   loglevel => 'err'
  }
 }
 else { #elsif $sid_in_yaml == 'T' or $sid_in_yaml == 'P' {
  if $sid_in_oratab == 'B' or $sid_in_oratab == 'C' {
  }
  elsif $sid_in_oratab == 'S' or $sid_in_oratab == 'F' {
   notify{"/etc/oratab does not contain the complete sid list requested for RMAN repo setup: ${home}" :
    loglevel => 'err'
   }
  }
  else { #elsif $sid_in_oratab == 'T' or $sid_in_oratab == 'P' {
   if $sid_in_running_ps == 'B' or $sid_in_running_ps == 'C' {
   }
   elsif $sid_in_running_ps == 'S' or $sid_in_running_ps == 'F' {
    notify{"Ps -ef does not contain the complete sid list requested for RMAN repo setup: ${home}" :
     loglevel => 'err'
    }
   }
   else { #elsif $sid_in_running_ps == 'T' or $sid_in_running_ps == 'P' {

    $rman_schemas = $facts['oradb_fs::rman_schemas'] ? {
     undef => [ '' ],
     default => $facts['oradb_fs::rman_schemas']
    }
 
    if $rman_schemas != [ '' ] {
     file { "/opt/oracle/sw/working_dir/${home}/fs_service_acct_${sid}.sql" :
      ensure => 'present',
      owner  => 'oracle',
      group  => 'oinstall',
      mode   => '0644',
      source => 'puppet:///modules/oradb_fs/rman/fs_service_acct.sql'
     }
     -> exec { "Create fs_service_acct profile: ${home} : ${sid}":
      command     => "sqlplus /nolog @/opt/oracle/sw/working_dir/${home}/fs_service_acct_${sid}.sql",
      user        => 'oracle',
      path        => "${home_path}/bin",
      environment => [ 'ORACLE_BASE=/opt/oracle', "ORACLE_HOME=${home_path}", "ORACLE_SID=${sid}", "LD_LIBRARY_PATH=${home_path}/lib"]
     }

     $rman_schemas.each | String $hostname_f | {
      $holding = split($hostname_f,'[.]')
      $schema = "rcat_${holding[1]}_${holding[0]}"
 
      $input = return_simple($facts['oradb_fs::sample_value'])
  
      file { "/opt/oracle/sw/working_dir/${home}/new_schema_${sid}-${schema}.sql" :
       ensure    => 'present',
       content => epp('oradb_fs/new_schema.sql.epp',
                     { 'user'  => $schema, 
                       'input' => $input}),
       owner     => 'oracle',
       group     => 'oinstall',
       mode      => '0644',
       show_diff => 'false'
      }
      -> exec { "Create new schema : ${home} : ${sid} : ${schema}":
       command     => "sqlplus /nolog @/opt/oracle/sw/working_dir/${home}/new_schema_${sid}-${schema}.sql",
       user        => 'oracle',
       path        => "${home_path}/bin",
       environment => [ 'ORACLE_BASE=/opt/oracle', "ORACLE_HOME=${home_path}", "ORACLE_SID=${sid}", "LD_LIBRARY_PATH=${home_path}/lib"],
       require     => Exec["Create fs_service_acct profile: ${home} : ${sid}"]
      }
   
      file { "/opt/oracle/sw/working_dir/${home}/create_catalog_objects_${sid}-${schema}.rmn" :
       ensure => 'present',
       owner  => 'oracle',
       group  => 'oinstall',
       mode   => '0644',
       source => 'puppet:///modules/oradb_fs/rman/create_catalog_objects.rmn'
      }
      -> exec { "Create catalog objects for new schema : ${home} : ${sid} : ${schema}" :
       command     => "/bin/echo ${input} | ${home_path}/bin/rman catalog ${schema} cmdfile=/opt/oracle/sw/working_dir/${home}/create_catalog_objects_${sid}-${schema}.rmn",
       user        => 'oracle',
       environment => [ 'ORACLE_BASE=/opt/oracle', "ORACLE_HOME=${home_path}", "ORACLE_SID=${sid}", "LD_LIBRARY_PATH=${home_path}/lib"],
       require     => Exec["Create new schema : ${home} : ${sid} : ${schema}"]
      }
     }
    }
   }
  }
 }
}

