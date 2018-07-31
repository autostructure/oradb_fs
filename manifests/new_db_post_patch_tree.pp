####
# oradb_fs::new_db_post_patch_tree
#  author: Matthew Parker
#
# performs various actions against a newly build database based on the base version of the Oracle home
# largely a hold over from 12.1, but still may be needed
#
# variables:
#  String  $home           - home variable set in use (db_#)
#  String  $home_path      - full path to the Oracle home
#  String  $db_name        - sid of the newly build database
#  String  $short_version  - major minor version of the Oracle home (12.2)
#
####
define oradb_fs::new_db_post_patch_tree (
 String   $home           = undef,
 String   $home_path      = undef,
 String   $db_name        = undef, 
 String   $short_version  = undef,
)
{
 if $short_version == '12.2' {
  notify {"No post db build steps for 12.2 : ${home} : ${db_name}":}
 }
 else {
  fail('Short version not recognized : new_db_post_patch_tree')
 }
}
