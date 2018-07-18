define oradb_fs::em_agent_control (
 String        $home        = undef,
 String        $action      = undef,
 String        $agent_home  = undef,
)
{
 if $action == 'stop' {
  exec { "Shutdown EM Agent : ${home}" :
   command     => "${agent_home}/bin/emctl stop agent",
   user        => 'oracle',
   onlyif      => "/bin/test -f ${agent_home}/bin/emctl"
  }
 }
 elsif $action == 'start' {
  exec { "Startup EM Agent : ${home}" :
   command     => "${agent_home}/bin/emctl start agent",
   user        => 'oracle',
   onlyif      => "/bin/test -f ${agent_home}/bin/emctl"
  }
 }
 else {
  fail('Action not recognized: em_agent_control')
 }
}
