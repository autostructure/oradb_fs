connect / as sysdba

--**************************************************************************************************************************
--**************************************************************************************************************************
--** Begin Package Specification 
--**************************************************************************************************************************
--**************************************************************************************************************************
--
--
CREATE OR REPLACE PACKAGE fs_db_admin.fs_security_pkg
AUTHID CURRENT_USER
AS
--
--
--**************************************************************************************************************************
--**     Package Name:	fs_security_pkg
--**      Application:	OPS Security Controls
--**           Schema:	fs_dba_admin
--**          Authors:	Matthew Parker, Oracle Puppet SME
--**			Ed Taylor
--**			Jane Reyling
--**          Comment:	This package contains procedures used to replace the functionality of the DBMaintenance DB Config
--**			scripts that are security related: user, roles and added functionality of pw complexity, profiles
--**			and random paw generator to match STIG requirements.
--**           NOTICE:	Portions of this code are from Oracle provided scripts 
--**			rdbms/admin/catpvf.sql - Create Password Verify Function, STIG profile
--**			Copyright (c) 2013, 2016, Oracle and/or its affiliates. All rights reserved.
--**************************************************************************************************************************
--**   Change Control:
--**	$Log: fs_db_admin.fs_exists_functions.sql,v $
--**	Revision 2.0.5  2018/07/23 5:01:52  matthewparker
--**
--**************************************************************************************************************************
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
 p_automation				IN		BOOLEAN						-- Variable to determine if this is automation.
);
--
--
FUNCTION fs_password_verify
(
 p_username				IN		VARCHAR2,
 p_password				IN		VARCHAR2,
 p_oldpassword				IN		VARCHAR2
)
RETURN boolean;
--
--
FUNCTION random_password
(
 p_pwlength				IN		INTEGER DEFAULT 15,
 p_debug				IN		NUMBER			-- Turn on DEBUG.
) 
RETURN VARCHAR2;
--
--
PROCEDURE secure_users
(
 p_action				IN		VARCHAR2 DEFAULT 'b',	-- p, l, b
 p_status				OUT		VARCHAR2,		-- Status message to check for errors.
 p_errormessage				OUT		VARCHAR2,		-- The actual error message.
 p_debug				IN		NUMBER			-- Turn on DEBUG.
);
--
--
PROCEDURE secure_database
(
 p_providedbinstancesobjects		IN		VARCHAR2,				-- t, f
 p_providegisroles			IN		VARCHAR2,		-- t, f
 p_passcnt				OUT		NUMBER,
 p_failcnt				OUT		NUMBER,
 p_status				OUT		VARCHAR2,		-- Status message to check for errors.
 p_errormessage				OUT		VARCHAR2,		-- The actual error message.
 p_debug				IN		NUMBER			-- Turn on DEBUG.
);
--
--
END fs_security_pkg;
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

