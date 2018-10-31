####
# oradb_fs::configure_rman
#  author: Matthew Parker
#
# Configures RMAN for the client side server and DBs.
#  Puts DBs from $sid_list into archivelog mode
#  Registers DBs from $sid_list with both RMAN repos
#  Unregisters DBs from the sid_exclude_list fact from both RMAN repos if they are associated to the home being worked on
#
# variables
#  String        $home         - home variable set in use (db_#)
#  String        $home_path    - full path to the Oracle home
#  Array[String] $db_info_list - flat fact array of database information
#  Array[String] $sid_list     - array from the rman_setup_list fact
#
# deploys:
#  /home/oracle/system/rman/${script} - see $scripts for full list
#  /home/oracle/system/rman/rman_parameters.sh
#
# creates:
#  /home/oracle/system/rman/admin.wallet/cwallet.sso     - output file from oracle mkstore command
#  /home/oracle/system/rman/admin.wallet/cwallet.sso.lck - output file from oracle mkstore command
#  /home/oracle/system/rman/admin.wallet/ewallet.p12     - output file from oracle mkstore command
#  /home/oracle/system/rman/admin.wallet/ewallet.p12.lck - output file from oracle mkstore command
#
# updates:
#  /home/oracle/system/rman/admin.wallet/tnsnames.ora - this is a softlink to tnsnames.ora in the home. Multihome servers may cause issues.
#  /home/oracle/system/rman/admin.wallet/sqlnet.ora   - this is a softlink to sqlnet.ora in the home. Multihome servers may cause issues.
#
####
define oradb_fs::configure_rman (
 String        $home         = undef,
 String        $home_path    = undef,
 Array[String] $db_info_list = undef,
 Array[String] $sid_list     = undef,
)
{

 $sid_exclude_list = $facts['sid_exclude_list'] ? {
  ''  => '',
  default => "'${facts['sid_exclude_list']}'"
 }

 $sid_exclude_list_comparable = split(regsubst($sid_exclude_list,'\'','','G'),'\|')

 $archive_mode_list = $facts['db_archive_mode_list']

 $oratab_home = return_sid_list($facts['home_associated_db_list'], $home, $home_path)
 $ps_home = return_sid_list($facts['home_associated_running_db_list'], $home, $home_path)
 $db_home = return_sid_list($db_info_list, $home, $home_path)

 $sid_list_in_oratab = compare_arrays($oratab_home, $sid_list)
 $sid_list_in_running_ps = compare_arrays($ps_home, $sid_list)
 $sid_list_in_yaml = compare_arrays($db_home, $sid_list)
 $sid_list_in_exclude = compare_arrays($sid_exclude_list_comparable, $sid_list)

 if $sid_list_in_yaml == 'B' or $sid_list_in_yaml == 'C' {
 }
 elsif $sid_list_in_yaml == 'S' or $sid_list_in_yaml == 'F' or $sid_list_in_yaml == 'P' {
  notify{"ora_db_info_list does not contain the complete sid list requested for RMAN setup: ${home}" :
   loglevel => 'err'
  }
  notify{ "sid_list_in_yaml: ${sid_list_in_yaml}":}
  notify{ "db_home: ${db_home}":}
  notify{ "sid_list: ${sid_list}":}
 }
 else { #elsif $sid_list_in_yaml == 'T' {
  if $sid_list_in_oratab == 'B' or $sid_list_in_oratab == 'C' {
  }
  elsif $sid_list_in_oratab == 'S' or $sid_list_in_oratab == 'F' or $sid_list_in_oratab == 'P' {
   notify{"/etc/oratab does not contain the complete sid list requested for RMAN setup: ${home}" :
    loglevel => 'err'
   }
  }
  else { #elsif $sid_list_in_oratab == 'T' {
   if $sid_list_in_running_ps == 'B' or $sid_list_in_running_ps == 'C' {
   }
   elsif $sid_list_in_running_ps == 'S' or $sid_list_in_running_ps == 'F' or $sid_list_in_running_ps == 'P' {
    notify{"Ps -ef does not contain the complete sid list requested for RMAN setup: ${home}" :
     loglevel => 'err'
    }
   }
   else { #elsif $sid_list_in_running_ps == 'T' {
    if $sid_list_in_exclude == 'B' or $sid_list_in_exclude == 'C' {
    }
    elsif $sid_list_in_exclude == 'T' or $sid_list_in_exclude == 'P' {
     not
    }
    else { #elsif $sid_list_in_exclude == 'S' or $sid_list_in_exclude == 'F' {

notify{"facts['hostname_ebn_exists'] : ${facts['hostname_ebn_exists']}" :}
     if $facts['libobk_so64_exists'] != 0 {
      if $facts['hostname_ebn_exists'] == 1 {
       exec {'Move libobk.so file aside if needed: ${home}' :
        command => "/bin/mv ${home_path}/lib/libobk.so ${home_path}/lib/libobk.so.orig",
        user    => 'oracle',
        creates => "${home_path}/lib/libobk.so.orig",
        onlyif  => "/bin/test -f ${home_path}/lib/libobk.so",
        unless  => "/bin/ls ${home_path}/lib/libobk.so.orig 2>/dev/null"
       }
       -> exec {'Remove libobk.so file if needed: ${home}' :
        command => "/bin/rm -f ${home_path}/lib/libobk.so",
        user    => 'oracle',
        onlyif  => "/bin/test -f ${home_path}/lib/libobk.so"
       }
       -> file { "${home_path}/lib/libobk.so" :
        ensure => 'link',
        target => '/usr/openv/netbackup/bin/libobk.so64'
       }
   
       $holding = split($facts['networking']['fqdn'],'[.]')
       $schema = "rcat_${holding[1]}_${holding[0]}"
       $input = return_simple($facts['oradb_fs::sample_value'])
       $tns_alias_list = [ 'RCAT01P', 'RCAT02P' ]
    
       $scripts = [ 'archivelog_mode.sh', 'build_SEND_cmd.sh', 'cf_snapshot_in_recovery.sh',
                    'check_recovery_space.sql', 'choose_a_sid.sh', 'choose_OH.sh',
                    'cold.rmn', 'cold.sh', 'create_catalog.rmn',
                    'create_rcat.sql', 'crosscheck_backup.sh', 'dbca.rsp',
                    'desc_all_catalogs.sh', 'ebn_oravip.sh', 'extrapolate_dbid.sh',
                    'find_asm.sh', 'fs615_allocate_disk.ora.fdc', 'fs615_allocate_disk.ora.mci',
                    'fs615_allocate_disk.ora.mci.crsrac7', 'fs615_allocate_disk.ora.phe', 'fs615_allocate_disk.ora.phe.crsdevxdb',
                    'fs615_allocate_disk.ora.prp', 'fs615_allocate_disk.ora.wrk', 'fs615_allocate_sbt.ora.fdc',
                    'fs615_allocate_sbt.ora.mci', 'fs615_allocate_sbt.ora.mci.crsrac7', 'fs615_allocate_sbt.ora.phe',
                    'fs615_allocate_sbt.ora.phe.crsdevxdb', 'fs615_allocate_sbt.ora.prp', 'fs615_allocate_sbt.ora.wrk',
                    'fs615_release_disk.ora.fdc', 'fs615_release_disk.ora.mci', 'fs615_release_disk.ora.phe',
                    'fs615_release_disk.ora.phe.crsdevxdb', 'fs615_release_disk.ora.prp', 'fs615_release_disk.ora.prp.crsrac7',
                    'fs615_release_disk.ora.wrk', 'imgcp_parameters.sh', 'imgcp.sh',
                    'insert_row1.sh', 'insert_wrong_val.sh', 'install_shield_cron.grid.sh',
                    'install_shield_cron.sh', 'local_sids.sh', 'meta_rpm_after-install.sh',
                    'meta_rpm_before-remove_4real.sh', 'meta_rpm_before-remove_wrapper.sh', 'nb_policy_fsx_oracle.txt',
                    'nid.sh', 'oracle_cron_conditional_arch_backup.sh', 'oraenv.usfs',
                    'rcat_12.2.0.sh', 'rcat_wallet.sh', 'rc_grant_all.sql',
                    'ReadMe.txt', 'report_obsolete.sh', 'repository_vote.sh',
                    'reregister_dbs.sh', 'restore_arch.rmn', 'restore_redo_2_local_disk_after_ckpt.rmn',
                    'restore_redo_2_local_disk_after_ckpt.sql', 'rman_backup.sh', 'rman_cf_scn.sh',
                    'rman_change_archivelog_all_crosscheck.sh', 'rman_change_crosscheck.sh', 'rman_change_del.sh',
                    'rman_cron_resync.sh', 'rman_delete.days.sh', 'rman_delete.DISK.krb.sh',
                    'rman_delete.sh', 
#'rman_parameters.sh', 
                    'rman_recover.sh',
                    'rman_report_need_backup.sh', 'rman_restore_cf.no_shutdown.sh', 'rman_restore_cf.sh',
                    'rman_restore_df.sh', 'rman_restore_pitr.preview.3.sh', 'rman_restore_pitr.preview.sh',
                    'rman_restore_pitr.sh', 'rman_restore_pitr_spfile_cf.sh', 'rman_restore.sh',
                    'rman_restore_tbs.sh', 'root.ebn_oravip.sh', 'rpm_post_install.sh',
                    'rpm_post_uninstall.sh', 'rpm_prereq.sh', 'select_tsm_test.sh',
                    'set_profile_rman_envars.sh', 'show_max_archived_log_scn.sh', 'tnsping_catalogs.sh',
                    'usfs_local_sids', 'usfs_local_sids_imgcp', 'vdc_prev.sh',
                    'voting_disk.sh' ]
    
       $scripts.each | $script | { 
        file { "/home/oracle/system/rman/${script}" :
         ensure => 'present',
         owner  => 'oracle',
         group  => 'oinstall',
         mode   => '0754',
         source  => "puppet:///modules/oradb_fs/rman/scripts/${script}",
        }
       }
  
       file { '/home/oracle/system/rman/rman_parameters.sh' :
        ensure => 'present',
        content => epp('oradb_fs/rman_parameters.sh.epp',
                     { 'sid_exclude_list'    => $sid_exclude_list}),
        owner  => 'oracle',
        group  => 'oinstall',
        mode   => '0754',
       }
  
       $rand_pass = random_wallet_password()
  
       file { [ '/home/oracle/system/rman' , '/home/oracle/system/rman/admin.wallet' ] :
        ensure => 'directory',
        owner  => 'oracle',
        group  => 'oinstall',
        mode   => '0644'
       }
       -> file { '/home/oracle/system/rman/admin.wallet/tnsnames.ora' :
        ensure  => 'link',
        target  => "${home_path}/network/admin/tnsnames.ora",
        replace => 'false',
       }
       -> exec { "Add tnsnames.ora entries for RMAN catalogs: ${home} : RCAT01P" :
        command => '/bin/echo "
RCAT01P =
  (DESCRIPTION =
     (ADDRESS = (PROTOCOL = TCP)(HOST = fsxopsx1470.fdc.fs.usda.gov)(PORT = 1521))
     (CONNECT_DATA =
        (SERVER = DEDICATED)
        (SERVICE_NAME = rcat01p.fdc.fs.usda.gov)
     )
  )" >> /home/oracle/system/rman/admin.wallet/tnsnames.ora',
        unless  => '/bin/grep RCAT01P /home/oracle/system/rman/admin.wallet/tnsnames.ora 2>/dev/null'
       }
       -> exec { "Add tnsnames.ora entries for RMAN catalogs: ${home} : RCAT02P" :
        command => '/bin/echo "
RCAT02P =
  (DESCRIPTION =
     (ADDRESS = (PROTOCOL = TCP)(HOST = fsxopsx1471.fdc.fs.usda.gov)(PORT = 1521))
     (CONNECT_DATA =
        (SERVER = DEDICATED)
        (SERVICE_NAME = rcat02p.fdc.fs.usda.gov)
     )
 )" >> /home/oracle/system/rman/admin.wallet/tnsnames.ora',
        unless  => '/bin/grep RCAT02P /home/oracle/system/rman/admin.wallet/tnsnames.ora 2>/dev/null'
       }
       file { '/home/oracle/system/rman/admin.wallet/sqlnet.ora' :
        ensure  => 'link',
        target  => "${home_path}/network/admin/sqlnet.ora",
        replace => 'false',
        require  => File['/home/oracle/system/rman/admin.wallet']
       }
       -> exec { "Update sqlnet.ora: ${home_path}" :
        command => '/bin/echo "WALLET_LOCATION =
      (SOURCE =
        (METHOD = FILE)
        (METHOD_DATA = (DIRECTORY = /home/oracle/system/rman/admin.wallet))
      )
SQLNET.WALLET_OVERRIDE = TRUE" >> /home/oracle/system/rman/admin.wallet/sqlnet.ora',
        unless => '/bin/grep "SQLNET.WALLET_OVERRIDE = TRUE" /home/oracle/system/rman/admin.wallet/sqlnet.ora 2>/dev/null'
       }
       -> exec { "Remove current wallet: ${home}" :
        command => "/bin/rm -f /home/oracle/system/rman/admin.wallet/cwallet.sso /home/oracle/system/rman/admin.wallet/cwallet.sso.lck /home/oracle/system/rman/admin.wallet/ewallet.p12 /home/oracle/system/rman/admin.wallet/ewallet.p12.lck",
        user    => 'oracle',
        onlyif   => '/bin/ls /home/oracle/system/rman/admin.wallet | /bin/grep wallet 2>/dev/null'
       }
       -> exec { "Create new wallet: ${home}" :
        command     => "/bin/echo '${rand_pass}\n${rand_pass}' | ${home_path}/bin/mkstore -wrl /home/oracle/system/rman/admin.wallet -create",
        user        => 'oracle',
        environment => [ 'TNS_ADMIN=/home/oracle/system/rman/admin.wallet', 'ORACLE_BASE=/opt/oracle', "ORACLE_HOME=${home_path}", "LD_LIBRARY_PATH=${home_path}/lib"],
        unless      => '/bin/ls /home/oracle/system/rman/admin.wallet | /bin/grep wallet 2>/dev/null'
       }
  
       $tns_alias_list.each | $tns_alias | {
        exec { "Add credentials to the wallet: ${home} : ${tns_alias}" :
         command     => "/bin/echo '${rand_pass}' | ${home_path}/bin/mkstore -wrl /home/oracle/system/rman/admin.wallet -createCredential ${tns_alias} ${schema} ${input}",
         user        => 'oracle',
         environment => [ 'TNS_ADMIN=/home/oracle/system/rman/admin.wallet', 'ORACLE_BASE=/opt/oracle', "ORACLE_HOME=${home_path}", "LD_LIBRARY_PATH=${home_path}/lib"],
         require     => Exec["Create new wallet: ${home}"]
        }
       }


       $db_home.each | $sid | {
        $sid_exclude_list_comparable.each | $exclude_compare | {
         if $sid == $exclude_compare {
          if $archive_mode_list["${sid}"] != 'NOARCHIVELOG' {
           file { "/opt/oracle/sw/working_dir/${home}/disable_archive_log_mode_${sid}.sql" :
            ensure => 'present',
            owner  => 'oracle',
            group  => 'oinstall',
            mode   => '0644',
            source => 'puppet:///modules/oradb_fs/rman/disable_archive_log_mode.sql'
           }
           -> exec { "Disable archive log mode: ${home} : ${sid}":
            command     => "sqlplus /nolog @/opt/oracle/sw/working_dir/${home}/disable_archive_log_mode_${sid}.sql",
            user        => 'oracle',
            path        => "${home_path}/bin",
            environment => [ 'ORACLE_BASE=/opt/oracle', "ORACLE_HOME=${home_path}", "ORACLE_SID=${sid}", "LD_LIBRARY_PATH=${home_path}/lib"]
           }
          }
          else {
           notify {"Database already has noarchivelog mode set : ${sid}" : }
          }
          $tns_alias_list.each | $tns_alias | {
           file { "/opt/oracle/sw/working_dir/${home}/${exclude_compare}_${tns_alias}_rman_unregister_cmdfile.sql" :
            ensure  => 'file',
            content => 'unregister database;',
            owner   => 'oracle',
            group   => 'oinstall',
            mode    => '0754',
           }
           file { "/opt/oracle/sw/working_dir/${home}/${exclude_compare}_${tns_alias}_test_registration.sh" :
            ensure  => 'file',
            content => epp('oradb_fs/rman_test_registration.sh.epp',
                         { 'home_path'   => $home_path,
                           'tns_alias'   => $tns_alias,
                           'rman_schema' => $schema,
                           'sid'         => $exclude_compare }),
            owner   => 'oracle',
            group   => 'oinstall',
            mode    => '0754',
           }
           file { "/opt/oracle/sw/working_dir/${home}/${exclude_compare}_${tns_alias}_rman_command_unreg.sh" :
            ensure  => 'file',
            content => epp('oradb_fs/rman_command_unreg.sh.epp',
                         { 'home_path'   => $home_path,
                           'home'        => $home,
                           'sid'         => $exclude_compare,
                           'tns_alias'   => $tns_alias }),
            owner   => 'oracle',
            group   => 'oinstall',
            mode    => '0754',
           }
           file { "/opt/oracle/sw/working_dir/${home}/${exclude_compare}_${tns_alias}_rman_unregister.sql" :
            ensure  => 'file',
            content => epp('oradb_fs/rman_unregister.sql',
                         { 'home'      => $home,
                           'sid'       => $exclude_compare,
                           'tns_alias' => $tns_alias }),
            owner   => 'oracle',
            group   => 'oinstall',
            mode    => '0754',
           }
           exec { "Unregister DB with RMAN catalog: ${exclude_compare} : ${tns_alias}" :
            command => "/opt/oracle/sw/working_dir/${home}/${exclude_compare}_${tns_alias}_rman_unregister.sql",
            require => [ File["/opt/oracle/sw/working_dir/${home}/${exclude_compare}_${tns_alias}_rman_unregister.sql"],
                         File["/opt/oracle/sw/working_dir/${home}/${exclude_compare}_${tns_alias}_test_registration.sh"],
                         File["/opt/oracle/sw/working_dir/${home}/${exclude_compare}_${tns_alias}_rman_command_unreg.sh"],
                         File["/opt/oracle/sw/working_dir/${home}/${exclude_compare}_${tns_alias}_rman_unregister_cmdfile.sql"] ]
           }
          }
         }        
        }
       }

       $sid_list.each | $sid | {
        if has_key($archive_mode_list, $sid) {
         if $archive_mode_list["${sid}"] == 'NOARCHIVELOG' {
          file { "/opt/oracle/sw/working_dir/${home}/archive_log_mode_${sid}.sql" :
           ensure => 'present',
           owner  => 'oracle',
           group  => 'oinstall',
           mode   => '0644',
           source => 'puppet:///modules/oradb_fs/rman/archive_log_mode.sql'
          }
          -> exec { "Enable archive log mode: ${home} : ${sid}":
           command     => "sqlplus /nolog @/opt/oracle/sw/working_dir/${home}/archive_log_mode_${sid}.sql",
           user        => 'oracle',
           path        => "${home_path}/bin",
           environment => [ 'ORACLE_BASE=/opt/oracle', "ORACLE_HOME=${home_path}", "ORACLE_SID=${sid}", "LD_LIBRARY_PATH=${home_path}/lib"]
          }
         }
         else {
          notify {"Database already has archivelog mode set : ${sid}" : }
         }
        }
        else {
         notify {"Datebase not currently running or issue querying v$database for log_mode: ${sid} " :
          loglevel => 'err'
         }
        }
        $tns_alias_list.each | $tns_alias | {
         file { "/opt/oracle/sw/working_dir/${home}/${sid}_${tns_alias}_rman_register_cmdfile.sql" :
          ensure  => 'file',
          content => 'register database;',
          owner   => 'oracle',
          group   => 'oinstall',
          mode    => '0754',
         }
         file { "/opt/oracle/sw/working_dir/${home}/${sid}_${tns_alias}_test_registration.sh" :
          ensure  => 'file',
          content => epp('oradb_fs/rman_test_registration.sh.epp',
                       { 'home_path'   => $home_path,
                         'tns_alias'   => $tns_alias,
                         'rman_schema' => $schema,
                         'sid'         => $sid }),
          owner   => 'oracle',
          group   => 'oinstall',
          mode    => '0754',
         }
         file { "/opt/oracle/sw/working_dir/${home}/${sid}_${tns_alias}_rman_command.sh" :
          ensure  => 'file',
          content => epp('oradb_fs/rman_command.sh.epp',
                       { 'home_path'   => $home_path,
                         'home'        => $home,
                         'sid'         => $sid,
                         'tns_alias'   => $tns_alias }),
          owner   => 'oracle',
          group   => 'oinstall',
          mode    => '0754',
         }
         file { "/opt/oracle/sw/working_dir/${home}/${sid}_${tns_alias}_rman_register.sql" :
          ensure  => 'file',
          content => epp('oradb_fs/rman_register.sql',
                       { 'home'      => $home,
                         'sid'       => $sid,
                         'tns_alias' => $tns_alias }),
          owner   => 'oracle',
          group   => 'oinstall',
          mode    => '0754',
         }
         exec { "Register DB with RMAN catalog: ${sid} : ${tns_alias}" :
          command => "/opt/oracle/sw/working_dir/${home}/${sid}_${tns_alias}_rman_register.sql",
          require => [ File["/opt/oracle/sw/working_dir/${home}/${sid}_${tns_alias}_rman_register.sql"],
                       File["/opt/oracle/sw/working_dir/${home}/${sid}_${tns_alias}_test_registration.sh"],
                       File["/opt/oracle/sw/working_dir/${home}/${sid}_${tns_alias}_rman_command.sh"],
                       File["/opt/oracle/sw/working_dir/${home}/${sid}_${tns_alias}_rman_register_cmdfile.sql"] ]
         }
        }
       }
 
       $rand_min = fqdn_rand(60)
       $rand_hour = fqdn_rand(2)
    
       $incr_hour_base = [ 5, 7, 9, 11, 13, 15, 17 ]
       $incr_hour_final = $incr_hour_base.map |$hour| { $hour + $rand_hour }
  
       cron { 'Cron entry: Conditionally archive during the day':
        command  => '/home/oracle/system/rman/oracle_cron_conditional_arch_backup.sh',
        user     => 'oracle',
        minute   => 10,
        hour     => absent,
        monthday => absent,
        month    => absent,
        weekday  => absent,
       }
   
       cron { 'Cron entry: Nightly incremental':
        command  => '/home/oracle/system/rman/rman_backup.sh -l4',
        user     => 'oracle',
        minute   => $rand_min,
        hour     => 19 + $rand_hour,
        monthday => absent,
        month    => absent,
        weekday  => [1,2,3,4,5],
       }
   
       cron { 'Cron entry: Weekend full':
        command  => '/home/oracle/system/rman/rman_backup.sh -l0',
        user     => 'oracle',
        minute   => $rand_min,
        hour     => 10 + $rand_hour,
        monthday => absent,
        month    => absent,
        weekday  => [6],
       }
   
       cron { 'Cron entry: Delete':
        command  => '/home/oracle/system/rman/rman_delete.sh',
        user     => 'oracle',
        minute   => 0,
        hour     => 16,
        monthday => absent,
        month    => absent,
        weekday  => [1],
       }
   
       cron { 'Cron entry: Delete mail messages':
        command  => ' >/var/spool/mail/oracle',
        user     => 'oracle',
        minute   => 0,
        hour     => 0,
        monthday => absent,
        month    => absent,
        weekday  => 0,
       }

       if $facts['oradb_fs::rman_bihourly_archives'] == 'true' {
        cron { 'Bihourly archives':
         command  => '/home/oracle/system/rman/rman_backup.sh -a',
         user     => 'oracle',
         minute   => $rand_min,
         hour     => $incr_hour_final,
         monthday => absent,
         month    => absent,
         weekday  => [1,2,3,4,5],
        }
       }
       else {
        cron { 'Bihourly archives':
         ensure => 'absent',
         command  => '/home/oracle/system/rman/rman_backup.sh -a',
         user     => 'oracle',
         minute   => $rand_min,
         hour     => $incr_hour_final,
         monthday => absent,
         month    => absent,
         weekday  => [1,2,3,4,5],
        }
       }
      }
      else {
       notify {"EBN network interface does not exist. Unable to configure RMAN backups on this server." :
        loglevel => 'err'
       }
       notify {"Please contact NITC helpdesk to remediate for the missing network interface. See RMAN RN for sample email." :
        loglevel => 'err'
       }
      }
     }
     else {
      notify {"/usr/openv/netbackup/bin/libobk.so64 does not exist. Unable to configure RMAN backups on this server." :
       loglevel => 'err'
      }
      notify {"Please contact NITC helpdesk to remediate for NetBackup. See RMAN RN for sample email." :
       loglevel => 'err'
      }
     }
    }
   }
  }
 }
}

