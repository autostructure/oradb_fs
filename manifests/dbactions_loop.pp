####
# oradb_fs::dbactions_loop
#  author: Matthew Parker
#
# wrapper to oradb::dbactions to handle for starting and stopping of an array of database names multiple times in a single puppet run
#
# variables:
#  String         $home       - home variable set in use (db_#)
#  Array[String]  $db_list    - flat fact array of information that includes database sids 
#  String         $action     - action to be performed against all the database sids listed in the $db_list array
#  String         $home_path  - full path to the Oracle home
#
####
define oradb_fs::dbactions_loop (
 String         $home       = undef,
 Array[String]  $db_list    = undef,
 String         $action     = undef,
 String         $home_path  = undef,
)
{

 $real_action = $action ? {
  /^start[0-9]*/     => 'start',
  /^upgrade[0-9]*/   => 'upgrade',
  /^stop[0-9]*/      => 'stop',
  default            => 'fail',
 }

 if $real_action == 'fail' { 
  fail('Wrong input action: dbactions_loop')
 }
 else { 
  $db_list.each | String $db_sid | {
   $holding = $db_sid.split(':')
   oradb::dbactions{ "${home}: ${action} ${db_sid}":
    oracle_home             => $home_path,
    user                    => 'oracle',
    group                   => 'dba',
    action                  => $real_action,
    db_name                 => $holding[0],
   }
  }
 }
}










