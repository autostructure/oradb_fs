connect /  as sysdba
SET SERVEROUTPUT ON
SET LINESIZE 300
SET PAGESIZE 10000
SET FEEDBACK OFF
SET ECHO OFF
SET FEED OFF
SET VERIFY OFF
SET HEADING OFF
SET TRIMSPOOL ON

VARIABLE db_patch_info VARCHAR2(60);

DECLARE

cursor c1 is
 select patchnum, rownum
 from opatch_inst_patch;

BEGIN

  BEGIN

    for c1_rec in c1 loop
      if c1_rec.rownum = 1 then
        :db_patch_info:= c1_rec.patchnum ;
      else
        :db_patch_info:= :db_patch_info || ':' || c1_rec.patchnum ;
      end if;
    end loop;

    EXCEPTION
      WHEN OTHERS THEN
        null;

  END;

END;
/
    SET TERMOUT OFF
    spool &1

    SELECT :db_patch_info from dual;

    spool off;

exit;


