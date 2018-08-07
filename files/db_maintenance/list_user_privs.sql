--*************************************************************
--** Modified to handle both original architecture and Puppet
--** delivered security architecture
--** Matthew Parker
--** June 11, 2018
--*************************************************************


CONNECT / AS SYSDBA
SET VERIFY off 
SET LINESIZE 250 
SET PAGESIZE 49999 
SET TRIM on 
SET TRIMSPOOL on 
SET FEEDBACK off 
SET HEAD on 
SET PAUSE off
PROMPT
PROMPT "List profiles with dba, resource privileges."
PROMPT
BREAK ON grantee
COL grantee      FORMAT a30  HEAD 'GRANTEE'   		JUSTIFY LEFT
COL granted_role FORMAT a15  HEAD 'ROLE'    		JUSTIFY LEFT
COL admin_option FORMAT a3   HEAD 'ADMIN OPTION'   	JUSTIFY LEFT

SELECT grantee, granted_role, admin_option
  FROM dba_role_privs
 WHERE granted_role in ('RESOURCE','DBA', 'FS_CREATE')
   AND grantee not in ('SYSTEM',
                       'SYS',
		       'SYSMAN',
		       'APPQOSSYS',
		       'SYSMAN_APM',
		       'SYSMAN_BIPLATFORM',
		       'AUDSYS',
		       'CTXSYS',
		       'DIP',
                       'GSMADMIN_INTERNAL',
                       'GSMCATUSER',
                       'GSMUSER',
                       'LOGSTDBY_ADMINISTRATOR',
                       'MDSYS',
                       'OJVMSYS',
                       'ORACLE_OCM',
                       'ORDDATA',
                       'ORDPLUGINS',
                       'ORDSYS',
                       'OUTLN',
                       'SI_INFORMTN_SCHEMA',
		       'SYSBACKUP',
                       'SYSDG',
                       'SYSKM',
                       'WMSYS',
                       'XDB',
                       'FSDBA',
                       'FS_DBA_ROLE',
                       'FS_RESOURCE_ROLE',
                       'XS$NULL')
ORDER BY grantee;
PROMPT
PROMPT "List profiles with sysdba, sysoper, or sysasm privileges."
PROMPT
BREAK ON username
COL username      FORMAT a30  HEAD 'USERNAME'    JUSTIFY LEFT
COL sysdba        FORMAT a10  HEAD 'SYSDBA'      JUSTIFY LEFT
COL sysoper	  FORMAT a10  HEAD 'SYSOPER'     JUSTIFY LEFT
COL sysasm        FORMAT a10  HEAD 'SYSASM'      JUSTIFY LEFT

SELECT * 
  FROM v$pwfile_users 
 WHERE username not in (
                        'SYS',
                        'SYSBACKUP',
			'SYSDG',
			'SYSKM')
ORDER BY username; 
PROMPT

exit;


