connect / as sysdba

--**************************************************************************************************************************
--**************************************************************************************************************************
--** Begin Package Specification 
--**************************************************************************************************************************
--**************************************************************************************************************************
--
--
CREATE OR REPLACE PACKAGE fs_db_admin.fs_puppet_structures
AUTHID CURRENT_USER
AS
--
--
--**************************************************************************************************************************
--**      Package Name: fs_puppet_structures
--**       Application: OPS Puppet Verify
--**            Schema: fs_dba_admin
--**           Authors: Matthew Parker, Oracle Puppet SME 
--**           Purpose: This package contains procedures used to for verifying the Oracle Platform puppet module's database
--**			internal configurations.
--**           Command: This procedure is not run directly by users.
--**			The /usr/local/bin/puppet_ora_verify.sh script calls the external script which calls this package by
--**			/usr/local/bin/sql/dbint_verification.sql $1 $2 $p_oraplatform ${HOME_INFO[1]} $FILE_PATH $p_dbinstances
--**			$1 is the first input parameter from the outer shell script. (ex. platform)
--**			$2 is the second input parameter from the outer shell script. (ex. detail)
--**			$p_oraplatform is the oradb_fs::ora_platform variable in External Fact fqdn-servername.yaml file
--**			${HOME_INFO[1]} is the Oracle SW Home Path in External Fact fqdn-servername.yaml file
--**			$FILE_PATH is a output file from this script
--**			$db_instances is the p_dbinstances value in External Fact fqdn-servername.yaml file
--**************************************************************************************************************************
--**   Change Control:
--**	$Log: fs_db_admin.fs_puppet_structures.sql,v $
--**	Revision 2.0.6  2018/07/29 12:29:02  matthewparker
--**	
--**************************************************************************************************************************
--
--
FUNCTION select_i_am_automation 
RETURN VARCHAR2 ;
--
--
FUNCTION get_i_am_automation 
RETURN BOOLEAN ;
--
--
PROCEDURE set_i_am_automation
(
 p_automation			IN		BOOLEAN		-- Variable to determine if this is automation.
);
--
--
PROCEDURE fs_verify_structures
(
 p_dbtemplate			IN		VARCHAR2,
 p_dbname			IN		VARCHAR2,
 p_dbdomain			IN		VARCHAR2,
 p_datavol			IN		VARCHAR2,
 p_fravol			IN		VARCHAR2,
 p_orabase			IN		VARCHAR2,
 p_dbstructurepasscnt		OUT		NUMBER,
 p_dbstructurefailcnt		OUT		NUMBER,
 p_debug			IN		NUMBER
);
--
--
END fs_puppet_structures;
/
--
--
--**************************************************************************************************************************
--**************************************************************************************************************************
--** End Package Specification.
--**************************************************************************************************************************
--**************************************************************************************************************************
--
--
--
--
--
--**************************************************************************************************************************
--**************************************************************************************************************************
--** Begin Package Body.
--**************************************************************************************************************************
--**************************************************************************************************************************
--
--

CREATE OR REPLACE PACKAGE BODY fs_db_admin.fs_puppet_structures IS
--
--
--**************************************************************************************************************************
--**************************************************************************************************************************
--**
--**					GLOBAL PRIVATE PACKAGE COMPONENTS
--** 
--**************************************************************************************************************************
--**************************************************************************************************************************
--
--
--**************************************************************************************************************************
--** Private Global Variables.
--**************************************************************************************************************************
--
--
g_iamautomation			BOOLEAN		DEFAULT false;
g_programmessage		CLOB;
g_dbinstance			VARCHAR2(32);
g_orahome			VARCHAR2(128);
g_programcontext		VARCHAR2(32);
g_dbmiscpasscnt			NUMBER	:= 0;
g_dbmiscfailcnt			NUMBER	:= 0;
g_dbparamspasscnt		NUMBER	:= 0;
g_dbparamsfailcnt		NUMBER	:= 0;
g_dbfeaturespasscnt		NUMBER	:= 0;
g_dbfeaturesfailcnt		NUMBER	:= 0;
g_dbstructurespasscnt		NUMBER	:= 0;
g_dbstructuresfailcnt		NUMBER	:= 0;
g_fsverifystructurespasscnt	NUMBER	:= 0;
g_fsverifystructuresfailcnt	NUMBER	:= 0;
g_datavol			VARCHAR2(128);
g_fravol			VARCHAR2(128);
g_orabase			VARCHAR2(64);
g_dbname			VARCHAR2(16);
g_dbdomain			VARCHAR2(64);
g_debug				NUMBER;
g_dbtemplate			VARCHAR2(64);
--
--
--**************************************************************************************************************************
--** Private Global Cursors.
--**************************************************************************************************************************
--
--
--
--
--**************************************************************************************************************************
--** Private Global Types.
--**************************************************************************************************************************
--
-- 
--
--
--**************************************************************************************************************************
--** Private Global Structs.
--**************************************************************************************************************************
--
--
--
--
--**************************************************************************************************************************
--**************************************************************************************************************************
--**
--**                              	PRIVATE CLASS PROCEDURES AND FUNCTIONS
--** 
--**************************************************************************************************************************
--**************************************************************************************************************************
--
--
--**************************************************************************************************************************
--**         Procedure:	exec_ddl
--**           Purpose:	This function shows the value of the global variable g_iamautomation.
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
--**			RETURN g_iamautomation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE exec_ddl
(
 p_sqltext			IN		VARCHAR2,
 p_sqltextsecure		IN		VARCHAR2,
 p_debug			IN		VARCHAR2
)
IS
BEGIN
	IF g_iamautomation = false OR p_debug > 0 THEN
		IF p_sqltextsecure IS NULL THEN
			dbms_output.put_line(p_sqltext);
		ELSE
			dbms_output.put_line(p_sqltextsecure);
		END IF;
	END IF;
	EXECUTE IMMEDIATE (p_sqltext);
END exec_ddl;
--
--
--**************************************************************************************************************************
--**         Procedure:	activity_stream
--**           Purpose:	This procedure based on p_boolean and p_path outputs activity to the screen or output in the 
--**			g_programmessage global variable for the verify program along with calling the exec_ddl procedure
--**			for passed ddl.
--**  Calling Programs:	--
--**   Programs Called: fs_db_admin.fs_exists_functions.exec_ddl
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
--**			RETURN g_iamautomation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE activity_stream
(
 p_sqltext			IN		VARCHAR2,
 p_sqltextsecure		IN		VARCHAR2,
 p_col1text			IN		VARCHAR2,
 p_col2text			IN		VARCHAR2,
 p_boolean			IN		BOOLEAN,
 p_verifycount			IN		NUMBER,
 p_path				IN		VARCHAR2,
 p_debug			IN		NUMBER
)
IS
 l_sysprivcnt		NUMBER		:= 0;
 l_booleantext		VARCHAR2(5);
 l_pfw			VARCHAR2(7);
