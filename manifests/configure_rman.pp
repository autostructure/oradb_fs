####
# oradb_fs::configure_rman
#  author: Matthew Parker
#
# placeholder manifest to configure database/home for rman backups
#
####
define oradb_fs::configure_rman (
 String  $home       = undef,
 String  $home_path  = undef,
)
{

 if $facts['libobk_so64_exists'] != 0 {
  if $facts['hostname-ebn_exists'] != 0 {
   exec {'Move Oracle provided libobk.so file aside' :
    command => "/bin/mv ${home_path}/lib/libobk.so ${home_path}/lib/libobk.so.orig",
    user    => 'oracle',
    creates => "${home_path}/lib/libobk.so.orig",
    unless  => "/bin/ls ${home_path}/lib/libobk.so.orig 2>/dev/null"
   }
   file { "${home_path}/lib/libobk.so" :
    ensure => 'link',
    target => '/usr/openv/netbackup/bin/libobk.so64'
   }
  }
  else {
   notify {"EBN network interface does not exist. Unable to configure RMAN backups on this server." :
    loglevel => 'err'
   }
   notify {"Please contact NITC helpdesk to remediate for the missing network interface. See RMAN RN for sample email." :
    loglevel => 'err'
   }
  }
 }
 else {
  notify {"/usr/openv/netbackup/bin/libobk.so64 does not exist. Unable to configure RMAN backups on this server." :
   loglevel => 'err'
  }
  notify {"Please contact NITC helpdesk to remediate for NetBackup. See RMAN RN for sample email." :
   loglevel => 'err'
  }
 }
}

