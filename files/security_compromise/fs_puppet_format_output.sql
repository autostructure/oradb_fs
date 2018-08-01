connect / as sysdba

--**************************************************************************************************************************
--**************************************************************************************************************************
--** Begin Package Specification 
--**************************************************************************************************************************
--**************************************************************************************************************************
--
--
CREATE OR REPLACE PACKAGE fs_db_admin.fs_puppet_format_output
AS
--
--
--**************************************************************************************************************************
--**      Package Name: fs_puppet_formatted_text
--**       Application: OPS Puppet Verify
--**            Schema: fs_dba_admin
--**           Authors: Matthew Parker, Oracle Puppet SME 
--**           Purpose: This package contains procedures used to outputting puppet verify formattted text.
--**************************************************************************************************************************
--**   Change Control:
--**	$Log: fs_db_admin.fs_puppet_formatted_text.sql,v $
--**	Revision 1.0  2018/05/30 7:04:36  matthewparker
--**	
--**************************************************************************************************************************
--
--
PROCEDURE format_entries
(
 p_messagetype			IN		VARCHAR2,
 p_messagetypedetail		IN		VARCHAR2,
 p_outlinechar			IN		VARCHAR2 DEFAULT '#',
 p_col1text			IN		VARCHAR2,
 p_col2text			IN		VARCHAR2,
 p_col3text			IN		VARCHAR2,
 p_passfail			IN		VARCHAR2,
 p_passcnt			IN		NUMBER,
 p_failcnt			IN		NUMBER,
 p_passwarncnt			IN		NUMBER,
 p_failwarncnt			IN		NUMBER
);
--
--
END fs_puppet_format_output;
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

CREATE OR REPLACE PACKAGE BODY fs_db_admin.fs_puppet_format_output IS
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
--**         Procedure:	cjust
--**           Purpose:	This function takes a text string and center justifies it.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: --
--**   Tables Modified:	--
--**  Passed Variables: p_string	-- Passed in string.
--**			p_size		-- Passed size of the overall text field including p_string.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: 
--**			l_string	-- Passed in string.
--**			l_temp		-- Temporary variable holding size of blank leftover after passed in string
--**			l_temp_1	-- Temporary variable holding half the size of the blank space
--**			l_left		-- Temporary variable holding the size of the left blank space
--**			l_right		-- Temporary variable holding the size of the right blank space
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			RETURN true/false
--**			EXCEPTION
--**************************************************************************************************************************
--
--
FUNCTION cjust_text
(
 p_string			IN		VARCHAR2,
 p_size				IN		INTEGER
)
RETURN VARCHAR2
IS
 l_string			VARCHAR2(4000);
 l_temp				NUMBER;
 l_temp_1			NUMBER;
 l_left				NUMBER;
 l_right			NUMBER;
BEGIN
	--
	l_temp   := p_size - LENGTH(p_string);
	l_temp_1 := l_temp/2;
	l_left   := FLOOR(l_temp_1);
	l_right  := CEIL(l_temp_1);
	l_string := LPAD(' ', l_left) || p_string || RPAD(' ', l_right);
	RETURN l_string;
	--
END cjust_text;
--
--
--**************************************************************************************************************************
--**         Procedure:	repeat
--**           Purpose:	This function takes an input string and duplicates it by the p_size input.
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
--**			RETURN true/false
--**			EXCEPTION
--**************************************************************************************************************************
--
--
FUNCTION repeat_char
(
 p_char				IN		VARCHAR2,
 p_size				IN		INTEGER
)
RETURN VARCHAR2
IS
 l_string			VARCHAR2(4000);
BEGIN
	--
	l_string := (LPAD(p_char, p_size, p_char));
	RETURN l_string;
	--
