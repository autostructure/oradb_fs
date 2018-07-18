define oradb_fs::autostart (
 String        $db_name      = undef,
 String        $oracle_home  = undef,
)
{
 $exec_path    = '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin'

 $sed_command  = "sed -i -e's/:N/:Y/g' /etc/oratab"

 exec { "set dbora ${db_name}:${oracle_home}":
  command   => $sed_command,
  unless    => "/bin/grep '^${db_name}:${oracle_home}:Y' /etc/oratab",
  path      => $exec_path,
  logoutput => true,
 }
}
