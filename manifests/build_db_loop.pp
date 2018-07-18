define oradb_fs::build_db_loop (
 String          $home              = undef,
 Array[String]   $db_info_list      = undef,
 String          $home_path         = undef,
 String          $version           = undef,
 String          $patch_path        = undef,
 Boolean         $default_detected  = undef,
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
