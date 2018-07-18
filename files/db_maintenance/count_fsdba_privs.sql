connect/ as sysdba
COL nroles    FORMAT 9999    HEAD '# of FSDBA Roles granted:'   JUSTIFY LEFT
select count(*) nroles from dba_role_privs where grantee='FSDBA';
exit;
