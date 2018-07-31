####
# oradb_fs::build_patched_sw
#  author: Matthew Parker
#
# wrapper to oradb::opatchupgrade and oradb::opatch to patch a newly build Oracle home
#
# variables:
#  String  $home                - home variable set in use (db_#)
#  String  $patch_path          - patch version the Oracle home is supposed to be patched to in Oracle 18c version format (12_2.xx.x, 18.xx.x, ...)
#  String  $home_path           - full path to the Oracle home
#  String  $version             - version of the base install of the Oracle home (12.2.0.1)
#  String  $download_dir_patch  - full path to the location of the unzipped oracle installation files
#
# calls the following manifests:
#  oradb::opatchupgrade              - upgrades the oracle opatch utility
#  oradb::opatch                     - apply patch of the patch component (db, ojvm)
#  oradb_fs::oracle_version_actions  - performs actions against the newly patched Oracle home. intended to fix for anomalies new patches may cause
#  oradb_fs::sig_file                - creation of sig file required from patching an Oracle home
#
####
define oradb_fs::build_patched_sw (
 String  $home                = undef,
 String  $patch_path          = undef,
 String  $home_path           = undef,
 String  $version             = undef,
 String  $download_dir_patch  = undef,
) 
{
 if $patch_path == 'xx.xx.x' or $patch_path =~ /.*\.0\.0/ {
 }
 else {
  
  $short_home_path = split($home_path,'/')[-1]
   
  $patch_path_holding = split($patch_path,'[.]')

  $patch_path_ru = $patch_path_holding[1] + $patch_path_holding[2]
  $patch_path_adjusted = "${patch_path_holding[0]}.${patch_path_ru}.0"
  $patch_path_lookup_db = regsubst($patch_path, '[.]', '_', 'G')
  $patch_path_lookup_other = "${patch_path_holding[0]}_${patch_path_ru}_0"

  $ocmrf = $patch_path_holding[0] ? {
   '11'    => true,
   default => false
  } 

  $db_patch_num_holding = split($facts["oradb_fs::${patch_path_lookup_db}::db_patch_file"],'_')[0]
  $db_patch_num = inline_template( '<%= @db_patch_num_holding[1..-1] %>' )
  $ojvm_patch_num_holding = split($facts["oradb_fs::${patch_path_lookup_other}::ojvm_patch_file"],'_')[0]
  $ojvm_patch_num = inline_template( '<%= @ojvm_patch_num_holding[1..-1] %>' )
 
  oradb::opatchupgrade{ "Opatch_upgrade_new_home:_${home}":
   oracle_home                => $home_path,
   patch_file                 => $facts["oradb_fs::${patch_path_lookup_other}::opatch_file"],
   opversion                  => $facts["oradb_fs::${patch_path_lookup_other}::opatch_ver"],
   user                       => 'oracle',
   group                      => 'dba',
   download_dir               => "/opt/oracle/sw/working_dir/${home}/${patch_path}",
   puppet_download_mnt_point  => "${download_dir_patch}/db/${patch_path_adjusted}/opatch",
  } ->
  oradb::opatch{ "DB patch new home: ${home}":
   ensure                     => 'present',
   oracle_product_home        => $home_path,
   patch_id                   => $db_patch_num,
   patch_file                 => $facts["oradb_fs::${patch_path_lookup_db}::db_patch_file"],
   user                       => 'oracle',
   group                      => 'dba',
   download_dir               => "/opt/oracle/sw/working_dir/${home}/${patch_path}",
   ocmrf                      => $ocmrf,
   puppet_download_mnt_point  => "${download_dir_patch}/db/${patch_path}/db",
   remote_file                => false
  } ->
  oradb_fs::oracle_version_actions { "ocm.rsp file : ${home}" :
   home_path                  => $home_path,
   version                    => $patch_path_holding[0],
   action                     => 'ocm', 
  } ->
  oradb_fs::sig_file{ "DB patch sig file for new home: ${home}" :
   product                    => 'Oracle Database',   
   sig_version                => '1.0',
   type                       => 'quarterly',
   sig_desc                   => "${patch_path} database PSU",
   global_name                => 'NewHome',
   oracle_home                => $home_path,
   sig_file_name              => "db_dbpsu_${patch_path}_NEWswHOME_${short_home_path}",
  } ->
  oradb::opatch{ "OJVM patch new home: ${home}":
   ensure                     => 'present',
   oracle_product_home        => $home_path,
   patch_id                   => $ojvm_patch_num,
   patch_file                 => $facts["oradb_fs::${patch_path_lookup_other}::ojvm_patch_file"],
   user                       => 'oracle',
   group                      => 'dba',
   download_dir               => "/opt/oracle/sw/working_dir/${home}/${patch_path}",
   ocmrf                      => $ocmrf,
   puppet_download_mnt_point  => "${download_dir_patch}/db/${patch_path_adjusted}/ojvm",
   remote_file                => false
  } ->
  oradb_fs::sig_file{ "OJVM patch sig file for new home: ${home}" :
   product                    => 'Oracle Database',   
   sig_version                => '1.0',
   type                       => 'quarterly',
   sig_desc                   => "${patch_path} Java VM PSU",
   global_name                => 'NewHome',
   oracle_home                => $home_path,
   sig_file_name              => "db_jvmpsu_${patch_path}_NEWswHOME_${short_home_path}",
  }
 }
}
