####
# oradb_fs::recover_sw
#  author: Matthew Parker
#
# recovers from a failed Oracle software install
#
# variables:
#  String  $home       - home variable set in use (db_#)
#  String  $home_path  - full path to the Oracle home
#
# empties:
#  $home_path
#
# updates:
#  /opt/oraInventory/ContentsXML/inventory.xml
#
####
define oradb_fs::recover_sw (
 String  $home       = undef,
 String  $home_path  = undef,
)
{

 $recovery_home_list  = $facts['recovery_home_list']

 $oratab_entries = $facts['home_associated_db_list']
 $ps_entries = $facts['home_associated_running_db_list']

 if $recovery_home_list != [''] {

  $oratab_home = return_home($oratab_entries, $home, $home_path, 'N')
  $ps_home = return_home($ps_entries, $home, $home_path, 'N')
  $recovery_home = return_home($recovery_home_list, $home, $home_path, 'N')

  $recovery_in_oratab = compare_arrays($oratab_home, $recovery_home)
  $recovery_in_running_ps = compare_arrays($ps_home, $recovery_home)

  if $recovery_in_oratab == 'B' or $recovery_in_oratab == 'C' {
  }
  elsif $recovery_in_oratab == 'T' or $recovery_in_oratab == 'P' {
   fail("Oratab contains the requested home to recover: ${home}")
  }
  else { #elsif $recovery_in_oratab == 'S' or $recovery_in_oratab == 'F' {
   if $recovery_in_running_ps == 'B' or $recovery_in_running_ps == 'C' {
   }
   elsif $recovery_in_running_ps == 'T' or $recovery_in_running_ps == 'P' {
    fail("Ps -ef contains at least one DB running against the requested home to recover: ${home}")
   }
   else { #elsif $recovery_in_running_ps == 'S' or $recovery_in_running_ps == 'F'{

    exec { "Kill listener in case it is somehow up: ${home}":
     command   => "pkill -u oracle -f ${home_path}/bin/tnslsnr | wc \$1>/dev/null",
     path      => '/bin',
     logoutput => true,
    }

    exec { "Wipe home Path : ${home_path}":
     command   => "rm -rf ${home_path}/*",
     path      => '/bin',
     logoutput => true,
    }

    $home_path_mod = regsubst($home_path, '/', '\/', 'G')

    $sed_command  = "sed -i '/${home_path_mod}/ {s/\/>/ REMOVED=\"T\"\/>/;s/${home_path_mod}/OraPlaceHolderDummyHome/}' /opt/oraInventory/ContentsXML/inventory.xml"

    exec { "Remove home from inventory.xml if needed : ${home_path}":
     command   => $sed_command,
     path      => '/bin',
     logoutput => true,
    }
   }
  }
 }
}
