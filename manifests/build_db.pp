####
# oradb_fs::build_db
#  author: Matthew Parker
#
# wrapper to oradb::database to build a new Oracle database associated to the Oracle home being worked on
#
# variables
#  String  $home        - home variable set in use (db_#)
#  String  $db_info     - single flat fact from the $db_info_list_db_# associated to the home being worked on
#  String  $home_path   - full path to the Oracle home
#  String  $version     - version of the base install of the Oracle home (12.2.0.1)
#  String  $patch_path  - patch version the Oracle home is supposed to be patched to in Oracle 18c version format (12_2.xx.x, 18.xx.x, ...)
#
# calls the following manifests:
#  oradb::database                   - builds a database
#  oradb_fs::new_db_post_patch_tree  - runs post database build scripts. largely a hold over from 11g, but still may be needed
#  oradb::dbactions                  - starts and stops the database being built
#  oradb_fs::autostart               - sets the autostart flag to Y in /etc/oratab for the database being built
#  oradb_fs::user_role_post_build    - runs post database build scripts to create required users and roles
#  oradb_fs::sig_file                - creation of sig file required from creating a new database
#  oradb_fs::db_security             - deploys security package set into the database and configures the databases based information
#                                      in the flat fact for this database
#
####
define oradb_fs::build_db (
 String  $home        = undef,
 String  $db_info     = undef,
 String  $home_path   = undef,
 String  $version     = undef,
 String  $patch_path  = undef,
)
{
 $db_info_function_feed = any2array(split($db_info,':')[0])

 $oratab_entries = $facts['home_associated_db_list']
 $ps_entries = $facts['home_associated_running_db_list']
 $delete_entries = $facts['home_associated_delete_db_list']

 if $oratab_entries == [''] {
  $oratab_all = ['']
 }
 else {
  $oratab_all = flatten($oratab_entries.map | String $oratab_info | { split($oratab_info, ':') })
 }

 if $ps_entries == [''] {
  $ps_all = ['']
 }
 else {
  $ps_all = flatten($ps_entries.map | $ps_info | { split($ps_info, ':') })
 }

 $delete_home = return_sid_list($delete_entries, $home, $home_path)

 $sid_in_oratab = compare_arrays($oratab_all, $db_info_function_feed)
 $sid_in_running_ps = compare_arrays($ps_all, $db_info_function_feed)
 $sid_in_db_list = compare_arrays($delete_home, $db_info_function_feed)

 if $sid_in_oratab == 'B' or $sid_in_oratab == 'C' or $sid_in_oratab == 'P' or $sid_in_oratab == 'T'{
 }
 else { #elsif sid_in_oratab = 'S' or sid_in_oratab = 'F' {
  if $sid_in_running_ps == 'B' or $sid_in_running_ps == 'C' or $sid_in_running_ps == 'P' or $sid_in_running_ps == 'T' {
  }
  else { #elsif sid_in_running_ps == 'S' or sid_in_running_ps == 'F' {
   if $sid_in_db_list == 'B' or $sid_in_db_list == 'C' {
   }
   elsif $sid_in_db_list == 'T' or $sid_in_db_list == 'P' {
    fail("Yaml file build list is fully or partially contained in delete list for home: ${home}")
   }
   else { #elsif $sid_in_db_list == 'S' or $sid_in_db_list == 'F'{
    $version_holding = split($version,'[.]')
    $version_compressed = regsubst($version, '\.', '', 'G')

    $db_info_holding = split($db_info, ':')
    $db_name = downcase($db_info_holding[0])
    $db_size = $db_info_holding[1]
    $db_data_fra = $db_info_holding[2]
    $db_security_options = $db_info_holding[3]

    $template_name = "FS_SI_v${version_compressed}_Puppet_${db_size}"

    $container_database = "${version_holding[0]}.${version_holding[1]}" ? {
     '12.2'    => false,
     default   => false,
    }

    $nls_param = "${version_holding[0]}.${version_holding[1]}" ? {
     '12.2'   => 'AL32UTF8',
     default  => $facts['oradb_fs::national_character_set'],
    }

    $short_home_path = split($home_path,'/')[-1]

    $patch_path_holding = split($patch_path,'[.]')

    if $patch_path_holding[1] == '0' and $patch_path_holding[2] == '0' {
     $db_patch_num = '0'
     $ojvm_patch_num = '0'
    }
    else {
     $patch_path_ru = $patch_path_holding[1] + $patch_path_holding[2]
     $patch_path_adjusted = "${patch_path_holding[0]}.${patch_path_ru}.0"
     $patch_path_lookup_db = regsubst($patch_path, '[.]', '_', 'G')
     $patch_path_lookup_other = "${patch_path_holding[0]}_${patch_path_ru}_0"

     $db_patch_num_holding = split($facts["oradb_fs::${patch_path_lookup_db}::db_patch_file"],'_')[0]
     $db_patch_num = inline_template( '<%= @db_patch_num_holding[1..-1] %>' )
     $ojvm_patch_num_holding = split($facts["oradb_fs::${patch_path_lookup_other}::ojvm_patch_file"],'_')[0]
     $ojvm_patch_num = inline_template( '<%= @ojvm_patch_num_holding[1..-1] %>' )
    }
    oradb::database{ "Db_Create_${home}_${db_name}" :
     oracle_base               => '/opt/oracle',
     oracle_home               => $home_path,
     version                   => "${version_holding[0]}.${version_holding[1]}",
     user                      => 'oracle',
     group                     => 'dba',
     download_dir              => "/opt/oracle/sw/working_dir/${home}",
     action                    => 'create',
     template                  => $template_name,
     db_name                   => $db_name,
     db_domain                 => $facts['networking']['domain'],
     db_port                   => $facts["oradb::db_port_${home}"],
     sys_password              => $facts['oradb_fs::ora_db_passwords'],
     system_password           => $facts['oradb_fs::ora_db_passwords'],
     asm_snmp_password         => $facts['oradb_fs::ora_db_passwords'],
     db_snmp_password          => $facts['oradb_fs::ora_db_passwords'],
     data_file_destination     => "/opt/oracle/oradata/data${db_data_fra}",
     recovery_area_destination => "/opt/oracle/oradata/fra${db_data_fra}",
     character_set             => $facts['oradb_fs::character_set'],
     nationalcharacter_set     => $nls_param,
     sample_schema             => 'FALSE',
     memory_percentage         => 40,
     memory_total              => 800,
     database_type             => $facts['oradb_fs::database_type'],
     em_configuration          => 'NONE',
     storage_type              => 'FS',
     puppet_download_mnt_point => 'oradb',  #'/nfsroot/work/sysinfra/oracle/automedia/12102',
     container_database        => $container_database,
    }
    -> oradb_fs::new_db_post_patch_tree { "Post DB build patch apply : ${home} : ${db_name}" :
     home          => $home,
     home_path     => $home_path,
     db_name       => $db_name,
     short_version => "${version_holding[0]}.${version_holding[1]}",
    }
    -> oradb::dbactions{ "${home}: ensure new DB is started : ${db_name}":
     oracle_home => $home_path,
     user        => 'oracle',
     group       => 'dba',
     action      => 'start',
     db_name     => $db_name,
    }
    -> oradb_fs::autostart{"set db autostart: ${db_name}" :
     db_name     => $db_name,
     oracle_home => $home_path,
    }
    -> oradb_fs::sig_file{ "SI DB Signature file: ${db_name}" :
     product       => 'Oracle Database' ,
     sig_version   => $version,
     type          => 'DB Creation',
     sig_desc      => "${version} DB Creation of ${db_name} using ${home_path}",
     oracle_home   => $home_path,
     global_name   => "${db_name}.${facts['networking']['domain']}",
     sig_file_name => "db12c_create_${db_name}_${short_home_path}",
    }
    -> oradb_fs::db_security { "Call to configure security settings: ${db_name}" :
     db_name             => $db_name,
     working_dir         => "/opt/oracle/sw/working_dir/${home}",
     home                => $home,
     home_path           => $home_path,
     db_security_options => $db_security_options,
    }
   }
  }
 }
}

