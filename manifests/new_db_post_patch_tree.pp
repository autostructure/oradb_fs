define oradb_fs::new_db_post_patch_tree (
 String    $home                 = undef,
 String    $home_path            = undef,
 String    $db_name              = undef, 
 String    $short_version        = undef,
)
{
 if $short_version == '11.2' {
 }
 elsif $short_version == '12.1' {
  oradb::dbactions{ "${home}: stop ${db_name}":
   oracle_home             => $home_path,
   user                    => 'oracle',
   group                   => 'dba',
   action                  => 'stop',
   db_name                 => $db_name,
  } ->
  oradb::dbactions{ "${home} : startup upgrade for new DB: ${db_name}":
   oracle_home             => $home_path,
   user                    => 'oracle',
   group                   => 'dba',
   action                  => 'upgrade',
   db_name                 => $db_name,
  } ->
  exec { "Run datapatch for new DB : ${home} : ${db_name}":
   command     => "datapatch -verbose",
   user        => 'oracle',
   path        => "${home_path}/OPatch",
   environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${db_name}", "LD_LIBRARY_PATH=${home_path}/lib"]
  } ->
  oradb::dbactions{ "${home} : datapatch finished : stop ${db_name}":
   oracle_home             => $home_path,
   user                    => 'oracle',
   group                   => 'dba',
   action                  => 'stop',
   db_name                 => $db_name,
  } ->
  oradb::dbactions{ "${home}: start ${db_name}":
   oracle_home             => $home_path,
   user                    => 'oracle',
   group                   => 'dba',
   action                  => 'start',
   db_name                 => $db_name,
  }
 }
 elsif $short_version == '12.2' {
 }
 else {
  fail('Short version not recognized : new_db_post_patch_tree')
 }
}