CREATE OR REPLACE PACKAGE BODY fs_db_admin.fs_security_pkg IS
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
g_iamautomation				BOOLEAN		DEFAULT false;
g_programmessage			CLOB;
g_dbinstance				VARCHAR2(32);
g_orahome				VARCHAR2(128);
g_programcontext			VARCHAR2(32);
g_providerolespasscnt			NUMBER;
g_providerolesfailcnt			NUMBER;
g_provideprofilespasscnt		NUMBER;
g_provideprofilesfailcnt		NUMBER;
g_providepublicgrantspasscnt		NUMBER;
g_providepublicgrantsfailcnt		NUMBER;
g_provideuserspasscnt			NUMBER;
g_provideusersfailcnt			NUMBER;
g_providebasicsecuritypasscnt		NUMBER;
g_providebasicsecurityfailcnt		NUMBER;
g_providebassecpasswarncnt		NUMBER;
g_providebassecfailwarncnt		NUMBER;
g_providedbinstancesobjectspasscnt	NUMBER;
g_providedbinstancesobjectsfailcnt	NUMBER;
g_providelegobjpasswarncnt		NUMBER;
g_providelegobjfailwarncnt		NUMBER;
g_providegisrolespasscnt		NUMBER;
g_providegisrolesfailcnt		NUMBER;
g_fssecuritypasscnt			NUMBER;
g_fssecurityfailcnt			NUMBER;
g_fssecuritypasswarncnt			NUMBER;
g_fssecurityfailwarncnt			NUMBER;
g_provideusers				VARCHAR2(1);
g_droplegobj				BOOLEAN		DEFAULT false;
g_dropbassecobj				BOOLEAN		DEFAULT false;
g_debug					NUMBER		DEFAULT 0;
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
--**        Pseudo code: 
--**			RETURN g_iamautomation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE exec_ddl
(
 p_sqltext				IN		VARCHAR2,
 p_sqltextsecure			IN		VARCHAR2,
 p_debug				IN		VARCHAR2
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
--**         Procedure:	verify_message_stream
--**           Purpose:	This procedure based on p_boolean and p_path outputs activity to the screen or output in the 
--**			g_programmessage global variable for the verify program along with calling the exec_ddl procedure
--**			for passed ddl.
--**  Calling Programs:	--
--**   Programs Called: fs_db_admin.fs_exists_functions
--**			fs_security_pkg.exec_ddl
--**			fs_db_admin.fs_puppet_format_output
--**   Tables Accessed: --
--**   Tables Modified:	--
--**  Passed Variables:
--**			p_sqltext				-- DDL
--**			p_sqltextsecure				-- Secure DDL (obscured PW for output)
--**			p_col1text				-- Main Column Message Text
--**			p_col2text				-- Secondary Column Message Text
--**			p_boolean				-- True/False for pass.
--**			p_verifycount				-- Count for Verify
--**			p_path					-- Message Choice/Path
--**			p_debug					-- Output Variable: The debug level set by the original calling program.
--** Passed Global Var:	
--**			g_programcontext			-- Local program for WARN variable.
--**			g_dropbassecobj				-- Special variable to handle for dropped object action seen by two procs only counted once.
--**   Global Var Mods:	
--**			g_providerolespasscnt			-- Provide Role Pass Count
--**			g_providerolesfailcnt			-- Provide Role Fail Count
--**			g_provideprofilespasscnt		-- Provide Profile Pass Count
--**			g_provideprofilesfailcnt		-- Provide Profile Fail Count
--**			g_provideuserspasscnt			-- Provide User Pass Count
--**			g_provideusersfailcnt			-- Provide User Fail Count
--**			g_providedbinstancesobjectspasscnt	-- Provide DBInstances Object Pass Count
--**			g_providedbinstancesobjectsfailcnt	-- Provide DBInstances Object Fail Count
--**			g_providedbinstancesobjectswarncnt	-- Provide DBInstances Object Warn Count
--**			g_providegisrolespasscnt		-- Provide Role Pass Count
--**			g_providegisroleswarncnt		-- Provide Role Fail Count
--**   Local Variables: 
--**			l_booleantext				-- Translate true/false boolean to text
--**			l_pfw					-- Transalte pass/fail booelan to text
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Pseudo code: 
--**			Convert boolean
--**			Determine procdure subfunction and add to global variable count
--**			execute DDL
--**			execute formatted output.
--**
--**************************************************************************************************************************
--
--
PROCEDURE activity_stream
(
 p_sqltext				IN		VARCHAR2,
 p_sqltextsecure			IN		VARCHAR2,
 p_col1text				IN		VARCHAR2,
 p_col2text				IN		VARCHAR2,
 p_boolean				IN		BOOLEAN,
 p_verifycount				IN		NUMBER,
 p_path					IN		VARCHAR2,
 p_debug				IN		NUMBER
)
IS
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
	IF g_programcontext = 'provide_roles' THEN
		IF p_boolean = true THEN
			g_providerolespasscnt := g_providerolespasscnt+p_verifycount;
		ELSE
			g_providerolesfailcnt := g_providerolesfailcnt+p_verifycount;
		END IF;
	ELSIF g_programcontext = 'provide_profiles' THEN
		IF p_boolean = true THEN
			g_provideprofilespasscnt := g_provideprofilespasscnt+p_verifycount;
		ELSE
			g_provideprofilesfailcnt := g_provideprofilesfailcnt+p_verifycount;
		END IF;
	ELSIF g_programcontext = 'provide_users' THEN
		IF p_boolean = true THEN
			g_provideuserspasscnt := g_provideuserspasscnt+p_verifycount;
		ELSE
			g_provideusersfailcnt := g_provideusersfailcnt+p_verifycount;
		END IF;
	ELSIF g_programcontext = 'provide_dbinstances_objects' THEN
		IF p_boolean = true  THEN
			IF g_droplegobj = false THEN
				g_providedbinstancesobjectspasscnt := g_providedbinstancesobjectspasscnt+p_verifycount;
			ELSE
				g_providelegobjpasswarncnt := g_providelegobjpasswarncnt+p_verifycount;
			END IF;
		ELSE
			IF g_droplegobj = false THEN
				g_providedbinstancesobjectsfailcnt := g_providedbinstancesobjectsfailcnt+p_verifycount;
			ELSE
				g_providelegobjfailwarncnt := g_providelegobjfailwarncnt+p_verifycount;
			END IF;
		END IF;
	ELSIF g_programcontext = 'provide_gis_roles' THEN
		IF p_boolean = true THEN
			g_providegisrolespasscnt := g_providegisrolespasscnt+p_verifycount;
		ELSE
			g_providegisrolesfailcnt := g_providegisrolesfailcnt+p_verifycount;
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
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', p_col1text, p_col2text, '', l_pfw,'','','','');
		--
		IF p_debug IN ( 0, 1 ) THEN
			IF p_sqltextsecure IS NULL THEN
				fs_security_pkg.exec_ddl(p_sqltext,'', p_debug);
			ELSE
				fs_security_pkg.exec_ddl(p_sqltext,p_sqltextsecure, p_debug);
			END IF;
		END IF;
	--
	--*********************************************************
	--** p_boolean = true REQUIREING NO OBJECT MODIFICATION
	--** Used for message and NO DDL execution.
	--*********************************************************
	--
	ELSIF p_path = 'P2' AND p_boolean = true THEN
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', p_col1text, p_col2text, '', l_pfw,'','','','');
	--
	--*********************************************************
	--** p_boolean = false MESSAGE ONLY NO SPEC CHANGE
	--*********************************************************
	--
	ELSIF p_path = 'P3' AND p_boolean = false  THEN
		--
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', p_col1text, p_col2text, '', 'WARN','','','','');
	--
	--*********************************************************
	--** p_boolean = true MESSAGE ONLY NO SPEC CHANGE
	--*********************************************************
	--
	ELSIF p_path = 'P4' AND p_boolean = true  THEN
		--
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', p_col1text, p_col2text, '', 'WARN','','','','');
	--
	--*********************************************************
	--** p_boolean = false MESSAGE AND SPEC CHANGE
	--*********************************************************
	--
	ELSIF p_path = 'P5' AND p_boolean = false THEN
		--
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', p_col1text, p_col2text, '', l_pfw,'','','','');
	--
	--*********************************************************
	--** p_boolean = true Header
	--*********************************************************
	--
	ELSIF p_path = 'P6' AND p_boolean = true THEN
		--
		fs_db_admin.fs_puppet_format_output.format_entries ( 'h', 'security', '#', 'Database: '||g_dbinstance||' - Oracle Home: '||g_orahome, p_col1text, p_col2text, '','','','','');
	--
	--*********************************************************
	--** p_boolean = true summary
	--*********************************************************
	--
	ELSIF p_path = 'P7' AND p_boolean = true THEN
		--
		IF g_programcontext = 'provide_roles' THEN
			fs_db_admin.fs_puppet_format_output.format_entries ( 's1', 'provide_roles', '#', p_col1text,
									 p_col2text, '','',g_providerolespasscnt,g_providerolesfailcnt,'','');
		ELSIF g_programcontext = 'provide_profiles' THEN
			fs_db_admin.fs_puppet_format_output.format_entries ( 's1', 'provide_profiles', '#', p_col1text,
									 p_col2text, '','',g_provideprofilespasscnt,g_provideprofilesfailcnt,'','');
		ELSIF g_programcontext = 'provide_users' THEN
			fs_db_admin.fs_puppet_format_output.format_entries ( 's1', 'provide_users', '#', p_col1text,
									 p_col2text, '','',g_provideuserspasscnt,g_provideusersfailcnt,'','');
		ELSIF g_programcontext = 'provide_dbinstances_objects' THEN
			fs_db_admin.fs_puppet_format_output.format_entries ( 's1', 'provide_dbinstances_objects', '#', p_col1text,
									 p_col2text, '','',g_providedbinstancesobjectspasscnt,g_providedbinstancesobjectsfailcnt,g_providelegobjpasswarncnt,g_providelegobjfailwarncnt);
		ELSIF g_programcontext = 'provide_gis_roles' THEN
			fs_db_admin.fs_puppet_format_output.format_entries ( 's1', 'provide_gis_roles', '#', p_col1text,
									 p_col2text, '','',g_providegisrolespasscnt,g_providegisrolesfailcnt,'','');
		ELSE
			NULL;
		END IF;
	--
	--*********************************************************
	--** p_boolean = true summary
	--*********************************************************
	--
	ELSIF p_path = 'P8' AND p_boolean = true THEN
		--
		fs_db_admin.fs_puppet_format_output.format_entries ( 'm', '', '#', '', '', '', l_pfw,'','','','');
	--
	--*********************************************************
	--**
	--*********************************************************
	--
	ELSE
		--
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', '', p_col1text, p_col2text, l_pfw,'','','','');
		--
	END IF;
END activity_stream;
--
--
--**************************************************************************************************************************
--**          Function:	count_special
--**           Purpose:	This function verify number and validity of special characters used.
--**  Calling Programs:	All.
--**   Programs Called: --
--**   Tables Accessed: --
--**   Tables Modified:	--
--**  Passed Variables:
--**			p_automation			-- Input Variable: value for g_iamautomation.
--**			p_status			-- Output Variable: Status message to check for errors.
--**			p_errormessage			-- Output Variable: The actual error message.
--**			p_debug				-- Output Variable: The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:
--**			l_localprogramname		-- This programs name. (For debugging purposes.)
--**			l_programmessage		-- The local debugging message.
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**           NOTICE:	This code copied from Oracle provided scripts 
--**			rdbms/admin/catpvf.sql - Create Password Verify Function, STIG profile
--**			Copyright (c) 2013, 2016, Oracle and/or its affiliates. All rights reserved.
--**************************************************************************************************************************
--**        Pseudo code: 
--**			PW Length check 15 to 30
--**			Construct PW Meeting Compliance Rules
--**			Check for 3x repeating characters
--**			EXCEPTION
--**************************************************************************************************************************
--
--
FUNCTION count_special
(
 p_password				IN		VARCHAR2,
 p_debug				IN		INTEGER
) 
RETURN INTEGER 
IS
 l_charcnt			INTEGER		:= 0;
 l_returnchar			VARCHAR2(1)	:= chr(10);
BEGIN
	--
	FOR i IN 1..LENGTH(p_password) LOOP
		--**************************************************
		--** Restrict special characters known to cause 
		--** problems in scripts and connection strings.
		--**************************************************
		--
		IF substr(p_password, i, 1) IN ('"', '''', '`', '¿', '@', '&', '\', '/', ' ', l_returnchar) THEN 
		--
		activity_stream ( '', '', 'PASSWORD SPECIAL CHARACTER', 'Avoid The Following Special Characters In Password: " '' ¿ ` @ & \ / (space) (return).', false, 1, 'P5', p_debug);
		--
		l_charcnt := -1;
		EXIT;
		--
		END IF;
		--**************************************************
		--** Count only those special characters deemed
		--** safe for passwords.
		--**************************************************
		-- 
		IF substr(p_password, i, 1) IN (
				'¿', '~', '!', '#', '$', '%', '^', '*', '(', ')', '_', '-', '+', '=', 
				'{', '}', '[', ']', '<', '>', ',', '.', ';', '?', ':', '|') THEN 
			l_charcnt := l_charcnt + 1;
		END IF;
    
	END LOOP;
	--
	RETURN l_charcnt;
END count_special;

--
--
--**************************************************************************************************************************
--**          Function:	string_distance
--**           Purpose:	This function verifies new PW differs from old pw by at least 8 chars..
--**  Calling Programs:	All.
--**   Programs Called: --
--**   Tables Accessed: --
--**   Tables Modified:	--
--**  Passed Variables:
--**			p_automation			-- Input Variable: value for g_iamautomation.
--**			p_status			-- Output Variable: Status message to check for errors.
--**			p_errormessage			-- Output Variable: The actual error message.
--**			p_debug				-- Output Variable: The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:
--**			l_localprogramname		-- This programs name. (For debugging purposes.)
--**			l_programmessage		-- The local debugging message.
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**           NOTICE:	This code copied from Oracle provided scripts 
--**			rdbms/admin/catpvf.sql - Create Password Verify Function, STIG profile
--**			Copyright (c) 2013, 2016, Oracle and/or its affiliates. All rights reserved.
--**************************************************************************************************************************
--**        Pseudo code: 
--**			PW Length check 15 to 30
--**			Construct PW Meeting Compliance Rules
--**			Check for 3x repeating characters
--**			EXCEPTION
--**************************************************************************************************************************
--
--
FUNCTION string_distance
(
 p_s					IN		VARCHAR2,
 p_t					IN		VARCHAR2,
 p_debug				IN		INTEGER
)
RETURN INTEGER IS
 l_slen			INTEGER		:= NVL(LENGTH(p_s), 0);
 l_tlen			INTEGER		:= NVL(LENGTH(p_t), 0);
 TYPE lt_arrtype		IS TABLE OF NUMBER INDEX BY binary_integer;
 lt_dcol		lt_arrtype;
 l_dist			INTEGER		:= 0;
BEGIN
	IF l_slen = 0 THEN
		l_dist := l_tlen;
	ELSIF l_tlen = 0 THEN
		l_dist := l_slen;
	--******************************************************
	--** Bug 18237713 : If source or target length exceeds
	--** max DB password length that is 128 bytes, then 
	--**  raise exception.
	--******************************************************
   	ELSIF l_tlen > 128 AND l_slen > 128 then
		--
		activity_stream ( '', '', 'PASSWORD LENGTH', l_tlen||': '||l_tlen||' And l_slen: '||l_slen||', More Than 128 Bytes.', false, 1, 'P5', p_debug);
		--
		return(-1);
   	ELSIF l_tlen > 128 then
		--
		activity_stream ( '', '', 'PASSWORD LENGTH', l_tlen||': '||l_tlen||', More Than 128 Bytes.', false, 1, 'P5', p_debug);
		--
		return(-1);
	ELSIF l_slen > 128 THEN
		--
		activity_stream ( '', '', 'PASSWORD LENGTH', l_slen||': '||l_slen||', More Than 128 Bytes.', false, 1, 'P5', p_debug);
		--
		return(-1);
	ELSIF p_s = p_t THEN
		return(0);
	ELSE
		FOR j IN 1 .. (l_tlen+1) * (l_slen+1) - 1 LOOP
			lt_dcol(j) := 0 ;
		END LOOP;
		--
		FOR i IN 0 .. l_slen LOOP
			lt_dcol(i) := i;
		END LOOP;
		--
		FOR j IN 1 .. l_tlen LOOP
			lt_dcol(j * (l_slen + 1)) := j;
		END LOOP;
		--
		FOR i IN 1.. l_slen LOOP
			FOR j IN 1 .. l_tlen LOOP
				IF substr(p_s, i, 1) = substr(p_t, j, 1) THEN
					lt_dcol(j * (l_slen + 1) + i) := lt_dcol((j-1) * (l_slen+1) + i-1) ;
				ELSE
					lt_dcol(j * (l_slen + 1) + i) := LEAST (
						lt_dcol( j * (l_slen+1) + (i-1)) + 1,      -- Deletion
						lt_dcol((j-1) * (l_slen+1) + i) + 1,       -- Insertion
						lt_dcol((j-1) * (l_slen+1) + i-1) + 1 ) ;  -- Substitution
				END IF ;
			END LOOP;
		END LOOP;
		--
		l_dist :=  lt_dcol(l_tlen * (l_slen+1) + l_slen);
	END IF;
	--
	RETURN (l_dist);
	--
END string_distance;
--
--
--**************************************************************************************************************************
--**         Procedure:	spec_char
--**           Purpose:	This function returns a random special character.
--**  Calling Programs:	All.
--**   Programs Called: --
--**   Tables Accessed: --
--**   Tables Modified:	--
--**  Passed Variables:
--**			p_automation			-- Input Variable: value for g_iamautomation.
--**			p_status			-- Output Variable: Status message to check for errors.
--**			p_errormessage			-- Output Variable: The actual error message.
--**			p_debug				-- Output Variable: The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:
--**			l_localprogramname		-- This programs name. (For debugging purposes.)
--**			l_programmessage		-- The local debugging message.
--**           Cursors:	--
--**           pragmas: --
--**         Exception:	
--**			soau_failure
--**************************************************************************************************************************
--**        Pseudo code: 
--**			PW Length check 15 to 30
--**			Construct PW Meeting Compliance Rules
--**			Check for 3x repeating characters
--**			EXCEPTION
--**************************************************************************************************************************
--
--
FUNCTION spec_char  
RETURN CHAR 
IS
 l_randomindex			INTEGER			:= 1;
 l_spch				VARCHAR2(10); 
BEGIN
	--******************************************************************************
	--** set a random value to index the list of special characters below.
	--******************************************************************************
	l_randomindex := trunc(dbms_random.value(1,26));
	--******************************************************************************
	--** Choose a special character based of the value of random_index
	--******************************************************************************
	l_spch := CASE  l_randomindex
		WHEN  1 THEN  '|'
		WHEN  2 THEN '~'
		WHEN  3 THEN '!'
		WHEN  4 THEN '#' 
		WHEN  5 THEN '$'
		WHEN  6 THEN '%'
		WHEN  7 THEN '^'
		WHEN  8 THEN '*' 
		WHEN  9 THEN '('
		WHEN 10 THEN ')'
		WHEN 11 THEN '_'
		WHEN 12 THEN '-'
		WHEN 13 THEN '+'
		WHEN 14 THEN '='
		WHEN 15 THEN '{'
		WHEN 16 THEN '}'
		WHEN 17 THEN '['
		WHEN 18 THEN ']'
		WHEN 19 THEN '<'
		WHEN 20 THEN '>'
		WHEN 21 THEN ','
		WHEN 22 THEN '.'
		WHEN 23 THEN ';'
		WHEN 24 THEN '?'
		WHEN 25 THEN ':'
	END;  
	RETURN l_spch;
	--
END spec_char;  
--
--
--**************************************************************************************************************************
--**         Procedure:	secure_admin_user
--**           Purpose:	This procedure alters the user's password and sets the account status.
--**  Calling Programs:	All.
--**   Programs Called: --
--**   Tables Accessed: --
--**   Tables Modified:	--
--**  Passed Variables:
--**			user_name			-- Input Variable: Username to change password for.
--**			account_status			-- Input Variable: LOCK/UNLOCK status.
--**			p_status			-- Output Variable: Status message to check for errors.
--**			p_errormessage			-- Output Variable: The actual error message.
--**			p_debug				-- Output Variable: The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:
--**			sql_sqltext			-- Constructed SQL statement.
--**			pwd_string			-- Generated Password String.
--**			acct_stat			-- Username to change password for.
--**			l_localprogramname		-- This programs name. (For debugging purposes.)
--**			l_programmessage		-- The local debugging message.
--**           Cursors:	--
--**           pragmas: --
--**         Exception:	
--**			soau_failure
--**************************************************************************************************************************
--**        Pseudo code: 
--**			g_iamautomation := p_automation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE secure_admin_user
(
 p_username				IN		VARCHAR2,
 p_accountstatus			IN		VARCHAR2 DEFAULT 'LOCK',
 p_status				OUT		VARCHAR2,				-- Status message to check for errors.
 p_errormessage				OUT		VARCHAR2,				-- The actual error message.
 p_debug				IN		NUMBER					-- Turn on DEBUG.
)
IS 
 l_localprogramname				VARCHAR2(128) := 'secure_admin_user';
 l_programmessage				CLOB;
 l_pwdstring					VARCHAR2(30);
 l_acctstat					VARCHAR2(20);
BEGIN
	--
	l_pwdstring := fs_security_pkg.random_password(30, p_debug);
	--
	IF upper (p_username) in ('SYS', 'SYSTEM', 'DBSNMP') OR upper (p_accountstatus) = 'UNLOCK'THEN
		l_acctstat := 'ACCOUNT UNLOCK';
		--
		IF SYS_CONTEXT( 'USERENV', 'CURRENT_SCHEMA' ) = 'SYS' AND upper (p_username) = 'SYS' THEN
			--
			activity_stream ( 'ALTER USER ' || lower(p_username) || ' IDENTIFIED BY "' || l_pwdstring || '" ' || l_acctstat,
					  'ALTER USER ' || lower(p_username)|| ' IDENTIFIED BY "' || 'HIDDEN' || '" ' || l_acctstat,
					  'USER', 'Password For '||lower(p_username)||' And Lock Status Set: '||l_acctstat||'.', false, 1, 'P1', p_debug);
			--
		ELSIF  SYS_CONTEXT( 'USERENV', 'CURRENT_SCHEMA' ) <> 'SYS' AND upper (p_username) = 'SYS' THEN
			--
			activity_stream ( '', '','USER PASSWORD', 'SYS Password Can only be Modified by Logging Into SYS or as sysdba.', false, 1, 'P3', p_debug);
			--
		ELSE
			--
			activity_stream ( 'ALTER USER ' || lower(p_username) || ' IDENTIFIED BY "' || l_pwdstring || '" ' || l_acctstat,
					  'ALTER USER ' || lower(p_username)|| ' IDENTIFIED BY "' || 'HIDDEN' || '" ' || l_acctstat,
					  'USER', 'Password For '||lower(p_username)||' And Lock Status Set: '||l_acctstat||'.', false, 1, 'P1', p_debug);
			--
		END IF;
		--
	ELSIF upper (p_accountstatus) = 'LOCK' THEN
		l_acctstat := 'ACCOUNT LOCK';
		--
		activity_stream ( 'ALTER USER ' || lower(p_username) || ' IDENTIFIED BY "' || l_pwdstring || '" ' || l_acctstat,
			 	  'ALTER USER ' || lower(p_username)|| ' IDENTIFIED BY "' || 'HIDDEN' || '" ' || l_acctstat,
				  'USER', 'Alter(ed) Password For '||lower(p_username)||' And Lock Status Set: '||l_acctstat||'.', false, 1, 'P1', p_debug);
		--
	ELSE
		--
		activity_stream ( '', '', 'CODE ERROR', 'secure_admin_user Input Value p_accountstatus: '||upper (p_accountstatus)||' Is An Incorrect Value.', false, 1, 'P5', p_debug);
		--
	END IF;
	--
EXCEPTION
	WHEN OTHERS THEN
		p_status := 'Error';
		p_errormessage := l_localprogramname||':'||sqlcode||':'||sqlerrm;
		IF g_iamautomation = false OR p_debug > 0 THEN
			dbms_output.put_line(p_errormessage);
		END IF;
END secure_admin_user;
--
--
--**************************************************************************************************************************
--**         Procedure:	drop_login_db_instances_obj
--**           Purpose:	This procedure drops the objects and grants surrounding login_db_instances objects.
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
--**        Pseudo code: 
--**			RETURN g_iamautomation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE drop_login_db_instances_obj
(
 p_debug				IN		NUMBER
)
AS
--
 l_localprogramname			VARCHAR2(128) := 'drop_login_db_instances_obj';
 l_programmessage			CLOB;
 l_sqltext				CLOB;
 l_count				NUMBER;
 l_verifycount				NUMBER;
 l_boolean				BOOLEAN;
 l_pathtrue				VARCHAR2(3);
 l_pathfalse				VARCHAR2(3);
--
BEGIN
	IF g_programcontext = 'provide_dbinstances_objects' THEN
		l_verifycount := 0;
		l_pathfalse := 'P3';
		l_pathtrue := 'P4';
		g_droplegobj := true;
	ELSE
		l_verifycount := 1;
		l_pathfalse := 'P1';
		l_pathtrue := 'P2';
		g_droplegobj := false;
	END IF;
	--
	--********************************
	--* Drop Synonyms
	--********************************
	--
	l_boolean := fs_db_admin.fs_exists_functions.synonym_exists ('LOGIN_DB_INSTANCES','INSTANCE_ID_SEQ','FSDBA', 'INSTANCE_ID_SEQ');
	--
	IF l_boolean = true THEN
		l_sqltext := 'DROP SYNONYM login_db_instances.instance_id_seq';
		--
		activity_stream ( l_sqltext, '', 'SYNONYM DOES NOT EXIST', 'LOGIN_DB_INSTANCES.INSTANCE_ID_SEQ For FSDBA.INSTANCE_ID_SEQ.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'SYNONYM DOES NOT EXIST', 'LOGIN_DB_INSTANCES.INSTANCE_ID_SEQ For FSDBA.INSTANCE_ID_SEQ.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	g_droplegobj := false;
	--
END drop_login_db_instances_obj;
--
--
--**************************************************************************************************************************
--**         Procedure:	drop_fsdba_obj
--**           Purpose:	This procedure drops the objects and grants surrounding fsdba objects.
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
--**        Pseudo code: 
--**			RETURN g_iamautomation
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE drop_fsdba_obj
(
 p_debug				IN		NUMBER
)
AS
--
 l_localprogramname			VARCHAR2(128) := 'drop_fsdba_obj';
 l_programmessage			CLOB;
 l_sqltext				CLOB;
 l_verifycount				NUMBER;
 l_boolean				BOOLEAN;
 l_pathtrue				VARCHAR2(3);
 l_pathfalse				VARCHAR2(3);
--
BEGIN
	IF g_programcontext = 'provide_dbinstances_objects' THEN
		l_verifycount := 0;
		l_pathfalse := 'P3';
		l_pathtrue := 'P4';
		g_droplegobj := true;
	ELSE
		l_verifycount := 1;
		l_pathfalse := 'P1';
		l_pathtrue := 'P2';
		g_droplegobj := false;
	END IF;
	--
	--********************************
	--* Drop Synonyms
	--********************************
	--
	l_boolean := fs_db_admin.fs_exists_functions.synonym_exists ('PUBLIC','THIS_DB_INSTANCE','FSDBA', 'THIS_DB_INSTANCE');
	--
	IF l_boolean = true THEN
		l_sqltext := 'DROP PUBLIC SYNONYM this_db_instance';
		--
		activity_stream ( l_sqltext, '', 'SYNONYM DOES NOT EXIST', 'PUBLIC.THIS_DB_INSTANCE For FSDBA.THIS_DB_INSTANCE.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'SYNONYM DOES NOT EXIST', 'PUBLIC.THIS_DB_INSTANCE For FSDBA.THIS_DB_INSTANCE.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	l_boolean := fs_db_admin.fs_exists_functions.synonym_exists ('PUBLIC','THIS_DB_INSTANCE_INFO','FSDBA', 'THIS_DB_INSTANCE_INFO');
	--
	IF l_boolean = true THEN
		l_sqltext := 'DROP PUBLIC SYNONYM this_db_instance_info';
		--
		activity_stream ( l_sqltext, '', 'SYNONYM DOES NOT EXIST', 'PUBLIC.THIS_DB_INSTANCE_INFO For FSDBA.THIS_DB_INSTANCE_INFO.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'SYNONYM DOES NOT EXIST', 'PUBLIC.THIS_DB_INSTANCE_INFO For FSDBA.THIS_DB_INSTANCE_INFO.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	l_boolean := fs_db_admin.fs_exists_functions.synonym_exists ('PUBLIC','DB_INSTANCE','FSDBA', 'DB_INSTANCE');
	--
	IF l_boolean = true THEN
		l_sqltext := 'DROP PUBLIC SYNONYM db_instance';
		--
		activity_stream ( l_sqltext, '', 'SYNONYM DOES NOT EXIST', 'PUBLIC.DB_INSTANCE For FSDBA.DB_INSTANCE.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'SYNONYM DOES NOT EXIST', 'PUBLIC.DB_INSTANCE For FSDBA.DB_INSTANCE.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	l_boolean := fs_db_admin.fs_exists_functions.synonym_exists ('PUBLIC','DB_INSTANCES','FSDBA', 'DB_INSTANCES');
	--
	IF l_boolean = true THEN
		l_sqltext := 'DROP PUBLIC SYNONYM db_instances ';
		--
		activity_stream ( l_sqltext, '', 'SYNONYM DOES NOT EXIST', 'PUBLIC.DB_INSTANCES For FSDBA.DB_INSTANCES.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'SYNONYM DOES NOT EXIST', 'PUBLIC.DB_INSTANCES For FSDBA.DB_INSTANCES.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	--************************************
	--** REMOVE COMMENTS
	--************************************
	--
	l_boolean := fs_db_admin.fs_exists_functions.tabcom_exists ('Version: V4.0, Effective Date: 15 May 2012, Created by: Puppet DB Instances Install.', 'FSDBA','THIS_DB_INSTANCE_INFO');
	--
	IF l_boolean = true THEN
		--
		l_sqltext := 'COMMENT ON TABLE fsdba.this_db_instance_info IS '||''''||'''';
		--
		activity_stream ( l_sqltext, '', 'COMMENT DOES NOT EXIST', 'FSDBA.THIS_DB_INSTANCE_INFO.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'COMMENT DOES NOT EXIST', 'FSDBA.THIS_DB_INSTANCE_INFO.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	l_boolean := fs_db_admin.fs_exists_functions.tabcom_exists ('Version: V4.0, Effective Date: 15-May-2012, Created by: Puppet DB Instances Install.', 'FSDBA','THIS_DB_INSTANCE');
	--
	IF l_boolean = true THEN
		--
		l_sqltext := 'COMMENT ON TABLE fsdba.this_db_instance IS '||''''||'''';
		--
		activity_stream ( l_sqltext, '', 'COMMENT DOES NOT EXIST', 'FSDBA.THIS_DB_INSTANCE.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'COMMENT DOES NOT EXIST', 'FSDBA.THIS_DB_INSTANCE.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	--************************************
	--** REVOKE GRANTS
	--************************************
	--
	l_boolean := fs_db_admin.fs_exists_functions.tabprivs_exists ('FSDBA','DB_INSTANCES','PUBLIC', 'SELECT');
	--
	IF l_boolean = true THEN
		l_sqltext := 'REVOKE SELECT ON fsdba.db_instances FROM PUBLIC';
		--
		activity_stream ( l_sqltext, '', 'TABPRIV DOES NOT EXIST', 'SELECT On FSDBA.DB_INSTANCES To PUBLIC.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'TABPRIV DOES NOT EXIST', 'SELECT On FSDBA.DB_INSTANCES To PUBLIC.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	l_boolean := fs_db_admin.fs_exists_functions.tabprivs_exists ('FSDBA','THIS_DB_INSTANCE','PUBLIC', 'SELECT');
	--
	IF l_boolean = true THEN
		l_sqltext := 'REVOKE SELECT ON fsdba.this_db_instance FROM PUBLIC';
		--
		activity_stream ( l_sqltext, '', 'TABPRIV DOES NOT EXIST', 'SELECT On FSDBA.THIS_DB_INSTANCE To PUBLIC.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'TABPRIV DOES NOT EXIST', 'SELECT On FSDBA.THIS_DB_INSTANCE To PUBLIC.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	l_boolean := fs_db_admin.fs_exists_functions.tabprivs_exists ('FSDBA','THIS_DB_INSTANCE_INFO','PUBLIC', 'SELECT');
	--
	IF l_boolean = true THEN
		l_sqltext := 'REVOKE SELECT ON fsdba.this_db_instance_info FROM PUBLIC';
		--
		activity_stream ( l_sqltext, '', 'TABPRIV DOES NOT EXIST', 'SELECT On FSDBA.THIS_DB_INSTANCE_INFO To PUBLIC.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'TABPRIV DOES NOT EXIST', 'SELECT On FSDBA.THIS_DB_INSTANCE_INFO To PUBLIC.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	l_boolean := fs_db_admin.fs_exists_functions.tabprivs_exists ('FSDBA','DB_INSTANCE','PUBLIC', 'EXECUTE');
	--
	IF l_boolean = true THEN
		l_sqltext := 'REVOKE EXECUTE ON fsdba.db_instance FROM PUBLIC';
		--
		activity_stream ( l_sqltext, '', 'TABPRIV DOES NOT EXIST', 'EXECUTE On FSDBA.DB_INSTANCE To PUBLIC.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'TABPRIV DOES NOT EXIST', 'EXECUTE On FSDBA.DB_INSTANCE To PUBLIC.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	--
	--************************************
	--** Drop Package And Package Body
	--** fsdba.db_instance
	--************************************
	--
	l_boolean := fs_db_admin.fs_exists_functions.object_exists ('FSDBA','DB_INSTANCE','PACKAGE BODY');
	--
	IF l_boolean = true THEN
		l_sqltext := 'DROP PACKAGE BODY fsdba.db_instance';
		--
		activity_stream ( l_sqltext, '', 'PACKAGE BODY DOES NOT EXIST', 'FSDBA.DB_INSTANCE.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'PACKAGE BODY DOES NOT EXIST', 'FSDBA.DB_INSTANCE.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	l_boolean := fs_db_admin.fs_exists_functions.object_exists ('FSDBA','DB_INSTANCE','PACKAGE');
	--
	IF l_boolean = true THEN
		l_sqltext := 'DROP PACKAGE fsdba.db_instance';
		--
		activity_stream ( l_sqltext, '', 'PACKAGE DOES NOT EXIST', 'FSDBA.DB_INSTANCE.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'PACKAGE DOES NOT EXIST', 'FSDBA.DB_INSTANCE.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	--************************************
	--* Drop View fsdba.this_db_instance_info
	--************************************
	--
	l_boolean := fs_db_admin.fs_exists_functions.object_exists ('FSDBA','THIS_DB_INSTANCE_INFO','VIEW');
	--
	IF l_boolean = true THEN
		l_sqltext := 'DROP VIEW fsdba.this_db_instance_info';
		--
		activity_stream ( l_sqltext, '', 'VIEW DOES NOT EXIST', 'FSDBA.THIS_DB_INSTANCE_INFO.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'VIEW DOES NOT EXIST', 'FSDBA.THIS_DB_INSTANCE_INFO.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	--**************************************
	--* Drop Sequences
	--**************************************
	--
	l_boolean := fs_db_admin.fs_exists_functions.object_exists ('FSDBA','INSTANCE_ID_SEQ','SEQUENCE');
	--
	IF l_boolean = true THEN
		l_sqltext := 'DROP SEQUENCE fsdba.instance_id_seq';
		--
		activity_stream ( l_sqltext, '', 'SEQUENCE DOES NOT EXIST', 'FSDBA.INSTANCE_ID_SEQ.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'SEQUENCE DOES NOT EXIST', 'FSDBA.INSTANCE_ID_SEQ.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	--********************************
	--* Drop Tables
	--********************************
	--
	l_boolean := fs_db_admin.fs_exists_functions.object_exists ('FSDBA','DB_INSTANCES','TABLE');
	--
	IF l_boolean = true THEN
		l_sqltext := 'DROP TABLE fsdba.db_instances';
		--
		activity_stream ( l_sqltext, '', 'TABLE NONEXISTENCE', 'FSDBA.DB_INSTANCES.', false, l_verifycount, l_pathfalse, p_debug);
	ELSE 
		--
		activity_stream ( '', '', 'TABLE NONEXISTENCE', 'FSDBA.DB_INSTANCES.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	l_boolean := fs_db_admin.fs_exists_functions.object_exists ('FSDBA','THIS_DB_INSTANCE','TABLE');
	--
	IF l_boolean = true THEN
		l_sqltext := 'DROP TABLE fsdba.this_db_instance';
		--
		activity_stream ( l_sqltext, '', 'TABLE NONEXISTENCE', 'FSDBA.THIS_DB_INSTANCE.', false, l_verifycount, l_pathfalse, p_debug);
		--
	ELSE 
		--
		activity_stream ( '', '', 'TABLE NONEXISTENCE', 'FSDBA.THIS_DB_INSTANCE.', true, l_verifycount, l_pathtrue, p_debug);
		--
	END IF;
	--
	g_droplegobj := false;
	--
END drop_fsdba_obj;
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
--**        Pseudo code: 
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
--**        Pseudo code: 
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
--**        Pseudo code: 
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
END;
--
--
--**************************************************************************************************************************
--**         Procedure:	fs_password_verify
--**           Purpose:	This procedure sets the value of the global variable g_iamautomation.
--**  Calling Programs:	All.
--**   Programs Called: --
--**   Tables Accessed: --
--**   Tables Modified:	--
--**  Passed Variables:
--**			p_automation			-- Input Variable: value for g_iamautomation.
--**			p_status			-- Output Variable: Status message to check for errors.
--**			p_errormessage			-- Output Variable: The actual error message.
--**			p_debug				-- Output Variable: The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:
--**			l_localprogramname		-- This programs name. (For debugging purposes.)
--**			l_programmessage		-- The local debugging message.
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**           NOTICE:	This code copied from Oracle provided scripts 
--**			rdbms/admin/catpvf.sql - Create Password Verify Function, STIG profile
--**			Copyright (c) 2013, 2016, Oracle and/or its affiliates. All rights reserved.
--**************************************************************************************************************************
--**        Pseudo code: 
--**			PW Length check 15 to 30
--**			Construct PW Meeting Compliance Rules
--**			Check for 3x repeating characters
--**			EXCEPTION
--**************************************************************************************************************************
--
--
FUNCTION fs_password_verify
(
 p_username				IN		VARCHAR2,
 p_password				IN		VARCHAR2,
 p_oldpassword				IN		VARCHAR2
)
RETURN boolean
IS
 l_localprogramname			VARCHAR2(128)		:= 'fs_password_verify';
 l_programmessage			CLOB;
 l_pwverifycnt				INTEGER			:= 0;
 l_m					INTEGER;
 l_differ				INTEGER;
 l_repeat				BOOLEAN;
 l_threechar				VARCHAR2(3);
BEGIN
	--
	--**********************************************************
	--** STIG ID: O121-C2-014500 - Check if the password differs
	--** from the previous password by at least 8 characters 
	--**********************************************************
	--
	IF p_oldpassword IS NOT NULL THEN
		l_differ := string_distance(p_oldpassword, p_password, g_debug);
		IF l_differ < 8 THEN
			--
			activity_stream ( '', '', 'USER', p_username||': New Password Should Differ From Previous Password By At Least 8 Characters.', false, 1, 'P5', g_debug);
			--
			l_pwverifycnt := l_pwverifycnt+1;
		END IF;
	END IF;
	--
	--*************************************************************
	--** STIG ID: O121-C2-013900 - must be at least 12 bytes
	--** in length.
	--*************************************************************
	--
	IF LENGTH(p_password) < 12 THEN
		--
		activity_stream ( '', '', 'USER', p_username||': Password Length Less Than 15 Bytes In Length.', false, 1, 'P5', g_debug);
		--
		l_pwverifycnt := l_pwverifycnt+1;
	END IF;
	--
	--*************************************************************
	--** STIG ID: O121-C2-014100 - require 2 upper case characters
	--** STIG ID: O121-C2-014200 - require 2 lower case characters
	--** STIG ID: O121-C2-014300 - require 2 numeric characters
	--** STIG ID: O121-C2-014400 - require 2 special characters
    	--** Points to Agency olicy that is on 1 character of each
	--*************************************************************
	--
	IF REGEXP_COUNT(p_password, '([1234567890])', 1) < 1 OR REGEXP_COUNT(p_password, '([abcdefghijklmnopqrstuvwxyz])', 1, 'c') < 1 
		OR REGEXP_COUNT(p_password, '([ABCDEFGHIJKLMNOPQRSTUVWXYZ])', 1, 'c') < 1 OR count_special(p_password, g_debug)  < 1 THEN
		--
		activity_stream ( '', '', 'USER', p_username||': Password must contain at least two upper, two lower, two numbers and two special characters.', false, 1, 'P5', g_debug);
		--
		l_pwverifycnt := l_pwverifycnt+1;
	END IF;
	--
	--*************************************************************
	--** STIG ID: N/A AC-14/IA-2/4/5/6/8 IDENTIFICATION AND 
	--** AUTHENTICATION 4.7.2 Do not allow dictionary words.
	--*************************************************************
	--
	IF NLS_UPPER(p_password) like '%SMOKEY%BEAR%' OR NLS_UPPER(p_password) like '%FOREST%SERVICE%' OR NLS_UPPER(p_password) like '%WOODSY%OWL%' 
		OR NLS_UPPER(p_password) like '%NATIONAL%FOREST%' OR (INSTR(NLS_UPPER(p_password),TO_CHAR(sysdate, 'MONTH')) > 0 AND 
		INSTR(NLS_UPPER(p_password),TO_CHAR(sysdate, 'YYYY')) > 0) THEN
		--
		activity_stream ( '', '', 'USER', p_username||': Password too simple.', false, 1, 'P5', g_debug);
		--
		l_pwverifycnt := l_pwverifycnt+1;
	END IF;
	--
	--*************************************************************
	--** STIG ID: N/A - Check to see if characters are repeated 
	--** more than twice Included this check as a best pactice.
	--*************************************************************
	--
	l_m := length(p_password);
	FOR i IN 1..l_m LOOP
		IF i < l_m-1 THEN
			IF substr(p_password,i,1) = substr(p_password,i+1,1) AND substr(p_password,i,1) = substr(p_password,i+2,1) THEN
				l_repeat := true;
				l_threechar := substr(p_password,i,1)||substr(p_password,i+1,1)||substr(p_password,i+2,1);
			END IF;
		END IF;
	END LOOP;
	--
	IF l_repeat = true THEN
		--
		activity_stream ( '', '', 'USER', p_username||': Password contains a character repeated 3 or more times: '||l_threechar||'.', false, 1, 'P5', g_debug);
		--
		l_pwverifycnt := l_pwverifycnt+1;
	END IF;
	--
	--*************************************************************
	--** STIG ID: N/A - Check if the password contains the  
	--** username. Included this check as a best pactice.
	--*************************************************************
	--
	IF REGEXP_COUNT(p_password, p_username, 1, 'i') > 0 OR REGEXP_COUNT(p_password, SYS_CONTEXT('USERENV', 'SESSION_USER'), 1, 'i') > 0 
		OR REGEXP_COUNT(p_password, SYS_CONTEXT('USERENV', 'OS_USER'), 1, 'i') > 0 THEN
		--
		activity_stream ( '', '', 'USER', p_username||': Password should not contain username.', false, 1, 'P5', g_debug);
		--
		l_pwverifycnt := l_pwverifycnt+1;
	END IF;
	--
	--*************************************************************
	--** STIG ID: N/A - Check if the password contains the database
	--** name. Included this check as a best pactice.
	--*************************************************************
	--
	IF REGEXP_COUNT(p_password, SYS_CONTEXT('USERENV', 'DB_NAME'), 1, 'i') > 0 THEN
		--
		activity_stream ( '', '', 'USER', p_username||': Password should not contain the database name.', false, 1, 'P5', g_debug);
		--
		l_pwverifycnt := l_pwverifycnt+1;
	END IF;
	--
	--*************************************************************
	--** STIG ID: N/A - Check if the password contains the server
	--** name. Included this check as a best pactice.
	--*************************************************************
	--
	IF REGEXP_COUNT(p_password, SYS_CONTEXT('USERENV', 'SERVER_HOST'), 1, 'i') > 0 THEN
		--
		activity_stream ( '', '', 'USER', p_username||': Password should not contain the server name.', false, 1, 'P5', g_debug);
		--
		l_pwverifycnt := l_pwverifycnt+1;
	END IF;
	--
	--*************************************************************
	--** If all checks passed, then return TRUE.
	--*************************************************************
	--
	IF l_pwverifycnt = 0 THEN
		RETURN(true);
	ELSE
		RETURN(false);
	END IF;
	--
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line(SQLERRM);
	RETURN FALSE;
END fs_password_verify;
--
--
--**************************************************************************************************************************
--**         Procedure:	random_password
--**           Purpose:	This procedure sets the value of the global variable g_iamautomation.
--**  Calling Programs:	All.
--**   Programs Called: --
--**   Tables Accessed: --
--**   Tables Modified:	--
--**  Passed Variables:
--**			p_automation			-- Input Variable: value for g_iamautomation.
--**			p_status			-- Output Variable: Status message to check for errors.
--**			p_errormessage			-- Output Variable: The actual error message.
--**			p_debug				-- Output Variable: The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:
--**			l_localprogramname		-- This programs name. (For debugging purposes.)
--**			l_programmessage		-- The local debugging message.
--**           Cursors:	--
--**           pragmas: --
--**         Exception:	
--**			soau_failure
--**************************************************************************************************************************
--**        Pseudo code: 
--**			PW Length check 15 to 30
--**			Construct PW Meeting Compliance Rules
--**			Check for 3x repeating characters
--**			EXCEPTION
--**************************************************************************************************************************
--
--
FUNCTION random_password
(
 p_pwlength				IN		INTEGER DEFAULT 15,
 p_debug				IN		NUMBER					-- Turn on DEBUG.
)
RETURN VARCHAR2
IS
 l_localprogramname			VARCHAR2(128)		:= 'random_password';
 l_programmessage			CLOB;
 l_pwvalue				VARCHAR2(50); 
 l_padlen				NUMBER(3)		:= 0;
 l_pwlength				NUMBER(3);
 l_strndx				NUMBER(1);
 l_pwverify				BOOLEAN			:= false;
BEGIN
	--
	--******************************************************************************
	--** The PW complexity requirements will be met in the first eight characters, 
	--** the remaining positions will be filled with random alpha characters. 
	--******************************************************************************
	--
	IF p_pwlength BETWEEN 15 AND 30 THEN 
		l_padlen := p_pwlength - 8;
		l_pwlength := p_pwlength;
	ELSIF p_pwlength < 15 THEN
		l_pwlength := 15;
		l_padlen := l_pwlength-8;
		--
		activity_stream ( '', '', 'PASSWORD LENGTH', p_pwlength||' Too Small. Modified To 15.', false, 1, 'P5', p_debug);
		--
	ELSIF p_pwlength > 30 THEN
		l_pwlength := 30;
		l_padlen := l_pwlength-8;
		--
		activity_stream ( '', '', 'PASSWORD LENGTH', p_pwlength||' Too Large. Modified To 30.', false, 1, 'P5', p_debug);
		--
	ELSE
		--
		activity_stream ( '', '', 'CODE ERROR', 'secure_admin_user Password Length Failure p_pwlength: '||p_pwlength||'. Setting Password Length To 15', false, 1, 'P5', p_debug);
		--
		l_pwlength := 15;
		l_padlen := l_pwlength-8;
	END IF;
	--
	WHILE l_pwverify = false LOOP
		--
		--******************************************************************************
		--** build a random string which meets password complexity rules.
		--******************************************************************************
		--
		l_pwvalue := dbms_random.string('U',2)         -- Two Upper Case
			|| trunc (dbms_random.value(0,10))   -- One Number (1 of 2)
			|| spec_char                         -- One Special Character (1 of 2)
			|| dbms_random.string('L',2)         -- Two Lower Case 
			|| trunc (dbms_random.value(0,10))   -- One Number (2 of 2)
			|| spec_char                         -- One Special Character (2 of 2) 
			|| dbms_random.string('A',l_padlen);  -- fill remaining with mixed case. 
		--
		--******************************************************************************
		--** check for characters repeated more than three times in a row.
		--******************************************************************************
		--
		FOR i IN 1..(l_pwlength - 2 ) LOOP
			IF substr(l_pwvalue,i,1) = substr(l_pwvalue,i+1,1) AND substr(l_pwvalue,i,1) = substr(l_pwvalue,i+2,1) THEN
				IF g_iamautomation = false OR p_debug > 0 THEN
					dbms_output.put_line('RETRY: Characters Repeated 3 Times Or More In A Row.'||substr(l_pwvalue,i,1)||substr(l_pwvalue,i+1,1)||substr(l_pwvalue,i+2,1));
				END IF;
				EXIT;
			END IF;
			IF i = l_pwlength - 2 THEN
				l_pwverify := true;
			END IF;
		END LOOP;
	END LOOP;
	--
	RETURN l_pwvalue;
	--
END random_password;
--
--
--**************************************************************************************************************************
--**         Procedure:	secure_users
--**           Purpose:	This procedure is generic debug procedure called when p_debug > 0.
--**  Calling Programs:	All.
--**   Programs Called:	
--**			fs_db_admin.fs_exists_functions
--**			fs_security_pkg.activity_stream
--**			fs_security_pkg.secure_admin_user
--**			dbms_output
--**   Tables Accessed:	
--**			dba_users
--**   Tables Modified:	--
--**  Passed Variables:
--**			p_action			-- p, l, b
--**			p_status			-- Status message to check for errors.
--**			p_error_message			-- The actual error message.
--**			p_debug				-- The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:
--**			l_localprogramname		-- This programs name. (For debugging purposes.)
--**			l_programmessage		-- The local debugging message.
--**           Cursors:	C1				-- oracle_maintained = 'Y'
--**			C2				-- oracle_maintained = 'N'
--**           pragmas: --
--**         Exception:	
--**			soau_failure
--**************************************************************************************************************************
--**        Pseudo code: 
--**			SELECT dba_users oracle_maintained = 'Y' and username NOT IN ('XS$NULL')
--**				LOOP
--**				CASE
--**					WHEN username 'SYS', 'SYSTEM'
--**						secure_admin_user: scramble password and unlock account
--**					WHEN username 'DBSNMP'
--**						if Never logged in
--**							secure_admin_user: scramble password and unlock account
--**						else
--**							unlock account
--**					WHEN account_status locked
--**						message
--**					ELSE
--**						secure_admin_user: scramble password and lock account
--**				END LOOP
--**			SELECT dba_users oracle_maintained = 'N' AND substr(username,1,3) = 'FS_'
--**				LOOP
--**				CASE
--**					WHEN x.account_status like '%LOCKED%'
--**						dbms_output
--**					ELSE
--**						secure_admin_user: scramble password and lock account
--**				END LOOP
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE secure_users
(
 p_action				IN		VARCHAR2 DEFAULT 'b',				-- p, l, b
 p_status				OUT		VARCHAR2,				-- Status message to check for errors.
 p_errormessage				OUT		VARCHAR2,				-- The actual error message.
 p_debug				IN		NUMBER					-- Turn on DEBUG.
)
IS
 CURSOR c1 IS
	SELECT username, account_status, last_login 
	FROM dba_users 
	WHERE oracle_maintained = 'Y'
	AND username NOT IN ('XS$NULL')
	ORDER BY username;
 --
 CURSOR c2 IS
	SELECT username, account_status 
	FROM dba_users 
	WHERE oracle_maintained = 'N'
	AND (substr(username,1,3) = 'FS_'
	OR username = 'FSDBA'
	OR username = 'FS_DB_ADMIN')
	ORDER BY username;
 --
 l_localprogramname			VARCHAR2(128) := 'secure_users';
 l_programmessage			CLOB;
 l_sqltext				VARCHAR2(1000);
 l_status				VARCHAR2(15);
 l_errormessage				VARCHAR2(1000);
 soau_failure				EXCEPTION;
BEGIN
	--
	IF LOWER(p_action) = 'p' OR LOWER(p_action) = 'b' THEN
		FOR c1_rec IN c1 LOOP
			--
			IF p_debug > 0 THEN
			dbms_output.put_line('Username: '||c1_rec.username);
			END IF;
			--
			IF c1_rec.username IN ('SYS', 'SYSTEM') THEN
				fs_security_pkg.secure_admin_user(c1_rec.username,'UNLOCK',l_status,l_errormessage,p_debug);
			--			
			--***************************************************************************
			--** for DBSNMP, ensure acccount is unlocked, but only change PW if the 
			--** account has never been logged on...created, but not set up in OEM yet.
			--** Once the account has been set up in OEM, just ensure it's unlocked.
			--***************************************************************************
			--
			ELSIF c1_rec.username = ('DBSMNP') THEN  
				IF c1_rec.last_login IS NULL THEN
					fs_security_pkg.secure_admin_user(c1_rec.username,'UNLOCK',l_status,l_errormessage,p_debug);
				ELSE
					IF c1_rec.account_status LIKE '%LOCKED%' THEN
						--
						activity_stream ( 'ALTER USER DBSNMP ACCOUNT UNLOCK', '', 'USER', 'DBSNMP Alter(ed) Account To Unlocked.', false, 1, 'P1', p_debug);
						--
					END IF;
				END IF;
			ELSIF c1_rec.account_status LIKE '%LOCKED%' THEN
				--
				activity_stream ( '', '', 'User', c1_rec.username||' Was Locked.', true, 1, 'P2', p_debug);
				--
			ELSE
				fs_security_pkg.secure_admin_user(c1_rec.username,'LOCK',l_status,l_errormessage,p_debug);
			END IF;
		END LOOP;
	END IF;
	--
	IF LOWER(p_action) = 'l' OR LOWER(p_action) = 'b' THEN
		FOR c2_rec IN c2 LOOP
			IF c2_rec.account_status like '%LOCKED%' then
				--
				activity_stream ( '', '', 'User', c2_rec.username||' Was Locked.', true, 1, 'P2', p_debug);
				--
			ELSE
				fs_security_pkg.secure_admin_user(c2_rec.username,'LOCK',l_status,l_errormessage,p_debug);
			END IF;
		END LOOP;
	END IF;
	--
END secure_users;
--
--
--**************************************************************************************************************************
--**         Procedure:	provide_dbinstances_objects
--**           Purpose:	This procedure creates or destroys the FSDBA DBInstances objects based on the value of the 
--**			p_dbinstancesobjectschoice 
--**				t = Build Original DBInstances Objects
--**				f = Do not build Original DBInstances Objects and remove them if they exist.
--**  Calling Programs:	--
--**   Programs Called:	fs_db_admin.fs_exists_functions
--**			fs_security_pkg.activity_stream
--**			drop_login_db_instances_obj
--**			drop_fsdba_obj
--**   Tables Accessed:	
--**			fsdba.this_db_instance
--**			fsdba.db_instances
--**   Tables Modified:	--
--**  Passed Variables: 
--**			p_dbinstancesobjectschoice	-- Choice Variable
--**			p_status			-- Status message to check for errors.
--**			p_errormessage			-- The actual error message.
--**			p_debug				-- The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:
--**			l_localprogramname		-- This programs name. (For debugging purposes.)
--**			l_programmessage		-- The local debugging message.
--**			l_sqltext			-- The DDL text
--**			l_count				-- Count Variable
--**			l_boolean			-- Choice Boolean
--**           Cursors:	--
--**           pragmas: --
--**         Exception:	
--**			soau_failure
--**************************************************************************************************************************
--**        Pseudo code: 
--**			IF LOWER(p_dbinstancesobjectschoice) = 't'
--**				CREATE all DBInstances objects
--**			IF LOWER(p_dbinstancesobjectschoice) = 'f'
--**				Remove all DBInstances objects
--**************************************************************************************************************************
--
--
PROCEDURE provide_dbinstances_objects
(
 p_dbinstancesobjectschoice		IN		VARCHAR2,				-- Selection t, f.
 p_status				OUT		VARCHAR2,				-- Status message to check for errors.
 p_errormessage				OUT		VARCHAR2,				-- The actual error message.
 p_debug				IN		NUMBER					-- Turn on DEBUG.
)
AS
--
 l_localprogramname			VARCHAR2(128) := 'provide_dbinstances_objects';
 l_programmessage			CLOB;
 l_sqltext				CLOB;
 l_count				NUMBER;
 l_boolean				BOOLEAN;
--
BEGIN
	--
	g_programcontext := l_localprogramname;
	g_providedbinstancesobjectspasscnt := 0;
	g_providedbinstancesobjectsfailcnt := 0;
	activity_stream ( '', '', 'DETAIL', 'PROVIDE DBINSTANCES OBJECTS', true, 0, 'P6', p_debug);
	--
	IF LOWER(p_dbinstancesobjectschoice) = 't' THEN
		--
		--********************************
		--* Build Table fsdba.db_instances
		--********************************
		--
		l_boolean := fs_db_admin.fs_exists_functions.object_exists ('FSDBA','DB_INSTANCES','TABLE');
		--
		IF l_boolean = false THEN
			--
			l_sqltext := 'CREATE TABLE fsdba.db_instances ('|| chr(10);
			l_sqltext := l_sqltext||' instance_id                              NUMBER(6)    Not null,'|| chr(10);
			l_sqltext := l_sqltext||' instance_name                            VARCHAR2(24) Not null,'|| chr(10);
			l_sqltext := l_sqltext||' db_server_name                           VARCHAR2(50) Not null,'|| chr(10);
			l_sqltext := l_sqltext||' db_server_domain                         VARCHAR2(50) Not null,'|| chr(10);
			l_sqltext := l_sqltext||' effective_date                           DATE         Not null,'|| chr(10);
			l_sqltext := l_sqltext||' expiration_date                          DATE,'|| chr(10);
			l_sqltext := l_sqltext||' created_by                               VARCHAR2(90) Not null,'|| chr(10);
			l_sqltext := l_sqltext||' created_date                             DATE Not null,'|| chr(10);
			l_sqltext := l_sqltext||' modified_by                              VARCHAR2(90),'|| chr(10);
			l_sqltext := l_sqltext||' modified_date                            DATE'|| chr(10);
			l_sqltext := l_sqltext||')'|| chr(10);
			l_sqltext := l_sqltext||'TABLESPACE FSDBA_DATA';
			--
			activity_stream ( l_sqltext, '', 'TABLE EXISTS', 'FSDBA.DB_INSTANCES.', false, 1, 'P1', p_debug);
			--
			l_sqltext := 'INSERT INTO fsdba.db_instances (';
			l_sqltext := l_sqltext||' 	INSTANCE_ID,';
			l_sqltext := l_sqltext||' 	INSTANCE_NAME,';
			l_sqltext := l_sqltext||' 	DB_SERVER_NAME,';
			l_sqltext := l_sqltext||' 	DB_SERVER_DOMAIN,';
			l_sqltext := l_sqltext||' 	EFFECTIVE_DATE,';
			l_sqltext := l_sqltext||' 	CREATED_BY,';
			l_sqltext := l_sqltext||' 	CREATED_DATE)';
			l_sqltext := l_sqltext||' VALUES (';
			l_sqltext := l_sqltext||'        (SELECT SUBSTR(dbid,-6) FROM v$database),';
			l_sqltext := l_sqltext||'        (SELECT name FROM v$database),';
			l_sqltext := l_sqltext||'        '||''''||'<%= $hostname %>'||''''||',';
			l_sqltext := l_sqltext||'        '||''''||'<%= $domain %>'||''''||',';
			l_sqltext := l_sqltext||'        sysdate,';
			l_sqltext := l_sqltext||'        '||''''||'FSDBA'||''''||',';
			l_sqltext := l_sqltext||'        sysdate)';
			--
			activity_stream ( l_sqltext, '', 'INSERTED ROW EXISTS', 'In FSDBA.DB_INSTANCES.', false, 1, 'P1', p_debug);
			l_sqltext := 'COMMIT';
			EXECUTE IMMEDIATE l_sqltext;
			--
		ELSE 
			--
			activity_stream ( '', '', 'TABLE EXISTS', 'FSDBA.DB_INSTANCES.', true, 1, 'P2', p_debug);
			--
			l_sqltext := 'SELECT count(*) FROM fsdba.db_instances';
			EXECUTE IMMEDIATE l_sqltext INTO l_count;
			--
			IF l_count = 0 THEN
				l_sqltext := 'INSERT INTO fsdba.db_instances (';
				l_sqltext := l_sqltext||' 	INSTANCE_ID,';
				l_sqltext := l_sqltext||' 	INSTANCE_NAME,';
				l_sqltext := l_sqltext||' 	DB_SERVER_NAME,';
				l_sqltext := l_sqltext||' 	DB_SERVER_DOMAIN,';
				l_sqltext := l_sqltext||' 	EFFECTIVE_DATE,';
				l_sqltext := l_sqltext||' 	CREATED_BY,';
				l_sqltext := l_sqltext||' 	CREATED_DATE)';
				l_sqltext := l_sqltext||' VALUES (';
				l_sqltext := l_sqltext||'        (SELECT SUBSTR(dbid,-6) FROM v$database),';
				l_sqltext := l_sqltext||'        (SELECT name FROM v$database),';
				l_sqltext := l_sqltext||'        '||''''||'<%= $hostname %>'||''''||',';
				l_sqltext := l_sqltext||'        '||''''||'<%= $domain %>'||''''||',';
				l_sqltext := l_sqltext||'        sysdate,';
				l_sqltext := l_sqltext||'        '||''''||'FSDBA'||''''||',';
				l_sqltext := l_sqltext||'        sysdate)';
				--
				activity_stream ( l_sqltext, '', 'INSERTED ROW EXISTS', 'In FSDBA.DB_INSTANCES.', false, 1, 'P1', p_debug);
				l_sqltext := 'COMMIT';
				EXECUTE IMMEDIATE l_sqltext;
				--
			ELSE 
				--
				activity_stream ( '', '', 'INSERTED ROW EXISTS', 'In FSDBA.DB_INSTANCES.', true, 1, 'P2', p_debug);
				--
			END IF;
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.constraint_exists ('FSDBA','DB_INSTANCES_PK','DB_INSTANCES');
		--
		IF l_boolean = false THEN
			l_sqltext := 'ALTER TABLE fsdba.db_instances ADD ('|| chr(10);
			l_sqltext := l_sqltext||'      CONSTRAINT db_instances_pk'|| chr(10);
			l_sqltext := l_sqltext||'      PRIMARY KEY (instance_id)'|| chr(10);
			l_sqltext := l_sqltext||'USING INDEX '|| chr(10);
			l_sqltext := l_sqltext||'PCTFREE  10 '|| chr(10);
			l_sqltext := l_sqltext||')';
			--
			activity_stream ( l_sqltext, '', 'CONSTRAINT EXISTS', 'FSDBA.DB_INSTANCES_PK On FSDBA.DB_INSTANCES.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'CONSTRAINT EXISTS', 'FSDBA.DB_INSTANCES_PK On FSDBA.DB_INSTANCES.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.tabprivs_exists ('FSDBA','DB_INSTANCES','LOGIN_DB_INSTANCES', 'INSERT');
		--
		IF l_boolean = false THEN
			l_sqltext := 'GRANT insert ON fsdba.db_instances TO login_db_instances';
			--
			activity_stream ( l_sqltext, '', 'TABPRIV EXISTS', 'INSERT On FSDBA.DB_INSTANCES To LOGIN_DB_INSTANCES.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'TABPRIV EXISTS', 'INSERT On FSDBA.DB_INSTANCES To LOGIN_DB_INSTANCES.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.tabprivs_exists ('FSDBA','DB_INSTANCES','LOGIN_DB_INSTANCES', 'UPDATE');
		--
		IF l_boolean = false THEN
			l_sqltext := 'GRANT update ON fsdba.db_instances TO login_db_instances';
			--
			activity_stream ( l_sqltext, '', 'TABPRIV EXISTS', 'UPDATE On FSDBA.DB_INSTANCES To LOGIN_DB_INSTANCES.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'TABPRIV EXISTS', 'UPDATE On FSDBA.DB_INSTANCES To LOGIN_DB_INSTANCES.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.tabprivs_exists ('FSDBA','DB_INSTANCES','LOGIN_DB_INSTANCES', 'DELETE');
		--
		IF l_boolean = false THEN
			l_sqltext := 'GRANT delete ON fsdba.db_instances TO login_db_instances';
			--
			activity_stream ( l_sqltext, '', 'TABPRIV EXISTS', 'DELETE On FSDBA.DB_INSTANCES To LOGIN_DB_INSTANCES.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'TABPRIV EXISTS', 'DELETE On FSDBA.DB_INSTANCES To LOGIN_DB_INSTANCES.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.tabprivs_exists ('FSDBA','DB_INSTANCES','LOGIN_DB_INSTANCES', 'SELECT');
		--
		IF l_boolean = false THEN
			l_sqltext := 'GRANT select ON fsdba.db_instances TO login_db_instances';
			--
			activity_stream ( l_sqltext, '', 'TABPRIV EXISTS', 'SELECT On FSDBA.DB_INSTANCES To LOGIN_DB_INSTANCES.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'TABPRIV EXISTS', 'SELECT On FSDBA.DB_INSTANCES To LOGIN_DB_INSTANCES.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		--**************************************
		--* Build Sequence fsdba.instance_id_seq
		--**************************************
		--
		l_boolean := fs_db_admin.fs_exists_functions.object_exists ('FSDBA','INSTANCE_ID_SEQ','SEQUENCE');
		--
		IF l_boolean = false THEN
			l_sqltext := 'create sequence fsdba.instance_id_seq'|| chr(10);
			l_sqltext := l_sqltext||'start with 90000'|| chr(10);
			l_sqltext := l_sqltext||'increment by 1'|| chr(10);
			l_sqltext := l_sqltext||'nocache'|| chr(10);
			l_sqltext := l_sqltext||'nocycle';
			--
			activity_stream ( l_sqltext, '', 'SEQUENCE EXISTS', 'FSDBA.INSTANCE_ID_SEQ.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'SEQUENCE EXISTS', 'FSDBA.INSTANCE_ID_SEQ.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.synonym_exists ('LOGIN_DB_INSTANCES','INSTANCE_ID_SEQ','FSDBA', 'INSTANCE_ID_SEQ');
		--
		IF l_boolean = false THEN
			l_sqltext := 'CREATE SYNONYM login_db_instances.instance_id_seq FOR fsdba.instance_id_seq';
			--
			activity_stream ( l_sqltext, '', 'SYNONYM EXISTS', 'LOGIN_DB_INSTANCES.INSTANCE_ID_SEQ For FSDBA.INSTANCE_ID_SEQ.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'SYNONYM EXISTS', 'LOGIN_DB_INSTANCES.INSTANCE_ID_SEQ for FSDBA.INSTANCE_ID_SEQ.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.tabprivs_exists ('FSDBA','INSTANCE_ID_SEQ', 'LOGIN_DB_INSTANCES', 'SELECT');
		IF l_boolean = false THEN
			l_sqltext := 'GRANT SELECT ON fsdba.instance_id_seq TO login_db_instances';
			--
			activity_stream ( l_sqltext, '', 'TABPRIV EXISTS', 'SELECT On FSDBA.INSTANCE_ID_SEQ To LOGIN_DB_INSTANCES.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'TABPRIV EXISTS', 'SELECT On FSDBA.INSTANCE_ID_SEQ To LOGIN_DB_INSTANCES.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		--************************************
		--* Build Table fsdba.this_db_instance
		--************************************
		--
		l_boolean := fs_db_admin.fs_exists_functions.object_exists ('FSDBA','THIS_DB_INSTANCE','TABLE');
		--
		IF l_boolean = false THEN
			l_sqltext := 'CREATE TABLE fsdba.this_db_instance('|| chr(10);
			l_sqltext := l_sqltext||' instance_id                     NUMBER(6)                  NOT NULL,'|| chr(10);
			l_sqltext := l_sqltext||' instance_name                   VARCHAR2(8)                NOT NULL,'|| chr(10);
			l_sqltext := l_sqltext||' db_server_name                  VARCHAR2(255)              NOT NULL,'|| chr(10);
			l_sqltext := l_sqltext||' db_server_domain                VARCHAR2(255)              NOT NULL,'|| chr(10);
			l_sqltext := l_sqltext||' effective_date                  DATE                       NOT NULL,'|| chr(10);
			l_sqltext := l_sqltext||' created_by                      VARCHAR2(30)               NOT NULL,'|| chr(10);
			l_sqltext := l_sqltext||' created_date                    DATE                       NOT NULL,'|| chr(10);
			l_sqltext := l_sqltext||' modified_by                     VARCHAR2(30)               NULL,'|| chr(10);
			l_sqltext := l_sqltext||' modified_date                   DATE                       NULL,'|| chr(10);
			l_sqltext := l_sqltext||' pk_suffix                       CHAR(6)                    NOT NULL'|| chr(10);
			l_sqltext := l_sqltext||')'|| chr(10);
			l_sqltext := l_sqltext||'TABLESPACE FSDBA_DATA';
			--
			activity_stream ( l_sqltext, '', 'TABLE EXISTS', 'FSDBA.THIS_DB_INSTANCE.', false, 1, 'P1', p_debug);
			--
			l_sqltext := 'INSERT INTO fsdba.this_db_instance ('|| chr(10);
			l_sqltext := l_sqltext||'        INSTANCE_ID,'|| chr(10);
			l_sqltext := l_sqltext||'        INSTANCE_NAME,'|| chr(10);
			l_sqltext := l_sqltext||'        DB_SERVER_NAME,'|| chr(10);
			l_sqltext := l_sqltext||'        DB_SERVER_DOMAIN,'|| chr(10);
			l_sqltext := l_sqltext||'        EFFECTIVE_DATE,'|| chr(10);
			l_sqltext := l_sqltext||'        CREATED_BY,'|| chr(10);
			l_sqltext := l_sqltext||'        CREATED_DATE,'|| chr(10);
			l_sqltext := l_sqltext||'	PK_SUFFIX)'|| chr(10);
			l_sqltext := l_sqltext||' VALUES ('|| chr(10);
			l_sqltext := l_sqltext||'        (SELECT SUBSTR(dbid,-6) FROM v$database),'|| chr(10);
			l_sqltext := l_sqltext||'        (SELECT name FROM v$database),'|| chr(10);
			l_sqltext := l_sqltext||'        '||''''||'<%= $hostname %>'||''''||','|| chr(10);
			l_sqltext := l_sqltext||'        '||''''||'<%= $domain %>'||''''||','|| chr(10);
			l_sqltext := l_sqltext||'        sysdate,'|| chr(10);
			l_sqltext := l_sqltext||'        '||''''||'FSDBA'||''''||','|| chr(10);
			l_sqltext := l_sqltext||'	sysdate,'|| chr(10);
			l_sqltext := l_sqltext||'	'||''''||'000000'||''''||')';
			--
			activity_stream ( l_sqltext, '', 'INSERTED ROW EXISTS', 'In FSDBA.THIS_DB_INSTANCE.', false, 1, 'P1', p_debug);
			l_sqltext := 'COMMIT';
			EXECUTE IMMEDIATE l_sqltext;
			--
		ELSE 
			--
			activity_stream ( '', '', 'TABLE EXISTS', 'FSDBA.THIS_DB_INSTANCE.', true, 1, 'P2', p_debug);
		--
		l_sqltext := 'SELECT count(*) FROM fsdba.this_db_instance';
		EXECUTE IMMEDIATE l_sqltext INTO l_count;
		--
		IF l_count = 0 THEN
			l_sqltext := 'INSERT INTO fsdba.this_db_instance ('|| chr(10);
			l_sqltext := l_sqltext||'        INSTANCE_ID,'|| chr(10);
			l_sqltext := l_sqltext||'        INSTANCE_NAME,'|| chr(10);
			l_sqltext := l_sqltext||'        DB_SERVER_NAME,'|| chr(10);
			l_sqltext := l_sqltext||'        DB_SERVER_DOMAIN,'|| chr(10);
			l_sqltext := l_sqltext||'        EFFECTIVE_DATE,'|| chr(10);
			l_sqltext := l_sqltext||'        CREATED_BY,'|| chr(10);
			l_sqltext := l_sqltext||'        CREATED_DATE,'|| chr(10);
			l_sqltext := l_sqltext||'	PK_SUFFIX)'|| chr(10);
			l_sqltext := l_sqltext||' VALUES ('|| chr(10);
			l_sqltext := l_sqltext||'        (SELECT SUBSTR(dbid,-6) FROM v$database),'|| chr(10);
			l_sqltext := l_sqltext||'        (SELECT name FROM v$database),'|| chr(10);
			l_sqltext := l_sqltext||'        '||''''||'<%= $hostname %>'||''''||','|| chr(10);
			l_sqltext := l_sqltext||'        '||''''||'<%= $domain %>'||''''||','|| chr(10);
			l_sqltext := l_sqltext||'        sysdate,'|| chr(10);
			l_sqltext := l_sqltext||'        '||''''||'FSDBA'||''''||','|| chr(10);
			l_sqltext := l_sqltext||'	sysdate,'|| chr(10);
			l_sqltext := l_sqltext||'	'||''''||'000000'||''''||')';
			--
			activity_stream ( l_sqltext, '', 'INSERTED ROW EXISTS', 'In FSDBA.THIS_DB_INSTANCE.', false, 1, 'P1', p_debug);
			l_sqltext := 'COMMIT';
			EXECUTE IMMEDIATE l_sqltext;
			--
		ELSE 
			--
			activity_stream ( '', '', 'INSERTED ROW EXISTS', 'In FSDBA.THIS_DB_INSTANCE.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.tabcom_exists ('Version: V4.0, Effective Date: 15-May-2012, Created by: Puppet DB Instances Install.', 'FSDBA','THIS_DB_INSTANCE');
		--
		IF l_boolean = false THEN
			--
			l_sqltext := 'COMMENT ON TABLE fsdba.this_db_instance';
			l_sqltext := l_sqltext||'    IS '||''''||'Version: V4.0, Effective Date: 15-May-2012, Created by: Puppet DB Instances Install.'||'''';
			--
			activity_stream ( l_sqltext, '', 'COMMENT EXISTS', 'On FSDBA. THIS_DB_INSTANCE.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'COMMENT EXISTS', 'On FSDBA.THIS_DB_INSTANCE.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.constraint_exists ('FSDBA','THIS_DB_INSTANCE_PK','THIS_DB_INSTANCE');
		--
		IF l_boolean = false THEN
			l_sqltext := 'ALTER TABLE fsdba.THIS_DB_INSTANCE ADD ('|| chr(10);
			l_sqltext := l_sqltext||'      CONSTRAINT THIS_DB_INSTANCE_PK'|| chr(10);
			l_sqltext := l_sqltext||'      PRIMARY KEY (INSTANCE_ID)'|| chr(10);
			l_sqltext := l_sqltext||'USING INDEX'|| chr(10);
			l_sqltext := l_sqltext||'PCTFREE  10'|| chr(10);
			l_sqltext := l_sqltext||')';
			--
			activity_stream ( l_sqltext, '', 'CONSTRIANT EXISTS', 'FSDBA.THIS_DB_INSTANCE_PK On FSDBA.THIS_DB_INSTANCE.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'CONSTRIANT EXISTS', 'FSDBA.THIS_DB_INSTANCE_PK On FSDBA.THIS_DB_INSTANCE.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.trigger_exists ('FSDBA','THIS_DB_INSTANCE_INSERT','FSDBA','THIS_DB_INSTANCE');
		--
		IF l_boolean = false AND p_debug >= 0  THEN
			l_sqltext := 'CREATE OR REPLACE TRIGGER fsdba.this_db_instance_insert'|| chr(10);
			l_sqltext := l_sqltext||'BEFORE INSERT OR UPDATE '|| chr(10);
			l_sqltext := l_sqltext||'ON fsdba.THIS_DB_INSTANCE'|| chr(10);
			l_sqltext := l_sqltext||'FOR EACH ROW'|| chr(10);
			l_sqltext := l_sqltext||'DECLARE'|| chr(10);
			l_sqltext := l_sqltext||'BEGIN'|| chr(10);
			l_sqltext := l_sqltext||'    :new.pk_suffix := substr('||''''||'000000'||''''||'||to_char(:new.instance_id),-6);'|| chr(10);
			l_sqltext := l_sqltext||'    IF INSERTING'|| chr(10);
			l_sqltext := l_sqltext||'    THEN'|| chr(10);
			l_sqltext := l_sqltext||'      delete from fsdba.this_db_instance;'|| chr(10);
			l_sqltext := l_sqltext||'      :new.created_by := user;'|| chr(10);
			l_sqltext := l_sqltext||'      :new.created_date := sysdate;'|| chr(10);
			l_sqltext := l_sqltext||'    ELSE'|| chr(10);
			l_sqltext := l_sqltext||'      :new.modified_by := user;'|| chr(10);
			l_sqltext := l_sqltext||'      :new.modified_date := sysdate;'|| chr(10);
			l_sqltext := l_sqltext||'    END IF;'|| chr(10);
			l_sqltext := l_sqltext||''|| chr(10);
			l_sqltext := l_sqltext||'END;';
			--
			activity_stream ( l_sqltext, '', 'TRIGGER EXISTS', 'FSDBA.THIS_DB_INSTANCE_INSERT On FSDBA.THIS_DB_INSTANCE.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'TRIGGER EXISTS', 'FSDBA.THIS_DB_INSTANCE_INSERT On FSDBA.THIS_DB_INSTANCE.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.object_exists ('FSDBA','DB_INSTANCE','PACKAGE');
		--
		IF l_boolean = false THEN
			l_sqltext := 'CREATE OR REPLACE PACKAGE fsdba.db_instance IS'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  -- Set CREATED audit columns on row insert.'|| chr(10);
			l_sqltext := l_sqltext||'  PROCEDURE insert_audit_columns(audit_column_by IN OUT VARCHAR2,'|| chr(10);
			l_sqltext := l_sqltext||'                                 audit_column_in_instance IN OUT NUMBER,'|| chr(10);
			l_sqltext := l_sqltext||'                                 audit_column_date IN OUT DATE);'|| chr(10);
			l_sqltext := l_sqltext||'  /* Insert_Audit_Columns may be used to set the standard GDI audit columns.  It'|| chr(10);
			l_sqltext := l_sqltext||'     has been designed to be called from an insert database trigger as follows:'|| chr(10);
			l_sqltext := l_sqltext||'       DB_Instance.Insert_Audit_Columns ( :new.Created_By ,'|| chr(10);
			l_sqltext := l_sqltext||'                                          :new.Created_In_Instance ,'|| chr(10);
			l_sqltext := l_sqltext||'                                          :new.Created_Date ) ;'|| chr(10);
			l_sqltext := l_sqltext||'     NOTE:  This procedure will only return values for the parameters if'|| chr(10);
			l_sqltext := l_sqltext||'            they are null.  This enables the insert triggers to call the procedure'|| chr(10);
			l_sqltext := l_sqltext||'            without testing for null (the triggers should only be setting'|| chr(10);
			l_sqltext := l_sqltext||'            these values if they are null).'|| chr(10);
			l_sqltext := l_sqltext||'  */';
			l_sqltext := l_sqltext||'pragma restrict_references(Insert_Audit_Columns,WNDS,WNPS);'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  -- Set MODIFIED audit columns on row update.'|| chr(10);
			l_sqltext := l_sqltext||'  PROCEDURE update_audit_columns(audit_column_by IN OUT VARCHAR2,'|| chr(10);
			l_sqltext := l_sqltext||'                                 audit_column_in_instance IN OUT NUMBER,'|| chr(10);
			l_sqltext := l_sqltext||'                                 audit_column_date IN OUT date);'|| chr(10);
			l_sqltext := l_sqltext||'  /* Update_Audit_Columns may be used to set the standard GDI audit columns.  It'|| chr(10);
			l_sqltext := l_sqltext||'     has been designed to be called from an insert database trigger as follows:'|| chr(10);
			l_sqltext := l_sqltext||'     Update Trigger code:'|| chr(10);
			l_sqltext := l_sqltext||'       DB_Instance.Update_Audit_Columns ( :new.Modified_By ,'|| chr(10);
			l_sqltext := l_sqltext||'                                          :new.Modified_In_Instance ,'|| chr(10);
			l_sqltext := l_sqltext||'                                          :new.Modified_Date ) ;'|| chr(10);
			l_sqltext := l_sqltext||'  */'|| chr(10);
			l_sqltext := l_sqltext||'pragma restrict_references(Update_Audit_Columns,WNDS,WNPS);'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  -- Set vaules for standard audit columns.'|| chr(10);
			l_sqltext := l_sqltext||'  PROCEDURE set_audit_columns(audit_column_by IN OUT VARCHAR2,'|| chr(10);
			l_sqltext := l_sqltext||'                              audit_column_in_instance IN OUT NUMBER,'|| chr(10);
			l_sqltext := l_sqltext||'                              audit_column_date IN OUT DATE);'|| chr(10);
			l_sqltext := l_sqltext||'  /*  Use Insert_Audit Columns or Update_Audit_Columns instead. */'|| chr(10);
			l_sqltext := l_sqltext||'pragma restrict_references(Set_Audit_Columns,WNDS,WNPS);'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  -- Get system generated primary key suffix.'|| chr(10);
			l_sqltext := l_sqltext||'  FUNCTION get_pk_suffix'|| chr(10);
			l_sqltext := l_sqltext||'    RETURN VARCHAR2;'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  -- Generate a globally unique id..'|| chr(10);
			l_sqltext := l_sqltext||'  FUNCTION generate_global_id(sequence IN VARCHAR2)'|| chr(10);
			l_sqltext := l_sqltext||'    RETURN VARCHAR2;'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  -- Use in a form to derive globally unique id when a field is entered.'|| chr(10);
			l_sqltext := l_sqltext||'  FUNCTION derive_global_id(sequence  IN VARCHAR2,'|| chr(10);
			l_sqltext := l_sqltext||'                           cn_column IN VARCHAR2)'|| chr(10);
			l_sqltext := l_sqltext||'    RETURN VARCHAR2;'|| chr(10);
			l_sqltext := l_sqltext||''|| chr(10);
			l_sqltext := l_sqltext||'END db_instance;';
			--
			activity_stream ( l_sqltext, '', 'PACKAGE EXISTS', 'FSDBA.DB_INSTANCE.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'PACKAGE EXISTS', 'FSDBA.DB_INSTANCE.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.object_exists ('FSDBA','DB_INSTANCE','PACKAGE BODY');
		--
		IF l_boolean = false THEN
			l_sqltext := 'CREATE OR REPLACE PACKAGE BODY fsdba.db_instance IS'|| chr(10);
			l_sqltext := l_sqltext||'   global_domain_suffix CONSTANT VARCHAR2(10) := '||''''||'.fs.fed.us'||''''||';'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  TYPE Database_Instance'|| chr(10);
			l_sqltext := l_sqltext||'    IS RECORD(Instance_ID NUMBER(15),'|| chr(10);
			l_sqltext := l_sqltext||'              DB_Server_Name VARCHAR2(255),'|| chr(10);
			l_sqltext := l_sqltext||'              DB_Server_Domain VARCHAR2(255),'|| chr(10);
			l_sqltext := l_sqltext||'              Instance_Name VARCHAR2(8),'|| chr(10);
			l_sqltext := l_sqltext||'              PK_Suffix CHAR(6));'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  This_Db_Instance_Record Database_Instance;'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  -- Set CREATED audit columns on row insert.'|| chr(10);
			l_sqltext := l_sqltext||'  PROCEDURE insert_audit_columns(audit_column_by IN OUT VARCHAR2 ,'|| chr(10);
			l_sqltext := l_sqltext||'                                 audit_column_in_instance IN OUT NUMBER ,'|| chr(10);
			l_sqltext := l_sqltext||'                                 audit_column_date IN OUT DATE ) IS'|| chr(10);
			l_sqltext := l_sqltext||'  BEGIN'|| chr(10);
			l_sqltext := l_sqltext||'    IF audit_column_by IS NULL THEN'|| chr(10);
			l_sqltext := l_sqltext||'       audit_column_by := USER;'|| chr(10);
			l_sqltext := l_sqltext||'    END IF;'|| chr(10);
			l_sqltext := l_sqltext||'    IF audit_column_in_instance IS NULL THEN'|| chr(10);
			l_sqltext := l_sqltext||'       audit_column_in_instance := this_db_instance_record.instance_id;'|| chr(10);
			l_sqltext := l_sqltext||'    END IF;'|| chr(10);
			l_sqltext := l_sqltext||'    IF audit_column_date IS NULL THEN'|| chr(10);
			l_sqltext := l_sqltext||'       audit_column_date := SYSDATE;'|| chr(10);
			l_sqltext := l_sqltext||'    END IF;'|| chr(10);
			l_sqltext := l_sqltext||'  END;'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  -- Set MODIFIED audit columns on row update.'|| chr(10);
			l_sqltext := l_sqltext||'  PROCEDURE update_audit_columns(audit_column_by IN OUT VARCHAR2 ,'|| chr(10);
			l_sqltext := l_sqltext||'                                 audit_column_in_instance IN OUT NUMBER ,'|| chr(10);
			l_sqltext := l_sqltext||'                                 audit_column_date IN OUT date ) IS'|| chr(10);
			l_sqltext := l_sqltext||'  BEGIN'|| chr(10);
			l_sqltext := l_sqltext||'    audit_column_by := USER;'|| chr(10);
			l_sqltext := l_sqltext||'    audit_column_in_instance := this_db_instance_record.instance_id;'|| chr(10);
			l_sqltext := l_sqltext||'    audit_column_date := SYSDATE;'|| chr(10);
			l_sqltext := l_sqltext||'  END;'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  -- Set vaules for standard audit columns.'|| chr(10);
			l_sqltext := l_sqltext||'  PROCEDURE set_audit_columns('|| chr(10);
			l_sqltext := l_sqltext||'    audit_column_by IN OUT VARCHAR2 ,'|| chr(10);
			l_sqltext := l_sqltext||'    audit_column_in_instance IN OUT NUMBER ,'|| chr(10);
			l_sqltext := l_sqltext||'    audit_column_date IN OUT DATE ) IS'|| chr(10);
			l_sqltext := l_sqltext||'  BEGIN'|| chr(10);
			l_sqltext := l_sqltext||'    IF audit_column_by IS NULL THEN'|| chr(10);
			l_sqltext := l_sqltext||'       audit_column_by := USER;'|| chr(10);
			l_sqltext := l_sqltext||'    END IF;'|| chr(10);
			l_sqltext := l_sqltext||'   IF audit_column_in_instance IS NULL THEN'|| chr(10);
			l_sqltext := l_sqltext||'       audit_column_in_instance := this_db_instance_record.instance_id;'|| chr(10);
			l_sqltext := l_sqltext||'    END IF;'|| chr(10);
			l_sqltext := l_sqltext||'    IF audit_column_date IS NULL THEN'|| chr(10);
			l_sqltext := l_sqltext||'       audit_column_date := SYSDATE;'|| chr(10);
			l_sqltext := l_sqltext||'    END IF;'|| chr(10);
			l_sqltext := l_sqltext||'  END;'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  -- Get system generated primary key suffix.'|| chr(10);
			l_sqltext := l_sqltext||'  FUNCTION get_pk_suffix'|| chr(10);
			l_sqltext := l_sqltext||'    RETURN VARCHAR2 IS'|| chr(10);
			l_sqltext := l_sqltext||'  BEGIN'|| chr(10);
			l_sqltext := l_sqltext||'    RETURN(This_Db_Instance_Record.pk_suffix);'|| chr(10);
			l_sqltext := l_sqltext||'  END;'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  -- Generate a globally unique id..'|| chr(10);
			l_sqltext := l_sqltext||'  FUNCTION generate_global_id(sequence IN VARCHAR2 )'|| chr(10);
			l_sqltext := l_sqltext||'    RETURN VARCHAR2 IS'|| chr(10);
			l_sqltext := l_sqltext||'    --'|| chr(10);
			l_sqltext := l_sqltext||'    --'|| chr(10);
			l_sqltext := l_sqltext||'    global_id NUMBER;'|| chr(10);
			l_sqltext := l_sqltext||'    vc_global_id VARCHAR2(34);'|| chr(10);
			l_sqltext := l_sqltext||'    --'|| chr(10);
			l_sqltext := l_sqltext||'    --'|| chr(10);
			l_sqltext := l_sqltext||'    seq_cursor INTEGER;'|| chr(10);
			l_sqltext := l_sqltext||'    --'|| chr(10);
			l_sqltext := l_sqltext||'    --'|| chr(10);
			l_sqltext := l_sqltext||'    ignore INTEGER;'|| chr(10);
			l_sqltext := l_sqltext||'  BEGIN'|| chr(10);
			l_sqltext := l_sqltext||'    seq_cursor := dbms_sql.open_cursor;'|| chr(10);
			l_sqltext := l_sqltext||'    dbms_sql.parse('|| chr(10);
			l_sqltext := l_sqltext||'            seq_cursor,'|| chr(10);
			l_sqltext := l_sqltext||'           '||''''||'SELECT '||'''' ||'|| sequence || '||''''||'.NEXTVAL FROM SYS.DUAL'||''''||','|| chr(10);
			l_sqltext := l_sqltext||'            dbms_sql.v7);'|| chr(10);
			l_sqltext := l_sqltext||'    dbms_sql.define_column('|| chr(10);
			l_sqltext := l_sqltext||'            seq_cursor,'|| chr(10);
			l_sqltext := l_sqltext||'            1,'|| chr(10);
			l_sqltext := l_sqltext||'            global_id);'|| chr(10);
			l_sqltext := l_sqltext||'    ignore := dbms_sql.execute_and_fetch('|| chr(10);
			l_sqltext := l_sqltext||'            seq_cursor,'|| chr(10);
			l_sqltext := l_sqltext||'            FALSE);'|| chr(10);
			l_sqltext := l_sqltext||'    dbms_sql.column_value('|| chr(10);
			l_sqltext := l_sqltext||'            seq_cursor,'|| chr(10);
			l_sqltext := l_sqltext||'            1,'|| chr(10);
			l_sqltext := l_sqltext||'            global_id);'|| chr(10);
			l_sqltext := l_sqltext||'    dbms_sql.close_cursor(seq_cursor);'|| chr(10);
			l_sqltext := l_sqltext||'    vc_global_id := to_char(global_id)||get_pk_suffix;'|| chr(10);
			l_sqltext := l_sqltext||'    RETURN(vc_global_id);'|| chr(10);
			l_sqltext := l_sqltext||'    EXCEPTION'|| chr(10);
			l_sqltext := l_sqltext||'    	WHEN OTHERS THEN'|| chr(10);
			l_sqltext := l_sqltext||'    	IF dbms_sql.is_open(seq_cursor) THEN'|| chr(10);
			l_sqltext := l_sqltext||'    		dbms_sql.close_cursor(seq_cursor);'|| chr(10);
			l_sqltext := l_sqltext||'   	END IF;'|| chr(10);
			l_sqltext := l_sqltext||'    	RAISE;'|| chr(10);
			l_sqltext := l_sqltext||'  END;'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  -- Use in a form to derive globally unique id when a field is entered.'|| chr(10);
			l_sqltext := l_sqltext||'  FUNCTION derive_global_id(sequence  IN VARCHAR2 ,'|| chr(10);
			l_sqltext := l_sqltext||'                            cn_column IN VARCHAR2 )'|| chr(10);
			l_sqltext := l_sqltext||'  RETURN VARCHAR2 IS'|| chr(10);
			l_sqltext := l_sqltext||'  BEGIN'|| chr(10);
			l_sqltext := l_sqltext||'    return(generate_global_id(sequence));'|| chr(10);
			l_sqltext := l_sqltext||'  END;'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||''|| chr(10);
			l_sqltext := l_sqltext||'BEGIN'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  -- Initialize This_Db_Instance_Record'|| chr(10);
			l_sqltext := l_sqltext||'  SELECT Instance_ID,'|| chr(10);
			l_sqltext := l_sqltext||'         DB_Server_Name,'|| chr(10);
			l_sqltext := l_sqltext||'         DB_Server_Domain,'|| chr(10);
			l_sqltext := l_sqltext||'         Instance_Name,'|| chr(10);
			l_sqltext := l_sqltext||'         PK_Suffix'|| chr(10);
			l_sqltext := l_sqltext||'  INTO   This_Db_Instance_Record'|| chr(10);
			l_sqltext := l_sqltext||'  FROM   This_DB_Instance;'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'  --'|| chr(10);
			l_sqltext := l_sqltext||'END db_instance;';
			--
			activity_stream ( l_sqltext, '', 'PACKAGE BODY EXISTS', 'FSDBA.DB_INSTANCE.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'PACKAGE BODY EXISTS', 'FSDBA.DB_INSTANCE.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.object_exists ('FSDBA','THIS_DB_INSTANCE_INFO','VIEW');
		--
		IF l_boolean = false THEN
			l_sqltext := 'CREATE OR REPLACE VIEW fsdba.this_db_instance_info'|| chr(10);
			l_sqltext := l_sqltext||'('|| chr(10);
			l_sqltext := l_sqltext||'     instance_id'|| chr(10);
			l_sqltext := l_sqltext||'    ,instance_name'|| chr(10);
			l_sqltext := l_sqltext||'    ,db_server_name'|| chr(10);
			l_sqltext := l_sqltext||'    ,db_server_domain'|| chr(10);
			l_sqltext := l_sqltext||'    ,effective_date'|| chr(10);
			l_sqltext := l_sqltext||'    ,created_date'|| chr(10);
			l_sqltext := l_sqltext||'    ,created_by'|| chr(10);
			l_sqltext := l_sqltext||'    ,modified_date'|| chr(10);
			l_sqltext := l_sqltext||'    ,modified_by'|| chr(10);
			l_sqltext := l_sqltext||'    ,pk_suffix'|| chr(10);
			l_sqltext := l_sqltext||')'|| chr(10);
			l_sqltext := l_sqltext||'AS SELECT'|| chr(10);
			l_sqltext := l_sqltext||'     THSDBIN.INSTANCE_ID'|| chr(10);                               
			l_sqltext := l_sqltext||'   ,THSDBIN.INSTANCE_NAME'|| chr(10);
			l_sqltext := l_sqltext||'    ,THSDBIN.DB_SERVER_NAME'|| chr(10);
			l_sqltext := l_sqltext||'    ,THSDBIN.DB_SERVER_DOMAIN'|| chr(10);
			l_sqltext := l_sqltext||'    ,THSDBIN.EFFECTIVE_DATE'|| chr(10);
			l_sqltext := l_sqltext||'    ,THSDBIN.CREATED_DATE'|| chr(10);
			l_sqltext := l_sqltext||'    ,THSDBIN.CREATED_BY'|| chr(10);
			l_sqltext := l_sqltext||'    ,THSDBIN.MODIFIED_DATE'|| chr(10);
			l_sqltext := l_sqltext||'    ,THSDBIN.MODIFIED_BY'|| chr(10);
			l_sqltext := l_sqltext||'    ,THSDBIN.PK_SUFFIX'|| chr(10);
			l_sqltext := l_sqltext||'FROM'|| chr(10);
			l_sqltext := l_sqltext||'    this_db_instance  thsdbin';
			--
			activity_stream ( l_sqltext, '', 'VIEW EXISTS', 'FSDBA.THIS_DB_INSTANCE_INFO.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'VIEW EXISTS', 'FSDBA.THIS_DB_INSTANCE_INFO.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_sqltext := 'COMMENT ON TABLE fsdba.this_db_instance_info';
		l_sqltext := l_sqltext||'    IS '||''''||'Version: V4.0, Effective Date: 15 May 2012, Created by: Puppet DB Instances Install.'||'''';
		--
		l_boolean := fs_db_admin.fs_exists_functions.tabcom_exists ('Version: V4.0, Effective Date: 15 May 2012, Created by: Puppet DB Instances Install.', 'FSDBA','THIS_DB_INSTANCE_INFO');
		--
		IF l_boolean = false THEN
			--
			activity_stream ( l_sqltext, '', 'COMMENT EXISTS', 'On FSDBA.THIS_DB_INSTANCE_INFO.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'COMMENT EXISTS', 'On FSDBA.THIS_DB_INSTANCE_INFO.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.synonym_exists ('PUBLIC','THIS_DB_INSTANCE','FSDBA', 'THIS_DB_INSTANCE');
		--
		IF l_boolean = false THEN
			l_sqltext := 'CREATE PUBLIC SYNONYM this_db_instance FOR fsdba.this_db_instance';
			--
			activity_stream ( l_sqltext, '', 'SYNONYM EXISTS', 'PUBLIC.THIS_DB_INSTANCE For FSDBA.THIS_DB_INSTANCE.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'SYNONYM EXISTS', 'PUBLIC.THIS_DB_INSTANCE For FSDBA.THIS_DB_INSTANCE.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.synonym_exists ('PUBLIC','THIS_DB_INSTANCE_INFO','FSDBA', 'THIS_DB_INSTANCE_INFO');
		--
		IF l_boolean = false THEN
			l_sqltext := 'CREATE PUBLIC SYNONYM this_db_instance_info FOR fsdba.this_db_instance_info';
			--
			activity_stream ( l_sqltext, '', 'SYNONYM EXISTS', 'PUBLIC.THIS_DB_INSTANCE_INFO For FSDBA.THIS_DB_INSTANCE_INFO.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'SYNONYM EXISTS', 'PUBLIC.THIS_DB_INSTANCE_INFO For FSDBA.THIS_DB_INSTANCE_INFO.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.synonym_exists ('PUBLIC','DB_INSTANCE','FSDBA', 'DB_INSTANCE');
		--
		IF l_boolean = false THEN
			l_sqltext := 'CREATE PUBLIC SYNONYM db_instance FOR fsdba.db_instance';
			--
			activity_stream ( l_sqltext, '', 'SYNONYM EXISTS', 'PUBLIC.DB_INSTANCE For FSDBA.DB_INSTANCE.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'SYNONYM EXISTS', 'PUBLIC.DB_INSTANCE For FSDBA.DB_INSTANCE.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.synonym_exists ('PUBLIC','DB_INSTANCES','FSDBA', 'DB_INSTANCES');
		--
		IF l_boolean = false THEN
			l_sqltext := 'CREATE PUBLIC SYNONYM db_instances FOR fsdba.db_instances';
			--
			activity_stream ( l_sqltext, '', 'SYNONYM EXISTS', 'PUBLIC.DB_INSTANCES For FSDBA.DB_INSTANCES.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'SYNONYM EXISTS', 'PUBLIC.DB_INSTANCES For FSDBA.DB_INSTANCES.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.tabprivs_exists ('FSDBA','DB_INSTANCES','PUBLIC', 'SELECT');
		--
		IF l_boolean = false THEN
			l_sqltext := 'GRANT SELECT ON fsdba.db_instances TO PUBLIC';
			--
			activity_stream ( l_sqltext, '', 'TABPRIV EXISTS', 'SELECT On FSDBA.DB_INSTANCES To PUBLIC.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'TABPRIV EXISTS', 'SELECT On FSDBA.DB_INSTANCES To PUBLIC.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.tabprivs_exists ('FSDBA','THIS_DB_INSTANCE','PUBLIC', 'SELECT');
		--
		IF l_boolean = false THEN
			l_sqltext := 'GRANT SELECT ON fsdba.this_db_instance TO PUBLIC';
			--
			activity_stream ( l_sqltext, '', 'TABPRIV EXISTS', 'SELECT On FSDBA.THIS_DB_INSTANCE To PUBLIC.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'TABPRIV EXISTS', 'SELECT On FSDBA.THIS_DB_INSTANCE To PUBLIC.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.tabprivs_exists ('FSDBA','THIS_DB_INSTANCE_INFO','PUBLIC', 'SELECT');
		--
		IF l_boolean = false THEN
			l_sqltext := 'GRANT SELECT ON fsdba.this_db_instance_info TO PUBLIC';
			--
			activity_stream ( l_sqltext, '', 'TABPRIV EXISTS', 'SELECT On FSDBA.THIS_DB_INSTANCE_INFO To PUBLIC.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'TABPRIV EXISTS', 'SELECT On FSDBA.THIS_DB_INSTANCE_INFO To PUBLIC.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.tabprivs_exists ('FSDBA','DB_INSTANCE','PUBLIC', 'EXECUTE');
		--
		IF l_boolean = false THEN
			l_sqltext := 'GRANT EXECUTE ON fsdba.db_instance TO PUBLIC';
			--
			activity_stream ( l_sqltext, '', 'TABPRIV EXISTS', 'EXECUTE On FSDBA.DB_INSTANCE To PUBLIC.', false, 1, 'P1', p_debug);
			--
		ELSE 
			--
			activity_stream ( '', '', 'TABPRIV EXISTS', 'EXECUTE On FSDBA.DB_INSTANCE To PUBLIC.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
	ELSIF LOWER(p_dbinstancesobjectschoice) = 'f' THEN
		drop_login_db_instances_obj (p_debug);
		drop_fsdba_obj (p_debug);
	ELSE
		--
		activity_stream ( '', '', 'CODE ERROR: provide_dbinstances_objects Improper Input Value', LOWER(p_dbinstancesobjectschoice)||'.', false, 1, 'P5', p_debug);
		--
	END IF;
	--
	activity_stream ( '', '', '', '', true, 0, 'P8', p_debug);
	--
	activity_stream ( '', '', 'SUMMARY', 'PROVIDE DBINSTANCES OBJECTS', true, 0, 'P7', p_debug);
	--
END provide_dbinstances_objects;
--
--
--**************************************************************************************************************************
--**         Procedure:	provide_users
--**           Purpose:	This procedure creates the basic users with the appropirate grants.
--**  Calling Programs:	--
--**   Programs Called: fs_db_admin.fs_exists_functions
--**			fs_security_pkg.activity_stream
--**   Tables Accessed: --
--**   Tables Modified:	--
--**  Passed Variables: --
--**			p_status			-- Status message to check for errors.
--**			p_error_message			-- The actual error message.
--**			p_debug				-- The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**			g_programcontext 		-- Set to l_localprogramname
--**			g_provideuserspasscnt		-- Pass Count Variable
--**			g_provideusersfailcnt		-- Fail Count Variable
--**   Local Variables: --
--**			l_localprogramname		-- This programs name. (For debugging purposes.)
--**			l_programmessage		-- The local debugging message.
--**			l_sqltext			-- The DDL text
--**			l_boolean			-- Choice Boolean
--**			l_password			-- Secure Password
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Pseudo code: 
--**			IF LOWER(p_userchoice) = 't'
--**				Create FSBA and LOGIN_DB_INSTANCES users
--**				Grant Sysprivs and roles
--**				Verify fs_db_admin user
--**			IF LOWER(p_userchoice) = 'f' THEN
--**				Remove FSDBA objects
--**				Remove FSBA and LOGIN_DB_INSTANCES users
--**************************************************************************************************************************
--
--
PROCEDURE provide_users
(
 p_userchoice				IN		VARCHAR2,				-- input of debinstancesobjects
 p_status				OUT		VARCHAR2,				-- Status message to check for errors.
 p_errormessage				OUT		VARCHAR2,				-- The actual error message.
 p_debug				IN		NUMBER					-- Turn on DEBUG.
)
IS
 l_localprogramname			VARCHAR2(128) := 'provide_users';
 l_programmessage			CLOB;
 l_errormessage				VARCHAR2(1000);
 l_sqltext				VARCHAR2(1000);
 l_boolean				BOOLEAN;
 l_password				VARCHAR2(30);
BEGIN
	--
	g_programcontext := l_localprogramname;
	g_provideuserspasscnt := 0;
	g_provideusersfailcnt := 0;
	activity_stream ( '', '', 'DETAIL', 'PROVIDE USERS', true, 0, 'P6', p_debug);
	--
	IF LOWER(p_userchoice) = 't' THEN
		--
		--***************************
		-- SETUP FSDBA USER
		--***************************
		--
		l_boolean := fs_db_admin.fs_exists_functions.tablespace_exists ('FSDBA_DATA');
		--
		IF l_boolean = false THEN
			--
                	l_sqltext := 'CREATE SMALLFILE TABLESPACE fsdba_data ';
                	l_sqltext := l_sqltext||'DATAFILE SIZE 5M AUTOEXTEND ON NEXT 100M MAXSIZE 32767M LOGGING EXTENT MANAGEMENT LOCAL ';
                	l_sqltext := l_sqltext||'SEGMENT SPACE MANAGEMENT AUTO';
			--
			activity_stream ( l_sqltext, '', 'TABLESPACE EXISTS', 'FSDBA_DATA.', false, 1, 'P1', p_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'TABLESPACE EXISTS', 'FSDBA_DATA.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.user_exists ('FSDBA');
		--
		IF l_boolean = false THEN
			l_password := fs_db_admin.fs_security_pkg.random_password(15,0);
			--
                	l_sqltext := 'CREATE USER fsdba IDENTIFIED BY "'||l_password||'"';
                	l_sqltext := l_sqltext || ' DEFAULT TABLESPACE FSDBA_DATA';
                	l_sqltext := l_sqltext || ' TEMPORARY TABLESPACE temp';
			l_sqltext := l_sqltext || ' PROFILE default';
			--
			activity_stream ( l_sqltext, '', 'USER EXISTS', 'FSDBA.', false, 1, 'P1', p_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'USER EXISTS', 'FSDBA.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.tsquota_exists ( 'FSDBA', 'FSDBA_DATA', '', '', true);
		--
		IF l_boolean = false THEN
			l_sqltext := 'ALTER USER fsdba QUOTA UNLIMITED ON FSDBA_DATA';
			--
			activity_stream ( l_sqltext, '', 'TABLESPACE QUOTA EXISTS', 'Quota UNLIMITED On FSDBA_DATA.', false, 1, 'P1', p_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'QUOTA GRANTED', 'UNLIMITED QUOTA On FSDBA_DATA.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		--*********************************
		--** Setup logon_db_instances User
		--*********************************
		--
		l_boolean := fs_db_admin.fs_exists_functions.user_exists ('LOGIN_DB_INSTANCES');
		--
		IF l_boolean = false THEN
			l_password := fs_db_admin.fs_security_pkg.random_password(15,0);
			--
			l_sqltext := 'CREATE USER login_db_instances IDENTIFIED BY "'||l_password||'"';
			l_sqltext := l_sqltext || ' DEFAULT TABLESPACE users';
			l_sqltext := l_sqltext || ' TEMPORARY TABLESPACE temp';
			l_sqltext := l_sqltext || ' PROFILE default';
			--
			activity_stream ( l_sqltext, '', 'USER EXISTS', 'LOGIN_DB_INSTANCES.', false, 1, 'P1', p_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'USER EXISTS', 'LOGIN_DB_INSTANCES.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.grantee_rolepriv_exists ('LOGIN_DB_INSTANCES','FS_SESSION');
		--
		IF l_boolean = false THEN
			--
			activity_stream ( 'GRANT FS_SESSION TO login_db_instances', '', 'ROLE GRANTED', 'FS_SESSION To LOGIN_DB_INSTANCES.', false, 1, 'P1', p_debug);
			--
 		ELSE
			--
			activity_stream ( '', '', 'ROLE GRANTED', 'FS_SESSION To LOGIN_DB_INSTANCES.', true, 1, 'P2', p_debug);
			--
		END IF;
	END IF;
	--
	activity_stream ( '', '', 'USER EXISTS', 'fs_db_admin.', true, 1, 'P2', p_debug);
	--
	l_boolean := fs_db_admin.fs_exists_functions.tablespace_exists ('FS_DB_ADMIN_DATA');
	--
	IF l_boolean = false THEN
		--
		activity_stream ( 'CREATE SMALLFILE TABLESPACE fs_db_admin_data DATAFILE SIZE 5M AUTOEXTEND ON NEXT 100M MAXSIZE 32767M LOGGING EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT AUTO', '',
				  'TABLESPACE CREATED', 'fs_db_admin_data.', false, 1, 'P1', p_debug);
		--
 	ELSE
		--
		activity_stream ( '', '', 'TABLESPACE CREATED', 'fs_db_admin_data.', true, 1, 'P2', p_debug);
		--
	END IF;
	--
	l_boolean := fs_db_admin.fs_exists_functions.tsquota_exists ('FS_DB_ADMIN', 'FS_DB_ADMIN_DATA', '', '', true);
	--
	IF l_boolean = false THEN
		--
		activity_stream ( 'ALTER USER fs_db_admin QUOTA UNLIMITED ON fs_db_admin_data', '', 'QUOTA GRANTED', 'UNLIMITED QUOTA On fs_db_admin_data To FS_DB_ADMIN.', false, 1, 'P1', p_debug);
		--
 	ELSE
		--
		activity_stream ( '', '', 'QUOTA GRANTED', 'UNLIMITED QUOTA On fs_db_admin_data To FS_DB_ADMIN.', true, 1, 'P2', p_debug);
		--
	END IF;
	--
	l_boolean := fs_db_admin.fs_exists_functions.grantee_syspriv_exists ('FS_DB_ADMIN','SELECT ANY DICTIONARY');
	--
	IF l_boolean = false THEN
		--
		activity_stream ( 'GRANT SELECT ANY DICTIONARY TO fs_db_admin', '', 'SYSPRIV GRANTED', 'SELECT ANY DICTIONARY To FS_DB_ADMIN.', false, 1, 'P1', p_debug);
		--
 	ELSE
		--
		activity_stream ( '', '', 'SYSPRIV GRANTED', 'SELECT ANY DICTIONARY To FS_DB_ADMIN.', true, 1, 'P2', p_debug);
		--
	END IF;
	--
	l_boolean := fs_db_admin.fs_exists_functions.user_assigned_profile_exists ('FS_DB_ADMIN','FS_OWNER_PROFILE');
	--
	IF l_boolean = false THEN
		--
		activity_stream ( 'ALTER USER fs_db_admin PROFILE FS_OWNER_PROFILE', '', 'PROFILE ASSIGNED', 'FS_OWNER_PROFILE To FS_DB_ADMIN.', false, 1, 'P1', p_debug);
		--
 	ELSE
		--
		activity_stream ( '', '', 'PROFILE ASSIGNED', 'FS_OWNER_PROFILE To FS_DB_ADMIN.', true, 1, 'P2', p_debug);
		--
	END IF;
	--
	IF LOWER(p_userchoice) = 'f'  THEN
		--
		l_boolean := fs_db_admin.fs_exists_functions.user_exists ('LOGIN_DB_INSTANCES');
		--
		IF l_boolean = true THEN
			--
			l_boolean := fs_db_admin.fs_exists_functions.user_objects_exists ('LOGIN_DB_INSTANCES');
			--
			IF l_boolean = true THEN
				drop_login_db_instances_obj (p_debug);
				--
				activity_stream ( 'DROP USER login_db_instances', '', 'USER DOES NOT EXIST', 'LOGIN_DB_INSTANCES.', false, 1, 'P1', p_debug);
				--
			ELSE
				drop_login_db_instances_obj (p_debug);
				--
				activity_stream ( 'DROP USER login_db_instances', '', 'USER DOES NOT EXIST', 'LOGIN_DB_INSTANCES.', false, 1, 'P1', p_debug);
				--
			END IF;
		ELSE
			drop_login_db_instances_obj (p_debug);
			--
			activity_stream ( '', '', 'USER DOES NOT EXIST', 'LOGIN_DB_INSTANCES.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.user_exists ('FSDBA');
		--
		IF l_boolean = true THEN
			--
			l_boolean := fs_db_admin.fs_exists_functions.user_objects_exists ('FSDBA');
			--
			IF l_boolean = true THEN
				drop_fsdba_obj (p_debug);
				--
				activity_stream ( 'DROP USER fsdba', '', 'USER DOES NOT EXIST', 'FSDBA.', false, 1, 'P1', p_debug);
				--
			ELSE
				drop_fsdba_obj (p_debug);
				--
				activity_stream ( 'DROP USER fsdba', '', 'USER DOES NOT EXIST', 'FSDBA.', false, 1, 'P1', p_debug);
				--
			END IF;
		ELSE
			drop_fsdba_obj (p_debug);
			--
			activity_stream ( '', '', 'USER DOES NOT EXIST', 'FSDBA.', true, 1, 'P2', p_debug);
			--
		END IF;
	END IF;
	--
	activity_stream ( '', '', '', '', true, 0, 'P8', p_debug);
	--
	activity_stream ( '', '', 'SUMMARY', 'PROVIDE USERS', true, 0, 'P7', p_debug);
	--
END provide_users;
--
--
--**************************************************************************************************************************
--**         Procedure:	provide_basic_security
--**           Purpose:	This procedure create the FSDBA legacy objects.
--**  Calling Programs:	--
--**   Programs Called:	fs_db_admin.fs_exists_functions
--**			fs_security_pkg.activity_stream
--**   Tables Accessed:	--
--**   Tables Modified:	--
--**  Passed Variables:
--**			p_basicsecuritychoice		-- Basic Security Choice Variable
--**			p_status			-- Status message to check for errors.
--**			p_error_message			-- The actual error message.
--**			p_debug				-- The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:
--**			l_localprogramname		-- This programs name. (For debugging purposes.)
--**			l_programmessage		-- The local debugging message.
--**			l_sqltext			-- The DDL text
--**			l_boolean			-- Choice Boolean
--**           Cursors:	--
--**           pragmas: --
--**         Exception:	--
--**************************************************************************************************************************
--**        Pseudo code: 
--**			IF LOWER(p_basicsecuritychoice) = 'c'
--**				Create fsdba.create_rpwd_lock
--**				Create fsdba.create_rpwd
--**			IF LOWER(p_basicsecuritychoice) = 's'
--**				's' components already exist in pkg.
--**			Create data_pump_dir
--**************************************************************************************************************************
--
--
PROCEDURE provide_basic_security
(
 p_basicsecuritychoice			IN		VARCHAR2,				-- Selection C, S, B.
 p_status				OUT		VARCHAR2,				-- Status message to check for errors.
 p_errormessage				OUT		VARCHAR2,				-- The actual error message.
 p_debug				IN		NUMBER					-- Turn on DEBUG.
)
AS
 l_localprogramname			VARCHAR2(128) := 'provide_basic_security';
 l_programmessage			CLOB;
 l_sqltext				VARCHAR2(1000);
 l_boolean				BOOLEAN;
BEGIN
	--
	g_programcontext := l_localprogramname;
	g_providebasicsecuritypasscnt := 0;
	g_providebasicsecurityfailcnt := 0;
	activity_stream ( '', '', 'DETAIL', 'PROVIDE BASIC SECURITY', true, 0, 'P6', p_debug);
	--
	IF LOWER(p_basicsecuritychoice) = 'c' THEN
		l_boolean := fs_db_admin.fs_exists_functions.object_exists('FSDBA','CREATE_RPWD_LOCK','PROCEDURE');
        	--
        	IF l_boolean = false THEN
			l_sqltext := 'create or replace procedure fsdba.create_rpwd_lock (uname IN VARCHAR2)'|| chr(10);
			l_sqltext := l_sqltext||' authid current_user '|| chr(10);
			l_sqltext := l_sqltext||'is '|| chr(10);
			l_sqltext := l_sqltext||'  rpwd varchar2(30);'|| chr(10);
			l_sqltext := l_sqltext||'begin'|| chr(10);
			l_sqltext := l_sqltext||'  rpwd := dbms_random.string('||''''||'U'||''''||',1)||dbms_random.string('||''''||'X'||''''||',29);'|| chr(10);
			l_sqltext := l_sqltext||'  execute immediate '||''''||'alter user '||''''||'||uname||'||''''||' identified by "'||''''||'||rpwd||'||''''||'"'||''''||'||'||''''||' account lock'||''''||';'|| chr(10);
			l_sqltext := l_sqltext||'end;';
			--
			activity_stream ( l_sqltext, '', 'PROCEDURE EXISTS', 'Create(d) create_rpwd_lock.', false, 1, 'P1', p_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'PROCEDURE EXISTS', 'create_rpwd_lock Created.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.object_exists('FSDBA','CREATE_RPWD','PROCEDURE');
        	--
        	IF l_boolean = false THEN
			l_sqltext := 'create or replace procedure fsdba.create_rpwd (uname IN VARCHAR2)'|| chr(10);
			l_sqltext := l_sqltext||'authid current_user '|| chr(10);
			l_sqltext := l_sqltext||'is '|| chr(10);
			l_sqltext := l_sqltext||'  rpwd varchar2(30);'|| chr(10);
			l_sqltext := l_sqltext||'begin'|| chr(10);
			l_sqltext := l_sqltext||'  rpwd := dbms_random.string('||''''||'U'||''''||',1)||dbms_random.string('||''''||'X'||''''||',29);'|| chr(10);
			l_sqltext := l_sqltext||'  execute immediate '||''''||'alter user '||''''||'||uname||'||''''||' identified by "'||''''||'||rpwd||'||''''||'"'||''''||';'|| chr(10);
			l_sqltext := l_sqltext||'end;';
			--
			activity_stream ( l_sqltext, '', 'PROCEDURE EXISTS', 'Create(d) create_rpwd.', false, 1, 'P1', p_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'PROCEDURE EXISTS', 'create_rpwd Created.', true, 1, 'P2', p_debug);
			--
		END IF;
		--
	END IF;
	--
	--*******************************
	--** All Modes Have Directory
	--*******************************
	l_boolean := fs_db_admin.fs_exists_functions.directory_exists ('SYS', 'DATA_PUMP_DIR', '/fslink/orapriv/ora_exports');
	--
	IF l_boolean = false THEN
		activity_stream ( 'CREATE OR REPLACE DIRECTORY data_pump_dir AS ' || '''' || '/fslink/orapriv/ora_exports' || '''', '',
				  'DIRECTORY EXISTS', 'DATA_PUMP_DIR To /fslink/orapriv/ora_exports.', false, 1, 'P1', p_debug);
		--
	ELSE
		--
		activity_stream ( '', '', 'DIRECTORY EXISTS', 'DATA_PUMP_DIR To /fslink/orapriv/ora_exports.', true, 1, 'P2', p_debug);
		--
	END IF;
	--
	--
	activity_stream ( '', '', '', '', true, 0, 'P8', p_debug);
	--
	activity_stream ( '', '', 'SUMMARY', 'PROVIDE BASIC SECURITY', true, 0, 'P7', p_debug);
	--
END provide_basic_security;
--
--
--**************************************************************************************************************************
--**         Procedure:	provide_roles
--**           Purpose:	This procedure creates and destroys the roles.
--**  Calling Programs:	--
--**   Programs Called:	fs_db_admin.fs_exists_functions
--**			fs_security_pkg.activity_stream
--**			sys.sys_context
--**   Tables Accessed:	
--**			dba_role_privs
--**			dba_roles
--**			v$instance
--**   Tables Modified:	--
--**  Passed Variables:
--**			p_status		-- Status message to check for errors.
--**			p_error_message		-- The actual error message.
--**			p_debug			-- The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:
--**			l_localprogramname	-- This programs name. (For debugging purposes.)
--**			l_programmessage	-- The local debugging message.
--**			l_sqltext		-- The DDL text
--**			l_count			-- Count Variable
--**			l_boolean		-- Choice Boolean
--**           Cursors:	
--**			c2			-- Select if these roles currently exist FS_DBA_ROLE, FS_CATALOG_ROLE.
--**			c3			-- Role list FS_DBA_ROLE,FS_CATALOG_ROLE.
--**			c5			-- Grantees associated to the role FS_DEVELOPER_ROLE.
--**			c6			-- List of System Privileges associated to FS_DEVELOPER_ROLE.
--**			c8			-- Grantees associated to the role FS_SELECT_CATALOG_ROLE.
--**			c9			-- Grantess who have CREATE SESSION, ALTER SESSION.
--**           pragmas: --
--**         Exception:	
--**************************************************************************************************************************
--**        Pseudo code: 
--**			GLOBAL Agreed to Roles: FS_SESSION, FS_CREATE
--**			IF LOWER(p_rolechoice) = 'c' OR LOWER(p_rolechoice) = 'b' OR LOWER(p_rolechoice) = 'h'
--**				NULL
--**			IF LOWER(p_rolechoice) = 'c'
--**				Switch roles for users to DBA and FS_SELECT_CATALOG_ROLE from FSDBA_ROLE and FS_CATALOG_ROLE
--**				Drop roles FSDBA_ROLE and FS_CATALOG_ROLE
--**			IF LOWER(p_rolechoice) = 's' OR LOWER(p_rolechoice) = 'b' OR LOWER(p_rolechoice) = 'h'
--**				Create FS_DBA_ROLE and FS_CATALOG_ROLE.
--**				Revoke FS_SELECT_CATALOG_ROLE and grant FS_CATALOG_ROLE
--**			IF PROD revoke role from users and drop role.
--**			IF not PROD then build FS_DEVELOPER_ROLE
--**				Syspriv Grants
--**				Protected Syspriv grants
--**				Role grants
--**			REVOKE grant of Roles to SYS	
--**************************************************************************************************************************
--
--
PROCEDURE provide_roles
(
 p_status				OUT		VARCHAR2,				-- Status message to check for errors.
 p_errormessage				OUT		VARCHAR2,				-- The actual error message.
 p_debug				IN		NUMBER					-- Turn on DEBUG.
)
AS
 --
 CURSOR c1 IS
	SELECT (column_value).getstringval() syspriv 
	FROM xmltable('"CREATE SESSION", "ALTER SESSION"');
 --
 CURSOR c2 IS
	SELECT (column_value).getstringval() syspriv
	FROM xmltable('"CREATE SYNONYM","CREATE SEQUENCE","CREATE VIEW","CREATE TABLE","CREATE CLUSTER"');
 --
 CURSOR c3 IS
	SELECT grantee, granted_role
	FROM dba_role_privs
	WHERE granted_role IN ('FS_DEVELOPER_ROLE')
	ORDER BY grantee;
 --
 CURSOR c4 IS
	SELECT (column_value).getstringval() syspriv
	FROM xmltable('"ALTER SESSION","CREATE SESSION",
	"ANALYZE ANY","ANALYZE ANY DICTIONARY","ALTER ANY ASSEMBLY","CREATE ANY ASSEMBLY","DROP ANY ASSEMBLY","EXECUTE ANY ASSEMBLY",
	"CHANGE NOTIFICATION","ALTER ANY CLUSTER","CREATE ANY CLUSTER","DROP ANY CLUSTER","CREATE ANY CONTEXT","DROP ANY CONTEXT",
	"DEBUG ANY PROCEDURE","DEBUG CONNECT SESSION","SELECT ANY DICTIONARY","ALTER ANY EDITION","CREATE ANY EDITION","DROP ANY EDITION",
	"ALTER ANY EVALUATION CONTEXT","CREATE ANY EVALUATION CONTEXT","DROP ANY EVALUATION CONTEXT","EXECUTE ANY EVALUATION CONTEXT",
	"EXECUTE ANY CLASS","EXECUTE ANY LIBRARY","ALTER ANY INDEX",
	"CREATE ANY INDEX","DROP ANY INDEX","ALTER ANY INDEXTYPE","CREATE ANY INDEXTYPE","DROP ANY INDEXTYPE","EXECUTE ANY INDEXTYPE",
	"ALTER ANY MINING MODEL","COMMENT ANY MINING MODEL","CREATE ANY MINING MODEL","DROP ANY MINING MODEL","LOGMINING","SELECT ANY MINING MODEL",
	"ALTER ANY MATERIALIZED VIEW","CREATE ANY MATERIALIZED VIEW","DROP ANY MATERIALIZED VIEW","GLOBAL QUERY REWRITE","ON COMMIT REFRESH",
	"CREATE ANY DIMENSION","DROP ANY DIMENSION","ALTER ANY DIMENSION","ALTER ANY MEASURE FOLDER","CREATE ANY MEASURE FOLDER",
	"DELETE ANY MEASURE FOLDER","DROP ANY MEASURE FOLDER","INSERT ANY MEASURE FOLDER","SELECT ANY MEASURE FOLDER",
	"ALTER ANY CUBE","CREATE ANY CUBE","DROP ANY CUBE","SELECT ANY CUBE",
	"UPDATE ANY CUBE","ALTER ANY CUBE BUILD PROCESS","CREATE ANY CUBE BUILD PROCESS","DROP ANY CUBE BUILD PROCESS","SELECT ANY CUBE BUILD PROCESS",
	"UPDATE ANY CUBE BUILD PROCESS","ALTER ANY CUBE DIMENSION","CREATE ANY CUBE DIMENSION","DELETE ANY CUBE DIMENSION","DROP ANY CUBE DIMENSION",
	"INSERT ANY CUBE DIMENSION","SELECT ANY CUBE DIMENSION","UPDATE ANY CUBE DIMENSION","ALTER ANY OPERATOR","CREATE ANY OPERATOR","DROP ANY OPERATOR",
	"EXECUTE ANY OPERATOR","ALTER ANY OUTLINE","CREATE ANY OUTLINE","DROP ANY OUTLINE","GRANT ANY OBJECT PRIVILEGE","GRANT ANY ROLE",
	"ALTER ANY PROCEDURE","CREATE ANY PROCEDURE","DROP ANY PROCEDURE","EXECUTE ANY PROCEDURE","ALTER RESOURCE COST","RESUMABLE","ALTER ANY ROLE",
	"CREATE ROLE","DROP ANY ROLE","ALTER ANY SEQUENCE","CREATE ANY SEQUENCE","DROP ANY SEQUENCE","SELECT ANY SEQUENCE","ALTER ANY SQL PROFILE",
	"CREATE ANY SQL PROFILE","DROP ANY SQL PROFILE","ALTER ANY SQL TRANSLATION PROFILE","CREATE ANY SQL TRANSLATION PROFILE","TRANSLATE ANY SQL",
	"DROP ANY SQL TRANSLATION PROFILE","USE ANY SQL TRANSLATION PROFILE","CREATE ANY SYNONYM","DROP ANY SYNONYM","ALTER ANY TABLE","BACKUP ANY TABLE",
	"COMMENT ANY TABLE","CREATE ANY TABLE","DELETE ANY TABLE","DROP ANY TABLE","FLASHBACK ANY TABLE","INSERT ANY TABLE","LOCK ANY TABLE",
	"READ ANY TABLE","REDEFINE ANY TABLE","SELECT ANY TABLE","UNDER ANY TABLE","UPDATE ANY TABLE","FORCE ANY TRANSACTION","ADMINISTER DATABASE TRIGGER",
	"ALTER ANY TRIGGER","CREATE ANY TRIGGER","DROP ANY TRIGGER","ADMINISTER ANY SQL TUNING SET","ADMINISTER SQL MANAGEMENT OBJECT",
	"ADMINISTER SQL TUNING SET","ADVISOR","ALTER ANY TYPE","CREATE ANY TYPE","DROP ANY TYPE","EXECUTE ANY TYPE","UNDER ANY TYPE","CREATE ANY VIEW",
	"DROP ANY VIEW","MERGE ANY VIEW","UNDER ANY VIEW"');
 --
 CURSOR c5 IS
	SELECT (column_value).getstringval() syspriv
	FROM xmltable('"CREATE ANY ANALYTIC VIEW","ALTER ANY ANALYTIC VIEW","DROP ANY ANALYTIC VIEW","CREATE ANY HIERARCHY","ALTER ANY HIERARCHY",
	"DROP ANY HIERARCHY","CREATE ANY ATTRIBUTE DIMENSION","ALTER ANY ATTRIBUTE DIMENSION","DROP ANY ATTRIBUTE DIMENSION"');
 --
 CURSOR c6 IS
	SELECT (column_value).getstringval() rolepriv
	FROM xmltable('"AQ_ADMINISTRATOR_ROLE","SCHEDULER_ADMIN","GATHER_SYSTEM_STATISTICS",
	"SELECT_CATALOG_ROLE","EM_EXPRESS_BASIC"');
 --
 l_localprogramname			VARCHAR2(128) := 'provide_roles';
 l_programmessage			CLOB;
 l_sqltext				VARCHAR2(1000);
 l_count				NUMBER;
 l_boolean				BOOLEAN;
 l_dbvers				VARCHAR2(5);
BEGIN
	--
	g_programcontext := l_localprogramname;
	g_providerolespasscnt := 0;
	g_providerolesfailcnt := 0;
	activity_stream ( '', '', 'DETAIL', 'PROVIDE ROLES', true, 0, 'P6', p_debug);
	SELECT substr(VERSION,1,4) INTO l_dbvers
	FROM v$instance;
	--
	--***************************
	--** SETUP FS_SESSION ROLE
	--***************************
	--
	l_boolean := fs_db_admin.fs_exists_functions.role_exists('FS_SESSION');
	--
	IF l_boolean = false THEN
		activity_stream ( 'CREATE ROLE FS_SESSION', '', 'ROLE EXISTS', 'FS_SESSION.', l_boolean, 1, 'P1', p_debug);
		activity_stream ( 'REVOKE FS_SESSION FROM sys', '', 'ROLE GRANTED', 'FS_SESSION TO SYS.', l_boolean, 1, 'P1', p_debug);
	ELSE
		activity_stream ( '', '', 'ROLE EXISTS', 'FS_SESSION Created.', l_boolean, 1, 'P2', p_debug);
		--
		l_boolean := fs_db_admin.fs_exists_functions.grantee_rolepriv_exists('SYS', 'FS_SESSION');
		--
		IF l_boolean = false THEN
			activity_stream ( '', '', 'ROLE NOT GRANTED', 'FS_SESSION NOT GRANTED TO SYS.', true, 1, 'P2', p_debug);
		ELSE
			activity_stream ( 'REVOKE FS_SESSION FROM sys', '', 'ROLE GRANTED', 'FS_SESSION TO SYS.', l_boolean, 1, 'P1', p_debug);
		END IF;
	END IF;
	--
	FOR c1_rec IN c1 LOOP
		l_boolean := fs_db_admin.fs_exists_functions.grantee_syspriv_exists('FS_SESSION',c1_rec.syspriv);
		--
		IF l_boolean = false THEN
			activity_stream ( 'GRANT '||c1_rec.syspriv||' TO FS_SESSION', '', 'SYSPRIV GRANTED', c1_rec.syspriv||' To FS_SESSION.', l_boolean, 1, 'P1', p_debug);
		ELSE
			activity_stream ( '', '', 'SYSPRIV GRANTED', c1_rec.syspriv||' To FS_SESSION.', l_boolean, 1, 'P2', p_debug);
		END IF;
	END LOOP;
 	--
	--***************************
	--** SETUP FS_CREATE ROLE
	--***************************
	--
	l_boolean := fs_db_admin.fs_exists_functions.role_exists('FS_CREATE');
	--
	IF l_boolean = false THEN
		activity_stream ( 'CREATE ROLE FS_CREATE', '', 'ROLE EXISTS', 'FS_CREATE.', l_boolean, 1, 'P1', p_debug);
		activity_stream ( 'REVOKE FS_CREATE FROM sys', '', 'ROLE NOT GRANTED', 'FS_CREATE TO SYS.', l_boolean, 1, 'P1', p_debug);
	ELSE
		activity_stream ( '', '', 'ROLE EXISTS', 'FS_CREATE.', l_boolean, 1, 'P2', p_debug);
		--
		l_boolean := fs_db_admin.fs_exists_functions.grantee_rolepriv_exists('SYS', 'FS_CREATE');
		--
		IF l_boolean = false THEN
			activity_stream ( '', '', 'ROLE NOT GRANTED', 'FS_CREATE NOT GRANTED TO SYS.', true, 1, 'P2', p_debug);
		ELSE
			activity_stream ( 'REVOKE FS_CREATE FROM sys', '', 'ROLE GRANTED', 'FS_CREATE TO SYS.', false, 1, 'P1', p_debug);
		END IF;
	END IF;
	--
	FOR c2_rec IN c2 LOOP
		l_boolean := fs_db_admin.fs_exists_functions.grantee_syspriv_exists('FS_CREATE',c2_rec.syspriv);
		--
		IF l_boolean = false THEN
			activity_stream ( 'GRANT '||c2_rec.syspriv||' TO FS_CREATE', '', 'SYSPRIV GRANTED', c2_rec.syspriv||' To FS_CREATE.', l_boolean, 1, 'P1', p_debug);
		ELSE
			activity_stream ( '', '', 'SYSPRIV GRANTED', c2_rec.syspriv||' To FS_CREATE.', l_boolean, 1, 'P2', p_debug);
		END IF;
	END LOOP;
	--
	--***************************
	--** Setup FS_DEVELOPER_ROLE
	--***************************
	--
	l_boolean := fs_db_admin.fs_exists_functions.role_exists('FS_DEVELOPER_ROLE');
	--
	IF  LOWER(SYS_CONTEXT ('USERENV', 'DB_DOMAIN')) LIKE 'fdc%' OR  (LOWER(SYS_CONTEXT ('USERENV', 'DB_DOMAIN')) LIKE 'wrk%'  AND LOWER(SYS_CONTEXT ('USERENV', 'DB_NAME')) LIKE '%t')
		AND l_boolean = false THEN 
		--
		activity_stream ( '', '', 'ROLE DOES NOT EXIST IN Non-Dev Environment', 'FS_DEVELOPER_ROLE', true, 1, 'P2', p_debug);
		--
		l_boolean := fs_db_admin.fs_exists_functions.grantee_rolepriv_exists('SYS', 'FS_DEVELOPER_ROLE');
		--
		IF l_boolean = false THEN
			activity_stream ( '', '', 'ROLE NOT GRANTED', 'FS_DEVELOPER_ROLE NOT GRANTED TO SYS.', true, 1, 'P2', p_debug);
		ELSE
			activity_stream ( 'REVOKE FS_DEVELOPER_ROLE FROM sys', '', 'ROLE GRANTED', 'FS_DEVELOPER_ROLE TO SYS.', false, 1, 'P1', p_debug);
		END IF;
		--
	ELSIF ( LOWER(SYS_CONTEXT ('USERENV', 'DB_DOMAIN')) LIKE 'fdc%' OR (LOWER(SYS_CONTEXT ('USERENV', 'DB_DOMAIN')) LIKE 'wrk%' ) AND LOWER(SYS_CONTEXT ('USERENV', 'DB_NAME')) LIKE '%t')
		AND l_boolean = true THEN
		--
		FOR c3_rec IN c3 LOOP
			--
			activity_stream ('REVOKE ROLE FS_DEVELOPER_ROLE FROM '||c3_rec.grantee, '', 'ROLE GRANTED', 'FS_DEVELOPER_ROLE Granted To '||c3_rec.grantee||'.', false, 1, 'P1', p_debug);
			--
		END LOOP;
		--
		l_boolean := fs_db_admin.fs_exists_functions.grantee_rolepriv_exists('SYS', 'FS_DEVELOPER_ROLE');
		--
		IF l_boolean = false THEN
			activity_stream ( '', '', 'ROLE NOT GRANTED', 'FS_DEVELOPER_ROLE NOT GRANTED TO SYS.', true, 1, 'P2', p_debug);
		ELSE
			activity_stream ( 'REVOKE FS_DEVELOPER_ROLE FROM sys', '', 'ROLE GRANTED', 'FS_DEVELOPER_ROLE TO SYS.', false, 1, 'P1', p_debug);
		END IF;
		--
		activity_stream ('DROP ROLE FS_DEVELOPER_ROLE', '', 'ROLE EXISTS Non-Dev Environment', 'FS_DEVELOPER_ROLE', false, 1, 'P1', p_debug);
		--
	ELSE
		IF l_boolean = true THEN
			--
			activity_stream ( '', '', 'ROLE EXISTS', 'FS_DEVELOPER_ROLE.', true, 1, 'P2', p_debug);
			--
			l_boolean := fs_db_admin.fs_exists_functions.grantee_rolepriv_exists('SYS', 'FS_DEVELOPER_ROLE');
			--
			IF l_boolean = false THEN
				activity_stream ( '', '', 'ROLE NOT GRANTED', 'FS_DEVELOPER_ROLE NOT GRANTED TO SYS.', true, 1, 'P2', p_debug);
			ELSE
				activity_stream ( 'REVOKE FS_DEVELOPER_ROLE FROM sys', '', 'ROLE GRANTED', 'FS_DEVELOPER_ROLE TO SYS.', false, 1, 'P1', p_debug);
			END IF;
		--
		ELSE
			--
			activity_stream ('CREATE ROLE FS_DEVELOPER_ROLE NOT IDENTIFIED', '', 'ROLE EXISTS', 'FS_DEVELOPER_ROLE.', false, 1, 'P1', p_debug);
			activity_stream ( 'REVOKE FS_DEVELOPER_ROLE FROM sys', '', 'ROLE NOT GRANTED', 'FS_DEVELOPER_ROLE TO SYS.', l_boolean, 1, 'P1', p_debug);
			--
		END IF;
		--
		IF l_dbvers IN ('12.1', '12.2', '18.1') THEN
			FOR c4_rec IN c4 LOOP
				l_boolean := fs_db_admin.fs_exists_functions.grantee_syspriv_exists('FS_DEVELOPER_ROLE', c4_rec.syspriv);
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'SYSPRIV GRANTED', c4_rec.syspriv||' To FS_DEVELOPER_ROLE.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ('GRANT '||c4_rec.syspriv|| ' TO FS_DEVELOPER_ROLE', '', 'SYSPRIV GRANTED', c4_rec.syspriv||' To FS_DEVELOPER_ROLE.', false, 1, 'P1', p_debug);
					--
				END IF;
			END LOOP;
		END IF;
		--
		IF l_dbvers IN ('12.2', '18.1') THEN
			FOR c5_rec IN c5 LOOP
				l_boolean := fs_db_admin.fs_exists_functions.grantee_syspriv_exists('FS_DEVELOPER_ROLE', c5_rec.syspriv);
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'SYSPRIV GRANTED', c5_rec.syspriv||' To FS_DEVELOPER_ROLE.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ('GRANT '||c5_rec.syspriv|| ' TO FS_DEVELOPER_ROLE', '', 'SYSPRIV GRANTED', c5_rec.syspriv||' To FS_DEVELOPER_ROLE.', false, 1, 'P1', p_debug);
					--
				END IF;
			END LOOP;
		END IF;
		--
		FOR c6_rec IN c6 LOOP
			l_boolean := fs_db_admin.fs_exists_functions.grantee_rolepriv_exists('FS_DEVELOPER_ROLE', c6_rec.rolepriv);
			IF l_boolean = true THEN
				--
				activity_stream ( '', '', 'ROLE GRANTED', c6_rec.rolepriv||' to FS_DEVELOPER_ROLE.', true, 1, 'P2', p_debug);
				--
			ELSE
				--
				activity_stream ('GRANT '||c6_rec.rolepriv|| ' TO FS_DEVELOPER_ROLE', '', 'ROLE GRANTED', c6_rec.rolepriv||' To FS_DEVELOPER_ROLE.', false, 1, 'P1', p_debug);
				--
			END IF;
		END LOOP;
		--
	END IF;
	--
	activity_stream ( '', '', '', '', true, 0, 'P8', p_debug);
	--
	activity_stream ( '', '', 'SUMMARY', 'PROVIDE ROLES', true, 0, 'P7', p_debug);
	--
END provide_roles;
--
--
--**************************************************************************************************************************
--**         Procedure:	provide_profiles
--**           Purpose:	This procedure create the profiles.
--**  Calling Programs:	--
--**   Programs Called:	fs_db_admin.fs_exists_functions
--**			fs_security_pkg.activity_stream
--**   Tables Accessed:	
--**			dba_users
--**			dba_profiles
--**			dual
--**   Tables Modified:	--
--**  Passed Variables:
--**			p_status			-- Status message to check for errors.
--**			p_error_message		-- The actual error message.
--**			p_debug				-- The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:
--**			l_localprogramname	-- This programs name. (For debugging purposes.)
--**			l_programmessage	-- The local debugging message.
--**			l_sqltext			-- The DDL text
--**			l_count				-- Count Variable
--**			l_boolean			-- Choice Boolean
--**           Cursors:	
--**			c1					-- The Profile List.
--**			c2					-- Username asociated to the profile list.
--**			c3					-- Profile Exceptions SESSIONS_PER_USER,IDLE_TIME,PASSWORD_LIFE_TIME
--**			c4					-- Profile exceptions SESSIONS_PER_USER
--**			c5					-- Profile exceptions SESSIONS_PER_USER,FAILED_LOGIN_ATTEMPTS,
--**								-- PASSWORD_LIFE_TIME,PASSWORD_GRACE_TIME
--**			c6					-- Default Profile Required Exceptions
--**			c7					-- Default Profile Original Delivered Exceptions
--**           pragmas: --
--**         Exception:	--
--**************************************************************************************************************************
--**        Pseudo code: 
--**			IF new profile exists verfiy execeptions set correctly.
--**			IF new profiles don'r exist create them
--**************************************************************************************************************************
--
--
PROCEDURE provide_profiles
(
 p_status				OUT		VARCHAR2,			-- Status message to check for errors.
 p_errormessage				OUT		VARCHAR2,			-- The actual error message.
 p_debug				IN		NUMBER DEFAULT 0		-- Turn on DEBUG.
)
AS
 CURSOR c1 IS
	SELECT (column_value).getstringval() profile
	FROM xmltable('"FS_APP_PROFILE", "FS_USER_PROFILE","FS_OWNER_PROFILE","FS_ADMIN_PROFILE","FS_TEMP_PROFILE"');
 --
 CURSOR c2 IS
	SELECT username
	FROM dba_users
	WHERE profile in ('FS_APP_PROFILE', 'FS_USER_PROFILE','FS_OWNER_PROFILE','FS_ADMIN_PROFILE','FS_TEMP_PROFILE');
 --
 CURSOR c3 (p_profile	VARCHAR2) IS
	SELECT profile, resource_name,limit
	FROM dba_profiles
	WHERE profile = p_profile
	AND resource_name NOT IN ('SESSIONS_PER_USER','IDLE_TIME','PASSWORD_LIFE_TIME');
 --
 CURSOR c4 (p_profile	VARCHAR2) IS
	SELECT profile, resource_name,limit
	FROM dba_profiles
	WHERE profile = p_profile
	AND resource_name NOT IN ('SESSIONS_PER_USER');
 --
 CURSOR c5 (p_profile	VARCHAR2) IS
	SELECT profile, resource_name, limit
	FROM dba_profiles
	WHERE profile = p_profile
	AND resource_name NOT IN ('SESSIONS_PER_USER','FAILED_LOGIN_ATTEMPTS','PASSWORD_LIFE_TIME','PASSWORD_GRACE_TIME');
 --
 CURSOR c6 IS
	WITH def_required AS
	( 
	SELECT 'COMPOSITE_LIMIT' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'CONNECT_TIME' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'CPU_PER_CALL' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'CPU_PER_SESSION' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'IDLE_TIME' resource_name,'15' limit FROM dual UNION
	SELECT 'LOGICAL_READS_PER_CALL' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'LOGICAL_READS_PER_SESSION' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'PRIVATE_SGA' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'SESSIONS_PER_USER' resource_name,'5' limit FROM dual UNION
	SELECT 'FAILED_LOGIN_ATTEMPTS' resource_name,'5' limit FROM dual UNION
	SELECT 'INACTIVE_ACCOUNT_TIME' resource_name,'60' limit FROM dual UNION
	SELECT 'PASSWORD_GRACE_TIME' resource_name,'5' limit FROM dual UNION
	SELECT 'PASSWORD_LIFE_TIME' resource_name,'60' limit FROM dual UNION
	SELECT 'PASSWORD_LOCK_TIME' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'PASSWORD_REUSE_MAX' resource_name,'24' limit FROM dual UNION
	SELECT 'PASSWORD_REUSE_TIME' resource_name,'365' limit FROM dual UNION
	SELECT 'PASSWORD_VERIFY_FUNCTION' resource_name,'FS_PASSWORD_VERIFY' limit FROM dual
	) 
	SELECT p.profile,p.resource_name,CASE WHEN p.limit=dr.limit THEN 0 ELSE 1 END decision, p.limit curr_limit, dr.limit req_limit
	FROM dba_profiles p, def_required dr
	WHERE p.resource_name = dr.resource_name
	AND p.profile = 'DEFAULT';
 --
 CURSOR c7 IS
	WITH def_original AS
	( 
	SELECT 'COMPOSITE_LIMIT' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'SESSIONS_PER_USER' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'CPU_PER_SESSION' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'CPU_PER_CALL' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'LOGICAL_READS_PER_SESSION' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'LOGICAL_READS_PER_CALL' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'IDLE_TIME' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'CONNECT_TIME' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'PRIVATE_SGA' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'FAILED_LOGIN_ATTEMPTS' resource_name,'10' limit FROM dual UNION
	SELECT 'PASSWORD_LIFE_TIME' resource_name,'180' limit FROM dual UNION
	SELECT 'PASSWORD_REUSE_TIME' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'PASSWORD_REUSE_MAX' resource_name,'UNLIMITED' limit FROM dual UNION
	SELECT 'PASSWORD_VERIFY_FUNCTION' resource_name,'NULL' limit FROM dual UNION
	SELECT 'PASSWORD_LOCK_TIME' resource_name,'1' limit FROM dual UNION
	SELECT 'PASSWORD_GRACE_TIME' resource_name,'7' limit FROM dual UNION
	SELECT 'INACTIVE_ACCOUNT_TIME' resource_name,'60' limit FROM dual
	) 
	SELECT p.profile,p.resource_name,CASE WHEN p.limit=do.limit THEN 0 ELSE 1 END decision, p.limit curr_limit, do.limit req_limit
	FROM dba_profiles p, def_original do
	WHERE p.resource_name = do.resource_name
	AND p.profile = 'DEFAULT';
 --
 l_localprogramname			VARCHAR2(128) := 'provide_profiles';
 l_programmessage			CLOB;
 l_sqltext				VARCHAR2(1000);
 l_boolean				BOOLEAN;
 l_count				NUMBER;
BEGIN
	--
	g_programcontext := l_localprogramname;
	g_provideprofilespasscnt := 0;
	g_provideprofilesfailcnt := 0;
	activity_stream ( '', '', 'DETAIL', 'PROVIDE PROFILES', true, 0, 'P6', p_debug);
	--
	--********************************************************************
	--**
	--********************************************************************
	--
	--
	FOR c1_rec IN c1 LOOP
		--
		l_boolean := fs_db_admin.fs_exists_functions.profile_exists (c1_rec.profile);
		--
		IF l_boolean = true THEN
			--
			activity_stream ( '', '', 'PROFILE EXISTS', c1_rec.profile||'.', true, 1, 'P2', p_debug);
			--
			IF c1_rec.profile = 'FS_APP_PROFILE' THEN
				l_boolean := fs_db_admin.fs_exists_functions.profile_limit_exists (c1_rec.profile, 'SESSIONS_PER_USER', '400');
				--
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', 'SESSIONS_PER_USER=400 On '||c1_rec.profile||'.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ( 'ALTER PROFILE '||c1_rec.profile||' LIMIT SESSIONS_PER_USER 400', '', 
					'PROFILE RESOURCE LIMIT', 'SESSIONS_PER_USER=400 On '||c1_rec.profile||'.', false, 1, 'P1', p_debug);
					--
				END IF;
				l_boolean := fs_db_admin.fs_exists_functions.profile_limit_exists (c1_rec.profile, 'IDLE_TIME', '30');
				--
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', 'IDLE_TIME=30 On '||c1_rec.profile||'.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ( 'ALTER PROFILE '||c1_rec.profile||' LIMIT IDLE_TIME 30', '', 
					'PROFILE RESOURCE LIMIT', 'IDLE_TIME=30 On '||c1_rec.profile||'.', false, 1, 'P1', p_debug);
					--
				END IF;
				--
				l_boolean := fs_db_admin.fs_exists_functions.profile_limit_exists (c1_rec.profile, 'PASSWORD_LIFE_TIME', '365');
				--
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', 'PASSWORD_LIFE_TIME=365 On '||c1_rec.profile||'.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ( 'ALTER PROFILE '||c1_rec.profile||' LIMIT PASSWORD_LIFE_TIME 365', '', 
					'PROFILE RESOURCE LIMIT SET', 'PASSWORD_LIFE_TIME=365 On '||c1_rec.profile||'.', false, 1, 'P1', p_debug);
					--
				END IF;
				--
				FOR c3_rec IN c3 (c1_rec.profile) LOOP
					IF c3_rec.limit = 'DEFAULT' THEN
						--
						activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c3_rec.resource_name||'='||c3_rec.limit||' On '||c3_rec.profile||'.', true, 1, 'P2', p_debug);
						--
					ELSE
						--
						activity_stream ( 'ALTER PROFILE '||c3_rec.profile||' LIMIT '||c3_rec.resource_name||' DEFAULT', '', 
						'PROFILE RESOURCE LIMIT SET', c3_rec.resource_name||'=DEFAULT On '||c3_rec.profile||'.', false, 1, 'P1', p_debug);
						--
					END IF;
				END LOOP;
			--
			ELSIF c1_rec.profile = 'FS_ADMIN_PROFILE' THEN
				l_boolean := fs_db_admin.fs_exists_functions.profile_limit_exists (c1_rec.profile, 'SESSIONS_PER_USER', '20');
				--
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', 'SESSIONS_PER_USER=20 On '||c1_rec.profile||'.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ( 'ALTER PROFILE '||c1_rec.profile||' LIMIT SESSIONS_PER_USER 20', '', 
					'PROFILE RESOURCE LIMIT SET', 'SESSIONS_PER_USER=20 On '||c1_rec.profile||'.', false, 1, 'P1', p_debug);
					--
				END IF;
				l_boolean := fs_db_admin.fs_exists_functions.profile_limit_exists (c1_rec.profile, 'IDLE_TIME', '20');
				--
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', 'IDLE_TIME=20 On '||c1_rec.profile||'.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ( 'ALTER PROFILE '||c1_rec.profile||' LIMIT IDLE_TIME 30', '', 
					'PROFILE RESOURCE LIMIT SET', 'IDLE_TIME=20 On '||c1_rec.profile||'.', false, 1, 'P1', p_debug);
					--
				END IF;
				--
				l_boolean := fs_db_admin.fs_exists_functions.profile_limit_exists (c1_rec.profile, 'PASSWORD_LIFE_TIME', '365');
				--
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', 'PASSWORD_LIFE_TIME=365 On '||c1_rec.profile||'.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ( 'ALTER PROFILE '||c1_rec.profile||' LIMIT PASSWORD_LIFE_TIME 365', '', 
					'PROFILE RESOURCE LIMIT SET', 'PASSWORD_LIFE_TIME=365 On '||c1_rec.profile||'.', false, 1, 'P1', p_debug);
					--
				END IF;
				--
				FOR c3_rec IN c3 (c1_rec.profile) LOOP
					IF c3_rec.limit = 'DEFAULT' THEN
						--
						activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c3_rec.resource_name||'='||c3_rec.limit||' On '||c3_rec.profile||'.', true, 1, 'P2', p_debug);
						--
					ELSE
						--
						activity_stream ( 'ALTER PROFILE '||c3_rec.profile||' LIMIT '||c3_rec.resource_name||' DEFAULT', '', 
						'PROFILE RESOURCE LIMIT SET', c3_rec.resource_name||'=DEFAULT On '||c3_rec.profile||'.', false, 1, 'P1', p_debug);
						--
					END IF;
				END LOOP;
				--
			ELSIF c1_rec.profile = 'FS_USER_PROFILE' THEN
				l_boolean := fs_db_admin.fs_exists_functions.profile_limit_exists (c1_rec.profile, 'SESSIONS_PER_USER', '5');
				--
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', 'SESSIONS_PER_USER=5 On '||c1_rec.profile||'.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ( 'ALTER PROFILE '||c1_rec.profile||' LIMIT SESSIONS_PER_USER 5', '', 
						'PROFILE RESOURCE LIMIT SET', 'SESSIONS_PER_USER=5 On '||c1_rec.profile||'.', false, 1, 'P1', p_debug);
					--
				END IF;
				--
				FOR c4_rec IN c4 (c1_rec.profile) LOOP
					IF c4_rec.limit = 'DEFAULT' THEN
						--
						activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c4_rec.resource_name||'='||c4_rec.limit||' On '||c4_rec.profile||'.', true, 1, 'P2', p_debug);
						--
					ELSE
						--
						activity_stream ( 'ALTER PROFILE '||c4_rec.profile||' LIMIT '||c4_rec.resource_name||' DEFAULT', '', 
						'PROFILE RESOURCE LIMIT SET', c4_rec.resource_name||'=DEFAULT On '||c4_rec.profile||'.', false, 1, 'P1', p_debug);
						--
					END IF;
				END LOOP;
				--
			ELSIF c1_rec.profile = 'FS_TEMP_PROFILE' THEN
				l_boolean := fs_db_admin.fs_exists_functions.profile_limit_exists (c1_rec.profile, 'SESSIONS_PER_USER', '5');
				--
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', 'SESSIONS_PER_USER=5 On '||c1_rec.profile||'.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ( 'ALTER PROFILE '||c1_rec.profile||' LIMIT SESSIONS_PER_USER 5', '', 
						'PROFILE RESOURCE LIMIT SET', 'SESSIONS_PER_USER=5 On '||c1_rec.profile||'.', false, 1, 'P1', p_debug);
					--
				END IF;
				--
				FOR c4_rec IN c4 (c1_rec.profile) LOOP
					IF c4_rec.limit = 'DEFAULT' THEN
						--
						activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c4_rec.resource_name||'='||c4_rec.limit||' On '||c4_rec.profile||'.', true, 1, 'P2', p_debug);
						--
					ELSE
						--
						activity_stream ( 'ALTER PROFILE '||c4_rec.profile||' LIMIT '||c4_rec.resource_name||' DEFAULT', '', 
						'PROFILE RESOURCE LIMIT SET', c4_rec.resource_name||'=DEFAULT On '||c4_rec.profile||'.', false, 1, 'P1', p_debug);
						--
					END IF;
				END LOOP;
				--
			ELSIF c1_rec.profile = 'FS_OWNER_PROFILE' THEN
				l_boolean := fs_db_admin.fs_exists_functions.profile_limit_exists (c1_rec.profile, 'SESSIONS_PER_USER', '1');
				--
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', 'SESSIONS_PER_USER=1 On '||c1_rec.profile||'.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ( 'ALTER PROFILE '||c1_rec.profile||' LIMIT SESSIONS_PER_USER 1', '', 
					'PROFILE RESOURCE LIMIT SET', 'SESSIONS_PER_USER=1 On '||c1_rec.profile||'.', false, 1, 'P1', p_debug);
					--
				END IF;
				l_boolean := fs_db_admin.fs_exists_functions.profile_limit_exists (c1_rec.profile, 'FAILED_LOGIN_ATTEMPTS', '1');
				--
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', 'FAILED_LOGIN_ATTEMPTS=1 On '||c1_rec.profile||'.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ( 'ALTER PROFILE '||c1_rec.profile||' LIMIT IDLE_TIME 1', '', 
					'PROFILE RESOURCE LIMIT SET', 'FAILED_LOGIN_ATTEMPTS=1 On '||c1_rec.profile||'.', false, 1, 'P1', p_debug);
					--
				END IF;
				--
				--********************************************
				--** Profile Limit PASSWORD_LIFE_TIME cannot
				--** be set to 0. Hasto have value > 0. When
				--** set to value < than .0001 it becomes 0.
				--********************************************
				l_boolean := fs_db_admin.fs_exists_functions.profile_limit_exists (c1_rec.profile, 'PASSWORD_LIFE_TIME', '0');
				--
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', 'PASSWORD_LIFE_TIME=0.00001 On '||c1_rec.profile||'.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ( 'ALTER PROFILE '||c1_rec.profile||' LIMIT PASSWORD_LIFE_TIME 0.00001', '', 
					'PROFILE RESOURCE LIMIT SET', 'PASSWORD_LIFE_TIME=0.00001 On '||c1_rec.profile||'.', false, 1, 'P1', p_debug);
					--
				END IF;
				--
				l_boolean := fs_db_admin.fs_exists_functions.profile_limit_exists (c1_rec.profile, 'PASSWORD_GRACE_TIME', '0');
				--
				IF l_boolean = true THEN
					--
					activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', 'PASSWORD_GRACE_TIME=0 On '||c1_rec.profile||'.', true, 1, 'P2', p_debug);
					--
				ELSE
					--
					activity_stream ( 'ALTER PROFILE '||c1_rec.profile||' LIMIT PASSWORD_GRACE_TIME 0', '', 
					'PROFILE RESOURCE LIMIT SET', 'PASSWORD_GRACE_TIME=0 On '||c1_rec.profile||'.', false, 1, 'P1', p_debug);
					--
				END IF;
				--
				FOR c5_rec IN c5 (c1_rec.profile) LOOP
					IF c5_rec.limit = 'DEFAULT' THEN
						--
						activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c5_rec.resource_name||'='||c5_rec.limit||' On '||c5_rec.profile||'.', true, 1, 'P2', p_debug);
						--
					ELSE
						--
						activity_stream ( 'ALTER PROFILE '||c5_rec.profile||' LIMIT '||c5_rec.resource_name||' DEFAULT', '', 
						'PROFILE RESOURCE LIMIT SET', c5_rec.resource_name||'=DEFAULT On '||c5_rec.profile||'.', false, 1, 'P1', p_debug);
						--
					END IF;
				END LOOP;
				--
			ELSE
				activity_stream ( '', '', 'CODE PATH ERROR', 'On '||c1_rec.profile||'.', false, 1, 'P5', p_debug);
			END IF;
			--
		ELSIF l_boolean = false THEN
			l_sqltext := 'CREATE PROFILE '||c1_rec.profile;
			--
			IF c1_rec.profile = 'FS_APP_PROFILE' THEN
				l_sqltext := l_sqltext || 
						' LIMIT 
						SESSIONS_PER_USER		400 
						IDLE_TIME			30 
						PASSWORD_LIFE_TIME		365';
				--
				activity_stream ( l_sqltext, '', 'PROFILE EXISTS', c1_rec.profile||'.', false, 1, 'P1', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource COMPOSITE_LIMIT=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CONNECT_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CPU_PER_CALL=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CPU_PER_SESSION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource FAILED_LOGIN_ATTEMPTS=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource IDLE_TIME=30.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource LOGICAL_READS_PER_CALL=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource LOGICAL_READS_PER_SESSION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_GRACE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_LIFE_TIME=365.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_LOCK_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_REUSE_MAX=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_REUSE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_VERIFY_FUNCTION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PRIVATE_SGA=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource SESSIONS_PER_USER=400.', false, 1, 'P5', p_debug);
				--
			ELSIF c1_rec.profile = 'FS_USER_PROFILE' THEN
				l_sqltext := l_sqltext || 
						' LIMIT 
						SESSIONS_PER_USER		5';
				--
				activity_stream ( l_sqltext, '', 'PROFILE EXISTS', c1_rec.profile||'.', false, 1, 'P1', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource COMPOSITE_LIMIT=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CONNECT_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CPU_PER_CALL=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CPU_PER_SESSION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource FAILED_LOGIN_ATTEMPTS=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource IDLE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource LOGICAL_READS_PER_CALL=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource LOGICAL_READS_PER_SESSION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_GRACE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_LIFE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_LOCK_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_REUSE_MAX=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_REUSE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_VERIFY_FUNCTION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PRIVATE_SGA=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource SESSIONS_PER_USER=5.', false, 1, 'P5', p_debug);
				--
			ELSIF c1_rec.profile = 'FS_OWNER_PROFILE' THEN
				l_sqltext := l_sqltext || 
						' LIMIT 
						SESSIONS_PER_USER		1 
						FAILED_LOGIN_ATTEMPTS		1
						PASSWORD_LIFE_TIME		0.00001
						PASSWORD_GRACE_TIME		0';
				--
				activity_stream ( l_sqltext, '', 'PROFILE EXISTS', c1_rec.profile||'.', false, 1, 'P1', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource COMPOSITE_LIMIT=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CONNECT_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CPU_PER_CALL=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CPU_PER_SESSION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource FAILED_LOGIN_ATTEMPTS=1.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource IDLE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource LOGICAL_READS_PER_CALL=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource LOGICAL_READS_PER_SESSION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_GRACE_TIME=0.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_LIFE_TIME=0.00001.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_LOCK_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_REUSE_MAX=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_REUSE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_VERIFY_FUNCTION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PRIVATE_SGA=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource SESSIONS_PER_USER=1.', false, 1, 'P5', p_debug);
				--
			ELSIF c1_rec.profile = 'FS_ADMIN_PROFILE' THEN
				l_sqltext := l_sqltext || 
						' LIMIT 
						SESSIONS_PER_USER		20 
						IDLE_TIME			20 
						PASSWORD_LIFE_TIME		365';
				--
				activity_stream ( l_sqltext, '', 'PROFILE EXISTS', c1_rec.profile||'.', false, 1, 'P1', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource COMPOSITE_LIMIT=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CONNECT_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CPU_PER_CALL=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CPU_PER_SESSION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource FAILED_LOGIN_ATTEMPTS=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource IDLE_TIME=20.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource LOGICAL_READS_PER_CALL=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource LOGICAL_READS_PER_SESSION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_GRACE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_LIFE_TIME=365.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_LOCK_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_REUSE_MAX=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_REUSE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_VERIFY_FUNCTION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PRIVATE_SGA=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource SESSIONS_PER_USER=20.', false, 1, 'P5', p_debug);
				--
			ELSIF c1_rec.profile = 'FS_TEMP_PROFILE' THEN
				l_sqltext := l_sqltext || 
						' LIMIT 
						SESSIONS_PER_USER		5';
				--
				activity_stream ( l_sqltext, '', 'PROFILE EXISTS', c1_rec.profile||'.', false, 1, 'P1', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource COMPOSITE_LIMIT=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CONNECT_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CPU_PER_CALL=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource CPU_PER_SESSION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource FAILED_LOGIN_ATTEMPTS=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource IDLE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource LOGICAL_READS_PER_CALL=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource LOGICAL_READS_PER_SESSION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_GRACE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_LIFE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_LOCK_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_REUSE_MAX=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_REUSE_TIME=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PASSWORD_VERIFY_FUNCTION=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource PRIVATE_SGA=DEFAULT.', false, 1, 'P5', p_debug);
				--
				activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c1_rec.profile||' Resource SESSIONS_PER_USER=5.', false, 1, 'P5', p_debug);
				--
			END IF;
			--
		END IF;
	END LOOP;
	--
	activity_stream ('', '', 'PROFILE EXISTS ', 'DEFAULT.', true, 0, 'P2', p_debug);
	--
	FOR c6_rec IN c6 LOOP
		--
		IF c6_rec.decision = 0 THEN
			--
			activity_stream ( '', '', 'PROFILE RESOURCE LIMIT SET', c6_rec.resource_name||'='||c6_rec.req_limit||' On '||c6_rec.profile||'.', true, 1, 'P2', p_debug);
			--
		ELSIF c6_rec.decision = 1 THEN
			--
			activity_stream ( 'ALTER PROFILE '||c6_rec.profile||' LIMIT '||c6_rec.resource_name||'  '||c6_rec.req_limit, '', 
				'PROFILE RESOURCE LIMIT SET', c6_rec.resource_name||'='||c6_rec.req_limit||' On '||c6_rec.profile||'.', false, 1, 'P1', p_debug);
			--
		ELSE
			--
			activity_stream ( '', '', 'CODE ERROR: provide_profiles c6', 'Decision Point '||c6_rec.decision||' On '||c6_rec.profile||' Bad Value.', false, 1, 'P5', p_debug);
			--
		END IF;
	END LOOP;
	--
	activity_stream ( '', '', '', '', true, 0, 'P8', p_debug);
	--
	activity_stream ( '', '', 'SUMMARY', 'PROVIDE PROFILES', true, 0, 'P7', p_debug);
	--
END provide_profiles;
--
--
--**************************************************************************************************************************
--**         Procedure:	provide_gis_roles
--**           Purpose:	This procedure createsd the GIS roles based on the setting p_providegisroles
--**				t = Build the GIS Roles
--**				f = Do not Build the GIS Roles
--**  Calling Programs:	--
--**   Programs Called:	fs_db_admin.fs_exists_functions
--**			fs_security_pkg.activity_stream
--**   Tables Accessed:	
--**			dba_role_privs
--**   Tables Modified:	--
--**  Passed Variables: 
--**			p_gisroleschoice	-- Choice Variable
--**			p_status			-- Status message to check for errors.
--**			p_error_message		-- The actual error message.
--**			p_debug				-- The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:
--**			l_localprogramname	-- This programs name. (For debugging purposes.)
--**			l_programmessage	-- The local debugging message.
--**			l_sqltext			-- The DDL text
--**			l_boolean			-- Choice Boolean
--**           Cursors:	C1			-- Privileges for FS_GIS role.
--**			C2					-- Privileges for FS_GIS_ADMIN role.
--**			C3					-- Grantee's of FS_GIS role.
--**			C4					-- Grantee's of FS_GIS_ADMIN role.
--**           pragmas: --
--**         Exception:	
--**			soau_failure
--**************************************************************************************************************************
--**        Pseudo code: 
--**			IF p_providegisroles = 't'
--**				CREATE FS_GIS role
--**				GRANT privileges to FS_GIS role
--**				CREATE FS_GIS_ADMIN role
--**				GRANT privileges to FS_GIS_ADMIN role
--**			ELSIF p_providegisroles = 'f'
--**				flip roles of users from FS_GIS to FS_RESOURCE
--**				DROP role FS_GIS
--**				flip roles of users from FS_GIS_ADMIN to FS_RESOURCE
--**				DROP role FS_GIS_ADMIN
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE provide_gis_roles
(
 p_gisroleschoice			IN		VARCHAR2,		-- Selection t, f.
 p_status				OUT		VARCHAR2,		-- Status message to check for errors.
 p_errormessage				OUT		VARCHAR2,		-- The actual error message.
 p_debug				IN		NUMBER			-- Turn on DEBUG.
)
AS
 CURSOR c1 IS
	SELECT (column_value).getstringval() syspriv
	FROM xmltable('"CREATE SEQUENCE","CREATE TRIGGER","CREATE VIEW","CREATE TABLE"');
 --
 CURSOR c2 IS
	SELECT (column_value).getstringval() syspriv
	FROM xmltable('"CREATE SEQUENCE","CREATE TRIGGER","CREATE PROCEDURE", "CREATE TABLE"');
 --
 CURSOR c3 IS
	SELECT grantee, granted_role
	FROM dba_role_privs
	WHERE granted_role = 'FS_GIS';
 --
 CURSOR c4 IS
	SELECT grantee, granted_role
	FROM dba_role_privs
	WHERE granted_role = 'FS_GIS_ADMIN';
 --
 l_localprogramname				VARCHAR2(128) := 'provide_gis_roles';
 l_programmessage				CLOB;
 l_sqltext					CLOB;
 l_boolean					BOOLEAN;
BEGIN
	--
	g_programcontext := l_localprogramname;
	g_providegisrolespasscnt := 0;
	g_providegisrolesfailcnt := 0;
	activity_stream ( '', '', 'DETAIL', 'PROVIDE GIS ROLES', true, 0, 'P6', p_debug);
	--
	IF LOWER(p_gisroleschoice) = 't' THEN
		--
		l_boolean := fs_db_admin.fs_exists_functions.role_exists('FS_GIS');
		--
		IF l_boolean = false THEN
			activity_stream ( 'CREATE ROLE FS_GIS NOT IDENTIFIED', '', 'ROLE EXISTS', 'FS_GIS.', false, 1, 'P1', p_debug);
			activity_stream ( 'REVOKE FS_GIS FROM sys', '', 'ROLE GRANTED', 'FS_GIS TO SYS.', false, 1, 'P1', p_debug);
		ELSE
			activity_stream ( '', '', 'ROLE EXISTS', 'FS_GIS.', true, 1, 'P2', p_debug);
		END IF;
		--
		FOR c1_rec IN c1 LOOP
				l_boolean := fs_db_admin.fs_exists_functions.grantee_syspriv_exists('FS_GIS', c1_rec.syspriv);
				--
				IF l_boolean = false THEN
					activity_stream ( 'GRANT '||c1_rec.syspriv||' TO FS_GIS', '', 'SYSPRIV GRANTED', c1_rec.syspriv||' TO FS_GIS.', false, 1, 'P1', p_debug);
				ELSE
					activity_stream ( '', '', 'SYSPRIV GRANTED', c1_rec.syspriv||' TO FS_GIS.', true, 1, 'P2', p_debug);
				END IF;
				--
		END LOOP;
		--
		l_boolean := fs_db_admin.fs_exists_functions.role_exists('FS_GIS_ADMIN');
		--
		IF l_boolean = false THEN
			activity_stream ( 'CREATE ROLE FS_GIS_ADMIN NOT IDENTIFIED', '', 'ROLE EXISTS', 'FS_GIS_ADMIN.', false, 1, 'P1', p_debug);
			activity_stream ( 'REVOKE FS_GIS_ADMIN FROM sys', '', 'ROLE GRANTED', 'FS_GIS_ADMIN TO SYS.', false, 1, 'P1', p_debug);
		ELSE
			activity_stream ( '', '', 'ROLE EXISTS', 'FS_GIS_ADMIN.', true, 1, 'P2', p_debug);
		END IF;
		--
		FOR c2_rec IN c2 LOOP
				l_boolean := fs_db_admin.fs_exists_functions.grantee_syspriv_exists('FS_GIS_ADMIN', c2_rec.syspriv);
				--
				IF l_boolean = false THEN
					activity_stream ( 'GRANT '||c2_rec.syspriv||' TO FS_GIS_ADMIN', '', 'SYSPRIV GRANTED', c2_rec.syspriv||' TO FS_GIS_ADMIN.', false, 1, 'P1', p_debug);
				ELSE
					activity_stream ( '', '', 'SYSPRIV GRANTED', c2_rec.syspriv||' TO FS_GIS_ADMIN.', true, 1, 'P2', p_debug);
				END IF;
				--
		END LOOP;

		--
	ELSIF LOWER(p_gisroleschoice) = 'f' THEN
		--
		l_boolean := fs_db_admin.fs_exists_functions.role_exists('FS_GIS');
		--
		IF l_boolean = true THEN
			FOR c3_rec IN c3 LOOP
				activity_stream ( 'GRANT FS_CREATE TO '||c3_rec.grantee, '', 'ROLE GRANTED', 'FS_CREATE To '||c3_rec.grantee||'.', false, 1, 'P1', p_debug);
				activity_stream ( 'REVOKE FS_GIS FROM '||c3_rec.grantee, '', 'ROLE REVOKED', 'FS_GIS From '||c3_rec.grantee||'.', false, 1, 'P1', p_debug);
				--
			END LOOP;

			activity_stream ( 'DROP ROLE FS_GIS', '', 'ROLE EXISTS', 'FS_GIS.', false, 1, 'P1', p_debug);
		ELSE
			activity_stream ( '', '', 'ROLE DOES NOT EXIST', 'FS_GIS.', true, 1, 'P2', p_debug);
		END IF;
		--
		l_boolean := fs_db_admin.fs_exists_functions.role_exists('FS_GIS_ADMIN');
		--
		IF l_boolean = true THEN
			FOR c4_rec IN c4 LOOP
				activity_stream ( 'GRANT FS_CREATE TO '||c4_rec.grantee, '', 'ROLE GRANTED', 'FS_CREATE To '||c4_rec.grantee||'.', false, 1, 'P1', p_debug);
				activity_stream ( 'REVOKE FS_GIS_ADMIN FROM '||c4_rec.grantee, '', 'ROLE REVOKED', 'FS_GIS_ADMIN From '||c4_rec.grantee||'.', false, 1, 'P1', p_debug);
				--
			END LOOP;
			--
			activity_stream ( 'DROP ROLE FS_GIS_ADMIN', '', 'ROLE EXISTS', 'FS_GIS_ADMIN.', false, 1, 'P1', p_debug);
		ELSE
			activity_stream ( '', '', 'ROLE DOES NOT EXIST', 'FS_GIS_ADMIN.', true, 1, 'P2', p_debug);
		END IF;
		--
	ELSE
		--
		activity_stream ( '', '', 'CODE ERROR: provide_gis_roles Improper Input Value', LOWER(p_gisroleschoice)||'.', false, 1, 'P5', p_debug);
		--
	END IF;
	--
	activity_stream ( '', '', '', '', true, 0, 'P8', p_debug);
	--
	activity_stream ( '', '', 'SUMMARY', 'PROVIDE GIS ROLES', true, 0, 'P7', p_debug);
	--
END provide_gis_roles;
--
--
--**************************************************************************************************************************
--**         Procedure:	secure_database
--**           Purpose:	This procedure creates or destroys the FSDBA legacy objects based on the value of the 
--**			p_legacydbinstanceschoice 
--**				c = Build Original DBInstances Objects
--**				s = Do not build Original Legacy Objects and remove them if they exist.
--**  Calling Programs:	--
--**   Programs Called:
--**			provide_dbinstances_objects
--**			provide_gis_roles
--**   Tables Accessed:	--
--**   Tables Modified:	--
--**  Passed Variables: 
--**			p_providedbinstancesobjects	--
--**			p_providegisroles		--
--**			p_status			-- Status message to check for errors.
--**			p_errormessage			-- The actual error message.
--**			p_debug				-- The debug level set by the original calling program.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:
--**			l_localprogramname		-- This programs name. (For debugging purposes.)
--**			l_programmessage		-- The local debugging message.
--**			l_sqltext			-- The DDL text
--**			l_count				-- Count Variable
--**			l_boolean			-- Choice Boolean
--**           Cursors:					--
--**           pragmas: 				--
--**         Exception:	
--**			soau_failure
--**************************************************************************************************************************
--**        Pseudo code: 
--**			Check Input Variables Have Correct Possible Inputs and set local variable
--**			IF no errors found on Input variables
--**				Modify local variables based on setting of p_provideusers to enure all variables have 
--**				appropriate corresponding values.
--**				==
--**				IF p_debug <> -2 
--**					Execute Internal Enforcement
--**					provide_dbinstances_objects
--**					provide_gis_roles
--**				ELSE
--**					NULL;
--**			EXCEPTION
--**************************************************************************************************************************
--
--
PROCEDURE secure_database
(
 p_providedbinstancesobjects		IN		VARCHAR2,		-- t, f
 p_providegisroles			IN		VARCHAR2,		-- t, f
 p_passcnt				OUT		NUMBER,			-- Pass Count Variable for Summary
 p_failcnt				OUT		NUMBER,			-- Fail Count Variable for Summary
 p_status				OUT		VARCHAR2,		-- Status message to check for errors.
 p_errormessage				OUT		VARCHAR2,		-- The actual error message.
 p_debug				IN		NUMBER			-- Turn on DEBUG.
)
AS
 l_localprogramname			VARCHAR2(128)		:= 'secure_database';
 l_programmessage			CLOB;
 l_errormessage				VARCHAR2(1000);
 l_status				VARCHAR2(15);
 l_badtrackingcnt			NUMBER			:=0;
 l_providedbinstancesobjects		VARCHAR2(1);
 l_providegisroles			VARCHAR2(1);
 l_temp1				XMLTYPE;
BEGIN
	g_programmessage := '';
	g_programcontext := '';
	g_droplegobj := false;
	g_droplegobj := false;
	g_debug := p_debug;
	--
	IF g_iamautomation = false OR p_debug > 0 THEN
		dbms_output.enable (buffer_size => 100000000);
	END IF;
	--
	IF SYS_CONTEXT( 'USERENV', 'CURRENT_SCHEMA' ) <> 'SYS' THEN
			--
			RAISE_APPLICATION_ERROR (-20000, 'PACKAGE EXECUTION: Can only run by Logging In As "/ as sysdba" or "username/password as sysdba".');
	END IF;
	--
	SELECT instance_name INTO g_dbinstance FROM v$instance;
	SELECT sys.DBMS_QOPATCH.GET_OPATCH_INSTALL_INFO INTO l_temp1 FROM dual;
	SELECT SUBSTR(l_temp1.getStringVal(),INSTR(l_temp1.getStringVal(),'<path>')+6,INSTR(l_temp1.getStringVal(),'</path>')-(INSTR(l_temp1.getStringVal(),'<path>')+6)) INTO g_orahome FROM dual;
	--
	--*******************************************
	--** Check Basic Variable Input
	--*******************************************
	--
	IF LOWER(p_providedbinstancesobjects) IN ('t', 'f') THEN
		l_providedbinstancesobjects := LOWER(p_providedbinstancesobjects);
	ELSE
		l_badtrackingcnt := l_badtrackingcnt+1;
		activity_stream ( '', '', 'CODE ERROR: Improper Input Value', 'Provide Legacy Objects: '||LOWER(p_providedbinstancesobjects)||'.', false, 1, 'P5', p_debug);
	END IF;
	--
	IF LOWER(p_providegisroles) IN ('t', 'f') THEN
		l_providegisroles := LOWER(p_providegisroles);
	ELSE
		l_badtrackingcnt := l_badtrackingcnt+1;
		activity_stream ( '', '', 'CODE ERROR: Improper Input Value', 'Provide GIS ROLES: '||LOWER(p_providegisroles)||'.', false, 1, 'P5', p_debug);
	END IF;
	--
	IF l_badtrackingcnt = 0 THEN
		--
		--*******************************************
		--** Execute Security Enforcement..
		--*******************************************
		--
		IF p_debug <> -2 THEN
			provide_roles (l_status, l_errormessage, p_debug);
			IF l_status = 'ERROR' THEN
				p_status := 'ERROR';
				p_errormessage := p_errormessage||l_errormessage;
			END IF;
			--
			provide_profiles (l_status, l_errormessage, p_debug);
			IF l_status = 'ERROR' THEN
				p_status := 'ERROR';
				p_errormessage := p_errormessage||l_errormessage;
			END IF;
			--
			provide_users (l_providedbinstancesobjects, l_status, l_errormessage, p_debug);
			IF l_status = 'ERROR' THEN
				p_status := 'ERROR';
				p_errormessage := p_errormessage||l_errormessage;
			END IF;
			--
			provide_dbinstances_objects (l_providedbinstancesobjects, l_status, l_errormessage, p_debug);
			IF l_status = 'ERROR' THEN
				p_status := 'ERROR';
				p_errormessage := p_errormessage||l_errormessage;
			END IF;
			--
			provide_gis_roles (l_providegisroles, l_status, l_errormessage, p_debug);
			IF l_status = 'ERROR' THEN
				p_status := 'ERROR';
				p_errormessage := p_errormessage||l_errormessage;
			END IF;
			--
		END IF;
	END IF;
	--
	g_fssecuritypasscnt := g_providerolespasscnt + g_provideprofilespasscnt  + g_provideuserspasscnt  + g_providedbinstancesobjectspasscnt + g_providegisrolespasscnt;
	g_fssecurityfailcnt := g_providerolesfailcnt + g_provideprofilesfailcnt  + g_provideusersfailcnt  + g_providedbinstancesobjectsfailcnt + g_providegisrolesfailcnt;
	--
	p_passcnt := g_fssecuritypasscnt;
	p_failcnt := g_fssecurityfailcnt;
	g_programcontext := '';
	--
END secure_database;
--
--
END fs_security_pkg;
--
--
--**************************************************************************************************************************
--End Package Body.
--**************************************************************************************************************************
--
--
/

exit;