END repeat_char;
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
--**         Procedure:	format_entries
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
PROCEDURE format_entries
(
 p_messagetype			IN		VARCHAR2,
 p_messagetypedetail		IN		VARCHAR2,
 p_outlinechar			IN		VARCHAR2 DEFAULT '#',
 p_col1text			IN		VARCHAR2,
 p_col2text			IN		VARCHAR2,
 p_col3text			IN		VARCHAR2,
 p_passfail			IN		VARCHAR2,
 p_passcnt			IN		NUMBER,
 p_failcnt			IN		NUMBER,
 p_passwarncnt			IN		NUMBER,
 p_failwarncnt			IN		NUMBER
)
AS
 l_color			VARCHAR2(32);
 l_text				VARCHAR2(2048);
 l_red				VARCHAR2(32) := chr(27)||'[0;'||chr(27)||'[31m';
 l_green			VARCHAR2(32) := chr(27)||'[0;'||chr(27)||'[32m';
 l_yellow			VARCHAR2(32) := chr(27)||'[1;'||chr(27)||'[33m';
 l_nc				VARCHAR2(32) := chr(27)||'[0m';
 l_col1size			NUMBER;
 l_col2size			NUMBER;
 l_col3size			NUMBER;
 l_passwarncnt			NUMBER;
 l_failwarncnt			NUMBER;
