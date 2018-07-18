define oradb_fs::recover_db (
 String           $home              = undef,
 String           $home_path         = undef,
 Array[String]    $db_info_list      = undef,
 Boolean          $default_detected  = undef,
)
{
 if !$default_detected {

  $sid_associated_vestige_list  = $facts['sid_associated_vestige_list']
   
  $oratab_entries = $facts['home_associated_db_list']
  $ps_entries = $facts['home_associated_running_db_list']
  $recovery_entries = $facts['recovery_db_list']
 
  if $recovery_entries != [''] {

   if $oratab_entries == [''] {
    $oratab_all = ['']
   }
   else {
    $oratab_all = flatten($oratab_entries.map | String $oratab_info | { split($oratab_info, ':') })
   }

   if $ps_entries == [''] {
    $ps_all = ['']
   }
   else{
    $ps_all = flatten($ps_entries.map | String $ps_info | { split($ps_info, ':') })
   }

   $recovery_home = return_sid_list($recovery_entries, $home, $home_path) 
   $db_home = return_sid_list($db_info_list, $home, $home_path)
 
   $recovery_in_oratab = compare_arrays($oratab_all, $recovery_home)
   $recovery_in_running_ps = compare_arrays($ps_all, $recovery_home)
   $recovery_in_db_list = compare_arrays($db_home, $recovery_home)
 
   if $recovery_in_oratab == 'B' or $recovery_in_oratab == 'C' {
   }
   elsif $recovery_in_oratab == 'T' or $recovery_in_oratab == 'P' {
    fail("Oratab contains the complete or partial requested recovery list for home: ${home}")
   }
   else { #elsif $recovery_in_oratab == 'S' or $recovery_in_oratab == 'F' {
    if $recovery_in_running_ps == 'B' or $recovery_in_running_ps == 'C' {
    } 
    elsif $recovery_in_running_ps == 'T' or $recovery_in_running_ps == 'P' {
     fail("Ps -ef contains the complete or partial requested recovery list running for home: ${home}")
    }
    else { #elsif $recovery_in_running_ps == 'S' or $recovery_in_running_ps == 'F'{
     if $recovery_in_db_list == 'B' or $recovery_in_db_list == 'C' {
     }
     elsif $recovery_in_db_list == 'S' or $recovery_in_db_list == 'P' or $recovery_in_db_list == 'F' {
      fail("Yaml file db list does not contain the complete requested recovery list running for home: ${home}")
     }
     else { #$recovery_in_db_list == 'T' {
      $recovery_entries.each | String $value | {
       $holding1 = split($value,':')
       if $holding1[0] == $home {
        $sid_list = delete_at($holding1, 0)
        $sid_list.each | String $db_sid | {
         $sid_associated_vestige_list.each | String $vestige_info | {
          $holding2 = split($vestige_info,':')
          $holding3 = delete_at($holding2, 0)
          if $db_sid == $holding2[0] {
           $holding3.each | String $dir | {
            file { $dir :
             ensure  => absent,
             force   => true, 
             backup  => false,
            }
           }
          }
         }
        }
       }
      }
     }
    }
   }
  }
 }
}
