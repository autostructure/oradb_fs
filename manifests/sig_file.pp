define oradb_fs::sig_file(
 String      $date             = generate('/bin/date','+%Y-%m-%d'), #should replace with function to move work from the master to the node
 String      $product          = '',   
 String      $sig_version      = '1.0',
 String      $type             = '',
 String      $sig_desc         = '',
 String      $global_name      = '',
 String      $scanid           = '',
 String      $nodeid           = '',
 String      $oracle_home      = '',
 String      $sig_file_name    = '',
)
{
 $host_name = $facts['networking']['hostname']

 file { "/opt/oracle/signatures/${sig_file_name}.xml":
  ensure  => present,
  content => template("oradb_fs/sig_template.xml.erb"),
  owner   => 'oracle',
  group   => 'oinstall',
  mode    => '0644',
 } ->
 file { "/fslink/sysinfra/signatures/oracle/${host_name}/${sig_file_name}.xml":
  ensure  => present,
  content => template("oradb_fs/sig_template.xml.erb"),
  owner   => 'oracle',
  group   => 'oinstall',
  mode    => '0644',
 }
}