BEGIN
	IF UPPER(p_passfail) = 'PASS' THEN
		l_color := l_green;
	ELSIF UPPER(p_passfail) = 'FAIL' THEN
		l_color := l_red;
	ELSIF UPPER(p_passfail) = 'WARN' THEN
		l_color := l_yellow;
	ELSE
		l_color := l_nc;
	END IF;
	--
	l_col1size := LENGTH(p_col1text);
	l_col2size := LENGTH(p_col2text);
	l_col3size := LENGTH(p_col3text);
	--
	l_passwarncnt := NVL(p_passwarncnt,0);
	l_failwarncnt := NVL(p_failwarncnt,0);
	--
	IF LOWER(p_messagetype) = 'h' THEN
		IF p_messagetypedetail = 'structures' OR p_messagetypedetail = 'security' THEN
			dbms_output.put_line(chr(13));
			dbms_output.put_line(rpad(p_outlinechar,140,p_outlinechar));
			dbms_output.put_line(p_outlinechar||cjust_text(p_col1text, 138)||p_outlinechar);
			dbms_output.put_line(rpad(p_outlinechar,140,p_outlinechar));
			dbms_output.put_line(p_outlinechar||cjust_text(p_col2text, 138)||p_outlinechar);
			dbms_output.put_line(p_outlinechar||cjust_text(p_col3text, 138)||p_outlinechar);
			dbms_output.put_line(rpad(p_outlinechar,140,p_outlinechar));
			dbms_output.put_line(p_outlinechar||' '||rpad('VERIFY ACTION',54)||p_outlinechar||' '||rpad('INTERNAL OBJECT TO VERIFY', 72)||p_outlinechar||' STATUS '||p_outlinechar);
			dbms_output.put_line(rpad(p_outlinechar,140,p_outlinechar));
		ELSIF p_messagetypedetail = 'patches' THEN
			NULL;
		ELSE
			NULL;
		END IF;
	ELSIF LOWER(p_messagetype) = 'l1' THEN
		IF UPPER(p_passfail) = 'PASS' OR UPPER(p_passfail) = 'FAIL' THEN
			IF l_col1size NOT IN (12,13) THEN
				dbms_output.put_line(l_color||'# '||p_col1text||rpad(' ',53-l_col1size)||'# '||p_col2text||rpad(' ',72-l_col2size)||'# '||p_passfail||'   #'||l_nc);
			ELSE
				dbms_output.put_line(l_color||'# '||p_col1text||rpad(' ',53-l_col1size+8)||'# '||p_col2text||rpad(' ',72-l_col2size)||'# '||p_passfail||'   #'||l_nc);
			END IF;
		ELSIF UPPER(p_passfail) = 'WARN' THEN
			IF l_col1size NOT IN (12,13,18,19,20,27) THEN
				dbms_output.put_line(l_color||'# '||p_col1text||rpad(' ',53-l_col1size)||'# '||p_col2text||rpad(' ',72-l_col2size)||'# '||p_passfail||'   #'||l_nc);
			ELSIF l_col1size IN (20) THEN
				dbms_output.put_line(l_color||'# '||p_col1text||rpad(' ',61-l_col1size)||'# '||p_col2text||rpad(' ',72-l_col2size)||'# '||p_passfail||'   #'||l_nc);
			ELSE
				dbms_output.put_line(l_color||'# '||p_col1text||rpad(' ',45-l_col1size+8)||'# '||p_col2text||rpad(' ',72-l_col2size)||'# '||p_passfail||'   #'||l_nc);
			END IF;
		ELSE
			IF l_col1size NOT IN (12,13) THEN
				dbms_output.put_line(l_color||'# '||p_col1text||rpad(' ',53-l_col1size)||'# '||p_col2text||rpad(' ',72-l_col2size)||'# '||substr(p_passfail,1,6)||'   #'||l_nc);
			ELSE
				dbms_output.put_line(l_color||'# '||p_col1text||rpad(' ',53-l_col1size+8)||'# '||p_col2text||rpad(' ',72-l_col2size)||'# '||substr(p_passfail,1,6)||'   #'||l_nc);
			END IF;
		END IF;
	ELSIF LOWER(p_messagetype) = 'l2' THEN
		dbms_output.put_line(rpad('#',140,'#'));
		dbms_output.put_line('# '||rpad(p_col1text,128)||'#        #'||l_nc);
		dbms_output.put_line(rpad('#',140,'#'));
	ELSIF LOWER(p_messagetype) = 'm' THEN
		dbms_output.put_line(rpad('#',140,'#'));
	ELSIF LOWER(p_messagetype) = 's1' THEN
		IF LOWER(p_messagetypedetail) = 'provide_legacy_objects' OR LOWER(p_messagetypedetail) = 'provide_basic_security' THEN
			dbms_output.put_line(rpad('#',60,'#'));
			dbms_output.put_line('#'||cjust_text(p_col1text, 58)||'#');
			dbms_output.put_line('#'||cjust_text(p_col2text, 58)||'#');
			dbms_output.put_line(rpad('#',60,'#'));
			dbms_output.put_line(l_yellow||rpad('# TOTAL SPECS PASSED COUNTED UNDER USERS: '||l_passwarncnt,58,' ')||'#'||l_nc);
			dbms_output.put_line(l_yellow||rpad('# TOTAL SPECS FAILED COUNTED UNDER USERS: '||l_failwarncnt,58,' ')||'#'||l_nc);
			dbms_output.put_line(l_green||rpad('# TOTAL SPECS PASSED          : '||p_passcnt,58,' ')||'#'||l_nc);
			IF p_failcnt=0 THEN
				dbms_output.put_line(l_green||rpad('# TOTAL SPECS FAILED          : '||p_failcnt,58,' ')||'#'||l_nc);
			ELSE
				dbms_output.put_line(l_red||rpad('# TOTAL SPECS FAILED          : '||p_failcnt,58,' ')||'#'||l_nc);
			END IF;
			dbms_output.put_line(rpad('# TOTAL SPECS TO ENFORCE       : '||(NVL(p_passcnt,0)+NVL(p_failcnt,0)),59,' ')||'#');
			IF MOD(p_passcnt,(p_passcnt+p_failcnt)) = 0 AND p_passcnt <> (p_passcnt+p_failcnt)  THEN
					dbms_output.put_line(l_green||rpad('# PERCENTAGE OF SPECS ENFORCED : 0%',58,' ')||'#'||l_nc);
			ELSIF MOD(p_passcnt,(p_passcnt+p_failcnt)) = 0 AND p_passcnt = 0 AND p_failcnt = 0  THEN
					dbms_output.put_line(l_green||rpad('# PERCENTAGE OF SPECS ENFORCED : 0%',58,' ')||'#'||l_nc);
			ELSIF (p_passcnt/(p_passcnt+p_failcnt))*100 = 100 THEN
				dbms_output.put_line(l_green||rpad('# PERCENTAGE OF SPECS ENFORCED : '||round((p_passcnt/(p_passcnt+p_failcnt))*100,2)||'%',58,' ')||'#'||l_nc);
			ELSE
				IF MOD(p_passcnt,(p_passcnt+p_failcnt)) > 0 THEN
					IF length(round((p_passcnt/(p_passcnt+p_failcnt))*100,2)) = 3 THEN
						dbms_output.put_line(l_red||rpad('# PERCENTAGE OF SPECS ENFORCED : '||round((p_passcnt/(p_passcnt+p_failcnt))*100,2)||'%',50,' ')||'        #'||l_nc);
					ELSIF length(round((p_passcnt/(p_passcnt+p_failcnt))*100,2)) > 3 THEN
						dbms_output.put_line(l_red||rpad('# PERCENTAGE OF SPECS ENFORCED : '||round((p_passcnt/(p_passcnt+p_failcnt))*100,2)||'%',58,' ')||'        #'||l_nc);
					ELSE
						dbms_output.put_line(l_red||rpad('# PERCENTAGE OF SPECS ENFORCED : '||round((p_passcnt/(p_passcnt+p_failcnt))*100,2)||'%',50,' ')||'        #'||l_nc);
					END IF;
				ELSE
					dbms_output.put_line(l_red||rpad('# PERCENTAGE OF SPECS ENFORCED : '||round((p_passcnt/(p_passcnt+p_failcnt))*100,2)||'%',50,' ')||'        #'||l_nc);
				END IF;
			END IF;
			dbms_output.put_line(rpad('#',60,'#'));
			dbms_output.put_line(chr(13));
		ELSE
			dbms_output.put_line(rpad('#',60,'#'));
			dbms_output.put_line('#'||cjust_text(p_col1text, 58)||'#');
			dbms_output.put_line('#'||cjust_text(p_col2text, 58)||'#');
			dbms_output.put_line(rpad('#',60,'#'));
			dbms_output.put_line(l_green||rpad('# TOTAL SPECS PASSED          : '||p_passcnt,58,' ')||'#'||l_nc);
			IF p_failcnt=0 THEN
				dbms_output.put_line(l_green||rpad('# TOTAL SPECS FAILED          : '||p_failcnt,58,' ')||'#'||l_nc);
			ELSE
				dbms_output.put_line(l_red||rpad('# TOTAL SPECS FAILED          : '||p_failcnt,58,' ')||'#'||l_nc);
			END IF;
			dbms_output.put_line(rpad('# TOTAL SPECS TO ENFORCE       : '||(NVL(p_passcnt,0)+NVL(p_failcnt,0)),59,' ')||'#');
			IF MOD(p_passcnt,(p_passcnt+p_failcnt)) = 0 AND p_passcnt <> (p_passcnt+p_failcnt)  THEN
					dbms_output.put_line(l_green||rpad('# PERCENTAGE OF SPECS ENFORCED : 0%',58,' ')||'#'||l_nc);
			ELSIF MOD(p_passcnt,(p_passcnt+p_failcnt)) = 0 AND p_passcnt = 0 AND p_failcnt = 0  THEN
					dbms_output.put_line(l_green||rpad('# PERCENTAGE OF SPECS ENFORCED : 0%',58,' ')||'#'||l_nc);
			ELSIF (p_passcnt/(p_passcnt+p_failcnt))*100 = 100 THEN
				dbms_output.put_line(l_green||rpad('# PERCENTAGE OF SPECS ENFORCED : '||round((p_passcnt/(p_passcnt+p_failcnt))*100,2)||'%',58,' ')||'#'||l_nc);
			ELSE
				IF MOD(p_passcnt,(p_passcnt+p_failcnt)) > 0 THEN
					IF length(round((p_passcnt/(p_passcnt+p_failcnt))*100,2)) > 2 THEN
						dbms_output.put_line(l_red||rpad('# PERCENTAGE OF SPECS ENFORCED : '||round((p_passcnt/(p_passcnt+p_failcnt))*100,2)||'%',58,' ')||'        #'||l_nc);
					ELSE
						dbms_output.put_line(l_red||rpad('# PERCENTAGE OF SPECS ENFORCED : '||round((p_passcnt/(p_passcnt+p_failcnt))*100,2)||'%',50,' ')||'        #'||l_nc);
					END IF;
				ELSE
					dbms_output.put_line(l_red||rpad('# PERCENTAGE OF SPECS ENFORCED : '||round((p_passcnt/(p_passcnt+p_failcnt))*100,2)||'%',50,' ')||'        #'||l_nc);
				END IF;
			END IF;
			dbms_output.put_line(rpad('#',60,'#'));
			dbms_output.put_line(chr(13));
		END IF;
	ELSIF LOWER(p_messagetype) = 's2' THEN
		dbms_output.put_line(chr(13));
		dbms_output.put_line(rpad('#',60,'#'));
		dbms_output.put_line('#'||cjust_text(p_col1text, 58)||'#');
	ELSE
		NULL;
	END IF;
END format_entries;
--
--
END fs_puppet_format_output;
--
--
--**************************************************************************************************************************
--End Package Body.
--**************************************************************************************************************************
--
--
/

exit


