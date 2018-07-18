connect / as sysdba
set echo on

select DIRECTORY_PATH from dba_directories where DIRECTORY_NAME = 'DATA_PUMP_DIR'; 
exit;
