define oradb_fs::delete_db_loop (
 String           $home              = undef,
 String           $home_path         = undef,
 String           $version           = undef,
 Array[String]    $db_list           = undef,
)
{

 $db_domain = $facts['networking']['domain']

 $oratab_entries = $facts['home_associated_db_list']
 $ps_entries = $facts['home_associated_running_db_list']
 $delete_entries = $facts['home_associated_delete_db_list']

 if $delete_entries != [''] {

  notify{"In delete: ${home}":}
 
  $oratab_home = return_sid_list($oratab_entries, $home, $home_path)
  $ps_home = return_sid_list($ps_entries, $home, $home_path)
  $db_home = return_sid_list($db_list, $home, $home_path)
  $delete_db_list_home = return_sid_list($delete_entries, $home, $home_path)

  $delete_in_oratab = compare_arrays($oratab_home, $delete_db_list_home)
  $delete_in_running_ps = compare_arrays($ps_home, $delete_db_list_home)
  $delete_in_db_list = compare_arrays($db_home, $delete_db_list_home)

  if $delete_in_oratab == 'B' or $delete_in_oratab == 'C' {
  }
  elsif $delete_in_oratab == 'S' or $delete_in_oratab == 'F' or $delete_in_oratab == 'P' {
   fail("Oratab does not contain the complete requested delete list for home: ${home}")
  }
  else { #elsif delete_in_oratab = 'T' {
   if $delete_in_running_ps == 'B' or $delete_in_running_ps == 'C' {
   } 
   elsif $delete_in_running_ps == 'S' or $delete_in_running_ps == 'F' or $delete_in_running_ps == 'P' {
    fail("Ps -ef does not contain the complete requested delete list running for home: ${home}")
   }
   else { #elsif delete_in_running_ps == 'T' {
    if $delete_in_db_list == 'B' or $delete_in_db_list == 'C' {
    }
    elsif $delete_in_db_list == 'T' or $delete_in_db_list == 'P' {
     fail("Delete list is fully or partially contained in yaml file db list for home: ${home}")
    }
    else { #elsif $delete_in_db_list == 'S' or $delete_in_db_list == 'F'{    
   
     $version_holding = split($version, '[.]')
   
     $short_home_path = split($home_path,'/')[-1]

     $container_database = "${version_holding[0]}.${version_holding[1]}" ? {
      '12.2'    => true,
      default   => false,
     }

     $delete_db_list_home.each | String $db_sid | {
      oradb::database{ "Delete db ${db_sid} for home: ${home}" :
       oracle_base               => '/opt/oracle',
       oracle_home               => $home_path,
       version                   => "${version_holding[0]}.${version_holding[1]}",
       user                      => 'oracle',
       group                     => 'dba',
       download_dir              => "/opt/oracle/sw/working_dir/${home}",
       action                    => 'delete',
       db_name                   => $db_sid,
       db_domain                 => $db_domain,
       sys_password              => $facts['oradb_fs::ora_db_passwords'],
       container_database        => $container_database,
      }

      $host_name = $facts['networking']['hostname']
      
      $sysinfra_ls = $facts['sysinfra_sig_ls']
      $local_ls = $facts['local_sig_ls']

      $regex1 = "/db_dbpsu_[1]?[2]?[_]?[1-9]?[0-9]\.[1-9]?[0-9]\.[0-2]_${db_sid}_${short_home_path}\.xml/"
      $regex2 = "/db_jvmpsu_[1]?[2]?[_]?[1-9]?[0-9]\.[1-9]?[0-9]\.[0-2]_${db_sid}_${short_home_path}\.xml/"
      $regex3 = "/db_create_${db_sid}_${short_home_path}\.xml/"
      $regex4 = "/ora_db_dbinstances_v01_${db_sid}\.xml/"

      if $sysinfra_ls != [''] {
       $sysinfra_ls.each | String $sysinfra_file_name | {
        if $sysinfra_file_name =~ $regex1 or $sysinfra_file_name =~ $regex2 or $sysinfra_file_name =~ $regex3 or $sysinfra_file_name =~ $regex4 {
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
  }
 }
}


