connect / as sysdba

declare

 CURSOR c1 IS
  SELECT (column_value).getstringval() tabs
  FROM xmltable('"DBA_CONSTRAINTS", "DBA_DIRECTORIES", "DBA_ROLE_PRIVS", "DBA_SYS_PRIVS",
                 "V_$PARAMETER", "V_$SPPARAMETER", "DBA_OBJECTS", "DBA_PROFILES",
                 "V_$PWFILE_USERS", "DBA_ROLES", "ROLE_ROLE_PRIVS", "ROLE_SYS_PRIVS",
                 "DBA_SYNONYMS", "DBA_TAB_COMMENTS", "DBA_TABLESPACES", "DBA_TAB_PRIVS",
                 "DBA_TRIGGERS", "DBA_TS_QUOTAS", "DBA_USERS", "DBA_REGISTRY",
                 "V_$INSTANCE", "DBA_FREE_SPACE", "DBA_DATA_FILES", "DBA_ROLE_PRIVS",
                 "ROLE_ROLE_PRIVS", "ROLE_TAB_PRIVS", "SESSION_ROLES", "USER_ROLE_PRIVS",
                 "DBA_JOBS", "DBA_RGROUP", "DBA_SNAPSHOTS", "V_$LOCKED_OBJECT",
                 "DBA_SEQUENCES", "V_$PARAMETER", "DBA_CONSTRAINTS", "V_$DATABASE",
                 "V_$SESSION", "DBA_REGISTRY"');

 lv_count number;
 lv_text varchar2(200);

begin

 select count(*) into lv_count from dba_users where username = 'FS_DB_ADMIN';

 if lv_count = 0 then

  select count(*) into lv_count from dba_tablespaces where tablespace_name='FS_DB_ADMIN_DATA';

  if lv_count = 0 then

   execute immediate 'create smallfile tablespace fs_db_admin_data ' ||
                     'DATAFILE SIZE 5M AUTOEXTEND ON NEXT 100M MAXSIZE 32767M LOGGING EXTENT MANAGEMENT LOCAL ' ||
                     'segment space management auto';

  end if;

  execute immediate 'create user fs_db_admin ' ||
                    'identified by "temporary_pw_2_use_4_install" ' ||
                    'default tablespace fs_db_admin_data ' ||
                    'temporary tablespace temp ' ||
#                    'profile fs_owner_profile ' ||
                    'password expire ' ||
                    'account lock';


 end if;

 select count(*) into lv_count from dba_users where username = 'FS_DB_ADMIN';

 if lv_count = 1 then

  execute immediate 'alter user fs_db_admin quota unlimited on fs_db_admin_data';
  execute immediate 'grant execute on dbms_qopatch to fs_db_admin';
  execute immediate 'grant select any dictionary to fs_db_admin';
  execute immediate 'grant drop any table to fs_db_admin';
  execute immediate 'grant grant any object privilege to fs_db_admin';
  execute immediate 'grant grant any privilege to fs_db_admin';
  execute immediate 'grant grant any role to fs_db_admin';
  execute immediate 'grant create user to fs_db_admin';
  execute immediate 'grant alter user to fs_db_admin';
  execute immediate 'grant drop user to fs_db_admin';
  execute immediate 'grant analyze any to fs_db_admin';
  execute immediate 'grant alter any index to fs_db_admin';
 
  execute immediate 'grant inherit privileges on user sys to fs_db_admin';
  execute immediate 'grant inherit privileges on user sys to fsdba';
  execute immediate 'grant execute on SYS.DBMS_QOPATCH to fs_db_admin';

  select count(*) into lv_count from dba_tab_privs
  where privilege = 'SELECT' 
  and table_name in ('DBA_CONSTRAINTS', 'DBA_DIRECTORIES', 'DBA_ROLE_PRIVS', 'DBA_SYS_PRIVS',
                     'V_$PARAMETER', 'V_$SPPARAMETER', 'DBA_OBJECTS', 'DBA_PROFILES',
                     'V_$PWFILE_USERS', 'DBA_ROLES', 'ROLE_ROLE_PRIVS', 'ROLE_SYS_PRIVS',
                     'DBA_SYNONYMS', 'DBA_TAB_COMMENTS', 'DBA_TABLESPACES', 'DBA_TAB_PRIVS',
                     'DBA_TRIGGERS', 'DBA_TS_QUOTAS', 'DBA_USERS', 'DBA_REGISTRY',
                     'V_$INSTANCE', 'DBA_FREE_SPACE', 'DBA_DATA_FILES', 'DBA_ROLE_PRIVS',
                     'ROLE_ROLE_PRIVS', 'ROLE_TAB_PRIVS', 'SESSION_ROLES', 'USER_ROLE_PRIVS',
                     'DBA_JOBS', 'DBA_RGROUP', 'DBA_SNAPSHOTS', 'V_$LOCKED_OBJECT',
                     'DBA_SEQUENCES', 'V_$PARAMETER', 'DBA_CONSTRAINTS', 'V_$DATABASE',
                     'V_$SESSION', 'DBA_REGISTRY');

  if lv_count < 32 then 

   FOR c1_rec IN c1 LOOP

    lv_text := 'grant select on ' || c1_rec.tabs || ' to fs_db_admin';
    execute immediate lv_text;

   END LOOP;
 
  end if;

 end if;

end;
/

exit
