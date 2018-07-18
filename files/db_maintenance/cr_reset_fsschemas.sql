--*************************************************************
--** Modified to handle both oriignal architecture and Puppet
--** delivered security architecture
--** Matthew Parker
--** June 11, 2018
--*************************************************************


connect / as sysdba
--set head off feedback off verify off echo off linesize 150 pagesize 250


DECLARE
 CURSOR c1 IS
      SELECT username uname
      FROM dba_users
      WHERE username like 'FS\_%'ESCAPE'\'
      OR username IN ('FSDBA', 'FS_DB_ADMIN');
 --
 CURSOR c2 IS
      SELECT username uname 
      FROM dba_users 
      WHERE oracle_maintained = 'Y'
      AND username NOT IN ('XS$NULL', 'SYS', 'SYSTEM', 'DBSNMP')
      ORDER BY username;
 --
 l_sqltext           VARCHAR2(1024);
 l_count             NUMBER;
 l_count1            NUMBER;
 l_count2            NUMBER;
 l_status            VARCHAR2(12);
 l_errormessage      CLOB;
BEGIN
  SELECT count(*) INTO l_count
  FROM dba_users
  WHERE username = 'FS_DB_ADMIN';
  --
  SELECT count(*) INTO l_count1
  FROM dba_objects
  WHERE object_name IN ('CREATE_RPWD', 'CREATE_RPWD_LOCK')
  AND OWNER = 'FSDBA'
  AND status = 'VALID';
  --
  SELECT count(*) INTO l_count2
  FROM dba_objects
  WHERE object_name IN ('FS_SECURITY_PKG',
    'FS_PUPPET_FORMAT_OUTPUT', 'FS_EXISTS_FUNCTION')
  AND OWNER = 'FS_DB_ADMIN'
  AND status = 'VALID';
  --
  IF l_count1 = 2 THEN
    IF l_count = 1 THEN
      l_sqltext := 'BEGIN fsdba.create_rpwd('||''''||'fs_db_admin'||''''||'); END;';
      execute immediate l_sqltext;
    END IF;
    l_sqltext := 'BEGIN fsdba.create_rpwd('||''''||'fsdba'||''''||'); END;';
    execute immediate l_sqltext;
    l_sqltext := 'BEGIN fsdba.create_rpwd('||''''||'sys'||''''||'); END;';
    execute immediate l_sqltext;
    l_sqltext := 'BEGIN fsdba.create_rpwd('||''''||'system'||''''||'); END;';
    execute immediate l_sqltext;
    --
    FOR x IN c1 LOOP
      l_sqltext := 'BEGIN fsdba.create_rpwd_lock('||''''||x.uname||''''||'); END;';
      execute immediate l_sqltext;
    END LOOP;
    --
    FOR x IN c2 LOOP
      l_sqltext := 'BEGIN fsdba.create_rpwd_lock('||''''||x.uname||''''||'); END;';
      execute immediate l_sqltext;
    END LOOP;
    --
  ELSIF l_count2 = 4 AND l_count1 = 0 THEN
    l_sqltext := 'DECLARE
                  l_status            VARCHAR2(12);
                  l_errormessage      CLOB;
                  BEGIN
                    fs_db_admin.fs_security_pkg.secure_users ('||''''||'b'||''''||', l_status, l_errormessage, 0 );
                  END;';
      execute immediate l_sqltext; 

  ELSE
    RAISE_APPLICATION_ERROR(-20000, 'FSDBA Or FS_DB_ADMIN Objects Do Not Exist For This To Run.');
  END IF;
end;
/

exit;


