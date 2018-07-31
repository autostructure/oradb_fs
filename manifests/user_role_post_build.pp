####
# oradb_fs::user_role_post_build
#  author: Matthew Parker
#
# runs a user/role build script against the newly created database
#
# variables:
#  String  $db_name      - sid of the database that scripts are being run against 
#  String  $oracle_home  - full path to the Oracle home
#  String  $working_dir  - path to the working directory to deploy transient files to 
#
# deploys:
#  ${working_dir}/user_role_build1_${db_name}.sh - transient file
#  ${working_dir}/user_role_build2_${db_name}.sh - transient file
#
####
define oradb_fs::user_role_post_build (
 String  $db_name      = undef,
 String  $oracle_home  = undef,
 String  $working_dir  = undef,
)
{
 file { "${working_dir}/user_role_build1_${db_name}.sh":
  ensure  => present,
  content => epp("oradb_fs/user_role_build1.sh.epp",
              { 'db_name'             => $db_name,
                'oracle_home'         => $oracle_home,
                'working_dir'         => $working_dir}),
  mode    => '0755',
  owner   => 'oracle',
  group   => 'oinstall',
 } ->
 file { "${working_dir}/user_role_build2_${db_name}.sh":
  ensure  => present,
  content => epp("oradb_fs/user_role_build2.sh.epp"),
  mode    => '0755',
  owner   => 'oracle',
  group   => 'oinstall',
 } ->
 exec { "Post db build: users and roles:${oracle_home}:${db_name}":
  command   => "${working_dir}/user_role_build1_${db_name}.sh",
  user      => 'oracle',
 }
}


