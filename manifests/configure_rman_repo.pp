####
# oradb_fs::configure_rman_repo
#  author: Matthew Parker
#
# placeholder manifest to configure RMAN repo database
#
####
define oradb_fs::configure_rman_repo (
 String  $home       = undef,
 String  $home_path  = undef,
)
{
 
 if $facts['rman_schemas'] != undef {
  $rman_schemas = $facts['rman_schemas']
 }
 else {
  $rman_schemas = [ '' ]
 }




}

