define oradb_fs::db_remediation (
 String         $home              = undef,
 String         $home_path         = undef,
 Array[String]  $db_list           = undef,
 String         $patch_path        = undef,
 String         $version           = undef,
 Boolean        $default_detected  = undef,
)
{
 if !$default_detected {
  if $patch_path != 'xx.xx.x' {

   $remediation_fact = $facts['home_associated_remediation_list']
   if $remediation_fact == [ '' ] {
    notify { "No remediation for home : ${home}" : }
   }
   else {
    $sid_action_list = return_sid_list($remediation_fact, $home, $home_path)

    $oratab_entries = $facts['home_associated_db_list']
    $oratab_home = return_sid_list($oratab_entries, $home, $home_path)
    $db_home = return_sid_list($db_list, $home, $home_path)

    $ps_entries = $facts['home_associated_running_db_list']
    $ps_home = return_sid_list($ps_entries, $home, $home_path)

    $sid_action_list.each | String $sid_action | {

     $db_sid = [ split($sid_action, '~')[0] ]
     $action_list = split($sid_action, '~')[1,-1]    
   
     $sid_in_oratab = compare_arrays($oratab_home, $db_sid)
     $sid_in_db_list = compare_arrays($db_home, $db_sid)
     $sid_in_running_ps = compare_arrays($ps_home, $db_sid)

     if $sid_in_oratab == 'B' or $sid_in_oratab == 'C' {
     }
     elsif $sid_in_oratab == 'S' or $sid_in_oratab == 'F' { 
      notify { "Oratab does not contain SID requested for remediation. SID skipped : ${home} : ${db_sid}" :
       loglevel => 'err'
      }
     }
     else { # $sid_in_oratab == 'T' or $sid_in_oratab == 'P'
      if $sid_in_db_list == 'B' or $sid_in_db_list == 'C' {
      }
      elsif $sid_in_db_list == 'S' or $sid_in_db_list == 'F' {
       notify { "Yaml file db list does not contain the SID requested for remediation. SID skipped : ${home} : ${db_sid}" :
        loglevel => 'err'
       }
      }
      else { #$sid_in_db_list == 'T' or $sid_in_db_list == 'P' 
 
       $action_list.each | String $rem_action | {

       if $rem_action == 'patch' or $rem_action == 'all' {
        if $sid_in_running_ps == 'P' or $sid_in_running_ps == 'T' {
          oradb_fs::dbactions_loop { "Stop all dbs requiring patch remediation in ${home}" :
           home           => $home,
           db_list        => $db_sid,
           action         => 'stop1',
           home_path      => $home_path,
          }
         }
    
         $version_holding = split($version, '[.]')
    
         $short_version = "${version_holding[0]}.${version_holding[1]}" 
  
         $patch_path_holding = split($patch_path,'[.]')
  
         $patch_path_ru = $patch_path_holding[1] + $patch_path_holding[2]
         $patch_path_adjusted = "${patch_path_holding[0]}.${patch_path_ru}.0"
         $patch_path_lookup_db = regsubst($patch_path, '[.]', '_', 'G')
         $patch_path_lookup_other = "${patch_path_holding[0]}_${patch_path_ru}_0"

         $db_patch_num_holding = split($facts["oradb_fs::${patch_path_lookup_db}::db_patch_file"],'_')[0]
         $db_patch_num = inline_template( '<%= @db_patch_num_holding[1..-1] %>' )
 
         $ojvm_patch_num_holding = split($facts["oradb_fs::${patch_path_lookup_other}::ojvm_patch_file"],'_')[0]
         $ojvm_patch_num = inline_template( '<%= @ojvm_patch_num_holding[1..-1] %>' )
    
         oradb_fs::dbactions_loop { "Startup Upgrade for all dbs requiring patch remediation in ${home}" :
          home           => $home,
          db_list        => $db_sid,
          action         => 'upgrade',
          home_path      => $home_path,
         } ->
         oradb_fs::post_patching_tree { "Patch remediation : ${home}" :
          home                 => $home,
          home_path            => $home_path,
          db_list              => $db_sid,
          db_patch_number      => $db_patch_num,
          ojvm_patch_number    => $ojvm_patch_num,
          short_version        => $short_version,
          patch_path           => $patch_path,
          ojvm_patch_path      => $patch_path_adjusted,
         } ->
         oradb_fs::dbactions_loop { "Stop all dbs requiring patch remediation in ${home} after running post patching" :
          home           => $home,
          db_list        => $db_sid,
          action         => 'stop2',
          home_path      => $home_path,
         } ->
         oradb_fs::dbactions_loop { "Restart all dbs requiring patch remediation in ${home}" :
          home           => $home,
          db_list        => $db_sid,
          action         => 'start',
          home_path      => $home_path,
         }
        }
        if $rem_action == 'security' or $rem_action == 'all' {
         $db_list.each | String $db_info | {
          $holding = split($db_info,':')
          if $holding[0] == $db_sid[0] {

           $security_options = $holding[3]

           oradb_fs::db_security { "Call to configure security settings: $db_sid[0]" :
            db_name              => $db_sid[0],
            working_dir          => "/opt/oracle/sw/working_dir/${home}",
            home                 => $home,
            home_path            => $home_path,
            db_security_options  => $security_options,
           }
          }
         }
 #        notify { "Remediation : security stub : ${home} : ${db_sid}" : }
        }
        if $rem_action == 'none' {
         notify { "Incorrect input for /tmp touch file of SID requested for remediation. SID skipped : ${home} : ${db_sid[0]}" :
          loglevel => 'err'
         }
        }
       }
      }
     }
    }
   }
  }
  else {
   notify{"Patch path is set to 'xx.xx.x' : remediation skipped : db_remediation : ${home}" : }
  }
 }
 else {
  notify{"Default value detected in db_info_list : remediation skipped: db_remediation : ${home}" : }
 }
}
    
