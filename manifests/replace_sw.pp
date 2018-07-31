####
# oradb_fs::replace_sw
#  author: Matthew Parker
#
# wipes out an Oracle software install while preserving some files to move to a new home.
# intended to be used if a home is corrupted or otherwise faulty
#
# variables:
#  String  $home       - home variable set in use (db_#)
#  String  $home_path  - full path to the Oracle home
#
# creates:
#  /opt/oracle/sw/home_files_copy/${home} 
#  /opt/oracle/sw/home_files_copy/${home}/${the_date}
#  /opt/oracle/sw/home_files_copy/${home}/${the_date}/dbs            - contains the contents of ${home_path}/dbs
#  /opt/oracle/sw/home_files_copy/${home}/${the_date}/network/admin  - contains the contents of ${home_path}/network/admin
#  /opt/oracle/sw/home_files_copy/${home}/${the_date}/               - copy of /etc/oratab
#
# empties:
#  $home_path
#
# updates:
#  /opt/oraInventory/ContentsXML/inventory.xml
#
####
define oradb_fs::replace_sw (
 String  $home       = undef,
 String  $home_path  = undef,
)
{
 
 $replace_home_list  = $facts['replace_home_list']
  
 if $replace_home_list != [''] {
 
  $oratab_entries = $facts['home_associated_db_list']
  $ps_entries = $facts['home_associated_running_db_list']

  $oratab_home = return_home($oratab_entries, $home, $home_path, 'N')
  $ps_home = return_home($ps_entries, $home, $home_path, 'N')
  $replace_home = return_home($replace_home_list, $home, $home_path, 'N')

  $replace_in_oratab = compare_arrays($oratab_home, $replace_home)
  $replace_in_running_ps = compare_arrays($ps_home, $replace_home)

  if $replace_in_oratab == 'B' or $replace_in_oratab == 'C' or $replace_in_oratab == 'P'  {
  }
  elsif $replace_in_oratab == 'T' {
   fail("Oratab contains the requested home to replace: ${home}")
  }
  else { #elsif $replace_in_oratab == 'S' or $replace_in_oratab == 'F' {
   if $replace_in_running_ps == 'B' or $replace_in_running_ps == 'C' or $replace_in_running_ps == 'P'  {
   } 
   elsif $replace_in_running_ps == 'T' {
    fail("Ps -ef contains at least one DB running against the requested home to replace: ${home}")
   }
   else { #elsif $replace_in_running_ps == 'S' or $replace_in_running_ps == 'F'{

    exec { "Kill listener before replacing home: ${home}":
     command   => "pkill -u oracle -f ${home_path}/bin/tnslsnr | wc \$1>/dev/null",
     path      => '/bin',
     logoutput => true,
    } ->
    file { [ "/opt/oracle/sw/home_files_copy/${home}",
             "/opt/oracle/sw/home_files_copy/${home}/${the_date}"] :
     ensure   => directory,
     owner    => 'oracle',
     group    => 'oinstall',
     mode     => '0775',
    } ->
    exec { "Back up oratab before replacing home: ${home}":
     command   => "cp -p /etc/oratab /opt/oracle/sw/home_files_copy/${home}/${the_date}/.",
     path      => '/bin',
     logoutput => true,
    } ->
    exec { "Back up ORACLE_HOME/dbs before replacing home: ${home}":
     command   => "cp -Rp ${home_path}/dbs /opt/oracle/sw/home_files_copy/${home}/${the_date}/.",
     path      => '/bin',
     logoutput => true,
    } ->
    exec { "Back up ORACLE_HOME/network/admin before replacing home: ${home}":
     command   => "cp -Rp ${home_path}/network/admin /opt/oracle/sw/home_files_copy/${home}/${the_date}/.",
     path      => '/bin',
     logoutput => true,
    } ->
    file { $home_path :
     ensure    => directory,
     force     => true,
     purge     => true,
     recurse   => true,
     backup    => false,
    }

    $replace_home_path_mod = regsubst($home_path, '/', '\/', 'G')

    $sed_command  = "sed -i '/${replace_home_path_mod}/ {s/\/>/ REMOVED=\"T\"\/>/;s/${replace_home_path_mod}/OraPlaceHolderDummyHome/}' /opt/oraInventory/ContentsXML/inventory.xml"

    exec { "Remove home from inventory.xml : ${home} : ${home_path}":
     command   => $sed_command,
     path      => '/bin',
     logoutput => true,
    }

   }
  }
 }
}
