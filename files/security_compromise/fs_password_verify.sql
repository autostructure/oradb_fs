connect / as sysdba

CREATE OR REPLACE FUNCTION sys.fs_password_verify
(
 p_username			IN		VARCHAR2,
 p_password			IN		VARCHAR2,
 p_oldpassword			IN		VARCHAR2
)
RETURN boolean
--
--
--**************************************************************************************************************************
--**   Procedure Name:	fs_password_verify
--**      Application:	Puppet STIG Implementation
--**           Schema:	sys
--**          Authors:	Ed Taylor, eDBA
--**			Matthew Parker, Oracle Puppet SME 
--**          Comment:	This function is the sys owned funtion to perform profile based password_verification.
--**************************************************************************************************************************
--**************************************************************************************************************************
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
--**            NOTICE:	This code copied from Oracle provided scripts 
--**			rdbms/admin/catpvf.sql - Create Password Verify Function, STIG profile
--**			Copyright (c) 2013, 2016, Oracle and/or its affiliates. All rights reserved.
--**      Special Note: The password verify function must be owned by sys and cannot be encapsulated in a package.
--**			ORA-02376 When ALTER PROFILE to Set the PASSWORD_VERIFY_FUNCTION (Doc ID 241621.1)
--**************************************************************************************************************************
--**        Psudo code: 
--**			PW Length check 15 to 30
--**			Construct PW Meeting Compliance Rules
--**			Check for 3x repeating characters
--**			EXCEPTION
--**************************************************************************************************************************
--
--
IS
 l_localprogramname				VARCHAR2(128)		:= 'fs_password_verify';
 l_programmessage				CLOB;
 l_pwverifycnt					INTEGER			:= 0;
 l_m						INTEGER;
 l_differ					INTEGER;
 l_repeat					BOOLEAN;
 l_threechar					VARCHAR2(3);
 --
FUNCTION count_special
(
 p_password			IN		VARCHAR2
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
			fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', 'PASSWORD SPECIAL CHARACTER', 'Avoid The Following Special Characters In Password: " '' ¿ ` @ & \ / (space) (return).', '', 'FAIL','','','','');
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
FUNCTION string_distance
(
 p_s			IN		VARCHAR2,
 p_t			IN		VARCHAR2
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
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', 'PASSWORD LENGTH', l_tlen||': '||l_tlen||' And l_slen: '||l_slen||', More Than 128 Bytes.', '', 'FAIL','','','','');
		--
		return(-1);
   	ELSIF l_tlen > 128 then
		--
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', 'PASSWORD LENGTH', l_tlen||': '||l_tlen||', More Than 128 Bytes.', '', 'FAIL','','','','');
		--
		return(-1);
	ELSIF l_slen > 128 THEN
		--
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', 'PASSWORD LENGTH', l_slen||': '||l_slen||', More Than 128 Bytes.', '', 'FAIL','','','','');
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
BEGIN
	--
	dbms_output.enable(10000);
	--
	--**********************************************************
	--** STIG ID: O121-C2-014500 - Check if the password differs
	--** from the previous password by at least 8 characters 
	--**********************************************************
	--
	IF p_oldpassword IS NOT NULL THEN
		l_differ := string_distance(p_oldpassword, p_password);
		IF l_differ < 8 THEN
			--
			fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', 'USER', p_username||': New Password Should Differ From Previous Password By At Least 8 Characters.', '', 'FAIL','','','','');
			--
			l_pwverifycnt := l_pwverifycnt+1;
		END IF;
	END IF;
	--
	--*************************************************************
	--** STIG ID: O121-C2-013900 - must be at least 15 bytes
	--** in length.
	--*************************************************************
	--
	IF LENGTH(p_password) < 15 THEN
		--
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', 'USER', p_username||': Password Length Less Than 15 Bytes In Length.', '', 'FAIL','','','','');
		--
		l_pwverifycnt := l_pwverifycnt+1;
	END IF;
	--
	--*************************************************************
	--** STIG ID: O121-C2-014100 - require 2 upper case characters
	--** STIG ID: O121-C2-014200 - require 2 lower case characters
	--** STIG ID: O121-C2-014300 - require 2 numeric characters
	--** STIG ID: O121-C2-014400 - require 2 special characters
	--*************************************************************
	--
	IF REGEXP_COUNT(p_password, '([1234567890])', 1) < 2 OR REGEXP_COUNT(p_password, '([abcdefghijklmnopqrstuvwxyz])', 1, 'c') < 2 
		OR REGEXP_COUNT(p_password, '([ABCDEFGHIJKLMNOPQRSTUVWXYZ])', 1, 'c') < 2 OR count_special(p_password)  < 2 THEN
		--
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', 'USER', p_username||': Password must contain at least two upper, two lower, two numbers and two special characters.', '', 'FAIL','','','','');
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
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', 'USER', p_username||': Password too simple.', '', 'FAIL','','','','');
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
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', 'USER', p_username||': Password contains a character repeated 3 or more times: '||l_threechar||'.', '', 'FAIL','','','','');
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
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', 'USER', p_username||': Password should not contain username.', '', 'FAIL','','','','');
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
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', 'USER', p_username||': Password should not contain the database name.', '', 'FAIL','','','','');
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
		fs_db_admin.fs_puppet_format_output.format_entries ( 'l1', '', '#', 'USER', p_username||': Password should not contain the server name.', '', 'FAIL','','','','');
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
/

exit


