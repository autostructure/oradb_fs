####
# oradb_fs::delete_sw
#  author: Matthew Parker
#
# removes an Oracle home  
#
# variables:
#  String  $home              - home variable set in use (db_#)
#  String  $delete_home_path  - full path to Oracle home being removed
#
# removes:
#  /opt/oracle/signatures/${local_file_name}                              - regex matched sig file names
#                                                                           associated to the home being removed
#  /fslink/sysinfra/signatures/oracle/${host_name}/${sysinfra_file_name}  - regex matched sig file names
#                                                                           associated to the home being removed
#
####
define oradb_fs::delete_sw (
 String  $home              = undef,
 String  $delete_home_path  = undef,
)
{

 $oratab_entries = $facts['home_associated_db_list']
 $ps_entries = $facts['home_associated_running_db_list']
 $delete_entries = $facts['delete_home_list']

 $oratab_home = return_home($oratab_entries, $home, $delete_home_path, 'N')
 $ps_home = return_home($ps_entries, $home, $delete_home_path, 'N')
 $delete_home = return_home($delete_entries, $home, $delete_home_path, 'N')

 $delete_in_oratab = compare_arrays($oratab_home, $delete_home)
 $delete_in_running_ps = compare_arrays($ps_home, $delete_home)

 if $delete_in_oratab == 'B' or $delete_in_oratab == 'C' {
 }
 elsif $delete_in_oratab == 'T' or $delete_in_oratab == 'P' {
  fail("Oratab contains the requested home to delete: ${home}")
 }
 else { #elsif $delete_in_oratab == 'S' or $delete_in_oratab == 'F' {
  if $delete_in_running_ps == 'B' or $delete_in_running_ps == 'C' {
  }
  elsif $delete_in_running_ps == 'T' or $delete_in_running_ps == 'P' {
   fail("Ps -ef contains at least one DB running against the requested home to recover: ${home}")
  }
  else { #elsif $delete_in_running_ps == 'S' or $delete_in_running_ps == 'F'{

   exec { "Kill listener before wiping home: ${home}":
    command   => "pkill -u oracle -f ${delete_home_path}/bin/tnslsnr | wc \$1>/dev/null",
    path      => '/bin',
    logoutput => true,
   }

   exec { "Remove home : ${delete_home_path}":
    command   => "rm -rf ${delete_home_path}/*",
    path      => '/bin',
    logoutput => true,
   }

   $delete_home_path_mod = regsubst($delete_home_path, '/', '\/', 'G')

   $sed_command  = "sed -i '/${delete_home_path_mod}/ {s/\/>/ REMOVED=\"T\"\/>/;s/${delete_home_path_mod}/OraPlaceHolderDummyHome/}' /opt/oraInventory/ContentsXML/inventory.xml"

   exec { "Remove home from inventory.xml : ${delete_home_path}":
    command   => $sed_command,
    path      => '/bin',
    logoutput => true,
   }

   $host_name = $facts['networking']['hostname']

   $short_home_path = split($delete_home_path,'/')[-1]

   $sysinfra_ls = $facts['sysinfra_sig_ls']
   $local_ls = $facts['local_sig_ls']

   $regex1 = "/db_dbpsu_[1]?[2]?[_]?[1-9]?[0-9]\.[1-9]?[0-9]\.[0-2]_NEWswHOME_${short_home_path}/"
   $regex2 = "/db_jvmpsu_[1]?[2]?[_]?[1-9]?[0-9]\.[1-9]?[0-9]\.[0-2]_NEWswHOME_${short_home_path}/"
   $regex3 = "/ora_db_SI_Install_${short_home_path}/"

   if $sysinfra_ls != [''] {
    $sysinfra_ls.each | String $sysinfra_file_name | {
     if $sysinfra_file_name =~ $regex1 or $sysinfra_file_name =~ $regex2 or $sysinfra_file_name =~ $regex3 {
      file { "/fslink/sysinfra/signatures/oracle/${host_name}/${sysinfra_file_name}" :
       ensure     => absent,
      }
     }
    }
   }

   if $local_ls != [''] {
    $local_ls.each | String $local_file_name | {
     if $local_file_name =~ $regex1 or $local_file_name =~ $regex2 or $local_file_name =~ $regex3 {
      file { "/opt/oracle/signatures/${local_file_name}" :
       ensure     => absent,
      }
     }
    }
   }
  }
 }
}

