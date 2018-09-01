####
# oradb_fs::db_maintenance_scripts
#  author: Matthew Parker
#
# deploys the db maintenance rn
#
# variables:
#  String  $optional_mail_list  - comma seperated e-mail list to go into the emailto file
#
# creates:
#  /home/oracle/dbcheck
#  /home/oracle/dbcheck/scripts
#  /home/oracle/dbcheck/logs
#  /opt/oracle/diag/bkp
#  /opt/oracle/diag/bkp/alertlogs
#  /opt/oracle/diag/bkp/rman
#  /opt/oracle/diag/bkp/rman/log
#
# deploys:
#  /home/oracle/dbcheck/scripts/${script} - see $scripts for full list
#  /home/oracle/dbcheck/scripts/emailto
#
# cron entries:
#  /home/oracle/dbcheck/scripts/rotate_alertlogs.sh > /home/oracle/dbcheck/logs/alert.log 2>&1
#  /home/oracle/dbcheck/scripts/dbmaint_start.job all > /tmp/dbmaint_daily.log 2>&1
#
####
define oradb_fs::db_maintenance_scripts (
 String  $optional_mail_list  = undef,
)
{
 file { [ '/home/oracle/dbcheck', '/home/oracle/dbcheck/scripts', '/home/oracle/dbcheck/logs',
          '/opt/oracle/diag/bkp', '/opt/oracle/diag/bkp/alertlogs', '/opt/oracle/diag/bkp/rman', '/opt/oracle/diag/bkp/rman/log' ]:
  ensure => 'directory',
  owner  => 'oracle',
  group  => 'oinstall',
  mode   => '0775',
 }
# Removed '12c_reset_profile_pwd.sql', from scripts. BUG script.
 $scripts =   ['archloglist.sql',
               'chained_rows.sql',
               'check_for_extents.sql',
               'ckalertlog.sh',
               'ckexplogs.sh',
               'ckrmanlogs.sh',
               'cleanup.sh',
               'count_fsdba_privs.sql',
               'cr_reset_fsschemas.sql',
               'cr_rpwd_lock_procedure.sql',
               'cr_rpwd_procedure.sql',
               'data_pump_dir.sql',
               'dbmaint_daily.sh',
               'dbmaint.sh',
               'dbmaint_start.job',
               'dbsize.sql',
               'db_start.sql',
               'FSoptions.sql',
               'FSutlrp.sql',
               'get_sid.ksh',
               'global_name.sql',
               'list_user_privs.sql',
               'logswitch.sql',
               'options_packs_usage_statistics.sql',
               'parms.sql',
               'reset_fsschemas.sh',
               'rotate_alertlogs.sh',
               'rundbsql.sh',
               'set_16k_dfile_ext.sql',
               'set_8k_dfile_ext.sql',
               'tbs.sql',
               'trim_logs.sh']

 $scripts.each |String $script| {
  file { "/home/oracle/dbcheck/scripts/${script}":
   ensure  => present,
   source  => "puppet:///modules/oradb_fs/db_maintenance/${script}",
   mode    => '0774',
   owner   => 'oracle',
   group   => 'oinstall',
   require => File['/home/oracle/dbcheck/scripts'],
  }
 }

 if $optional_mail_list != null {
  file { '/home/oracle/dbcheck/scripts/emailto':
   ensure  => present,
   content => $optional_mail_list,
   mode    => '0774',
   owner   => 'oracle',
   group   => 'oinstall',
   require => File['/home/oracle/dbcheck/scripts'],
  }
 }
 else {
  file { '/home/oracle/dbcheck/scripts/emailto' :
   ensure  => present,
   source  => 'puppet:///modules/oradb_fs/db_maintenance/emailto',
   mode    => '0774',
   owner   => 'oracle',
   group   => 'oinstall',
   require => File['/home/oracle/dbcheck/scripts'],
  }
 }

 cron { 'rotate alert log files on the 1st of every month':
   command  => '/home/oracle/dbcheck/scripts/rotate_alertlogs.sh > /home/oracle/dbcheck/logs/alert.log 2>&1',
   user     => 'oracle',
   minute   => 0,
   hour     => 0,
   monthday => 1,
   month    => absent,
   weekday  => absent,
 }

 cron { 'run db maintenance scripts daily':
   command  => '/home/oracle/dbcheck/scripts/dbmaint_start.job all > /tmp/dbmaint_daily.log 2>&1',
   user     => 'oracle',
   minute   => 0,
   hour     => 05,
   monthday => absent,
   month    => absent,
   weekday  => absent,
 }
}

