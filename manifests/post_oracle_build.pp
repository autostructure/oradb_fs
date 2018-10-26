####
# oradb_fs::post_oracle_build
#  author: Matthew Parker
#
# collection of manifests run every puppet run and clean up of any files in the working directory used during a single run
# only manifest in continuous enforcement mode
#
# variables:
#  $ora_platform  - value of the ora_platform variable from the fqdn.yaml deployed from artifactory
#
# calls the following manifests:
#  oradb_fs::full_export_scripts     - deployment of the full export rn
#  oradb_fs::sig_file                - creation of sig files as needed
#  oradb_fs::db_maintenance_scripts  - deployment of the db maintenance rn
#  oradb_fs::bash_profile            - deploys a .bash_profile for the Oracle user based on the value of $ora_platform 
#
####
define oradb_fs::post_oracle_build(
 $ora_platform  = undef,
)
{
 oradb_fs::full_export_scripts { 'Full export scripts RN' :
 }
 -> oradb_fs::sig_file{ 'full export signature file' :
  product       => 'Database Full Export',
  sig_version   => '1.0',
  type          => 'Base Install',
  sig_desc      => 'full export script for all databases',
  sig_file_name => 'ora_db_fullexport_v1.0',
 }

 oradb_fs::db_maintenance_scripts { 'DB maintenance scripts RN' :
  optional_mail_list  => $facts['oradb_fs::optional_mail_list']
 }
 -> oradb_fs::sig_file{ 'single instance maintenance signature file' :
  product       => 'DBmaintenance Package',
  sig_version   => '1.0',
  type          => 'base install',
  sig_desc      => 'DB maintenance scripts for SI databases',
  sig_file_name => 'ora_db_dbmaintSI_v1.0',
 }

 oradb_fs::bash_profile{ 'set up oracle bash_profile' :
  db_name      => $facts['oradb::ora_bash_db_name'],
  db_home      => $facts['oradb::ora_bash_home'],
  ora_platform => $ora_platform,
  agent_core   => $facts['oradb_fs::agent_core'],
  agent_home   => $facts['oradb_fs::agent_home'],
 }

# exec { 'Clean up working directory' :
#  command   => 'rm -rf /opt/oracle/sw/working_dir/*',
#  path      => '/bin',
#  logoutput => true,
# }

 exec { 'Clean up old /tmp Oracle install directories.' :
  command   => "find /tmp -mtime +5 -name 'OraInstall*[AP]M' -exec rm -rf {} +",
  path      => '/bin',
  logoutput => true,
  onlyif    => [ 'test `date +"%H"` -gt 20', 'test `date +"%H"` -lt 21' ]
 }

 exec { 'Clean up old /tmp Oracle deinstall directories.' :
  command   => "find /tmp -mtime +5 -name 'deinstall*[AP]M' -exec rm -rf {} +",
  path      => '/bin',
  logoutput => true,
  onlyif    => [ 'test `date +"%H"` -gt 20', 'test `date +"%H"` -lt 21' ]
 }

# exec { 'Clean up old Opatch log files: lspatches' :
#  command   => "find /opt/oracle/product/12.2.0/*/cfgtoollogs/opatch -mtime +2 -name 'opatch*[AP]M*.log' -exec rm -f {} +",
#  path      => '/bin',
#  logoutput => true,
#  onlyif    => [ 'test -d /opt/oracle/product/12.2.0/*/cfgtoollogs/opatch', 'test `date +"%H"` -gt 20', 'test `date +"%H"` -lt 21' ]
# }

 exec { 'Clean up old Opatch log files: lock files' :
  command   => "find /opt/oracle/product/12.2.0/*/cfgtoollogs/opatch -mtime +7 -name 'opatch*[AP]M*.log*.lck' -exec rm -f {} +",
  path      => '/bin',
  logoutput => true,
  onlyif    => [ 'test -d /opt/oracle/product/12.2.0/*/cfgtoollogs/opatch', 'test `date +"%H"` -gt 20', 'test `date +"%H"` -lt 21' ]
 }

 exec { 'Clean up old Opatch log files: lspatches' :
  command   => "cat /opt/oracle/product/12.2.0/*/cfgtoollogs/opatch/opatch_history.txt | awk '/lspatches/ {for(i=1; i<=1; i++) {getline; print}}' | awk -F: '{print $2 }' | xargs rm 2>/dev/null | wc -l",
  path      => '/bin',
  logoutput => true,
  onlyif    => [ 'test -d /opt/oracle/product/12.2.0/*/cfgtoollogs/opatch', 'test `date +"%H"` -gt 20', 'test `date +"%H"` -lt 21' ]
 }

 exec { 'Clean up old Opatch log files: lsinventory' :
  command   => "cat /opt/oracle/product/12.2.0/*/cfgtoollogs/opatch/opatch_history.txt | awk '/lsinventory/ {for(i=1; i<=1; i++) {getline; print}}' | awk -F: '{print $2 }' | xargs rm 2>/dev/null | wc -l",
  path      => '/bin',
  logoutput => true,
  onlyif    => [ 'test -d /opt/oracle/product/12.2.0/*/cfgtoollogs/opatch', 'test `date +"%H"` -gt 20', 'test `date +"%H"` -lt 21' ]
 }

 exec { 'Clean up old Opatch output files: lsinventory' :
  command   => "find /opt/oracle/product/12.2.0/*/cfgtoollogs/opatch/lsinv -mtime +1 -name 'lsinventory*[AP]M.txt' -exec rm -f {} +",
  path      => '/bin',
  logoutput => true,
  onlyif    => [ 'test -d /opt/oracle/product/12.2.0/*/cfgtoollogs/opatch/lsinv', 'test `date +"%H"` -gt 20', 'test `date +"%H"` -lt 21' ]
 }
}

