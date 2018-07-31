####
# oradb_fs::build_db_loop
#  author: Matthew Parker
#
# pass through manifest to oradb_fs::build_db to cycle through one set of database information at a time
# needs to be rewritten to look like oradb_fs::delete_db_loop
#
# variables
#  String         $home              - home variable set in use (db_#) 
#  Array[String]  $db_info_list      - flat fact array of information required to build a new database(s) using this module
#  String         $home_path         - full path to the Oracle home
#  String         $version           - version of the base install of the Oracle home (12.2.0.1)
#  String         $patch_path        - patch version the Oracle home is supposed to be patched to in Oracle 18c version format (12_2.xx.x, 18.xx.x, ...)
#  Boolean        $default_detected  - set to true if the db_info_list_db_# array associated to the home being patched contains any default value
#
# calls the following manifests:
#  oradb_fs::build_db - builds a database associated to the Oracle home being worked on
#
####
define oradb_fs::build_db_loop (
 String         $home              = undef,
 Array[String]  $db_info_list      = undef,
 String         $home_path         = undef,
 String         $version           = undef,
 String         $patch_path        = undef,
 Boolean        $default_detected  = undef,
)
{
 if !$default_detected {
  $db_info_list.each | String $db_info | {
    if !empty($db_info) {
    oradb_fs::build_db { "Build db: ${home} : ${db_info}" :
     home        => $home,
     db_info     => $db_info,
     home_path   => $home_path,
     version     => $version,
     patch_path  => $patch_path
    }
   }
  }
 }
}
