####
# oradb_fs::listener
#  author: Matthew Parker
#
# variables: 
#  String   $home_path  - full path to the Oracle home
#  Integer  $db_port    - port number to assign to the listener
#
# deploys:
#  ${home_path}/network/admin/listener.ora
#
####
define oradb_fs::listener (
 String   $home_path  = undef,
 Integer  $db_port    = undef,
)
{

# $valid_node_checking  = $facts['oradb_fs::valid_node_checking']

 file { "${home_path}/network/admin/listener.ora":
  ensure  => present,
  content => epp("oradb_fs/listner.ora.epp",
                { 'db_port'              => $db_port,
                  'hostname_f'           => $facts['networking']['fqdn'],
                  'ora_base'             => '/opt/oracle',
#                  'valid_node_checking'  => $valid_node_checking,}),
                  'valid_node_checking'  => $facts['oradb_fs::valid_node_checking'],}),
  mode    => '0644',
  owner   => 'oracle',
  group   => 'oinstall',
 }
}
