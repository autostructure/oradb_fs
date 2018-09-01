####
# oradb_fs::em_agent_control
#  author: Matthew Parker
#
# starts and stops the em agent
#
# variables:
#  String  $home        - home variable set in use (db_#)
#  String  $action      - action to be taken again the em agent
#  String  $agent_home  - full path to the em agent home
#
####
define oradb_fs::em_agent_control (
 String  $home        = undef,
 String  $action      = undef,
 String  $agent_home  = undef,
)
{
 if $action == 'stop' {
  exec { "Shutdown EM Agent : ${home}" :
   command => "${agent_home}/bin/emctl stop agent",
   user    => 'oracle',
   onlyif  => "/bin/test -f ${agent_home}/bin/emctl"
  }
 }
 elsif $action == 'start' {
  exec { "Startup EM Agent : ${home}" :
   command => "${agent_home}/bin/emctl start agent",
   user    => 'oracle',
   onlyif  => "/bin/test -f ${agent_home}/bin/emctl"
  }
 }
 else {
  fail('Action not recognized: em_agent_control')
 }
}
