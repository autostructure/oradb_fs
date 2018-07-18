define oradb_fs::oem_support (
)
{
 file { ['/home/oracle/cleanup',
         '/home/oracle/cleanup/logs',
         '/home/oracle/cleanup/scripts'] :
  ensure    => 'directory',
  owner     => 'oracle',
  group     => 'oinstall',
  mode      => '0775',
 }

 file { '/home/oracle/cleanup/scripts/cleanup.sh' :
  ensure    => 'present',
  owner     => 'oracle',
  group     => 'oinstall',
  mode      => '0755',
  source  => "puppet:///modules/oradb_fs/oem/cleanup.sh",
 }

 cron { 'clean up em log directories':
   command       => '/home/oracle/cleanup/scripts/cleanup.sh > /home/oracle/cleanup/logs/cleanup.log 2>&1',
   user          => 'oracle',
   minute        => 0,
   hour          => 5,
   monthday      => absent,
   month         => absent,
   weekday       => absent,
 }
}

