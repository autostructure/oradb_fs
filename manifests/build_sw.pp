####
# oradb_fs::build_sw
#  author: Matthew Parker
#
# wrapper to oradb::installdb to build a new Oracle home
#
# variables:
#  String  $home           - home variable set in use (db_#)
#  String  $version        - version of the base install of the Oracle home (12.2.0.1)
#  String  $database_type  - edition of the Oracle software being installed (ee, se)
#  String  $home_path      - full path to the Oracle home
#  String  $patch_path     - patch version the Oracle home is supposed to be patched to in
#                            Oracle 18c version format (12_2.xx.x, 18.xx.x, ...)
#
# calls the following manifests:
#  oradb::installdb                  - creates a new Oracle home
#  oradb::listener                   - start and stop of the listener associated to the home
#  oradb_fs::listener                - creates listener.ora file
#  oradb_fs::build_patched_sw        - patches a newly built Oracle home
#  oradb_fs::oracle_version_actions  - actions to be perfromed against the home based on version. largely a hold
#                                      over from 11g, but still may be needed
#  oradb_fs::deploy_restart_service  - deploy restart service associated to the new home
#  oradb_fs::sig_file                - creation of sig file required from creating a new Oracle home
#
# deploys:
#  ${home_path}/network/admin/sqlnet.ora
#  ${home_path}/network/admin/ldap.ora
#
# modifies:
#  oracle binaries (chopt disable partitioning, ${home_path}/bin/relink)
#
####
define oradb_fs::build_sw (
 String  $home           = undef,
 String  $version        = undef,
 String  $database_type  = $facts['oradb_fs::database_type_ee'],
 String  $home_path      = undef,
 String  $patch_path     = undef,
)
{

 #This is a straight copy over from the Biemond-OraDB as it perfroms the needed functionality already.
 #This includes various ruby code under the lib directory.
 $found = oradb_fs::oracle_exists( $home_path )

 $short_home_path = split($home_path,'/')[-1]

 $version_holding = split($version,'[.]')

 $download_dir_sw = $version ? {
  '12.2.0.1'                      => $facts["oradb_fs::ora_sw_dir_path_12_2_0_0"],
  /[0-9][0-9].[0-9]?[0-9].[0-2]/  => $facts["oradb_fs::ora_sw_dir_path_${version_holding[0]}_0_0"],
  default                         => 'fail',
 }

 $download_dir_patch = $version ? {
  '12.2.0.1'                      => $facts["oradb_fs::patch_source_dir_12_2_0_0"],
  /[0-9][0-9].[0-9]?[0-9].[0-2]/  => $facts["oradb_fs::patch_source_dir_${version_holding[0]}_0_0"],
  default                         => 'fail',
 }

 if $download_dir_sw != 'fail' {
  if $found == false {
   file { "${home_path}" :
    ensure   => 'directory',
    owner    => 'oracle',
    group    => 'oinstall',
    mode     => '0775',
   } ->
   file { "${home_path}/ops-perms" :
    ensure => 'absent',
   } ->
   oradb::installdb{ "${home}_home_install" :
    version                => $version,
    file                   => 'install',
    database_type          => $database_type,
    oracle_base            => '/opt/oracle',
    oracle_home            => $home_path,
    bash_profile           => false,
    user                   => 'oracle',
    group                  => 'dba',
    group_install          => 'oinstall',
    group_oper             => 'oper',
    group_backup           => 'dba',
    group_dg               => 'dba',
    group_km               => 'dba',
    group_rac              => 'dba',
    download_dir           => $download_dir_sw,
    zip_extract            => false,
    cleanup_install_files  => false 
   } ->
   oradb::listener {"Shut down listener before building listener.ora: ${home}" :
    oracle_base    => '/opt/oracle',
    oracle_home    => $home_path,
    user           => 'oracle',
    group          => 'dba',
    action         => 'stop',
    listener_name  => 'LISTENER',
   } ->
   oradb_fs::listener{"Create listener.ora for LISTENER in new home: ${home}" :
    home_path  => $home_path,
    db_port    => $facts["oradb::db_port_${home}"],
   } -> 
   oradb_fs::build_patched_sw { "Patch new home if necessary: ${home}" :
    home                => $home,
    patch_path          => $patch_path,
    home_path           => $home_path,
    version             => $version,
    download_dir_patch  => $download_dir_patch, 
   } ->
   exec {"Disable partitioning for home: ${home}":
     command  => "${home_path}/bin/chopt disable partitioning",
     user     => 'oracle',
   } ->
   oradb_fs::oracle_version_actions { "Fix ins_emagent.mk file : ${home}" :
    home_path  => $home_path,
    version    => $version_holding[0],
    action     => 'mk',
   } ->
   exec {"Relink all for home: ${home}":
    command      => "relink >> /tmp/relink.out",
    user         => 'oracle',
    path         => "${home_path}/bin",
    environment  => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "LD_LIBRARY_PATH=${home_path}/lib:/usr/lib"]
   } ->
   file { "${home_path}/network/admin/sqlnet.ora" :
    ensure   => present,
    content  => epp("oradb_fs/sqlnet.ora.epp",
                  { 'fqdn'       => $facts['networking']['fqdn'],
                    'home_path'  => $home_path}),
    mode     => '0744',
    owner    => oracle,
    group    => oinstall,
   } ->
   file { "${home_path}/network/admin/ldap.ora" :
    ensure  => present,
    source  => 'puppet:///modules/oradb_fs/ldap.ora',
    mode    => '0744',
    owner   => 'oracle',
    group   => 'oinstall',
   } ->
   file { "${home_path}/network/admin/krb5.conf" :
    ensure         => 'file',
    source         => 'puppet:///modules/oradb_fs/os_files/krb5_r7.conf',
    owner          => 'oracle',
    group          => 'oinstall',
    mode           => '0744',
   } ->
   oradb::listener { "Start listener after patching new home: ${home}":
    oracle_base    => '/opt/oracle',
    oracle_home    => $home_path,
    user           => 'oracle',
    group          => 'dba',
    action         => 'start',
    listener_name  => 'LISTENER',
   } ->
   oradb_fs::deploy_restart_service { "Deploy restart service for new home : ${home}":
    home        => $home,
    home_path   => $home_path,
    action      => 'deploy',
   }
   oradb_fs::sig_file{ "SI SW Signature file: ${home}" :
    product        => 'Oracle Database' ,
    sig_version    => "${version}",
    type           => 'Base Install',
    sig_desc       => '12c DB Single Instance Software Install',
    oracle_home    => $home_path,
    sig_file_name  => "ora_db_SI_Install_${short_home_path}",
   } 
  }
  else {
   notify {"Build:${home}:no":}
  }
 }
 else {
  notify {"Version input not recognized. SW home not built : ${home}" :}
 }
}
    
