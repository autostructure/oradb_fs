--
--  @(#)fs615/db/ora/rman/linux/rh/rc_grant_all.sql, ora, build6_1, build6_1a,1.1:9/5/11:15:46:32
--  VERSION:  1.1
--  DATE:  9/5/11:15:46:32
--
--  (C) COPYRIGHT International Business Machines Corp. 2003
--  All Rights Reserved
--  Licensed Materials - Property of IBM
--
--  US Government Users Restricted Rights - Use, duplication or
--  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
--
-- Purpose:
--

connect &username
set head off
set echo off
set feedback off
set termout off
set lines 160
set pages 0

spool /tmp/rc_grant_all.2.sql

select 'grant select on '||view_name||' to public;'
from user_views
where view_name like 'RC_%';

spool off
set head on
set echo on
set feedback on
set termout on
set lines 160
set pages 0
spool /tmp/rc_grant_all.2.lst
--host cat /tmp/rc_grant_all.2.sql
@/tmp/rc_grant_all.2.sql
show user
spool off

host echo "Remeber to remove /tmp/rc_grant_all.2.*"
exit