BEGIN
	--
	IF p_boolean = true THEN
		l_booleantext := 'true';
		l_pfw := 'PASS';
	ELSIF p_boolean = false THEN
		l_booleantext := 'false';
		l_pfw := 'FAIL';
	ELSE
		l_booleantext := 'bad~input';
	END IF;
	IF g_programcontext = 'db_params' THEN
		IF p_boolean = true THEN
			g_dbparamspasscnt := g_dbparamspasscnt+p_verifycount;
		ELSE
			g_dbparamsfailcnt := g_dbparamsfailcnt+p_verifycount;
		END IF;
	ELSIF g_programcontext = 'db_features' THEN
		IF p_boolean = true THEN
			g_dbfeaturespasscnt := g_dbfeaturespasscnt+p_verifycount;
		ELSE
			g_dbfeaturesfailcnt := g_dbfeaturesfailcnt+p_verifycount;
		END IF;
	ELSIF g_programcontext = 'db_structures' THEN
		IF p_boolean = true THEN
			g_dbstructurespasscnt := g_dbstructurespasscnt+p_verifycount;
		ELSE
			g_dbstructuresfailcnt := g_dbstructuresfailcnt+p_verifycount;
		END IF;
	ELSIF g_programcontext = 'db_misc' THEN
		IF p_boolean = true THEN
			g_dbmiscpasscnt := g_dbmiscpasscnt+p_verifycount;
		ELSE
			g_dbmiscfailcnt := g_dbmiscfailcnt+p_verifycount;
		END IF;
	ELSE
		NULL;
	END IF;
	--
	--*********************************************************
	--** p_boolean = false REQUIREING OBJECT MODIFICATION
	--** Used for message and DDL execution.
	--*********************************************************
	--
	IF p_path = 'P1' AND p_boolean = false  THEN
		--
		IF p_debug IN ( -1 ) THEN
			fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', p_col1text, p_col2text, '', l_pfw,'','','','');
		ELSE
			IF g_iamautomation = false OR p_debug > 0 THEN
     				dbms_output.put_line(p_col1text||p_col2text);
			END IF;
			--
			fs_puppet_structures.exec_ddl(p_sqltext,'', p_debug);
		END IF;
	--
	--*********************************************************
	--** p_boolean = true REQUIREING NO OBJECT MODIFICATION
	--** Used for message and NO DDL execution.
	--*********************************************************
	--
	ELSIF p_path = 'P2' AND p_boolean = true THEN
		--
		IF g_iamautomation = false OR p_debug > 0 THEN
     			dbms_output.put_line(p_col1text||p_col2text);
		END IF;
		--
		IF p_debug IN ( -1 ) THEN
			fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', p_col1text, p_col2text, '', l_pfw,'','','','');
		END IF;
	--
	--*********************************************************
	--** p_boolean = false MESSAGE ONLY NO SPEC CHANGE
	--*********************************************************
	--
	ELSIF p_path = 'P3' AND p_boolean = false  THEN
		--
		IF p_debug IN ( -1 ) THEN
			fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', p_col1text, p_col2text, '', 'WARNING','','','','');
		ELSE
			IF g_iamautomation = false OR p_debug > 0 THEN
     				dbms_output.put_line(p_col1text||p_col2text);
			END IF;
		END IF;
	--
	--*********************************************************
	--** p_boolean = true MESSAGE ONLY NO SPEC CHANGE
	--*********************************************************
	--
	ELSIF p_path = 'P4' AND p_boolean = true  THEN
		--
		IF p_debug IN ( -1 ) THEN
			fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', p_col1text, p_col2text, '', 'WARNING','','','','');
		ELSE
			IF g_iamautomation = false OR p_debug > 0 THEN
     				dbms_output.put_line(p_col1text||p_col2text);
			END IF;
		END IF;
	--
	--*********************************************************
	--** p_boolean = false MESSAGE AND SPEC CHANGE
	--*********************************************************
	--
	ELSIF p_path = 'P5' AND p_boolean = false THEN
		--
		IF g_iamautomation = false OR p_debug > 0 THEN
     			dbms_output.put_line(p_col1text||p_col2text);
		END IF;
		--
		IF p_debug IN ( -1 ) THEN
			fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', p_col1text, p_col2text, '', l_pfw,'','','','');
		END IF;
	--
	--*********************************************************
	--** p_boolean = true Header
	--*********************************************************
	--
	ELSIF p_path = 'P6' AND p_boolean = true THEN
		--
		IF g_iamautomation = false OR p_debug > 0 THEN
     			dbms_output.put_line(p_col1text||p_col2text);
		END IF;
		--
		IF p_debug IN ( -1 ) THEN
			fs_db_admin.fs_puppet_format_output.format_entries ( 'h', 'structures', '#', 'Database: '||g_dbinstance||' - Oracle Home: '||g_orahome, p_col1text, p_col2text, '','','','','');
		END IF;
	--
	--*********************************************************
	--** p_boolean = true summary
	--*********************************************************
	--
	ELSIF p_path = 'P7' AND p_boolean = true THEN
		--
		IF g_iamautomation = false OR p_debug > 0 THEN
     			dbms_output.put_line(p_col1text||p_col2text);
		END IF;
		--
		IF p_debug IN ( -1 ) THEN
			IF g_programcontext = 'db_params' THEN
				fs_db_admin.fs_puppet_format_output.format_entries ( 's1', 'structures', '#', p_col1text,
										 p_col2text, '','',g_dbparamspasscnt,g_dbparamsfailcnt,'','');
			ELSIF g_programcontext = 'db_features' THEN
				fs_db_admin.fs_puppet_format_output.format_entries ( 's1', 'structures', '#', p_col1text,
										 p_col2text, '','',g_dbfeaturespasscnt,g_dbfeaturesfailcnt,'','');
			ELSIF g_programcontext = 'db_structures' THEN
				fs_db_admin.fs_puppet_format_output.format_entries ( 's1', 'structures', '#', p_col1text,
										 p_col2text, '','',g_dbstructurespasscnt,g_dbstructuresfailcnt,'','');
			ELSIF g_programcontext = 'db_misc' THEN
				fs_db_admin.fs_puppet_format_output.format_entries ( 's1', 'structures', '#', p_col1text,
										 p_col2text, '','',g_dbmiscpasscnt,g_dbmiscfailcnt,'','');
			ELSE
				NULL;
			END IF;
		END IF;
	--
	--*********************************************************
	--** p_boolean = true summary
	--*********************************************************
	--
	ELSIF p_path = 'P8' AND p_boolean = true THEN
		--
		IF g_iamautomation = false OR p_debug > 0 THEN
     			dbms_output.put_line(p_col1text||p_col2text);
		END IF;
		--
		IF p_debug IN ( -1, -2, 1 ) THEN
			fs_db_admin.fs_puppet_format_output.format_entries ( 'm', '', '#', '', '', '', l_pfw,'','','','');
		END IF;
	--
	--*********************************************************
	--**
	--*********************************************************
	--
	ELSE
		--
		IF g_iamautomation = false OR p_debug > 0 THEN
     			dbms_output.put_line('Wrong Code PATH.');
		END IF;
		--
		IF p_debug IN ( -1, -2, 1 ) THEN
			fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', '', p_col1text, p_col2text, l_pfw,'','','','');
		END IF;
		--
	END IF;
	--
END activity_stream;
--
--
--**************************************************************************************************************************
--**         Procedure:	db_misc
--**           Purpose:	This procedure based on p_boolean and p_path outputs activity to the screen or output in the 
--**			g_programmessage global variable for the verify program along with calling the exec_ddl procedure
--**			for passed ddl.
--**  Calling Programs:	--
--**   Programs Called: fs_db_admin.fs_exists_functions.exec_ddl
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
--**			RETURN g_iamautomation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE db_misc
AS
 --
 l_localprogramname			VARCHAR2(128) := 'db_misc';
 l_programmessage			CLOB;
 l_sqltext				CLOB;
 l_count				NUMBER;
 l_boolean				BOOLEAN;
 l_hostname				VARCHAR2(128);
 l_gname				VARCHAR2(128);
 l_dbgname				VARCHAR2(128);
BEGIN
	g_programcontext := l_localprogramname;
	--
	activity_stream ( '', '', 'DETAIL', 'DB MISCELLANEOUS', true, 0, 'P6', g_debug);
	--
	
	l_dbgname := UPPER(g_dbname||'.'||g_dbdomain);
	SELECT global_name INTO l_gname
	FROM global_name;
	--
	IF l_gname = l_dbgname THEN
		--
		activity_stream ( '', '', 'GLOBAL NAME SETTING', l_dbgname||'.' , true, 1, 'P2', g_debug);
		--
	ELSE
		--
		activity_stream ( l_sqltext, '', 'GLOBAL NAME SETTING', l_dbgname||'.', false, 1, 'P1', g_debug);
		--
	END IF;
	--
	activity_stream ( '', '', '', '', true, 0, 'P8', g_debug);
	--
	activity_stream ( '', '', 'SUMMARY', 'DB MISCELLANEOUS', true, 0, 'P7', g_debug);
	--
	g_programcontext := '';
	--
END db_misc;
--
--
--**************************************************************************************************************************
--**         Procedure:	db_structures
--**           Purpose:	This procedure based on p_boolean and p_path outputs activity to the screen or output in the 
--**			g_programmessage global variable for the verify program along with calling the exec_ddl procedure
--**			for passed ddl.
--**  Calling Programs:	--
--**   Programs Called: fs_db_admin.fs_exists_functions.exec_ddl
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
--**			RETURN g_iamautomation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE db_structures
AS
 --
 --**********************************************
 --** Internal Structures
 --**********************************************
 --
 CURSOR c1 IS
	SELECT bts.base_ts, tablespace_name, block_size, status, contents, logging, extent_management, segment_space_management, bigfile
	FROM dba_tablespaces real_ts,
	(SELECT (column_value).getstringval() base_ts
		FROM xmltable('"UNDOTBS1", "SYSTEM", "TEMP","SYSAUX"')) bts
	WHERE  bts.base_ts = real_ts.tablespace_name (+)
	ORDER BY bts.base_ts;
 --
 CURSOR c2 IS
	SELECT rts.req_ts, tablespace_name, block_size, status, contents, logging, extent_management, segment_space_management, bigfile
	FROM dba_tablespaces real_ts,
	(SELECT (column_value).getstringval() req_ts
		FROM xmltable('"USERS","FS_DB_ADMIN_DATA"')) rts
	WHERE rts.req_ts = real_ts.tablespace_name (+)
	ORDER BY rts.req_ts;
 --
 CURSOR c3 IS
	SELECT group#, sum(the_val) the_sum, count(*) the_count
	FROM (
		select group#, CASE WHEN instr(member, 'fra') > 0 THEN 1  WHEN instr(member, 'data') > 0 THEN 2 ELSE -1 END the_val 
		from v$logfile)
	GROUP BY group#;
 --
 CURSOR c4 IS
	SELECT block_size, sum(the_val) the_sum, count(*) the_count
	FROM (
		SELECT block_size, CASE WHEN instr(name, 'fra') > 0 THEN 1  WHEN instr(name, 'data') > 0 THEN 2 ELSE -1 END the_val 
		FROM v$controlfile)
	GROUP BY block_size;
 --
 CURSOR c5
	(
	 l_tsname	VARCHAR2
	)
	IS
	SELECT tablespace_name, substr(file_name, instr(file_name,'/', -1)+1) file_name, autoextensible, maxbytes/1024/1024 maxbytes_mb, (increment_by*(SELECT value FROM v$parameter WHERE name = 'db_block_size'))/(1024*1024) inc_by_mb, online_status, bytes/1024/1024 the_size
	FROM dba_data_files
	WHERE tablespace_name = l_tsname
	UNION ALL
	SELECT tablespace_name, substr(file_name, instr(file_name,'/', -1)+1) file_name, autoextensible, maxbytes/1024/1024 maxbytes_mb, (increment_by*(SELECT value FROM v$parameter WHERE name = 'db_block_size'))/(1024*1024) inc_by_mb, status online_status, bytes/1024/1024 the_size
	FROM dba_temp_files
	WHERE tablespace_name = l_tsname;
 --
 CURSOR c6 IS
	SELECT rts.req_ts, tablespace_name
	FROM dba_tablespaces real_ts,
	(SELECT (column_value).getstringval() req_ts
		FROM xmltable('"HR", "OE", "PM", "SH", "IX"')) rts
	WHERE rts.req_ts = real_ts.tablespace_name (+)
	ORDER BY rts.req_ts;
 --
 l_localprogramname			VARCHAR2(128) := 'db_structures';
 l_programmessage			CLOB;
 l_sqltext				CLOB;
 l_count				NUMBER;
 l_boolean				BOOLEAN;
 l_str1					VARCHAR2(16);
 l_str2					VARCHAR2(16);
 l_blocksize				NUMBER;
