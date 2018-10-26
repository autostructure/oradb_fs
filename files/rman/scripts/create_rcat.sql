--
--  @(#)fs615/db/ora/rman/linux/rh/create_rcat.sql, ora, build6_1, build6_1a,1.1:9/5/11:15:36:46
--  VERSION:  1.1
--  DATE:  9/5/11:15:36:46
--
--  (C) COPYRIGHT International Business Machines Corp. 2003, 2007
--  All Rights Reserved
--  Licensed Materials - Property of IBM
--
--  US Government Users Restricted Rights - Use, duplication or
--  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
--
-- Purpose:
--
define schema_name = &schema_name
create profile fs_service_acct LIMIT
COMPOSITE_LIMIT                  UNLIMITED
SESSIONS_PER_USER                UNLIMITED
CPU_PER_SESSION                  UNLIMITED
CPU_PER_CALL                     UNLIMITED
LOGICAL_READS_PER_SESSION        UNLIMITED
LOGICAL_READS_PER_CALL           UNLIMITED
IDLE_TIME                        UNLIMITED
CONNECT_TIME                     UNLIMITED
PRIVATE_SGA                      UNLIMITED
FAILED_LOGIN_ATTEMPTS            10
PASSWORD_LIFE_TIME               UNLIMITED
PASSWORD_REUSE_TIME              UNLIMITED
PASSWORD_REUSE_MAX               UNLIMITED
PASSWORD_VERIFY_FUNCTION         NULL
PASSWORD_LOCK_TIME               1
PASSWORD_GRACE_TIME              7;

create user &schema_name identified by &password
temporary tablespace TEMP
default tablespace USERS quota unlimited on USERS
profile fs_service_acct;

grant connect, resource, recovery_catalog_owner to &schema_name;

-- 02/08/18 -- Threw RMAN-07539, SOLUTION: Doc ID 1915561.1
@?/rdbms/admin/dbmsrmansys.sql
-- For upgrades only @?/rdbms/admin/dbmsrmanvpc.sql  &schema_name
