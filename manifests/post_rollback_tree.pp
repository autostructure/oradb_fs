define oradb_fs::post_rollback_tree (
 String           $home                 = undef,
 String           $home_path            = undef,
 Array[String]    $db_list              = undef, 
 String           $db_patch_number      = undef,
 String           $ojvm_patch_number    = undef,
 String           $short_version        = undef,
 String           $type                 = undef,
 String           $patch_path           = undef,
)
{
 $db_list.each | String $db_name | {
  $holding = $db_name.split(':')

  file { "/opt/oracle/sw/working_dir/${home}/post_${type}_rollback_utlrp_${holding[0]}.sql" :
   ensure  => present,
   content => epp("oradb_fs/run_utlrp.sql.epp",
               { 'home_path'             => $home_path,
               }),
   mode    => '0755',
   owner   => 'oracle',
   group   => 'dba',
  }

  if $short_version == '11.2' {
   if $type == 'db' { 
    
    file { "/opt/oracle/sw/working_dir/${home}/11g_db_post_rollback_${holding[0]}.sql" :
     ensure  => present,
     content => epp("oradb_fs/11g_db_post_rollback.sql.epp",
                 { 'home_path'             => $home_path,
                   'db_name'               => upcase($holding[0]), }),
     mode    => '0755',
     owner   => 'oracle',
     group   => 'dba',
    }
 
    exec {"DB patch post rollback: ${home} : ${holding[0]}":
     command => "sqlplus /nolog @/opt/oracle/sw/working_dir/${home}/11g_db_post_rollback_${holding[0]}.sql",
     user    => 'oracle',
     path    => "${home_path}/bin",
     environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${holding[0]}", "LD_LIBRARY_PATH=${home_path}/lib"]
    }
   }
   elsif $type == 'ojvm' {
    
    file { "/opt/oracle/sw/working_dir/${home}/11g_ojvm_post_rollback_${holding[0]}.sql" :
     ensure  => present,
     content => epp("oradb_fs/11g_ojvm_post_rollback.sql.epp",
                 { 'home_path'             => $home_path,
                   'patch_number'          => $ojvm_patch_number}),
     mode    => '0755',
     owner   => 'oracle',
     group   => 'dba',
    }

    exec {"OJVM patch post rollback: ${home} : ${holding[0]}":
      command => "sqlplus /nolog @/opt/oracle/sw/working_dir/${home}/11g_ojvm_post_rollback_${holding[0]}.sql",
      user    => 'oracle',
      path    => "${home_path}/bin",
      environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${holding[0]}", "LD_LIBRARY_PATH=${home_path}/lib"]
    }
   }
   else {
    fail('Unrecognized type selection : post_rollback_tree')
   }
  }
  elsif $short_version == '12.1' {
   exec { "Run datapatch after rollback: ${home} : ${holding[0]} : ${type}":
    command     => "datapatch -verbose",
    user        => 'oracle',
    path        => "${home_path}/OPatch",
    environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${holding[0]}", "LD_LIBRARY_PATH=${home_path}/lib"]
   }
  }
  elsif $short_version == '12.2' {
   exec { "Run datapatch after rollback: ${home} : ${holding[0]} : ${type}":
    command     => "datapatch -verbose",
    user        => 'oracle',
    path        => "${home_path}/OPatch",
    environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${holding[0]}", "LD_LIBRARY_PATH=${home_path}/lib"]
   }
  }
  else {
   fail('Short version not recognized : post_rollback_tree')
  }
  exec {"UTLRP post ${type} rollback precautionary run: ${home} : ${holding[0]}":
   command => "sqlplus /nolog @/opt/oracle/sw/working_dir/${home}/post_rollback_utlrp_${holding[0]}.sql",
   user    => 'oracle',
   path    => "${home_path}/bin",
   environment => [ "ORACLE_BASE=/opt/oracle", "ORACLE_HOME=${home_path}", "ORACLE_SID=${holding[0]}", "LD_LIBRARY_PATH=${home_path}/lib"]
  }
 }
}
