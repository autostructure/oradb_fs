set head off echo off
select 'Database name: '|| (select name from v$database ) || chr(10)||
       'db_recovery_file_dest_size: '|| to_char(p.VALUE/1024/1024/1024, '999999.99') ||' GB'|| chr(10)||
       'Total space in FLASH disk group: '|| to_char(dg.TOTAL_MB/1024, '999999.99') ||' GB'|| chr(10)||
       'Free space in FLASH disk group: '|| to_char(dg.FREE_MB/1024, '999999.99') ||' GB'|| chr(10)||
       'Database size: '|| (select to_char(sum(bytes)/1024/1024/1024, '999999.99') from v$datafile) ||' GB' || chr(10)||
 (
CASE
 WHEN p.VALUE/1024/1024 >= dg.TOTAL_MB*0.99 THEN 'CHECK FAILED: db_recovery_file_dest_size parameter must be set to less than 90% of FLASH diskgroup size'
 WHEN (select sum(bytes)/1024/1024 from v$datafile) > dg.FREE_MB THEN 'CHECK FAILED: Insufficient space in FLASH diskgroup'
 WHEN (select sum(bytes)/1024/1024*1.4 from v$datafile) > dg.TOTAL_MB THEN 'CHECK FAILED: Flash recovery area size must be at least 1.4 x database size'
 WHEN (select sum(bytes)*1.4 from v$datafile) > p.VALUE THEN 'CHECK FAILED: db_recovery_file_dest_size must be at least 1.4 x database size'
 ELSE 'Flash recovery area space allocation test SUCCEEDED'
END)
 from v$parameter p, v$asm_diskgroup dg
where p.name='db_recovery_file_dest_size'
and dg.NAME = (select REPLACE(value,'+') from v$parameter  where name='db_recovery_file_dest')
/
