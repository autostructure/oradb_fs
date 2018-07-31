####
# oradb_fs::autostart
#  author: Matthew Parker
#
# sets the autostart flag to Y in /etc/oratab
#
# variables
#  String        $db_name      - database sid that is having the autostart flag set to Y
#  String        $oracle_home  - full path of the Oracle home that the $db_name is assoctiated to
#
# updates:
#  /etc/oratab
#
####
define oradb_fs::autostart (
 String  $db_name      = undef,
 String  $oracle_home  = undef,
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
