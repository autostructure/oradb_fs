define oradb_fs::build_working_dir (
 String     $home              = undef,
 String     $patch_path        = undef,
 String     $version           = undef,
)
{
 file { "/opt/oracle/sw/working_dir/${home}" :
           ensure   => 'directory',
           owner    => 'oracle',
           group    => 'oinstall',
           mode     => '0755',
 }
 if $patch_path != 'xx.xx.x' {
/*
  $version_holding = split($version,'[.]')
  $short_version_mod = "${version_holding[0]}_${version_holding[1]}"

  $patch_date_num = patch_date_to_num($patch_date)

  $min_patch_date = $facts["oradb_fs::${short_version_mod}::min_patch_date"]

  if $patch_date_num < patch_date_to_num($min_patch_date) {
   $patch_date_final = $min_patch_date
  }
  else {
   $patch_date_final = $patch_date
  }
*/
  file { "/opt/oracle/sw/working_dir/${home}/${patch_path}" :
            ensure   => 'directory',
            owner    => 'oracle',
            group    => 'oinstall',
            mode     => '0755',
  }
 }
}

