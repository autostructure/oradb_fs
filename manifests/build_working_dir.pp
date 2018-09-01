####
# oradb_fs::build_working_dir
#  author: Matthew Parker
#
# builds out the working direcories needed by any puppet run where work as been authorized
#
# variables
#  String  $home        - home variable set in use (db_#)
#  String  $patch_path  - patch version the Oracle home is supposed to be patched to in Oracle 18c version format (12_2.xx.x, 18.xx.x, ...)
#  String  $version     - version of the base install of the Oracle home (12.2.0.1)
#
# creates
#  /opt/oracle/sw/working_dir/${home} - transient directory
#  /opt/oracle/sw/working_dir/${home}/${patch_path} - transient directory
#
####
define oradb_fs::build_working_dir (
 String  $home        = undef,
 String  $patch_path  = undef,
 String  $version     = undef,
)
{
 file { "/opt/oracle/sw/working_dir/${home}" :
           ensure => 'directory',
           owner  => 'oracle',
           group  => 'oinstall',
           mode   => '0755',
 }
 if $patch_path != 'xx.xx.x' {
  file { "/opt/oracle/sw/working_dir/${home}/${patch_path}" :
            ensure => 'directory',
            owner  => 'oracle',
            group  => 'oinstall',
            mode   => '0755',
  }
 }
}

