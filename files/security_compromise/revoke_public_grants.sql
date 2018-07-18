connect / as sysdba

--
--
--**************************************************************************************************************************
--**         Procedure:	revoke_public_grants
--**           Purpose:	This procedure revokes the public grants associated to the db_instances scripts.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: --
--**   Tables Modified:	--
--**  Passed Variables: --
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: --
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			
--**			
--**************************************************************************************************************************
--
--
CREATE OR REPLACE PROCEDURE fs_db_admin.revoke_public_grants
AUTHID CURRENT_USER
AS
 CURSOR c1 IS
	SELECT (column_value).getstringval() tabs
	FROM xmltable('"dba_free_space","dba_data_files","dba_tablespaces","dba_roles","dba_role_privs","role_role_privs",
			"role_sys_privs","role_tab_privs","session_roles","user_role_privs","dba_jobs","dba_rgroup",
			"dba_snapshots","v_$locked_object","dba_sequences","v_$parameter","dba_constraints","v_$database",
			"v_$session"');
 --
 CURSOR c2 IS
	SELECT (column_value).getstringval() tabs
	FROM xmltable('"dbms_pipe","dbms_lock","utl_smtp"');
 --
 l_sqltext			CLOB;
 l_count			NUMBER;
BEGIN
	FOR c1_rec IN c1 LOOP
		SELECT count(*) INTO l_count
		FROM sys.dba_tab_privs
		WHERE table_name = UPPER(c1_rec.tabs)
		AND PRIVILEGE = 'SELECT'
		AND grantee = 'PUBLIC';
		--
		IF l_count > 0 THEN
			l_sqltext := 'REVOKE SELECT ON '||c1_rec.tabs||' FROM public';
			dbms_output.put_line (l_sqltext);
			execute immediate l_sqltext;
		END IF;
	END LOOP;
	--
	FOR c2_rec IN c2 LOOP
		SELECT count(*) INTO l_count
		FROM sys.dba_tab_privs
		WHERE table_name = UPPER(c2_rec.tabs)
		AND PRIVILEGE = 'EXECUTE'
		AND grantee = 'PUBLIC';
		--
		IF l_count > 0 THEN
			l_sqltext := 'REVOKE EXECUTE ON '||c2_rec.tabs||' FROM public';
			dbms_output.put_line (l_sqltext);
			execute immediate l_sqltext;
		END IF;
	END LOOP;
	--
END revoke_public_grants;
/

exit

