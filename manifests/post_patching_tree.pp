define oradb_fs::post_patching_tree (
 String           $home                 = undef,
 String           $home_path            = undef,
 Array[String]    $db_list              = undef,
 String           $db_patch_number      = undef,
 String           $ojvm_patch_number    = undef,
 String           $short_version        = undef,
 String           $patch_path           = undef,
 String           $ojvm_patch_path      = undef,
)
{
 $db_list.each | String $db_name | {
  $holding = $db_name.split(':')

  file { "/opt/oracle/sw/working_dir/${home}/${patch_path}/post_patch_utlrp_${holding[0]}.sql" :
   ensure  => present,
   content => epp("oradb_fs/run_utlrp.sql.epp",
               { 'home_path'             => $home_path,
               }),
   mode    => '0755',
   owner   => 'oracle',
   group   => 'dba',
  }

  if $short_version == '11.2' {
   file { "/opt/oracle/sw/working_dir/${home}/${patch_path}/11g_db_post_patch_${holding[0]}.sql" :
    ensure  => present,
    content => epp("oradb_fs/11g_db_post_patch.sql.epp",
                { 'home_path'             => $home_path,
                }),
    mode    => '0755',
    owner   => 'oracle',
    group   => 'dba',
   }

   file { "/opt/oracle/sw/working_dir/${home}/${patch_path}/11g_ojvm_post_patch_${holding[0]}.sql" :
    ensure  => present,
    content => epp("oradb_fs/11g_ojvm_post_patch.sql.epp",
                { 'home_path'             => $home_path,
                  'patch_number'          => $ojvm_patch_number}),
    mode    => '0755',
    owner   => 'oracle',
    group   => 'dba',
   }     

   exec {"DB patch post install: ${home} : ${holding[0]}":
    command => "sqlplus /nolog @/opt/oracle/sw/working_dir/${home}/${patch_path}/11g_db_post_patch_${holding[0]}.sql",
    user    => 'oracle',
    path    => "${home_path}/bin",
    environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${holding[0]}", "LD_LIBRARY_PATH=${home_path}/lib"]
   } ->
   exec {"OJVM patch post install: ${home} : ${holding[0]}":
    command => "sqlplus /nolog @/opt/oracle/sw/working_dir/${home}/${patch_path}/11g_ojvm_post_patch_${holding[0]}.sql",
    user    => 'oracle',
    path    => "${home_path}/bin",
    environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${holding[0]}", "LD_LIBRARY_PATH=${home_path}/lib"]
   } 
  }
  elsif $short_version == '12.1' {
   exec { "Run datapatch : ${home} : ${holding[0]}":
    command     => "datapatch -verbose",
    user        => 'oracle',
    path        => "${home_path}/OPatch",
    environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${holding[0]}", "LD_LIBRARY_PATH=${home_path}/lib"]
   }
  }
  elsif $short_version == '12.2' {
   exec { "Run datapatch : ${home} : ${holding[0]}":
    command     => "datapatch -verbose",
    user        => 'oracle',
    path        => "${home_path}/OPatch",
    environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${holding[0]}", "LD_LIBRARY_PATH=${home_path}/lib"]
   }
  }
  else {
   fail('Short version not recognized : post_patching_tree')
  }

  exec {"UTLRP post patch precautionary run: ${home} : ${holding[0]}":
   command => "sqlplus /nolog @/opt/oracle/sw/working_dir/${home}/${patch_path}/post_patch_utlrp_${holding[0]}.sql",
   user    => 'oracle',
   path    => "${home_path}/bin",
   environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${holding[0]}", "LD_LIBRARY_PATH=${home_path}/lib"]
  }
 }
}
