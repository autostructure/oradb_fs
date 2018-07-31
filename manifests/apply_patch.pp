####
# oradb_fs::apply_patch
#  author: Matthew Parker
#
# wrapper to oradb::opatch and oradb::opatchupgrade to patch a multi-database oracle home
#
# variables:
#  String         $home              - home variable set in use (db_#)
#  String         $patch_path        - patch version the Oracle home is supposed to be patched to in Oracle 18c version format (12_2.xx.x, 18.xx.x, ...)
#  String         $home_path         - full path to the Oracle home
#  Array[String]  $db_list           - array of database sids associated to the Oracle home being patched
#  String         $version           - version of the base install of the Oracle home (12.2.0.1)
#  Boolean        $default_detected  - set to true if the db_info_list_db_# array associated to the home being patched contains any default value
#  String         $agent_home        - full path of the em agent home
#
# calls the following manifests:
#  oradb_fs::em_agent_control        - stopping of the em agent
#  oradb::listener                   - start and stop of the listener associated to the home
#  oradb_fs::dbactions_loop          - start and stop of all databases associated to the home
#  oradb::opatchupgrade              - upgrades the oracle opatch utility
#  oradb_fs::oracle_version_actions  - actions to be perfromed against the home as part of patching 
#  oradb::opatch                     - apply patch of the patch component (db, ojvm)
#  oradb_fs::post_patching_tree      - actions to be performed against all databases associated to the home after patching the home
#  oradb_fs::sig_file_loop           - creation of all sig files required from patching
#
####
define oradb_fs::apply_patch (
 String         $home              = undef,
 String         $patch_path        = undef,
 String         $home_path         = undef,
 Array[String]  $db_list           = undef,
 String         $version           = undef,
 Boolean        $default_detected  = undef,
 String         $agent_home        = undef,
)
{

 if !$default_detected {

  if $patch_path == 'xx.xx.x' or $patch_path =~ /.*\.0\.0/ {
  }
  else {
   $found = oradb_fs::oracle_exists( $home_path )

   if $found
   {
    $version_holding = split($version,'[.]')

    $download_dir_patch = $version ? {
     '12.2.0.1'                     => $facts["oradb_fs::patch_source_dir_12_2_0_0"],
     /[0-9][0-9].[0-9]?[0-9].[0-2]/ => $facts["oradb_fs::patch_source_dir_${version_holding[0]}_0_0"],
     default     => 'fail',
    }
 
    if $download_dir_patch != 'fail' {

     $patch_path_holding = split($patch_path,'[.]')

     $patch_path_ru = $patch_path_holding[1] + $patch_path_holding[2]
     $patch_path_adjusted = "${patch_path_holding[0]}.${patch_path_ru}.0"
     $patch_path_lookup_db = regsubst($patch_path, '[.]', '_', 'G')
     $patch_path_lookup_other = "${patch_path_holding[0]}_${patch_path_ru}_0"

     $db_patch_num_holding = split($facts["oradb_fs::${patch_path_lookup_db}::db_patch_file"],'_')[0]
     $db_patch_num = inline_template( '<%= @db_patch_num_holding[1..-1] %>' )
     $ojvm_patch_num_holding = split($facts["oradb_fs::${patch_path_lookup_other}::ojvm_patch_file"],'_')[0]
     $ojvm_patch_num = inline_template( '<%= @ojvm_patch_num_holding[1..-1] %>' )

     $home_patch_list = $facts['home_patch_list']
     $home_patch_list_installed = return_sid_list($home_patch_list, $home, $home_path)

     $patch_check_db   = patch_installed( $db_patch_num, $home_patch_list_installed[0])
     $patch_check_ojvm = patch_installed( $ojvm_patch_num, $home_patch_list_installed[0])

     if ($patch_check_db != $db_patch_num or $patch_check_ojvm != $ojvm_patch_num) {

      $oratab_entries = $facts['home_associated_db_list']
      $ps_entries = $facts['home_associated_running_db_list']
      $delete_entries = $facts['home_associated_delete_db_list']
 
      $oratab_home = return_sid_list($oratab_entries, $home, $home_path)
      $ps_home = return_sid_list($ps_entries, $home, $home_path)
      $db_home = return_sid_list($db_list, $home, $home_path)
 
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
 
        $ocmrf = $version_holding[0] ? {
         '11'    => true,
         default => false
        }
       
        oradb_fs::em_agent_control { "Shutdown emagent : ${home}" : 
         home          => $home,
         action        => 'stop',
         agent_home    => $agent_home,
        } ->
        oradb::listener {"Ensure listener is down before patching: ${home}" :
         oracle_base   => '/opt/oracle',
         oracle_home   => $home_path,
         user          => 'oracle',
         group         => 'dba',
         action        => 'stop',
         listener_name => 'LISTENER',
        } ->
        oradb_fs::dbactions_loop { "Stop all dbs in ${home}" :
         home           => $home,
         db_list        => $db_list,
         action         => 'stop1',
         home_path      => $home_path,
        } ->
        oradb::opatchupgrade{ "Opatch_upgrade_home:${home}:_${sid}":
         oracle_home               => $home_path,
         patch_file                => $facts["oradb_fs::${patch_path_lookup_other}::opatch_file"],
         opversion                 => $facts["oradb_fs::${patch_path_lookup_other}::opatch_ver"],
         user                      => 'oracle',
         group                     => 'dba',
         download_dir              => "/opt/oracle/sw/working_dir/${home}/${patch_path}",
         puppet_download_mnt_point => "${download_dir_patch}/db/${patch_path_adjusted}/opatch",
        } ->
        oradb_fs::oracle_version_actions { "ocm.rsp file : ${home}" :
         home_path        => $home_path,
         version          => $version_holding[0],
         action           => 'ocm',
        } ->
        oradb::opatch{ "DB patch home: ${home}":
         ensure                    => 'present',
         oracle_product_home       => $home_path,
         patch_id                  => $db_patch_num,
         patch_file                => $facts["oradb_fs::${patch_path_lookup_db}::db_patch_file"],
         user                      => 'oracle',
         group                     => 'dba',
         download_dir              => "/opt/oracle/sw/working_dir/${home}/${patch_path}",
         ocmrf                     => $ocmrf,
         puppet_download_mnt_point => "${download_dir_patch}/db/${patch_path}/db",
         remote_file               => false # False to force usable permissioning on unzipped files
        } ->
        oradb::opatch{ "OJVM patch home: ${home}":
         ensure                    => 'present',
         oracle_product_home       => $home_path,
         patch_id                  => $ojvm_patch_num,
         patch_file                => $facts["oradb_fs::${patch_path_lookup_other}::ojvm_patch_file"],
         user                      => 'oracle',
         group                     => 'dba',
         download_dir              => "/opt/oracle/sw/working_dir/${home}/${patch_path}",
         ocmrf                     => $ocmrf,
         puppet_download_mnt_point => "${download_dir_patch}/db/${patch_path_adjusted}/ojvm",
         remote_file               => false
        } ->
        oradb_fs::dbactions_loop { "Startup Upgrade for all dbs in ${home}" :
         home           => $home,
         db_list        => $db_list,
         action         => 'upgrade',
         home_path      => $home_path,
        } ->
        oradb_fs::post_patching_tree { "Post patching : ${home}" :
         home                 => $home,
         home_path            => $home_path,
         db_list              => $db_list,
         db_patch_number      => $db_patch_num,
         ojvm_patch_number    => $ojvm_patch_num,
         short_version        => "${version_holding[0]}.${version_holding[1]}",
         patch_path           => $patch_path,
         ojvm_patch_path      => $patch_path_adjusted,
        } ->
        oradb_fs::dbactions_loop { "Stop all dbs in ${home} after running datapatch" :
         home           => $home,
         db_list        => $db_list,
         action         => 'stop2',
         home_path      => $home_path,
        } ->
        oradb_fs::sig_file_loop { "Create DB patch sig files for ${home} DBs" :
         home             => $home,
         product          => 'Oracle Database',
         sig_version      => '1.0',
         type             => 'quarterly',
         sig_desc         => "${patch_path} database PSU",
         global_name      => $db_list,
         oracle_home      => $home_path,
         sig_file_name    => "db${major_ver}_dbpsu_${patch_path}",
         home_path        => $home_path,
        } ->
        oradb_fs::sig_file_loop { "Create OJVM patch sig files for ${home} DBs" :
         home             => $home,
         product          => 'Oracle Database',
         sig_version      => '1.0',
         type             => 'quarterly',
         sig_desc         => "${patch_path} Java VM PSU",
         global_name      => $db_list,
         oracle_home      => $home_path,
         sig_file_name    => "db${major_ver}_jvmpsu_${patch_path}",
         home_path        => $home_path,
        } ->
        oradb::listener { "Restart listener after patching: ${home}" :
         oracle_base   => '/opt/oracle',
         oracle_home   => $home_path,
         user          => 'oracle',
         group         => 'dba',
         action        => 'start',
         listener_name => 'LISTENER',
        } ->
        oradb_fs::dbactions_loop { "Start all dbs in ${home}" :
         home           => $home,
         db_list        => $db_list,
         action         => 'start',
         home_path      => $home_path,
        }
       }
      }
     }
    }
    else {
     notify {"apply_patch : version input not recognized : ${home}" :}
    }
   }
   else {
    notify {"apply_patch : sw does not exist : skipping : ${home}" :}
   }
  }
 }
 else {
  notify {"apply_patch : default detected : ${home}" :}
 }
}
 
