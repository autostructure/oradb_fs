####
# oradb_fs::full_export_scripts
#  author: Matthew Parker
#
# deploys the full export rn
#
# deploys:
#  /home/oracle/system/oraexport/full_export_nocomp.sh
#  /home/oracle/system/oraexport/get_sid.ksh
#
# cron entries:
#  /home/oracle/system/oraexport/full_export_nocomp.sh -o ALL > /fslink/orapriv/ora_exports/full_export.sh.log 2>&1
#
####
define oradb_fs::full_export_scripts (
)
{
 file { '/home/oracle/system/oraexport' :
  ensure => 'directory',
  owner  => 'oracle',
  group  => 'oinstall',
  mode   => '0775',
 }

 $scripts =  [ 'full_export_nocomp.sh',
                'get_sid.ksh']

 $scripts.each |String $script| {
  file { "/home/oracle/system/oraexport/${script}":
   ensure  => present,
   source  => "puppet:///modules/oradb_fs/full_export/${script}",
   mode    => '0774',
   owner   => 'oracle',
   group   => 'oinstall',
   require => File['/home/oracle/system/oraexport'],
  }
 }

 cron { 'run a full export on a nightly basis':
   command  => '/home/oracle/system/oraexport/full_export_nocomp.sh -o ALL > /fslink/orapriv/ora_exports/full_export.sh.log 2>&1',
   user     => 'oracle',
   minute   => 30,
   hour     => 22,
   monthday => absent,
   month    => absent,
   weekday  => [1,2,3,4,5,6],
 }
}

