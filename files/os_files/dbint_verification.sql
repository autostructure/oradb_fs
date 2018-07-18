--
--****************************************************************************************************
--****************************************************************************************************
--** File   : /usr/local/bin/dbint_verifications.sql
--** Author : matthewparker
--** Date   : June 1, 2018
--** Version: Oracle Platform Puppet Module 2.0
--** Purpose: This is the database sql file for verifying the Oracle Platform
--**          puppet module's database internal configuration.
--** Command: This file is not run directly by users.
--**          The /usr/local/bin/puppet_ora_verify.sh script calls this script by
--**          /usr/local/bin/sql/dbint_verification.sql $1 $2 $3 $4 $5 $6 $7 $8 $9 $10 $11 $12 $13
--**          $1 is the template size used for the db, e.g., small_8k
--**          $2 is the database SID
--**          $3 is the domain name of the server (hostname -d)
--**          $4 is the DATA mount path for the database 
--**          $5 is the FRA mount path for the database
--**          $6 is the value of $ORACLE_BASE, e.g., '/opt/oracle'
--**          $7 is the first security parameter of the fs_security_pkg.secure_database procedure
--**          $8 is the second security parameter of the fs_security_pkg.secure_database procedure
--**          $9 is the third security parameter of the fs_security_pkg.secure_database procedure
--**          $10 is the fourth security parameter of the fs_security_pkg.secure_database procedure
--**          $11 is the fifth security parameter of the fs_security_pkg.secure_database procedure
--**          $12 is the sixth security parameter of the fs_security_pkg.secure_database procedure
--**          $13 is the sixth security parameter of the fs_security_pkg.secure_database procedure
--**          $14 is the fully pathed /tmp output file where pass/fail counts will be stored
--****************************************************************************************************
--****************************************************************************************************
--

connect /  as sysdba

 SET SERVEROUTPUT ON SIZE 1000000
 SET LINESIZE 300
 SET PAGESIZE 10000
 SET FEEDBACK OFF
 SET ECHO OFF
 SET FEED OFF
 SET VERIFY OFF
 SET HEADING OFF
 SET TRIMSPOOL ON
 
 VARIABLE db_pass NUMBER;
 VARIABLE db_fail NUMBER;
 
 exec fs_db_admin.fs_puppet_structures.set_i_am_automation(true);
 set serveroutput on size 1000000   

 declare 
  l_dbstructurepasscnt  NUMBER := 0;
  l_dbstructurefailcnt  NUMBER := 0;
  l_passcnt       NUMBER := 0;
  l_failcnt       NUMBER := 0;
  l_status        VARCHAR2(12);
  l_errormessage  CLOB;
  l_count         NUMBER;
  l_name          VARCHAR2(30);
 BEGIN

  :db_pass := 0;
  :db_fail := 0;

  select count(*) into l_count
  from dba_users
  where username='FS_DB_ADMIN';

  if l_count = 1 then
   execute immediate 'grant select any dictionary to fs_db_admin';

   fs_db_admin.fs_puppet_structures.fs_verify_structures ('&1','&2', '&3', '&4', '&5', '&6',l_dbstructurepasscnt, l_dbstructurefailcnt, '-1');

   :db_pass := :db_pass + l_dbstructurepasscnt;
   :db_fail := :db_fail + l_dbstructurefailcnt;

   fs_db_admin.fs_security_pkg.secure_database ('&7','&8','&9','&10','&11','&12','&13',l_passcnt, l_failcnt, l_status, l_errormessage, '-1');

   :db_pass := :db_pass + l_passcnt;
   :db_fail := :db_fail + l_failcnt;
  else
   dbms_output.put_line('FS_DB_ADMIN user does not exist in ' || l_name || '. Please run security remediation for this DB.');
  end if;

 end;
 /

 SET TERMOUT OFF
 spool &14

 SELECT :db_pass || ':' || :db_fail from dual;

 spool off;

exit;


