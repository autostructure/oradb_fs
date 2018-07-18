connect / as sysdba
set echo off
set feed off
set pagesize 100
set linesize 120

Column DB_SIZE 	 format 999,999.99

alter session set nls_date_format='DD-MON-YYYY HH24:MI' ;
break on report
compute sum of MAXSPACE on report ;
compute sum of allocated on report ;
compute sum of freespace on report ;

Column Allocated format 999,999,999
Column MaxSpace  format 999,999,999
Column FreeSpace format 999,999,999
column name 	 format a25

ttitle lef 'Datbase and Tablespace Usage (GB)' skip 2

select sysdate "Date", 
       (select sum(bytes)/1073741824 from dba_data_files) - (select sum(bytes)/1073741824 from dba_free_space) DB_SIZE from dual ;

ttitle lef 'Tablespace Storage Usage Report in GB' skip 2
select a.tablespace_name Tablespace, 
       a.MaxSpace, a.Allocated, 
       (decode(a.MaxSpace,0,null,a.MaxSpace)-a.Allocated) FreeSpace,
       round(((a.Allocated - b.freespace)/(decode(a.maxspace,0,null,a.maxspace)))*100)  UsedPercent
FROM
       (SELECT tablespace_name, 
       ROUND(SUM(bytes) / 1073741824) Allocated, 
       ROUND(SUM(maxbytes) /1073741824) MaxSpace FROM dba_data_files GROUP BY tablespace_name) a,
       (SELECT tablespace_name, 
       ROUND(SUM(bytes) / 1073741824) FreeSpace FROM dba_free_space GROUP BY tablespace_name) b
WHERE  a.tablespace_name = b.tablespace_name(+)
ORDER BY a.tablespace_name;

exit;
