connect / as sysdba

declare
--
--
--**************************************************************************************************************************
--**   Procedure Name:	Anonymous Block
--**      Application:	Puppet STIG Implementation
--**           Schema:	sys
--**          Authors:	Matthew Parker, Oracle Puppet SME 
--**          Comment:	This anonymous block bootstraps the fs_db_admin user.
--**************************************************************************************************************************
--**************************************************************************************************************************
--**  Calling Programs:	External
--**   Programs Called: --
--**   Tables Accessed: dba_users
--**			dba_tablespaces
--**			dba_tab_privs
--**   Tables Modified:	--
--**  Passed Variables: --
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: --
--**			l_sqltext			dynamic SQL
--**			l_count				Count variable for existence
--**           Cursors:
--**			C1				Table access privileges to be granted to fs_db_admin.
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Loop c1 cursor and grant minimum privileges to fs_db_admin.
--**			
--**************************************************************************************************************************
--
--
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

 lv_count NUMBER;
 lv_text VARCHAR2(200);

BEGIN
 --
 SELECT count(*) INTO lv_count FROM dba_users WHERE username = 'FS_DB_ADMIN';
 --
 IF lv_count = 0 THEN
   --
   SELECT count(*) INTO lv_count FROM dba_tablespaces WHERE tablespace_name='FS_DB_ADMIN_DATA';
   --
   IF lv_count = 0 THEN
     --
     EXECUTE IMMEDIATE 'CREATE SMALLFILE TABLESPACE fs_db_admin_data ' ||
                     'DATAFILE SIZE 5M AUTOEXTEND ON NEXT 100M MAXSIZE 32767M LOGGING EXTENT MANAGEMENT LOCAL ' ||
                     'SEGMENT SPACE MANAGEMENT AUTO';
     --
   END IF;
   --
   EXECUTE IMMEDIATE 'CREATE USER fs_db_admin ' ||
                    'IDENTIFIED BY "temporary_pw_2_use_4_install" ' ||
                    'DEFAULT TABLESPACE fs_db_admin_data ' ||
                    'TEMPORARY TABLESPACE temp ' ||
                    'PASSWORD EXPIRE ' ||
                    'ACCOUNT LOCK';
   --
 END IF;
 --
 SELECT count(*) INTO lv_count FROM dba_users WHERE username = 'FS_DB_ADMIN';
 --
 IF lv_count = 1 THEN
   --
   EXECUTE IMMEDIATE 'ALTER USER fs_db_admin QUOTA UNLIMITED ON fs_db_admin_data';
   EXECUTE IMMEDIATE 'GRANT EXECUTE ON dbms_qopatch TO fs_db_admin';
   EXECUTE IMMEDIATE 'GRANT SELECT ANY DICTIONARY TO fs_db_admin';
   EXECUTE IMMEDIATE 'GRANT DROP ANY TABLE TO fs_db_admin';
   EXECUTE IMMEDIATE 'GRANT GRANT ANY OBJECT privilege TO fs_db_admin';
   EXECUTE IMMEDIATE 'GRANT GRANT ANY PRIVILEGE TO fs_db_admin';
   EXECUTE IMMEDIATE 'GRANT GRANT ANY ROLE TO fs_db_admin';
   EXECUTE IMMEDIATE 'GRANT CREATE USER TO fs_db_admin';
   EXECUTE IMMEDIATE 'GRANT ALTER USER TO fs_db_admin';
   EXECUTE IMMEDIATE 'GRANT DROP USER TO fs_db_admin';
   EXECUTE IMMEDIATE 'GRANT ANALYZE ANY TO fs_db_admin';
   EXECUTE IMMEDIATE 'GRANT ALTER ANY INDEX TO fs_db_admin';
   --
   EXECUTE IMMEDIATE 'GRANT INHERIT PRIVILEGES ON USER sys TO fs_db_admin';
   EXECUTE IMMEDIATE 'GRANT INHERIT PRIVILEGES ON USER sys TO fsdba';
   EXECUTE IMMEDIATE 'GRANT EXECUTE ON sys.dbms_qopatch TO fs_db_admin';
   --
   SELECT count(*) INTO lv_count FROM dba_tab_privs
   WHERE privilege = 'SELECT' 
   AND table_name IN ('DBA_CONSTRAINTS', 'DBA_DIRECTORIES', 'DBA_ROLE_PRIVS', 'DBA_SYS_PRIVS',
                     'V_$PARAMETER', 'V_$SPPARAMETER', 'DBA_OBJECTS', 'DBA_PROFILES',
                     'V_$PWFILE_USERS', 'DBA_ROLES', 'ROLE_ROLE_PRIVS', 'ROLE_SYS_PRIVS',
                     'DBA_SYNONYMS', 'DBA_TAB_COMMENTS', 'DBA_TABLESPACES', 'DBA_TAB_PRIVS',
                     'DBA_TRIGGERS', 'DBA_TS_QUOTAS', 'DBA_USERS', 'DBA_REGISTRY',
                     'V_$INSTANCE', 'DBA_FREE_SPACE', 'DBA_DATA_FILES', 'DBA_ROLE_PRIVS',
                     'ROLE_ROLE_PRIVS', 'ROLE_TAB_PRIVS', 'SESSION_ROLES', 'USER_ROLE_PRIVS',
                     'DBA_JOBS', 'DBA_RGROUP', 'DBA_SNAPSHOTS', 'V_$LOCKED_OBJECT',
                     'DBA_SEQUENCES', 'V_$PARAMETER', 'DBA_CONSTRAINTS', 'V_$DATABASE',
                     'V_$SESSION', 'DBA_REGISTRY');
   --
   IF lv_count < 32 THEN 
     --
     FOR c1_rec IN c1 LOOP
       --
       lv_text := 'GRANT SELECT ON ' || c1_rec.tabs || ' TO fs_db_admin';
       EXECUTE IMMEDIATE lv_text;
       --
     END LOOP;
     --
   END IF;
   --
 END IF;

END;
/

EXIT

