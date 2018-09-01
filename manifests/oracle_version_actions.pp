####
# oradb_fs::oracle_version_actions
#  author: Matthew Parker
#
# performs actions against a newly created oracle home
# hold over from 11g, but may be useful later
#
# variables:
#  String  $home_path  - full path to the Oracle home
#  String  $version    - version of the base install of the Oracle home (12.2.0.1)
#  String  $action     - action to perform
#
####
define oradb_fs::oracle_version_actions (
 String   $home_path  = undef,
 String   $version    = undef,
 String   $action     = undef,
)
{
 if $version == '11' {
  if $action == 'ocm' {
   file { "${home_path}/OPatch/ocm.rsp" :
    ensure => 'file',
    owner  => 'oracle',
    group  => 'oinstall',
    mode   => '0755',
    source => 'puppet:///modules/oradb_fs/ocm.rsp',
   }
  }
  elsif $action == 'mk' {
   file { "${home_path}/sysman/lib/ins_emagent.mk" :
    ensure => 'file',
    owner  => 'oracle',
    group  => 'oinstall',
    mode   => '0666',
    source => 'puppet:///modules/oradb_fs/ins_emagent.mk',
   }
  }
  else {
   fail('Action not recognized : oracle_version_actions')
  }
 }
}

