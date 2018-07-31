####
# oradb_fs::psu_rollback
#  author: Matthew Parker
#
# wrapper to oradb::opatch to rollback patches
#
# variables:
#  String         $home              - home variable set in use (db_#)
#  String         $home_path         - full path to the Oracle home
#  Array[String]  $db_list           - flat fact array of information required to build a new database(s) using this module 
#  String         $version           - version of the base install of the Oracle home (12.2.0.1)
#  Array[String]  $patch_path_array  - flat fact array of homes and patches to roll back
#  Boolean        $default_detected  - set to true if the db_info_list_db_# array associated to the home being patched contains any default value
#  String         $agent_home        - full path of the em agent home
#
# calls the following manifests:
#  oradb_fs::em_agent_control    - starts and stops the em agent
#  oradb::listener               - starts and stop the listener associated to the home
#  oradb_fs::dbactions_loop      - starts and stop all databases associated to the home
#  oradb::opatch                 - rolls back patch components in the home
#  oradb_fs::post_rollback_tree  - post actions to be perfromed against databases associated to the home
#
# removes:
#  /opt/oracle/signatures/${local_file_name}                              - regex matched sig file names associated to the patch being removed rolled back
#  /fslink/sysinfra/signatures/oracle/${host_name}/${sysinfra_file_name}  - regex matched sig file names associated to the patch being removed rolled back
#
####
define oradb_fs::psu_rollback (
 String            $home                = undef,
 String            $home_path           = undef,
 Array[String]     $db_list             = undef,
 String            $version             = undef,
 Array[String]     $patch_path_array    = undef, 
 Boolean           $default_detected    = undef,
 String            $agent_home          = undef,
)
{
 if !$default_detected {
  if size($patch_path_array) > 1 {
   notify{"Patch path array has too many inputs. Too many /tmp files exist for psu_rollback. Rollback skipped for ${home}." :}
  }
  else { 
   $oratab_entries = $facts['home_associated_db_list']
   $delete_entries = $facts['home_associated_delete_db_list']
  
   $oratab_home = return_sid_list($oratab_entries, $home, $home_path)
   $db_home = return_sid_list($db_list, $home, $home_path)
   $delete_db_list_home = return_sid_list($delete_entries, $home, $home_path)
  
   $db_list_in_oratab = compare_arrays($oratab_home, $db_home)
   $db_list_in_delete = compare_arrays($delete_db_list_home, $db_home)

   $download_dir_patch = $version ? {
    '12.2.0.1'                     => $facts["oradb_fs::patch_source_dir_12_2_0_0"],
    /[0-9][0-9].[0-9]?[0-9].[0-2]/ => $facts["oradb_fs::patch_source_dir_${version_holding[0]}_0_0"],
    default     => 'fail',
   }
  
   if $download_dir_patch != 'fail' {
    if $db_list_in_oratab == 'B' or $db_list_in_oratab == 'C' {
    }
    elsif $db_list_in_oratab == 'S' or $db_list_in_oratab == 'P' or $db_list_in_oratab == 'F' {
     fail("Oratab does not contain the complete yaml db list for home: ${home}")
    }
    else { #elsif $db_list_in_oratab = 'T' {
     if $db_list_in_delete == 'B' or $db_list_in_delete == 'C' {
     }
     elsif $db_list_in_delete == 'T' or $db_list_in_delete == 'P' {
      fail("Delete list fully or partially contains yaml file db list for home: ${home}")
      }
     else { #elsif $db_list_in_delete == 'S' or $db_list_in_delete == 'F'{

      $patch_path = $patch_path_array[0]     

      $version_holding = split($version,'[.]')

      $patch_path_holding = split($patch_path,'[.]')

      $patch_path_ru = $patch_path_holding[1] + $patch_path_holding[2]
      $patch_path_adjusted = "${patch_path_holding[0]}.${patch_path_ru}.0"
      $patch_path_lookup_db = regsubst($patch_path, '[.]', '_', 'G')
      $patch_path_lookup_other = "${patch_path_holding[0]}_${patch_path_ru}_0"
  
      $db_patch_num_holding = split($facts["oradb_fs::${patch_path_lookup_db}::db_patch_file"],'_')[0]
      $db_patch_num = inline_template( '<%= @db_patch_num_holding[1..-1] %>' )
      $ojvm_patch_num_holding = split($facts["oradb_fs::${patch_path_lookup_other}::ojvm_patch_file"],'_')[0]
      $ojvm_patch_num = inline_template( '<%= @ojvm_patch_num_holding[1..-1] %>' )
   
      oradb_fs::em_agent_control { "Shutdown emagent : ${home}" :
       home          => $home,
       action        => 'stop',
       agent_home    => $agent_home,
      } ->
      oradb::listener {"Ensure listener is down before rollback: ${home}" :
       oracle_base   => '/opt/oracle',
       oracle_home   => $home_path,
       user          => 'oracle',
       group         => 'dba',
       action        => 'stop',
       listener_name => 'LISTENER',
      } ->
      oradb_fs::dbactions_loop { "Stop all dbs prior to rollback in ${home}" :
       home           => $home,
       db_list        => $db_list,
       action         => 'stop3',
       home_path      => $home_path,
      } ->
      oradb::opatch { "Rollback ojvm patch ${patch_path} for home : ${home}" :
       ensure                      => 'absent',
       oracle_product_home         => $home_path,
       patch_id                    => $ojvm_patch_num,
       patch_file                  => $facts["oradb_fs::${patch_path_lookup_other}::ojvm_patch_file"],
       user                        => 'oracle',
       group                       => 'oinstall',
       download_dir                =>  "/opt/oracle/sw/working_dir/${home}",
       ocmrf                       => $ocmrf,
       puppet_download_mnt_point   => "${download_dir_patch}/db/${patch_path_lookup_other}/ojvm",
       remote_file                 => false,
      } ->
      oradb_fs::dbactions_loop { "Startup Upgrade for all dbs for ojvm rollback: ${home}" :
       home           => $home,
       db_list        => $db_list,
       action         => 'upgrade2',
       home_path      => $home_path,
      } ->
      oradb_fs::post_rollback_tree { "Post home ojvm rollback : ${home}" :
       home                 => $home,
       home_path            => $home_path,
       db_list              => $db_list,
       db_patch_number      => $db_patch_num,
       ojvm_patch_number    => $ojvm_patch_num,
       short_version        => "${version_holding[0]}.${version_holding[1]}",
       type                 => 'ojvm',
       patch_path           => $patch_path,
      } ->
      oradb_fs::dbactions_loop { "Stop all dbs in home after running ojvm rollback: ${home}" :
       home           => $home,
       db_list        => $db_list,
       action         => 'stop4',
       home_path      => $home_path,
      } ->
      oradb::opatch { "Rollback db patch ${patch_path} for home : ${home}" :
       ensure                      => 'absent',
       oracle_product_home         => $home_path,
       patch_id                    => $db_patch_num,
       patch_file                  => $facts["oradb_fs::${patch_path_lookup_db}::db_patch_file"],
       user                        => 'oracle',
       group                       => 'oinstall',
       download_dir                =>  "/opt/oracle/sw/working_dir/${home}",
       ocmrf                       => $ocmrf,
       puppet_download_mnt_point   => "${download_dir_patch}/db/${patch_path_lookup_db}/db",
       remote_file                 => false,
      } ->
      oradb_fs::dbactions_loop { "Startup Upgrade for all dbs for db rollback: ${home}" :
       home           => $home,
       db_list        => $db_list,
       action         => 'upgrade3',
       home_path      => $home_path,
      } ->
      oradb_fs::post_rollback_tree { "Post home db rollback : ${home}" :
       home                 => $home,
       home_path            => $home_path,
       db_list              => $db_list,
       db_patch_number      => $db_patch_num,
       ojvm_patch_number    => $ojvm_patch_num,
       short_version        => "${version_holding[0]}.${version_holding[1]}",
       type                 => 'db',
       patch_path           => $patch_path,
      } ->
      oradb_fs::dbactions_loop { "Stop all dbs in home after running db rollback: ${home}" :
       home           => $home,
       db_list        => $db_list,
       action         => 'stop5',
       home_path      => $home_path,
      } ->
/*
      oradb_fs::oracle_version_actions { "Fix ins_emagent.mk file after rollback: ${home}" :
       home_path        => $home_path,
       version          => $version_holding[0],
       action           => 'mk',
      } ->
      exec {"Relink all after rollback and fixing ins_emagent.mk for home: ${home}":
        command => "relink >> /tmp/relink.out",
        user    => 'oracle',
        path    => "${home_path}/bin",
        environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "LD_LIBRARY_PATH=${home_path}/lib:/usr/lib"]
      } ->
*/
      oradb::listener { "Restart listener after psu rollback: ${home}" :
       oracle_base   => '/opt/oracle',
       oracle_home   => $home_path,
       user          => 'oracle',
       group         => 'dba',
       action        => 'start',
       listener_name => 'LISTENER',
      } ->
      oradb_fs::dbactions_loop { "Start all dbs in home after rollback: ${home}" :
       home           => $home,
       db_list        => $db_list,
       action         => 'start2',
       home_path      => $home_path,
      }
   
      $host_name = $facts['networking']['hostname']
 
      $short_home_path = split($home_path,'/')[-1]
 
      $sysinfra_ls = $facts['sysinfra_sig_ls']
      $local_ls = $facts['local_sig_ls']
 
      $regex1 = "/db_dbpsu_${patch_path}_${db_sid}_${short_home_path}/"
      $regex2 = "/db_jvmpsu_${patch_path}_${db_sid}_${short_home_path}/"
      $regex3 = "/db_dbpsu_${patch_path}_NEWswHOME_${short_home_path}/"
      $regex4 = "/db_jvmpsu_${patch_path}_NEWswHOME_${short_home_path}/"
  
      if $sysinfra_ls != [''] {
       $sysinfra_ls.each | String $sysinfra_file_name | {
        if $sysinfra_file_name =~ $regex1 or $sysinfra_file_name =~ $regex2 or $sysinfra_file_name =~ $regex3 or $sysinfra_file_name =~ $regex4  {
         file { "/fslink/sysinfra/signatures/oracle/${host_name}/${sysinfra_file_name}" :
          ensure     => absent,
         }
        }
       }
      }
      if $local_ls != [''] {
       $local_ls.each | String $local_file_name | {
        if $local_file_name =~ $regex1 or $local_file_name =~ $regex2 or $local_file_name =~ $regex3 or $local_file_name =~ $regex4 {
         file { "/opt/oracle/signatures/${local_file_name}" :
          ensure     => absent,
         }
        }
       }
      }
     }
    }
   }
   else {
    notify {"Version input not recognized. Home not rolled back : ${home}" :} 
   }
  }
 }
}

