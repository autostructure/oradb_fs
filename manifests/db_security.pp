####
# oradb_fs::db_security
#  author: Matthew Parker
#
# builds the security package set inside the database indicated and runs the main package to configure the database
#
# variables
#  String  $db_name              - sid of the database the security package set is being deployed against
#  String  $working_dir          - path to the working directory to deploy transient files to
#  String  $home                 - home variable set in use (db_#)
#  String  $home_path            - full path to the Oracle home
#  String  $db_security_options  - security options from the fqdn.yaml file for the database the security package set is being deployed against
#
# deploys:
#  ${working_dir}/fs_db_admin_bootstrap_${db_name}.sql    - transient file
#  ${working_dir}/fs_exists_functions_${db_name}.sql      - transient file
#  ${working_dir}/fs_puppet_format_output_${db_name}.sql  - transient file
#  ${working_dir}/fs_puppet_structures_${db_name}.sql     - transient file
#  ${working_dir}/fs_security_pkg_${db_name}.sql          - transient file
#  ${working_dir}/fs_password_verify_${db_name}.sql       - transient file
#  ${working_dir}/revoke_public_grants_${db_name}.sql     - transient file
#  ${working_dir}/security_compromise_${db_name}.sql      - transient file
#  ${working_dir}/fs_public_grants_update_${db_name}.sql  - transient file
#
####
define oradb_fs::db_security (
 String    $db_name              = undef,
 String    $working_dir          = undef,
 String    $home                 = undef,
 String    $home_path            = undef,
 String    $db_security_options  = undef,
)
{
 $holding = split($db_security_options,'~')
 file { "${working_dir}/fs_db_admin_bootstrap_${db_name}.sql":
  ensure  => 'file',
  owner   => 'oracle',
  group   => 'oinstall',
  mode    => '0644',
  source  => 'puppet:///modules/oradb_fs/security_compromise/fs_db_admin_bootstrap.sql'
 }
 file { "${working_dir}/fs_exists_functions_${db_name}.sql":
  ensure  => 'file',  
  owner   => 'oracle',
  group   => 'oinstall',
  mode    => '0644',
  source  => 'puppet:///modules/oradb_fs/security_compromise/fs_exists_functions.sql'
 }
 file { "${working_dir}/fs_puppet_format_output_${db_name}.sql":
  ensure  => 'file',
  owner   => 'oracle',
  group   => 'oinstall',
  mode    => '0644',
  source  => 'puppet:///modules/oradb_fs/security_compromise/fs_puppet_format_output.sql'
 }
 file { "${working_dir}/fs_puppet_structures_${db_name}.sql":
  ensure  => 'file',
  owner   => 'oracle',
  group   => 'oinstall',
  mode    => '0644',
  source  => 'puppet:///modules/oradb_fs/security_compromise/fs_puppet_structures.sql'
 }
 file { "${working_dir}/fs_security_pkg_${db_name}.sql":
  ensure  => 'file',
  owner   => 'oracle',
  group   => 'oinstall',
  mode    => '0644',
  source  => 'puppet:///modules/oradb_fs/security_compromise/fs_security_pkg.sql'
 }
 file { "${working_dir}/fs_password_verify_${db_name}.sql":
  ensure  => 'file',
  owner   => 'oracle',
  group   => 'oinstall',
  mode    => '0644',
  source  => 'puppet:///modules/oradb_fs/security_compromise/fs_password_verify.sql'
 }
/*
 file { "${working_dir}/revoke_public_grants_${db_name}.sql":
  ensure  => 'file',
  owner   => 'oracle',
  group   => 'oinstall',
  mode    => '0644',
  source  => 'puppet:///modules/oradb_fs/security_compromise/revoke_public_grants.sql'
 }
*/
 file { "${working_dir}/security_compromise_${db_name}.sql":
  ensure   => 'file',
  content  => epp("oradb_fs/security_compromise.sql.epp",
                 { 'dbinstances_objects'  => $holding[0],
                   'gis_roles'            => $holding[1] }),
  owner    => 'oracle',
  group    => 'oinstall',
  mode     => '0644',
 }
 exec {"Create FS_DB_ADMIN if needed : ${home} : ${db_name}":
  command      => "sqlplus /nolog @${working_dir}/fs_db_admin_bootstrap_${db_name}.sql",
  user         => 'oracle',
  path         => "${home_path}/bin",
  environment  => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${db_name}", "LD_LIBRARY_PATH=${home_path}/lib"],
  require      => File["${working_dir}/fs_db_admin_bootstrap_${db_name}.sql"],
  before       => [ Exec["Build fs_puppet_format_output inside DB : ${home} : ${db_name}"], Exec["Build fs_exists_functions inside DB : ${home} : ${db_name}"] ]
 }
 exec {"Build fs_exists_functions inside DB : ${home} : ${db_name}":
  command      => "sqlplus /nolog @${working_dir}/fs_exists_functions_${db_name}.sql",
  user         => 'oracle',
  path         => "${home_path}/bin",
  environment  => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${db_name}", "LD_LIBRARY_PATH=${home_path}/lib"],
  require      => File["${working_dir}/fs_exists_functions_${db_name}.sql"],
  before       => [ Exec["Build fs_puppet_structures inside DB : ${home} : ${db_name}"], Exec["Build fs_security_pkg inside DB : ${home} : ${db_name}"], Exec["Build fs_password_verify inside DB : ${home} : ${db_name}"] ]
 }
 exec {"Build fs_puppet_format_output inside DB : ${home} : ${db_name}":
  command      => "sqlplus /nolog @${working_dir}/fs_puppet_format_output_${db_name}.sql",
  user         => 'oracle',
  path         => "${home_path}/bin",
  environment  => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${db_name}", "LD_LIBRARY_PATH=${home_path}/lib"],
  require      => File["${working_dir}/fs_puppet_format_output_${db_name}.sql"],
  before       => [ Exec["Build fs_puppet_structures inside DB : ${home} : ${db_name}"], Exec["Build fs_security_pkg inside DB : ${home} : ${db_name}"], Exec["Build fs_password_verify inside DB : ${home} : ${db_name}"] ]
 }
 exec {"Build fs_puppet_structures inside DB : ${home} : ${db_name}":
  command    => "sqlplus /nolog @${working_dir}/fs_puppet_structures_${db_name}.sql",
  user         => 'oracle',
  path         => "${home_path}/bin",
  environment  => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${db_name}", "LD_LIBRARY_PATH=${home_path}/lib"],
  require      => File["${working_dir}/fs_puppet_structures_${db_name}.sql"]
 }
 exec {"Build fs_security_pkg inside DB : ${home} : ${db_name}":
  command      => "sqlplus /nolog @${working_dir}/fs_security_pkg_${db_name}.sql",
  user         => 'oracle',
  path         => "${home_path}/bin",
  environment  => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${db_name}", "LD_LIBRARY_PATH=${home_path}/lib"],
  require      => File["${working_dir}/fs_security_pkg_${db_name}.sql"]
 }
 exec {"Build fs_password_verify inside DB : ${home} : ${db_name}":
  command      => "sqlplus /nolog @${working_dir}/fs_password_verify_${db_name}.sql",
  user         => 'oracle',
  path         => "${home_path}/bin",
  environment  => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${db_name}", "LD_LIBRARY_PATH=${home_path}/lib"],
  require      => File["${working_dir}/fs_password_verify_${db_name}.sql"],
 }
/*
 exec {"Build revoke_public_grants inside DB : ${home} : ${db_name}":
  command      => "sqlplus /nolog @${working_dir}/revoke_public_grants_${db_name}.sql",
  user         => 'oracle',
  path         => "${home_path}/bin",
  environment  => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${db_name}", "LD_LIBRARY_PATH=${home_path}/lib"],
  require      => File["${working_dir}/revoke_public_grants_${db_name}.sql"]
 }
*/

 if $holding[0] in [ 't', 'f' ] {
  if $holding[1] in [ 't', 'f' ] {
   exec {"Run security_compromise against DB : ${home} : ${db_name}":
    command      => "sqlplus /nolog @${working_dir}/security_compromise_${db_name}.sql",
    user         => 'oracle',
    path         => "${home_path}/bin",
    environment  => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${db_name}", "LD_LIBRARY_PATH=${home_path}/lib"],
    require      => [ File["${working_dir}/security_compromise_${db_name}.sql"], Exec["Build fs_exists_functions inside DB : ${home} : ${db_name}"], Exec["Build fs_puppet_format_output inside DB : ${home} : ${db_name}"], Exec["Build fs_puppet_structures inside DB : ${home} : ${db_name}"], Exec["Build fs_security_pkg inside DB : ${home} : ${db_name}"], Exec["Build fs_password_verify inside DB : ${home} : ${db_name}"] ]
   }
  }
  else {
   notify { "Security options for SID not recognized. Update FQDN.yaml file and run remediation for SID : ${home} : ${db_name} : position 1 - ${holding[0]}" :
    loglevel => 'err'
   }
  }
 }
 else {
  notify { "Security options for SID not recognized. Update FQDN.yaml file and run remediation for SID : ${home} : ${db_name} : position 2 - ${holding[1]}" :
   loglevel => 'err'
  }
 }
}

