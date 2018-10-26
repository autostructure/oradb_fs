connect / as sysdba

declare
lv_count number;
lv_text  varchar2(4000);

begin

 select count(*) into lv_count from dba_profiles where profile='FS_SERVICE_ACCT';

 if lv_count > 0 then
  lv_text := 'alter profile fs_service_acct LIMIT ' ||
             'COMPOSITE_LIMIT                  UNLIMITED ' ||
             'SESSIONS_PER_USER                UNLIMITED ' ||
             'CPU_PER_SESSION                  UNLIMITED ' ||
             'CPU_PER_CALL                     UNLIMITED ' ||
             'LOGICAL_READS_PER_SESSION        UNLIMITED ' ||
             'LOGICAL_READS_PER_CALL           UNLIMITED ' ||
             'IDLE_TIME                        UNLIMITED ' ||
             'CONNECT_TIME                     UNLIMITED ' ||
             'PRIVATE_SGA                      UNLIMITED ' ||
             'FAILED_LOGIN_ATTEMPTS            10 ' ||
             'PASSWORD_LIFE_TIME               UNLIMITED ' ||
             'PASSWORD_REUSE_TIME              UNLIMITED ' ||
             'PASSWORD_REUSE_MAX               UNLIMITED ' ||
             'PASSWORD_VERIFY_FUNCTION         NULL ' ||
             'PASSWORD_LOCK_TIME               1 ' ||
             'PASSWORD_GRACE_TIME              7';
  execute immediate lv_text;
 elsif lv_count = 0 then
  lv_text := 'create profile fs_service_acct LIMIT ' ||
             'COMPOSITE_LIMIT                  UNLIMITED ' ||
             'SESSIONS_PER_USER                UNLIMITED ' ||
             'CPU_PER_SESSION                  UNLIMITED ' ||
             'CPU_PER_CALL                     UNLIMITED ' ||
             'LOGICAL_READS_PER_SESSION        UNLIMITED ' ||
             'LOGICAL_READS_PER_CALL           UNLIMITED ' ||
             'IDLE_TIME                        UNLIMITED ' ||
             'CONNECT_TIME                     UNLIMITED ' ||
             'PRIVATE_SGA                      UNLIMITED ' ||
             'FAILED_LOGIN_ATTEMPTS            10 ' ||
             'PASSWORD_LIFE_TIME               UNLIMITED ' ||
             'PASSWORD_REUSE_TIME              UNLIMITED ' ||
             'PASSWORD_REUSE_MAX               UNLIMITED ' ||
             'PASSWORD_VERIFY_FUNCTION         NULL ' ||
             'PASSWORD_LOCK_TIME               1 ' ||
             'PASSWORD_GRACE_TIME              7';
  execute immediate lv_text;
 end if;

end;
/

exit