BEGIN
	g_programcontext := l_localprogramname;
	--
	activity_stream ( '', '', 'DETAIL', 'DB STRUCTURES', true, 0, 'P6', g_debug);
	--
	l_str1 := substr(g_dbtemplate, instr(g_dbtemplate, '_')+1 ) ;
	l_str2 := substr(l_str1, 1, length(l_str1)-1);
	--
	FOR c1_rec IN c1 LOOP
		IF c1_rec.tablespace_name IS NULL THEN
			--
			activity_stream ( '', '', 'BASE TABLESPACE EXISTS', c1_rec.base_ts||'.' , false, 1, 'P1', g_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'BASE TABLESPACE EXISTS', c1_rec.base_ts||'.', true, 1, 'P2', g_debug);
			--
		END IF;
		--
		IF c1_rec.block_size/1024 <> l_str2 THEN
			--
			activity_stream ( '', '', 'BASE TABLESPACE BLOCK SIZE', c1_rec.base_ts||' cur: '||c1_rec.block_size/1024||'K tar: '||l_str2||'K.' , false, 1, 'P1', g_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'BASE TABLESPACE BLOCK SIZE', c1_rec.base_ts||' cur: '||c1_rec.block_size/1024||'K tar: '||l_str2||'K.', true, 1, 'P2', g_debug);
			--
		END IF;
		--
		IF c1_rec.status <> 'ONLINE' THEN
			--
			activity_stream ( '', '', 'BASE TABLESPACE STATUS', c1_rec.base_ts||' cur: '||c1_rec.status||' tar: ONLINE.' , false, 1, 'P1', g_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'BASE TABLESPACE STATUS', c1_rec.base_ts||' cur: '||c1_rec.status||' tar: ONLINE.', true, 1, 'P2', g_debug);
			--
		END IF;
		--
		IF c1_rec.tablespace_name = 'TEMP' THEN
			IF c1_rec.contents <> 'TEMPORARY' THEN
				--
				activity_stream ( '', '', 'BASE TABLESPACE CONTENTS', c1_rec.base_ts||' cur: '||c1_rec.contents||' tar: TEMPORARY.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'BASE TABLESPACE CONTENTS', c1_rec.base_ts||' cur: '||c1_rec.contents||' tar: TEMPORARY.', true, 1, 'P2', g_debug);
				--
			END IF;
		ELSIF c1_rec.tablespace_name = 'UNDOTBS1' THEN
			IF c1_rec.contents <> 'UNDO' THEN
				--
				activity_stream ( '', '', 'BASE TABLESPACE CONTENTS', c1_rec.base_ts||' cur: '||c1_rec.contents||' tar: UNDO.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'BASE TABLESPACE CONTENTS', c1_rec.base_ts||' cur: '||c1_rec.contents||' tar: UNDO.', true, 1, 'P2', g_debug);
				--
			END IF;
		ELSE
			IF c1_rec.contents <> 'PERMANENT' THEN
				--
				activity_stream ( '', '', 'BASE TABLESPACE CONTENTS', c1_rec.base_ts||' cur: '||c1_rec.contents||' tar: PERMANENT.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'BASE TABLESPACE CONTENTS', c1_rec.base_ts||' cur: '||c1_rec.contents||' tar: PERMANENT.', true, 1, 'P2', g_debug);
				--
			END IF;
		END IF;
		--
		IF c1_rec.base_ts = 'TEMP' THEN
			IF c1_rec.logging <> 'NOLOGGING' THEN
				--
				activity_stream ( '', '', 'BASE TABLESPACE LOGGING SET', c1_rec.base_ts||' cur: '||c1_rec.logging||' tar: NOLOGGING.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'BASE TABLESPACE LOGGING SET', c1_rec.base_ts||' cur: '||c1_rec.logging||' tar: NOLOGGING.', true, 1, 'P2', g_debug);
				--
			END IF;
		ELSE
			IF c1_rec.logging <> 'LOGGING' THEN
				--
				activity_stream ( '', '', 'BASE TABLESPACE LOGGING SET', c1_rec.base_ts||' cur: '||c1_rec.logging||' tar: LOGGING.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'BASE TABLESPACE LOGGING SET', c1_rec.base_ts||' cur: '||c1_rec.logging||' tar: LOGGING.', true, 1, 'P2', g_debug);
				--
			END IF;
		END IF;
		--
		IF c1_rec.base_ts IN ('SYSTEM', 'TEMP', 'UNDOTBS1') THEN
			IF c1_rec.segment_space_management <> 'MANUAL' THEN
				--
				activity_stream ( '', '', 'BASE TABLESPACE SSM', c1_rec.base_ts||' cur: '||c1_rec.segment_space_management||' tar: MANUAL.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'BASE TABLESPACE SSM', c1_rec.base_ts||' cur: '||c1_rec.segment_space_management||' tar: MANUAL.', true, 1, 'P2', g_debug);
				--
			END IF;
		ELSE
			IF c1_rec.segment_space_management <> 'AUTO' THEN
				--
				activity_stream ( '', '', 'BASE TABLESPACE SSM', c1_rec.base_ts||' cur: '||c1_rec.segment_space_management||' tar: AUTO.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'BASE TABLESPACE SSM', c1_rec.base_ts||' cur: '||c1_rec.segment_space_management||' tar: AUTO.', true, 1, 'P2', g_debug);
				--
			END IF;
		END IF;
		--
		IF c1_rec.bigfile <> 'NO' THEN
			--
			activity_stream ( '', '', 'BASE TABLESPACE NOT A BIG FILE TS', c1_rec.base_ts||' cur: '||c1_rec.bigfile||' tar: NO.' , false, 1, 'P1', g_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'BASE TABLESPACE NOT A BIG FILE TS', c1_rec.base_ts||' cur: '||c1_rec.bigfile||' tar: NO.', true, 1, 'P2', g_debug);
			--
		END IF;
		--
		FOR c5_rec IN c5 (c1_rec.base_ts) LOOP  
			IF c5_rec.autoextensible <> 'YES' THEN
				--
				activity_stream ( '', '', 'BASE TABLESPACE DATAFILE AUTO EXTENDABLE', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.autoextensible||' tar: YES.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'BASE TABLESPACE DATAFILE AUTO EXTENDABLE', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.autoextensible||' tar: YES.', true, 1, 'P2', g_debug);
				--
			END IF;
			--
			IF c5_rec.maxbytes_mb < 32767 THEN
				--
				activity_stream ( '', '', 'BASE TABLESPACE DATAFILE MAXBYTES', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.maxbytes_mb||' tar: 32767.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'BASE TABLESPACE DATAFILE MAXBYTES', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.maxbytes_mb||' tar: 32767.', true, 1, 'P2', g_debug);
				--
			END IF;
			--
			IF c5_rec.inc_by_mb <> '100' THEN
				--
				activity_stream ( '', '', 'BASE TABLESPACE DATAFILE INCRMENTED BY', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.inc_by_mb||' tar: 100.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'BASE TABLESPACE DATAFILE INCRMENTED BY', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.inc_by_mb||' tar: 100.', true, 1, 'P2', g_debug);
				--
			END IF;
			--
			IF c5_rec.tablespace_name = 'SYSTEM' THEN
				IF c5_rec.online_status <> 'SYSTEM' THEN
					--
					activity_stream ( '', '', 'BASE TABLESPACE DATAFILE ONLINE STATUS', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.online_status||' tar: SYSTEM.' , false, 1, 'P1', g_debug);
					--
				ELSE
					--
					activity_stream ( '', '', 'BASE TABLESPACE DATAFILE ONLINE STATUS', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.online_status||' tar: SYSTEM.', true, 1, 'P2', g_debug);
					--
				END IF;
			ELSE
				IF c5_rec.online_status <> 'ONLINE' THEN
					--
					activity_stream ( '', '', 'BASE TABLESPACE DATAFILE ONLINE STATUS', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.online_status||' tar: ONLINE.' , false, 1, 'P1', g_debug);
					--
				ELSE
					--
					activity_stream ( '', '', 'BASE TABLESPACE DATAFILE ONLINE STATUS', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.online_status||' tar: ONLINE.', true, 1, 'P2', g_debug);
					--
				END IF;
			END IF;
			--
			activity_stream ( '', '', 'BASE TABLESPACE DATAFILE  SIZE', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.the_size||' tar: 800.', true, 1, 'P2', g_debug);
/*
			IF c5_rec.tablespace_name = 'SYSTEM' THEN
				IF c5_rec.the_size < '800' THEN
					--
					activity_stream ( '', '', 'BASE TABLESPACE DATAFILE  SIZE', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.the_size||' tar: 800.' , false, 1, 'P1', g_debug);
					--
				ELSE
					--
					activity_stream ( '', '', 'BASE TABLESPACE DATAFILE  SIZE', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.the_size||' tar: 800.', true, 1, 'P2', g_debug);
					--
				--END IF;
			ELSIF c5_rec.tablespace_name = 'SYSAUX' THEN
				IF c5_rec.the_size < '600' THEN
					--
					activity_stream ( '', '', 'BASE TABLESPACE DATAFILE  SIZE', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.the_size||' tar: 600.' , false, 1, 'P3', g_debug);
					--
				ELSE
					--
					activity_stream ( '', '', 'BASE TABLESPACE DATAFILE  SIZE', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.the_size||' tar: 600.', true, 1, 'P2', g_debug);
					--
				END IF;
			ELSIF c5_rec.tablespace_name = 'UNDOTBS1' THEN
				IF c5_rec.the_size < '500' THEN
					--
					activity_stream ( '', '', 'BASE TABLESPACE DATAFILE  SIZE', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.the_size||' tar: 500.' , false, 1, 'P1', g_debug);
					--
				ELSE
					--
					activity_stream ( '', '', 'BASE TABLESPACE DATAFILE  SIZE', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.the_size||' tar: 500.', true, 1, 'P2', g_debug);
					--
				END IF;
			ELSIF c5_rec.tablespace_name IN ('TEMP') THEN
				IF c5_rec.the_size < '20' THEN
					--
					activity_stream ( '', '', 'BASE TABLESPACE DATAFILE  SIZE', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.the_size||' tar: 20.' , false, 1, 'P1', g_debug);
					--
				ELSE
					--
					activity_stream ( '', '', 'BASE TABLESPACE DATAFILE  SIZE', c1_rec.base_ts||':'||c5_rec.file_name||' cur: '||c5_rec.the_size||' tar: 20.', true, 1, 'P2', g_debug);
					--
				END IF;
			END IF;
			--
*/
		END LOOP;
		--
	END LOOP;
	--
	FOR c2_rec IN c2 LOOP
		IF c2_rec.tablespace_name IS NULL THEN
			--
			activity_stream ( '', '', 'REQUIRED TABLESPACES EXISTS', c2_rec.req_ts||'.' , false, 1, 'P1', g_debug);
			--
		ELSE
			--
			activity_stream ( l_sqltext, '', 'REQUIRED TABLESPACES EXISTS', c2_rec.req_ts||'.', true, 1, 'P2', g_debug);
			--
		END IF;
		--
		IF c2_rec.status <> 'ONLINE' THEN
			--
			activity_stream ( '', '', 'REQUIRED TABLESPACES STATUS', c2_rec.req_ts||' cur: '||c2_rec.status||' tar: ONLINE.' , false, 1, 'P1', g_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'REQUIRED TABLESPACES STATUS', c2_rec.req_ts||' cur: '||c2_rec.status||' tar: ONLINE.', true, 1, 'P2', g_debug);
			--
		END IF;
		--
		IF c2_rec.contents <> 'PERMANENT' THEN
			--
			activity_stream ( '', '', 'REQUIRED TABLESPACES CONTENTS SET', c2_rec.req_ts||' cur: '||c2_rec.contents||' tar: PERMANENT.' , false, 1, 'P1', g_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'REQUIRED TABLESPACES CONTENTS SET', c2_rec.req_ts||' cur: '||c2_rec.contents||' tar: PERMANENT.', true, 1, 'P2', g_debug);
			--
		END IF;
		--
		IF c2_rec.logging <> 'LOGGING' THEN
			--
			activity_stream ( '', '', 'REQUIRED TABLESPACES LOGGING SET', c2_rec.req_ts||' cur: '||c2_rec.logging||' tar: LOGGING.' , false, 1, 'P1', g_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'REQUIRED TABLESPACES LOGGING SET', c2_rec.req_ts||' cur: '||c2_rec.logging||' tar: LOGGING.', true, 1, 'P2', g_debug);
			--
		END IF;
		--
		IF c2_rec.segment_space_management <> 'AUTO' THEN
			--
			activity_stream ( '', '', 'REQUIRED TABLESPACES SSM', c2_rec.req_ts||' cur: '||c2_rec.segment_space_management||' tar: AUTO.' , false, 1, 'P1', g_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'REQUIRED TABLESPACES SSM', c2_rec.req_ts||' cur: '||c2_rec.segment_space_management||' tar: AUTO.', true, 1, 'P2', g_debug);
			--
		END IF;
		--
		IF c2_rec.bigfile <> 'NO' THEN
			--
			activity_stream ( '', '', 'REQUIRED TABLESPACES NOT A BIG FILE TS', c2_rec.req_ts||' cur: '||c2_rec.bigfile||' tar: NO.' , false, 1, 'P1', g_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'REQUIRED TABLESPACES NOT A BIG FILE TS', c2_rec.req_ts||' cur: '||c2_rec.bigfile||' tar: NO.', true, 1, 'P2', g_debug);
			--
		END IF;
		--
		--
		FOR c5_rec IN c5 (c2_rec.req_ts) LOOP 
			IF c5_rec.autoextensible <> 'YES' THEN
				--
				activity_stream ( '', '', 'REQUIRED TABLESPACES DATAFILE AUTO  EXTENDABLE', c2_rec.req_ts||':'||c5_rec.file_name||' cur: '||c5_rec.autoextensible||' tar: YES.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'REQUIRED TABLESPACES DATAFILE AUTO  EXTENDABLE', c2_rec.req_ts||':'||c5_rec.file_name||' cur: '||c5_rec.autoextensible||' tar: YES.', true, 1, 'P2', g_debug);
				--
			END IF;
			--
			IF c5_rec.maxbytes_mb < 32767 THEN
				--
				activity_stream ( '', '', 'REQUIRED TABLESPACES DATAFILE MAXBYTES', c2_rec.req_ts||':'||c5_rec.file_name||' cur: '||c5_rec.maxbytes_mb||' tar: 32767.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'REQUIRED TABLESPACES DATAFILE MAXBYTES', c2_rec.req_ts||':'||c5_rec.file_name||' cur: '||c5_rec.maxbytes_mb||' tar: 32767.', true, 1, 'P2', g_debug);
				--
			END IF;
			--
			IF c5_rec.inc_by_mb <> '100' THEN
				--
				activity_stream ( '', '', 'REQUIRED TABLESPACES DATAFILE INCRMENT BY', c2_rec.req_ts||':'||c5_rec.file_name||' cur: '||c5_rec.inc_by_mb||' tar: 100.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'REQUIRED TABLESPACES DATAFILE INCRMENT BY', c2_rec.req_ts||':'||c5_rec.file_name||' cur: '||c5_rec.inc_by_mb||' tar: 100.', true, 1, 'P2', g_debug);
				--
			END IF;
			--
			IF c5_rec.online_status <> 'ONLINE' THEN
				--
				activity_stream ( '', '', 'REQUIRED TABLESPACES DATAFILE ONLINE STATUS', c2_rec.req_ts||':'||c5_rec.file_name||' cur: '||c5_rec.online_status||' tar: ONLINE.' , false, 1, 'P1', g_debug);
				--
			ELSE
				--
				activity_stream ( '', '', 'REQUIRED TABLESPACES DATAFILE ONLINE STATUS', c2_rec.req_ts||':'||c5_rec.file_name||' cur: '||c5_rec.online_status||' tar: ONLINE.', true, 1, 'P2', g_debug);
				--
			END IF;
			--
			IF c5_rec.tablespace_name IN ('USERS', 'FS_DB_ADMIN_DATA', 'FSDBA_DATA') THEN
				IF c5_rec.the_size < '5' THEN
					--
					activity_stream ( '', '', 'REQUIRED TABLESPACES DATAFILE SIZE', c2_rec.req_ts||':'||c5_rec.file_name||' cur: '||c5_rec.the_size||' tar: 5.' , false, 1, 'P1', g_debug);
					--
				ELSE
					--
					activity_stream ( '', '', 'REQUIRED TABLESPACES DATAFILE SIZE', c2_rec.req_ts||':'||c5_rec.file_name||' cur: '||c5_rec.the_size||' tar: 5.', true, 1, 'P2', g_debug);
					--
				END IF;
			END IF;
			--
		END LOOP;
	END LOOP;
	--
	FOR c6_rec IN c6 LOOP
		IF c6_rec.tablespace_name IS NOT NULL THEN
			--
			activity_stream ( '', '', 'SAMPLE SCHEMA/TABLESPACES DO NOT EXIST', c6_rec.req_ts||'.' , false, 1, 'P1', g_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'SAMPLE SCHEMA/TABLESPACES DO NOT EXIST', c6_rec.req_ts||'.', true, 1, 'P2', g_debug);
			--
		END IF;
	END LOOP;
	FOR c3_rec IN c3 LOOP
		IF c3_rec.the_count <> 2 THEN
			--
			activity_stream ( '', '', 'REQUIRED REDOLOGS PER GROUP', 'Group '||c3_rec.group#||': 2 Logs cur:'||c3_rec.the_count||' Logs.' , false, 1, 'P1', g_debug);
			--
			activity_stream ( l_sqltext, '', 'REDOLOG CONFIG', 'Unknown.', false, 1, 'P1', g_debug);
			--
		ELSE
			--
			activity_stream ( l_sqltext, '', 'REQUIRED REDOLOGS PER GROUP', 'Group '||c3_rec.group#||': 2 Logs cur:'||c3_rec.the_count||' Logs.', true, 1, 'P2', g_debug);
			--
			IF c3_rec.the_sum = 2 THEN
				--
				activity_stream ( '', '', 'REDOLOG CONFIG', 'Group '||c3_rec.group#||': SMO: REDOLOGS On FRA Only.' , true, 1, 'P2', g_debug);
				--
			ELSIF c3_rec.the_sum = 4 THEN
				--
				activity_stream ( l_sqltext, '', 'REDOLOG CONFIG', 'Group '||c3_rec.group#||': RMAN: REDOLOGS On DATA And FRA.', true, 1, 'P2', g_debug);
				--
			ELSE
				--
				activity_stream ( l_sqltext, '', 'REDOLOG CONFIG INCORRECT', 'Group '||c3_rec.group#||': REDOLOGS UNKNOWN Config.', false, 1, 'P1', g_debug);
				--
			END IF;
		END IF;
	END LOOP;
	--
	FOR c4_rec IN c4 LOOP
		IF c4_rec.the_count <> 2 THEN
			--
			activity_stream ( '', '', 'REQUIRED CONTROLFILE PAIR', '2 cur:'||c4_rec.the_count||'.' , false, 1, 'P1', g_debug);
			--
			activity_stream ( l_sqltext, '', 'CONTROLFILES CONFIG', 'Unknown.', false, 1, 'P1', g_debug);
			--
		ELSE
			--
			activity_stream ( l_sqltext, '', 'REQUIRED CONTROLFILE PAIR', '2 Controlfiles cur:'||c4_rec.the_count||' Controlfiles.', true, 1, 'P2', g_debug);
			--
			IF c4_rec.the_sum = 2 THEN
				--
				activity_stream ( '', '', 'CONTROLFILE CONFIG', 'SMO: CONTROLFILES On FRA Only.' , true, 1, 'P2', g_debug);
				--
			ELSIF c4_rec.the_sum = 4 THEN
				--
				activity_stream ( l_sqltext, '', 'CONTROLFILE CONFIG', 'RMAN: CONTROLFILES On DATA And FRA.', true, 1, 'P2', g_debug);
				--
			ELSE
				--
				activity_stream ( l_sqltext, '', 'CONTROLFILE CONFIG INCORRECT', 'CONTROLFILES UNKNOWN Config.', false, 1, 'P1', g_debug);
				--
			END IF;
		END IF;
	END LOOP;
	--
	activity_stream ( '', '', '', '', true, 0, 'P8', g_debug);
	--
	activity_stream ( '', '', 'SUMMARY', 'DB STRUCTURES', true, 0, 'P7', g_debug);
	--
	g_programcontext := '';
	--
END db_structures;

--
--
--**************************************************************************************************************************
--**         Procedure:	db_features
--**           Purpose:	This procedure based on p_boolean and p_path outputs activity to the screen or output in the 
--**			g_programmessage global variable for the verify program along with calling the exec_ddl procedure
--**			for passed ddl.
--**  Calling Programs:	--
--**   Programs Called: fs_db_admin.fs_exists_functions.exec_ddl
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
--**			RETURN g_iamautomation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE db_features
AS
 CURSOR c1 IS
	SELECT parameter, value   
	FROM v$option
	WHERE parameter in (
		'Partitioning',
		'Oracle Database Vault',
		'Real Application Clusters',
		'Oracle Label Security',
		'Automatic Storage Management')
	ORDER BY parameter;
 --
 l_localprogramname			VARCHAR2(128) := 'db_features';
 l_programmessage			CLOB;
 l_sqltext				CLOB;
 l_count				NUMBER;
 l_boolean				BOOLEAN;
BEGIN
	g_programcontext := l_localprogramname;
	--
	activity_stream ( '', '', 'DETAIL', 'DB FEATURES', true, 0, 'P6', g_debug);
	--
	--****************************************
	--** LICENSE COMPLIANCE SPATIAL
	--****************************************
	--
	SELECT count(*) into l_count
	FROM DBA_REGISTRY
	WHERE COMP_ID = 'SDO';
	--
	IF l_count = 1 THEN
		--
		activity_stream ( '', '', 'FEATURE NOT CURRENTLY INSTALLED', 'SDO - Spatial.' , false, 1, 'P1', g_debug);
		--
	ELSE
		--
		activity_stream ( '', '', 'FEATURE NOT CURRENTLY INSTALLED', 'SDO - Spatial.', true, 1, 'P2', g_debug);
		--
	END IF;
/*	--
	SELECT count(*) into l_count
	FROM DBA_REGISTRY
	WHERE COMP_ID = 'ORDIM';
	--
	IF l_count = 1 THEN
		--
		activity_stream ( '', '', 'FEATURE INSTALLED', 'Locator Subcomponent.', true, 1, 'P2', g_debug);
		--
	ELSE
		--
		activity_stream ( '', '', 'FEATURE INSTALLED', 'Locator Subcomponent.', false, 1, 'P1', g_debug);
		activity_stream ( '', '', 'FEATURE INSTALLED', 'Install to prevent possible upgrade issues - Oracle Doc ID: 179472.1', false, 1, 'P5', g_debug);
		--
	END IF;
*/	--
	FOR c1_rec IN c1 LOOP
		IF c1_rec.value = 'FALSE' THEN
			--
			activity_stream ( '', '', 'FEATURE NOT CURRENTLY INSTALLED', c1_rec.parameter||'.', true, 1, 'P2', g_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'FEATURE NOT CURRENTLY INSTALLED', c1_rec.parameter||'.', false, 1, 'P1', g_debug);
			--
		END IF;
	END LOOP;
	--
	activity_stream ( '', '', '', '', true, 0, 'P8', g_debug);
	--
	activity_stream ( '', '', 'SUMMARY', 'DB FEATURES', true, 0, 'P7', g_debug);
	--
	g_programcontext := '';
	--
END db_features;
--
--
--**************************************************************************************************************************
--**         Procedure:	init_params_special
--**           Purpose:	This function shows the converted value of the global variable g_iamautomation.
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
--**			RETURN g_iamautomation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE init_params_special
(
 p_name				IN		VARCHAR2,
 p_memval			IN		VARCHAR2,
 p_spval			IN		VARCHAR2,
 p_dbblocksize			IN		VARCHAR2,
 p_processes			IN		VARCHAR2,
 p_sgatarget			IN		VARCHAR2,
 p_pgaaggregatetarget		IN		VARCHAR2,
 p_debug			IN		NUMBER
)
AS
 l_localprogramname			VARCHAR2(128) := 'init_params_special';
 l_programmessage			CLOB;
 l_sqltext			CLOB;
 l_boolean			BOOLEAN;
BEGIN
	IF p_name = 'db_block_size' THEN
		IF p_memval = p_dbblocksize and p_spval = p_dbblocksize THEN
			--
			activity_stream ( '', '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', p_name||'='||p_dbblocksize||': mem:'||p_memval||' sp:'||p_spval||'.', true, 1, 'P2', g_debug);
			--
		ELSE
			l_sqltext := 'ALTER SYSTEM SET '||p_name||'='||p_dbblocksize||' SID='||''''||'*'||''''||' SCOPE=SPFILE';
			--
			activity_stream ( l_sqltext, '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', p_name||'='||p_dbblocksize||': mem:'||p_memval||' sp:'||p_spval||'.', false, 1, 'P1', g_debug);
			--
		END IF;
	ELSIF p_name = 'processes' THEN
		IF p_memval = p_processes and p_spval = p_processes THEN
			--
			activity_stream ( '', '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', p_name||'='||p_processes||': mem:'||p_memval||' sp:'||p_spval||'.', true, 1, 'P2', g_debug);
			--
		ELSE
			l_sqltext := 'ALTER SYSTEM SET '||p_name||'='||p_processes||' SID='||''''||'*'||''''||' SCOPE=SPFILE';
			--
			activity_stream ( l_sqltext, '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', p_name||'='||p_processes||': mem:'||p_memval||' sp:'||p_spval||'.', false, 1, 'P1', g_debug);
			--
		END IF;
	ELSIF p_name = 'sga_target' THEN
		IF p_memval = p_sgatarget and p_spval = p_sgatarget THEN
			--
			activity_stream ( '', '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', p_name||'='||p_sgatarget||': mem:'||p_memval||' sp:'||p_spval||'.', true, 1, 'P2', g_debug);
			--
		ELSE
			l_sqltext := 'ALTER SYSTEM SET '||p_name||'='||p_sgatarget||' SID='||''''||'*'||''''||' SCOPE=SPFILE';
			--
			activity_stream ( l_sqltext, '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', p_name||'='||p_sgatarget||': mem:'||p_memval||' sp:'||p_spval||'.', false, 1, 'P1', g_debug);
			--
		END IF;
	ELSIF p_name = 'pga_aggregate_target' THEN
		IF p_memval = p_pgaaggregatetarget and p_spval = p_pgaaggregatetarget THEN
			--
			activity_stream ( '', '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', p_name||'='||p_pgaaggregatetarget||': mem:'||p_memval||' sp:'||p_spval||'.', true, 1, 'P2', g_debug);
			--
		ELSE
			l_sqltext := 'ALTER SYSTEM SET '||p_name||'='||p_pgaaggregatetarget||' SID='||''''||'*'||''''||' SCOPE=BOTH';
			--
			activity_stream ( l_sqltext, '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', p_name||'='||p_pgaaggregatetarget||': mem:'||p_memval||' sp:'||p_spval||'.', false, 1, 'P1', g_debug);
			--
		END IF;
	END IF;
	--
END init_params_special;
--
--
--**************************************************************************************************************************
--**         Procedure:	db_params
--**           Purpose:	This procedure based on p_boolean and p_path outputs activity to the screen or output in the 
--**			g_programmessage global variable for the verify program along with calling the exec_ddl procedure
--**			for passed ddl.
--**  Calling Programs:	--
--**   Programs Called: fs_exists_functions
--**			fs_puppet_structures.exec_ddl
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
--**			RETURN g_iamautomation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE db_params
AS
 --
 --**********************************************
 --** Init Parameters with no trackable Memory 
 --** Components.
 --**********************************************
 --
 CURSOR c1
	(
	l_datavol	VARCHAR2,
	l_fravol	VARCHAR2,
	l_orabase	VARCHAR2,
	l_dbname	VARCHAR2,
	l_dbdomain	VARCHAR2
	)
	IS
	SELECT srp.name, 
	CASE WHEN srp.value=mp.value THEN 0 ELSE 1 END mem_decision,
	CASE WHEN srp.value=spp.value THEN 0 ELSE 1 END sp_decision,
	srp.value reqval, mp.value memval, spp.value spval
	FROM v$parameter mp, v$spparameter spp, 
	(SELECT 'audit_file_dest' name, l_orabase||'/admin/'||l_dbname||'/adump' value FROM dual UNION
	 SELECT 'audit_trail' name, 'OS' value FROM dual UNION
	 SELECT 'compatible' name, '12.2.0.0.0' value FROM dual UNION
	 SELECT 'db_create_file_dest' name, l_datavol value FROM dual UNION
	 SELECT 'db_name' name, l_dbname value FROM dual UNION
	 SELECT 'db_recovery_file_dest' name, l_fravol value FROM dual UNION
	 SELECT 'db_recovery_file_dest_size' name, '2147483648' value FROM dual UNION
	 SELECT 'diagnostic_dest' name, l_orabase value FROM dual UNION
	 SELECT 'dispatchers' name, '(PROTOCOL=TCP) (SERVICE='||l_dbname||'XDB)' value FROM dual UNION
	 SELECT 'nls_language' name, 'AMERICAN' value FROM dual UNION
	 SELECT 'nls_territory' name, 'AMERICA' value FROM dual UNION 
	 SELECT 'open_cursors' name, '300' value FROM dual UNION
	 SELECT 'remote_login_passwordfile' name, 'EXCLUSIVE' value FROM dual UNION
	 SELECT 'undo_tablespace' name, 'UNDOTBS1' value FROM dual UNION
	 SELECT 'global_names' name, 'TRUE' value FROM dual UNION
	 SELECT 'db_domain' name, l_dbdomain value FROM dual UNION
	 SELECT 'log_buffer' name, '10485760' value FROM dual) srp
	WHERE srp.name = mp.name (+)
	AND srp.name = spp.name (+);
 --
 --**********************************************
 --** Init Parameters For OEM with trackable 
 --** Memory Components.
 --**********************************************
 --
 CURSOR c2 IS
	SELECT srp.name, 
	mp.value memval, spp.value spval
	FROM v$parameter mp, v$spparameter spp,
	(SELECT (column_value).getstringval() name
	FROM xmltable('"processes","sga_target","pga_aggregate_target", "db_block_size"')) srp
	WHERE srp.name = mp.name (+)
	AND srp.name = spp.name (+);
 --
 --**********************************************
 --** Init Parameters For OEM with no trackable
 --** Memory Components.
 --**********************************************
 --
 CURSOR c3
	(
	l_datavol	VARCHAR2,
	l_fravol	VARCHAR2,
	l_orabase	VARCHAR2,
	l_dbname	VARCHAR2,
	l_dbdomain	VARCHAR2
	)
	IS
	SELECT srp.name, 
	CASE WHEN srp.value=mp.value THEN 0 ELSE 1 END mem_decision,
	CASE WHEN srp.value=spp.value THEN 0 ELSE 1 END sp_decision,
	srp.value reqval, mp.value memval, spp.value spval
	FROM v$parameter mp, v$spparameter spp, 
	(SELECT 'db_create_file_dest' name, l_datavol value FROM dual UNION
	SELECT 'db_recovery_file_dest' name, l_fravol value FROM dual UNION
	SELECT 'audit_file_dest' name, l_orabase||'/admin/'||l_dbname||'/adump' value FROM dual UNION
	SELECT 'audit_trail' name, 'DB' value FROM dual UNION
	SELECT 'compatible' name, '12.2.0' value FROM dual UNION
	SELECT 'db_name' name, l_dbname value FROM dual UNION
--	SELECT 'db_domain' name, l_dbdomain value FROM dual UNION
	SELECT 'diagnostic_dest' name, l_orabase value FROM dual UNION
	SELECT 'dispatchers' name, '(PROTOCOL=TCP) (SERVICE='||l_dbname||'XDB)' value FROM dual UNION
	SELECT 'remote_login_passwordfile' name, 'EXCLUSIVE' value FROM dual UNION
	SELECT 'undo_tablespace' name, 'UNDOTBS1' value FROM dual UNION
	SELECT 'statistics_level' name, 'TYPICAL' value FROM dual UNION
--	SELECT 'lock_sga' name, 'FALSE' value FROM dual UNION
--	SELECT 'db_cache_size' name, '0' value FROM dual UNION
--	SELECT 'db_cache_advice' name, 'ON' value FROM dual UNION
--	SELECT 'workarea_size_policy' name, 'AUTO' value FROM dual UNION
	SELECT 'db_block_size' name, '8192' value FROM dual UNION
	SELECT 'db_recovery_file_dest_size' name, '' value FROM dual UNION
	SELECT 'processes' name, '500' value FROM dual UNION
	SELECT 'memory_target' name, '2147483648' value FROM dual UNION
	SELECT 'memory_max_target' name, '2147483648' value FROM dual UNION
	SELECT 'open_cursors' name, '500' value FROM dual UNION
	SELECT 'global_names' name, 'TRUE' value FROM dual UNION
	SELECT 'log_buffer' name, '10485760' value FROM dual UNION
	SELECT 'streams_pool_size' name, '0' value FROM dual UNION
	SELECT 'java_pool_size' name, '318767104' value FROM dual UNION
	SELECT 'pga_aggregate_target' name, '314572800' value FROM dual UNION
	SELECT 'shared_pool_size' name, '788529152' value FROM dual UNION
	SELECT 'processes' name, '600' value FROM dual UNION
	SELECT 'open_cursors' name, '300' value FROM dual UNION
	SELECT 'nls_language' name, 'AMERICAN' value FROM dual UNION
	SELECT 'nls_territory' name, 'AMERICA' value FROM dual UNION
	SELECT 'parallel_max_servers' name, '8' value FROM dual UNION
	SELECT 'parallel_min_servers' name, '0' value FROM dual UNION
	SELECT 'pga_aggregate_target' name, '1661992960' value FROM dual UNION
	SELECT 'session_cached_cursors' name, '200' value FROM dual UNION
	SELECT 'sga_target" value' name, '6694109184' value FROM dual) srp
	WHERE srp.name = mp.name (+)
	AND srp.name = spp.name (+);
 --
 l_localprogramname			VARCHAR2(128) := 'db_params';
 l_programmessage			CLOB;
 l_sqltext				CLOB;
 l_count				NUMBER;
 l_boolean				BOOLEAN;
 l_dbblocksize				VARCHAR2(4000);
 l_processes				VARCHAR2(4000);
 l_memorytarget				VARCHAR2(4000);
 l_memorymaxtarget			VARCHAR2(4000);
 l_opencursors				VARCHAR2(4000);
 l_dbrecoveryfiledestsize		VARCHAR2(4000);
 l_nlslanguage				VARCHAR2(4000);
 l_nlsterritory				VARCHAR2(4000);
 l_parallelmaxservers			VARCHAR2(4000);
 l_parallelminservers			VARCHAR2(4000);
 l_pgaaggregatetarget			VARCHAR2(4000);
 l_sessioncachedcursors			VARCHAR2(4000);
 l_sgatarget				VARCHAR2(4000);
 l_temp1				XMLTYPE;
BEGIN
	--
	--***************************************
	--** INIT PARAMS
	--***************************************
	--
	g_programcontext := l_localprogramname;
	--
	activity_stream ( '', '', 'DETAIL', 'INIT PARAMETERS MEMORY/SPFILE', true, 0, 'P6', g_debug);
	--
	IF LOWER(g_dbtemplate) <> 'oem' THEN
		FOR c1_rec IN c1 (g_datavol,g_fravol,g_orabase,g_dbname,g_dbdomain) LOOP
			IF c1_rec.mem_decision = 1 OR c1_rec.sp_decision = 1 THEN
				IF c1_rec.name IN ('audit_file_dest', 'audit_trail', 'compatible', 'db_name', 'db_domain', 'diagnostic_dest', 'remote_login_passwordfile') THEN
					--
					l_sqltext := 'ALTER SYSTEM SET '||c1_rec.name||'='||''''||c1_rec.reqval||''''||' SID='||''''||'*'||''''||' SCOPE=SPFILE';
					--
				ELSIF c1_rec.name IN ('log_buffer') THEN
					--
					l_sqltext := 'ALTER SYSTEM SET '||c1_rec.name||'='||c1_rec.reqval||' SID='||''''||'*'||''''||' SCOPE=SPFILE';
					--
				ELSIF c1_rec.name IN ('global_names') THEN
					--
					l_sqltext := 'ALTER SYSTEM SET '||c1_rec.name||'='||c1_rec.reqval||' SID='||''''||'*'||''''||' SCOPE=BOTH';
					--
				ELSE
					l_sqltext := 'ALTER SYSTEM SET '||c1_rec.name||'='||''''||c1_rec.reqval||''''||' SID='||''''||'*'||''''||' SCOPE=BOTH';
				END IF;
				--
				
				IF c1_rec.name IN ('audit_file_dest', 'diagnostic_dest', 'db_create_file_dest', 'dispatchers', 'db_recovery_file_dest') THEN
					--
					activity_stream ( l_sqltext, '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', c1_rec.name||'='||c1_rec.reqval||'.', false, 1, 'P1', g_debug);
					--
				ELSE
					--
					activity_stream ( l_sqltext, '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', c1_rec.name||'='||c1_rec.reqval||': mem:'||c1_rec.memval||' , sp:'||c1_rec.spval||'.', false, 1, 'P1', g_debug);
					--
				END IF;
			ELSE 
				IF c1_rec.name IN ('audit_file_dest', 'diagnostic_dest', 'db_create_file_dest', 'dispatchers', 'db_recovery_file_dest') THEN
					--
					activity_stream ( '', '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', c1_rec.name||'='||c1_rec.reqval||'.', true, 1, 'P2', g_debug);
					--
				ELSE
					--
					activity_stream ( '', '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', c1_rec.name||'='||c1_rec.reqval||': mem:'||c1_rec.memval||' , sp:'||c1_rec.spval||'.', true, 1, 'P2', g_debug);
					--
				END IF;
				--
			END IF;
		END LOOP;
	ELSE
		FOR c3_rec IN c3 (g_datavol,g_fravol,g_orabase,g_dbname,g_dbdomain) LOOP
			IF c3_rec.mem_decision = 1 OR c3_rec.sp_decision = 1 THEN
				IF c3_rec.name IN ('audit_file_dest', 'audit_trail', 'compatible', 'db_name', 'db_domain', 'diagnostic_dest', 'remote_login_passwordfile') THEN
					--
					l_sqltext := 'ALTER SYSTEM SET '||c3_rec.name||'='||''''||c3_rec.reqval||''''||' SID='||''''||'*'||''''||' SCOPE=SPFILE';
					--
				ELSIF c3_rec.name IN ('lock_sga', 'log_buffer', 'processes') THEN
					--
					l_sqltext := 'ALTER SYSTEM SET '||c3_rec.name||'='||c3_rec.reqval||' SID='||''''||'*'||''''||' SCOPE=SPFILE';
					--
				ELSIF c3_rec.name IN ('global_names', 'streams_pool_size', 'java_pool_size', 'pga_aggregate_target', 'shared_pool_size') THEN
					--
					l_sqltext := 'ALTER SYSTEM SET '||c3_rec.name||'='||c3_rec.reqval||' SID='||''''||'*'||''''||' SCOPE=BOTH';
					--
				ELSE
					l_sqltext := 'ALTER SYSTEM SET '||c3_rec.name||'='||''''||c3_rec.reqval||''''||' SID='||''''||'*'||''''||' SCOPE=BOTH';
				END IF;
				--
				IF c3_rec.name IN ('db_cache_size') AND c3_rec.reqval = 0 AND c3_rec.spval = 0 THEN
					activity_stream ( '', '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', c3_rec.name||'='||c3_rec.reqval||': mem:'||c3_rec.memval||' , sp:'||c3_rec.spval||'.', true, 1, 'P2', g_debug);
				ELSIF c3_rec.name IN ('memory_target') THEN
					l_boolean := fs_db_admin.fs_exists_functions.init_param_value_spfile_exists('memory_max_target', c3_rec.reqval);
						IF l_boolean = true THEN
							--
							activity_stream ( '', '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', c3_rec.name||'='||c3_rec.reqval||': mem:'||c3_rec.memval||' , sp:'||c3_rec.spval||'.', true, 1, 'P2', g_debug);
							--
						ELSE
							--
							activity_stream ( l_sqltext, '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', c3_rec.name||'='||c3_rec.reqval||': mem:'||c3_rec.memval||' , sp:'||c3_rec.spval||'.', false, 1, 'P1', g_debug);
							--
						END IF;
				ELSIF c3_rec.name IN ('audit_file_dest', 'diagnostic_dest', 'db_create_file_dest', 'dispatchers', 'db_recovery_file_dest') THEN
					--
					activity_stream ( l_sqltext, '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', c3_rec.name||'='||c3_rec.reqval||'.', false, 1, 'P1', g_debug);
					--
				ELSE
					--
					activity_stream ( l_sqltext, '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', c3_rec.name||'='||c3_rec.reqval||': mem:'||c3_rec.memval||' , sp:'||c3_rec.spval||'.', false, 1, 'P1', g_debug);
					--
				END IF;
			ELSE 
				IF c3_rec.name IN ('audit_file_dest', 'diagnostic_dest', 'db_create_file_dest', 'dispatchers', 'db_recovery_file_dest') THEN 
					--
					activity_stream ( '', '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', c3_rec.name||'='||c3_rec.reqval||'.', true, 1, 'P2', g_debug);
					--
				ELSIF c3_rec.name IN ('memory_target') THEN
					l_boolean := fs_db_admin.fs_exists_functions.init_param_value_spfile_exists('memory_max_target', c3_rec.reqval);
						IF l_boolean = true THEN
							--
							activity_stream ( '', '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', c3_rec.name||'='||c3_rec.reqval||': mem:'||c3_rec.memval||' , sp:'||c3_rec.spval||'.', true, 1, 'P2', g_debug);
							--
						ELSE
							--
							activity_stream ( l_sqltext, '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', c3_rec.name||'='||c3_rec.reqval||': mem:'||c3_rec.memval||' , sp:'||c3_rec.spval||'.', false, 1, 'P1', g_debug);
							--
						END IF;
				ELSE
					--
					activity_stream ( '', '', 'INITIALIZATION PARAMETERS MEMORY/SPFILE', c3_rec.name||'='||c3_rec.reqval||': mem:'||c3_rec.memval||' , sp:'||c3_rec.spval||'.', true, 1, 'P2', g_debug);
					--
				END IF;
				--
			END IF;
		END LOOP;
	END IF;
	--
	IF LOWER(g_dbtemplate) = 'db01g_8k' THEN
		-- processes=300
		-- sga_target=788529152
		-- pga_aggregate_target=260046848
		l_dbblocksize:='8192';
		l_processes:='300';
		l_sgatarget:='788529152';
		l_pgaaggregatetarget:='260046848';
		FOR c2_rec IN c2 LOOP
			init_params_special (c2_rec.name,c2_rec.memval,c2_rec.spval,l_dbblocksize,l_processes,l_sgatarget,l_pgaaggregatetarget,g_debug);
		END LOOP;
	ELSIF LOWER(g_dbtemplate) = 'db02g_8k' THEN
		-- processes=500
		-- sga_target=1577058304
		-- pga_aggregate_target=520093696
		l_dbblocksize:='8192';
		l_processes:='300';
		l_sgatarget:='1577058304';
		l_pgaaggregatetarget:='520093696';
		FOR c2_rec IN c2 LOOP
			init_params_special (c2_rec.name,c2_rec.memval,c2_rec.spval,l_dbblocksize,l_processes,l_sgatarget,l_pgaaggregatetarget,g_debug);
		END LOOP;
	ELSIF LOWER(g_dbtemplate) = 'db04g_8k' THEN
		-- processes=500
		-- sga_target=3154116608
		-- pga_aggregate_target=1040187392
		l_dbblocksize:='8192';
		l_processes:='500';
		l_sgatarget:='3154116608';
		l_pgaaggregatetarget:='1040187392';
		FOR c2_rec IN c2 LOOP
			init_params_special (c2_rec.name,c2_rec.memval,c2_rec.spval,l_dbblocksize,l_processes,l_sgatarget,l_pgaaggregatetarget,g_debug);
		END LOOP;
	ELSIF LOWER(g_dbtemplate) = 'db08g_8k' THEN
		-- processes=750
		-- sga_target=6291456000
		-- pga_aggregate_target=2097152000
		l_dbblocksize:='8192';
		l_processes:='750';
		l_sgatarget:='6291456000';
		l_pgaaggregatetarget:='2097152000';
		FOR c2_rec IN c2 LOOP
			init_params_special (c2_rec.name,c2_rec.memval,c2_rec.spval,l_dbblocksize,l_processes,l_sgatarget,l_pgaaggregatetarget,g_debug);
		END LOOP;
	ELSIF LOWER(g_dbtemplate) = 'db12g_8k' THEN
		-- processes=750
		-- sga_target=9462349824
		-- pga_aggregate_target=3120562176
		l_dbblocksize:='8192';
		l_processes:='750';
		l_sgatarget:='9462349824';
		l_pgaaggregatetarget:='3120562176';
		FOR c2_rec IN c2 LOOP
			init_params_special (c2_rec.name,c2_rec.memval,c2_rec.spval,l_dbblocksize,l_processes,l_sgatarget,l_pgaaggregatetarget,g_debug);
		END LOOP;
	ELSIF LOWER(g_dbtemplate) = 'db16g_8k' THEN
		-- processes=1000
		-- sga_target=12582912000
		-- pga_aggregate_target=4194304000
		l_dbblocksize:='8192';
		l_processes:='1000';
		l_sgatarget:='12582912000';
		l_pgaaggregatetarget:='4194304000';
		FOR c2_rec IN c2 LOOP
			init_params_special (c2_rec.name,c2_rec.memval,c2_rec.spval,l_dbblocksize,l_processes,l_sgatarget,l_pgaaggregatetarget,g_debug);
		END LOOP;
	ELSIF LOWER(g_dbtemplate) = 'db24g_8k' THEN
		-- processes=1000
		-- sga_target=18924699648
		-- pga_aggregate_target=6241124352
		l_dbblocksize:='8192';
		l_processes:='1000';
		l_sgatarget:='18924699648';
		l_pgaaggregatetarget:='6241124352';
		FOR c2_rec IN c2 LOOP
			init_params_special (c2_rec.name,c2_rec.memval,c2_rec.spval,l_dbblocksize,l_processes,l_sgatarget,l_pgaaggregatetarget,g_debug);
		END LOOP;
	ELSIF LOWER(g_dbtemplate) = 'db16g_16k' THEN
		-- processes=1000
		-- sga_target=10066329600
		-- pga_aggregate_target=6710886400
		l_dbblocksize:='8192';
		l_processes:='1000';
		l_sgatarget:='10066329600';
		l_pgaaggregatetarget:='6710886400';
		FOR c2_rec IN c2 LOOP
			init_params_special (c2_rec.name,c2_rec.memval,c2_rec.spval,l_dbblocksize,l_processes,l_sgatarget,l_pgaaggregatetarget,g_debug);
		END LOOP;
	ELSIF LOWER(g_dbtemplate) = 'db24g_16k' THEN
		-- processes=1000
		-- sga_target=15099494400
		-- pga_aggregate_target=10066329600
		l_dbblocksize:='8192';
		l_processes:='1000';
		l_sgatarget:='15099494400';
		l_pgaaggregatetarget:='10066329600';
		FOR c2_rec IN c2 LOOP
			init_params_special (c2_rec.name,c2_rec.memval,c2_rec.spval,l_dbblocksize,l_processes,l_sgatarget,l_pgaaggregatetarget,g_debug);
		END LOOP;
	ELSE
		NULL;
	END IF;
	--
	activity_stream ( '', '', '', '', true, 0, 'P8', g_debug);
	--
	activity_stream ( '', '', 'SUMMARY', 'INIT PARAMS MEMORY/SPFILE', true, 0, 'P7', g_debug);
	--
	g_programcontext := '';
	--
END db_params;
--
--
--**************************************************************************************************************************
--**************************************************************************************************************************
--**
--**						PUBLIC CLASS PROCEDURES AND FUNCTIONS
--**
--**************************************************************************************************************************
--**************************************************************************************************************************
--
--
--**************************************************************************************************************************
--**         Procedure:	select_i_am_automation
--**           Purpose:	This function shows the converted value of the global variable g_iamautomation.
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
--**			RETURN g_iamautomation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
FUNCTION select_i_am_automation
RETURN VARCHAR2 
AS
BEGIN
	IF g_iamautomation = true THEN
		RETURN 'TRUE';
	ELSE
		RETURN 'FALSE';
	END IF;
END select_i_am_automation;
--
--
--**************************************************************************************************************************
--**         Procedure:	get_i_am_automation
--**           Purpose:	This function returns the value of the global variable g_iamautomation.
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
--**			RETURN g_iamautomation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
FUNCTION get_i_am_automation
RETURN BOOLEAN 
AS
BEGIN
	RETURN g_iamautomation;
END get_i_am_automation;
--
--
--**************************************************************************************************************************
--**         Procedure:	set_i_am_automation
--**           Purpose:	This procedure sets the value of the global variable g_iamautomation.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: --
--**   Tables Modified:	--
--**  Passed Variables:
--**			p_automation			-- Input Variable: value for g_iamautomation.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: --
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			g_iamautomation := p_automation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE set_i_am_automation
(
 p_automation			IN		BOOLEAN				-- Variable to determine if this is automation.
)
AS
BEGIN
	g_iamautomation := p_automation;
END set_i_am_automation;
--
--
--**************************************************************************************************************************
--**         Procedure:	fs_verify_structures
--**           Purpose:	This function shows the converted value of the global variable g_iamautomation.
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
--**			RETURN g_iamautomation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE fs_verify_structures
(
 p_dbtemplate			IN		VARCHAR2,
 p_dbname			IN		VARCHAR2,
 p_dbdomain			IN		VARCHAR2,
 p_datavol			IN		VARCHAR2,
 p_fravol			IN		VARCHAR2,
 p_orabase			IN		VARCHAR2,
 p_dbstructurepasscnt		OUT		NUMBER,
 p_dbstructurefailcnt		OUT		NUMBER,
 p_debug			IN		NUMBER
)
AS
 --
 l_localprogramname			VARCHAR2(128) := 'fs_verify_structures';
 l_programmessage			CLOB;
 l_sqltext				CLOB;
 l_temp1				XMLTYPE;
 --
BEGIN
	IF g_iamautomation = false OR p_debug > 0 THEN
		dbms_output.enable (buffer_size => 100000000);
	END IF;
	g_dbparamspasscnt := 0;
	g_dbparamsfailcnt := 0;
	g_dbfeaturespasscnt := 0;
	g_dbfeaturesfailcnt := 0;
	g_dbstructurespasscnt := 0;
	g_dbstructuresfailcnt := 0;
	g_fsverifystructurespasscnt := 0;
	g_fsverifystructuresfailcnt := 0;
	--
	g_datavol := p_datavol;
	g_fravol := p_fravol;
	g_orabase := p_orabase;
	g_dbname := p_dbname;
	g_dbdomain := p_dbdomain;
	g_debug := p_debug;
	g_dbtemplate := p_dbtemplate;
	--
	SELECT instance_name INTO g_dbinstance FROM v$instance;
	SELECT sys.DBMS_QOPATCH.GET_OPATCH_INSTALL_INFO INTO l_temp1 FROM dual;
	SELECT SUBSTR(l_temp1.getStringVal(),INSTR(l_temp1.getStringVal(),'<path>')+6,INSTR(l_temp1.getStringVal(),'</path>')-(INSTR(l_temp1.getStringVal(),'<path>')+6)) INTO g_orahome FROM dual;
	--
	--****************************************
	--****************************************
	--** DB PARAMS
	--****************************************
	--****************************************
	--
	db_params;
	--
	--****************************************
	--****************************************
	--** DB FEATURES
	--****************************************
	--****************************************
	--
	db_features;
	--
	--****************************************
	--****************************************
	--** DB STRUCUTRES
	--****************************************
	--****************************************
	--
	db_structures;
	--
	--****************************************
	--****************************************
	--** DB MISC
	--****************************************
	--****************************************
	--
	db_misc;
	--
	g_fsverifystructurespasscnt := g_dbparamspasscnt+g_dbfeaturespasscnt+g_dbstructurespasscnt+g_dbmiscpasscnt;
	g_fsverifystructuresfailcnt := g_dbparamsfailcnt+g_dbfeaturesfailcnt+g_dbstructuresfailcnt+g_dbmiscfailcnt;
	p_dbstructurepasscnt := g_fsverifystructurespasscnt;
	p_dbstructurefailcnt := g_fsverifystructuresfailcnt;
	--
END fs_verify_structures;
--
--
END fs_puppet_structures;
--
--
--**************************************************************************************************************************
--End Package Body.
--**************************************************************************************************************************
--
--
/

exit;




