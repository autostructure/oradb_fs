####
# oradb_fs::nfs_patch_deployment_12201
#  author: Matthew Parker
#
####
define oradb_fs::nfs_patch_deployment_12201 (
)
{
 file { [ '/fslink/sysinfra/oracle/automedia',
          '/fslink/sysinfra/oracle/automedia/12.2.0.1',
          '/fslink/sysinfra/oracle/automedia/12.2.0.1/db' ] :
  ensure => 'directory',
  owner  => 'oracle',
  group  => 'oinstall',
  mode   => '755',
 }
 $patch_types = [ 'db', 'ojvm', 'opatch' ]
 
 $nfs_art_compare_array = $facts['nfs_art_compare']
 if $nfs_art_compare_array == [ '0' ] {
  notify { "Skipping NFS patch check and deployment." : }
 }
 elsif $nfs_art_compare_array != [ '' ] {
  $nfs_art_compare_array.each | String $patch_path_info | {
   $holding = split($patch_path_info,':')
   $patch_path = $holding[0]
   $patch_validity = $holding[1]
   $version = $holding[2]
   $patch_date = $holding[3]
   $yaml_patch_path = $holding[4]

   if $patch_validity == '0' {
    notify { "Patches for ${patch_path} match what is in artifactory. Update skipped." : }
   }
   elsif $patch_validity == '-3' {
    notify { "Some combination of patches are missing from artifcatory while being present down ../sysinfra or do not exist in artifactory or down ../sysinfra. Please check that the fact, 'oradb_fs::12_2::available_patches', is populated with valid values as well as the existence of the correct patch files in artifactory: ${patch_path}" :
     loglevel => 'err',
    }
   }
   elsif $patch_validity == '-2' {
    notify { "No patch file in artifcatory and no patch file down ../sysinfra. Please check that the fact, 'oradb_fs::12_2::available_patches', is populated with valid values as well as the existence of the correct patch files in artifactory: ${patch_path}" :
     loglevel => 'err',
    }
   }
   elsif $patch_validity == '-1' {
    notify { "Patch file down ../sysinfra detected with no patch file in artifactory. Please check that the fact, 'oradb_fs::12_2::available_patches', is populated with valid values as well as the existence of the correct patch files in artifactory: ${patch_path}" :
     loglevel => 'err',
    }
   }
   elsif $patch_validity == '1' {
notify { "patch_path: ${patch_path}" : }
    if $patch_path =~ /.*\.0/ {
     file { [ "/fslink/sysinfra/oracle/automedia/12.2.0.1/db/${patch_path}",
              "/fslink/sysinfra/oracle/automedia/12.2.0.1/db/${patch_path}/db",
              "/fslink/sysinfra/oracle/automedia/12.2.0.1/db/${patch_path}/opatch",
              "/fslink/sysinfra/oracle/automedia/12.2.0.1/db/${patch_path}/ojvm" ] :
      ensure => 'directory',
      owner  => 'oracle',
      group  => 'oinstall',
      mode   => '0755',
     }
     $db_zip = $facts["oradb_fs::${yaml_patch_path}::db_patch_file"]
     $ojvm_zip = $facts["oradb_fs::${yaml_patch_path}::ojvm_patch_file"]
     $opatch_zip = $facts["oradb_fs::${yaml_patch_path}::opatch_file"]
     $file_pathes = [ "oracle-media-local/db/${version}/psu/${patch_date}/${patch_path}/db/${db_zip}:/fslink/sysinfra/oracle/automedia/${version}/db/${patch_path}/db/${db_zip}",
                      "oracle-media-local/db/${version}/psu/${patch_date}/${patch_path}/ojvm/${ojvm_zip}:/fslink/sysinfra/oracle/automedia/${version}/db/${patch_path}/ojvm/${ojvm_zip}",
                      "oracle-media-local/db/${version}/psu/${patch_date}/${patch_path}/opatch/${opatch_zip}:/fslink/sysinfra/oracle/automedia/${version}/db/${patch_path}/opatch/${opatch_zip}" ]
    }
    else {
     file { [ "/fslink/sysinfra/oracle/automedia/12.2.0.1/db/${patch_path}",
              "/fslink/sysinfra/oracle/automedia/12.2.0.1/db/${patch_path}/db" ] :
      ensure => 'directory',
      owner  => 'oracle',
      group  => 'oinstall',
      mode   => '0755',
     }
     $db_zip = $facts["oradb_fs::${yaml_patch_path}::db_patch_file"]
     $file_pathes = [ "oracle-media-local/db/${version}/psu/${patch_date}/${patch_path}/db/${db_zip}:/fslink/sysinfra/oracle/automedia/${version}/db/${patch_path}/db/${db_zip}" ]
    }
    $file_pathes.each | Integer $index, String $path_pair | {
     $art_path = split($path_pair, ':')[0]
     $nfs_path = split($path_pair, ':')[1]
     $patch_type_curr = $patch_types[$index]
     exec { "Update patch zip(s) on disk: ${patch_path} : ${patch_type_curr}" :
      command => "/bin/curl -s https://artifactory.fdc.fs.usda.gov/artifactory/${art_path} -o $nfs_path",
      require => File["/fslink/sysinfra/oracle/automedia/12.2.0.1/db/${patch_path}"]
     }
     file { "${nfs_path}" :
      ensure => 'present',
      owner  => 'oracle',
      group  => 'oinstall',
      mode   => '0744',
     }
    }
   }
   else {
    notify { "Output from the 'nfs_art_compare' fact not recognized: ${patch_path}" :
     loglevel => 'err',
    }
   }
  }
 }
 else {
  notify { "The puppet fact that compares Oracle 12.2 patches in artifcatory to those down ../sysinfra returned an empty array. Please check that that the fact, 'oradb_fs::12_2::available_patches', is populated with valid values." :
   loglevel => 'err',
  }
 }
}
