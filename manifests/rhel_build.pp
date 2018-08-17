####
# oradb_fs::rhel_build
#  author: Matthew Parker
# 
# main manifest for oradb_fs. calls all supporting manifests
#
# calls the following manifests:
#  oradb_fs::build_working_dir  - builds working directory for the home being worked on
#  oradb_fs::delete_db_loop     - removes databases specified
#  oradb_fs::delete_sw          - removed Oracle software install
#  oradb_fs::recover_sw         - recovers from a fail Oracle software install
#  oradb_fs::replace_sw         - removes an Oracle home and saves files to be moved to another home
#  oradb_fs::psu_rollback       - rollbacks patches in an Oracle home and associated databases
#  oradb_fs::recover_db         - recovers from failed database creation
#  oradb_fs::db_remediation     - performs various remediation tasks against the requested database(s)
#  oradb_fs::apply_patch        - applies patches against an Oracle home and associated databases
#  oradb_fs::build_sw           - build a new Oracle software home
#  oradb_fs::build_db_loop      - create databases
#  oradb_fs::em_agent_control   - starts and stops the em agent
#
####
define oradb_fs::rhel_build (
# String  $db_1  = $facts['puppet_run_db_1'],
# String  $db_2  = $facts['puppet_run_db_2'],
# String  $db_3  = $facts['puppet_run_db_3'],
# String  $db_4  = $facts['puppet_run_db_4'],
# String  $db_5  = $facts['puppet_run_db_5'],
# String  $db_6  = $facts['puppet_run_db_6'],
)
{
 notify {'start':}
/*
 $data = {'db_1' => $db_1, 'db_2' => $db_2,
          'db_3' => $db_3, 'db_4' => $db_5,
          'db_5' => $db_5, 'db_6' => $db_6}
*/
 $data = {'db_1' => $facts['puppet_run_db_1'], 'db_2' => $facts['puppet_run_db_2'],
          'db_3' => $facts['puppet_run_db_3'], 'db_4' => $facts['puppet_run_db_4'],
          'db_5' => $facts['puppet_run_db_5'], 'db_6' => $facts['puppet_run_db_6']}

 tidy { 'Clear puppet run temp files.' :
  path    => '/tmp',
  backup  => false,
  matches => ['puppet_run_db_[0-9]**', 'puppet_deletehome_db_[0-9]**', 
              'puppet_delete_db_[0-9]**', 'puppet_remediate_db_[0-9]**',
              'puppet_recover_db_[0-9]**', 'puppet_recoverhome_db_[0-9]**', 
              'puppet_rollback_db_[0-9]**', 'puppet_replace_db_[0-9]**'],
  recurse => 1,
  rmdirs  => false,
 }

 $agent_home = $facts['oradb_fs::agent_home'] 

 $data_values = values($data)
 $work_to_be_done = compare_arrays($data_values, ['1'])
 
 if $work_to_be_done == 'T' or $work_to_be_done == 'P' {
  $data.each |String $home, String $value| {
   notify {"${home}:before if:${value}":}
   if $value == '1' {
 
    notify {"${home}:in if":}
 
    $home_path = $facts["oradb::ora_home_${home}"]

    $patch_path = $facts["oradb::ora_patch_path_${home}"]
    $patch_path_holding = split($patch_path, '[.]')
    
    if $patch_path_holding[0] == '12_2' {
     $version = '12.2.0.1'
    }
    elsif $patch_path_holding[0] =~ /[0-9][0-9]/ {
     $version = "${patch_path_holding[0]}.0.0"
    }
    else {
     $version = 'xx.xx.x'
    }

    if $patch_path_holding[1] =~ /[0-9]?[0-9]/ {
     $ru = $patch_path_holding[1]
    }
    else {
     $ru = 'xx'
    }

    $rur = $patch_path_holding[2] ? {
     /[0-2]/ => $patch_path_holding[2],
     default => 'x'
    }

    if $version == 'xx.xx.x' or $ru == 'xx' or $ru == 'x' {
     $patch_path_final = 'xx.xx.x'
    }
    else {
     $patch_path_final = $patch_path
    }

    $db_info_list = empty($facts["oradb_fs::ora_db_info_list_${home}"]) ? {
     true     => [''],
     default  => $facts["oradb_fs::ora_db_info_list_${home}"],
    }
 
    if $patch_path_final == 'xx.xx.x' or $home_path =~ /^\/opt\/oracle\/.*\/db_x/ {
    }
    else {
     
     $expanded_db_info = $db_info_list ? {
      ['']     => ['yzzzzzzz', 'yyyyy_xxk', 'xx', 'y~y~y~y~y~y', 'xxxx' ],
      default  => flatten($db_info_list.map | String $db_info | { split($db_info, ':') }),
     }

     $default_db_info = compare_arrays($expanded_db_info, ['yzzzzzzz', 'yyxxg_xk', 'xx', 'y~y', 'xxxx' ])
 
     $default_detected = $default_db_info ? {
      'T'      => true,
      'P'      => true,
      default  => false,
     }     

     $delete_db_found = $facts['home_associated_delete_db_list'] ? {
      ['']       => [''],
      default  => return_sid_list($facts['home_associated_delete_db_list'], $home, $home_path),
     }

     $replace_home_found = $facts['replace_home_list'] ? {
      ['']       => [''],
      default  => return_home($facts['replace_home_list'], $home, $home_path, 'N'),
     }

     $delete_home_found = $facts['delete_home_list'] ? {
      ['']       => [''],
      default  => return_home($facts['oradb_fs::delete_home'], $home, $home_path, 'P'),
     }
 
     $rollback_found = $facts['rollback_psu_list'] ? {
      ['']       => [''],
      default  => return_sid_list($facts['rollback_psu_list'], $home, $home_path),
     }
  
     $home_recovery_found = $facts['recovery_home_list'] ? {
      ['']       => [''],
      default  => return_home($facts['recovery_home_list'], $home, $home_path, 'N'),
     }

     oradb_fs::build_working_dir { "Build working dirs for home: ${home}" :
      home            => $home,
      patch_path      => $patch_path,
      version         => $version,
     }
     
     if $delete_db_found != [''] {
      oradb_fs::delete_db_loop { "Delete db(s): ${home}" :
       home               => $home,
       home_path          => $home_path,
       version            => $version,
       db_list            => $db_info_list,
      }
     }
     elsif $delete_home_found != [''] {
      oradb_fs::delete_sw { "Delete home: ${home} : ${home_path}" :
       home               => $home,
       delete_home_path   => $delete_home_found[0],
      }
     }
     elsif $home_recovery_found != [''] {
      oradb_fs::recover_sw { "Recover failed sw install: ${home}" :
       home               => $home,
       home_path          => $home_path,
      }
     }
     elsif $replace_home_found != [''] {
      oradb_fs::replace_sw { "Replace sw install: ${home}" :
       home               => $home,
       home_path          => $home_path,
      }
     }
     elsif $rollback_found != [''] {
      oradb_fs::psu_rollback { "Rollback psu for home: ${home}" :
       home               => $home,
       home_path          => $home_path,
       db_list            => $db_info_list,
       version            => $version,
       patch_path_array   => $rollback_found,
       default_detected   => $default_detected,
       agent_home         => $agent_home,
      }
     }
     else {
      oradb_fs::recover_db { "Recover failed create db for home: ${home}" :
       home               => $home,
       home_path          => $home_path,
       db_info_list       => $db_info_list,
       default_detected   => $default_detected,
      } ->
      oradb_fs::sw_remediation { "Home remediation: ${home}" :
       home        => $home,
       home_path   => $home_path,
       patch_path  => $patch_path,       
       db_list     => $db_info_list,
      } ->
      oradb_fs::db_remediation { "DB remediation: ${home}" :
       home               => $home,
       home_path          => $home_path,
       db_list            => $db_info_list,
       patch_path         => $patch_path,
       version            => $version,
       default_detected   => $default_detected,
      } ->
      oradb_fs::apply_patch { "Patch non-empty home: ${home}" :
       home               => $home,
       patch_path         => $patch_path,
       home_path          => $home_path,
       db_list            => $db_info_list,
       version            => $version,
       default_detected   => $default_detected,
       agent_home         => $agent_home,
      } ->
      oradb_fs::build_sw { "Build sw : ${home}" :
       home               => $home,
       version            => $version,
       home_path          => $home_path,
       patch_path         => $patch_path,
      } ->
      oradb_fs::build_db_loop { "Build db(s): ${home}" :
       home               => $home,
       db_info_list       => $db_info_list,
       home_path          => $home_path,
       version            => $version,
       patch_path         => $patch_path,
       default_detected   => $default_detected,
      } 
     }
    }
   } 
  }
  oradb_fs::em_agent_control {'Ensure EM agent is up' :
   home                 => 'all',
   action               => 'start',
   agent_home           => $agent_home,
  }
 } 
  else { #$work_to_be_done == 'B' or $work_to_be_done == 'S' or $work_to_be_done == 'C' or $work_to_be_done == 'F' {
 }
}  
    
