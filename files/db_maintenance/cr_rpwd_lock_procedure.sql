--*************************************************************
--** Modified with schema dot notation so as to not install
--** under sys
--** Matthew Parker
--** June 11, 2018
--*************************************************************

create or replace procedure fsdba.create_rpwd_lock (uname IN VARCHAR2)
authid current_user
is
  rpwd varchar2(30);
begin
  rpwd := dbms_random.string('U',1)||dbms_random.string('X',29);
  execute immediate 'alter user '||uname||' identified by "'||rpwd||'"'||' account lock';
end;
/


