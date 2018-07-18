connect / as sysdba

--**************************************************************************************************************************
--**************************************************************************************************************************
--** Begin Package Specification 
--**************************************************************************************************************************
--**************************************************************************************************************************
--
--
CREATE OR REPLACE PACKAGE fs_db_admin.fs_exists_functions
AUTHID CURRENT_USER
AS
--
--
--**************************************************************************************************************************
--**     Package Name:	fs_exists_functions
--**      Application:	Puppet Verification
--**           Schema:	fs_dba_admin
--**          Authors:	Matthew Parker, Oracle Puppet SME 
--**          Comment:	This package contains functions used to verify Internal Database component existence.
--**************************************************************************************************************************
--**   Change Control:
--**	$Log: fs_security_pkg.sql,v $
--**	Revision 1.0  2018/05/12 00:19:01  matthewparker
--**	Pulled code components from fs_security_pkg.
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
FUNCTION constraint_exists
(
 p_consowner			IN		VARCHAR2, 
 p_consname			IN		VARCHAR2,
 p_tabname			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION directory_exists
(
 p_dirowner			IN		VARCHAR2, 
 p_dirname			IN		VARCHAR2, 
 p_dirpath			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION grantee_rolepriv_exists
(
 p_grantee			IN		VARCHAR2,
 p_rolepriv			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION grantee_syspriv_exists
(
 p_grantee			IN		VARCHAR2,
 p_syspriv			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION init_param_value_mem_exists
(
 p_initparam			IN		VARCHAR2,
 p_initvalue			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION init_param_value_spfile_exists
(
 p_initparam			IN		VARCHAR2,
 p_initvalue			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION object_exists
(
 p_objowner			IN		VARCHAR2, 
 p_objname			IN		VARCHAR2, 
 p_objtype			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION profile_exists
(
 p_profilename			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION profile_limit_exists
(
 p_profile			IN		VARCHAR2,
 p_resourcename			IN		VARCHAR2,
 p_limit			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION pwfile_user_exists
(
 p_username			IN		VARCHAR2,
 p_privlege			IN		VARCHAR2,
 p_booleanchar			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION role_exists
(
 p_rolename			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION role_rolepriv_exists
(
 p_role				IN		VARCHAR2,
 p_rolepriv			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION role_syspriv_exists
(
 p_role				IN		VARCHAR2,
 p_syspriv			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION synonym_exists
(
 p_synowner			IN		VARCHAR2, 
 p_synname			IN		VARCHAR2,
 p_tabowner			IN		VARCHAR2,
 p_tabname			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION tabcom_exists
(
 p_tabcom			IN		VARCHAR2,
 p_tabowner			IN		VARCHAR2,
 p_tabname			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION tablespace_exists
(
 p_tablespace			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION tabprivs_exists
(
 p_tabowner			IN		VARCHAR2, 
 p_tabname			IN		VARCHAR2,
 p_grantee			IN		VARCHAR2,
 p_privilege			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION trigger_exists
(
 p_trigowner			IN		VARCHAR2,
 p_trigname			IN		VARCHAR2,
 p_tabowner			IN		VARCHAR2,
 p_tabname			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION tsquota_exists
(
 p_username			IN		VARCHAR2,
 p_tablespace			IN		VARCHAR2,
 p_tsquota			IN		NUMBER,
 p_uom				IN		VARCHAR2,
 p_unlimited			IN		BOOLEAN
)
RETURN BOOLEAN;
--
--
FUNCTION user_exists
(
 p_username			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION user_assigned_profile_exists
(
 p_username			IN		VARCHAR2,
 p_profile			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
FUNCTION user_objects_exists
(
 p_username			IN		VARCHAR2
)
RETURN BOOLEAN;
--
--
END fs_exists_functions;
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
--**************************************************************************************************************************
--**************************************************************************************************************************
--** Begin Package Body.
--**************************************************************************************************************************
--**************************************************************************************************************************
--
--
CREATE OR REPLACE PACKAGE BODY fs_db_admin.fs_exists_functions IS
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
--**         Procedure:	constraint_exists
--**           Purpose:	This function returns true or false based on existence of a passed constraint name.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_constraints
--**   Tables Modified:	--
--**  Passed Variables:  p_consowner	Passed Constraint Owner 
--**			 p_consname	Passed Constraint Name
--**			 p_tabname	Passed Table Name Constraint Is On.
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_conscnt 	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION constraint_exists
(
 p_consowner			IN		VARCHAR2, 
 p_consname			IN		VARCHAR2,
 p_tabname			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_conscnt 			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_conscnt 
	FROM sys.dba_constraints
	WHERE owner = upper(p_consowner)
	AND table_name = upper(p_tabname)
	AND constraint_name = upper(p_consname);
	--
	IF l_conscnt   > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END constraint_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	directory_exists
--**           Purpose:	This function returns true or false based on existence of a passed Directory information.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_directories
--**   Tables Modified:	--
--**  Passed Variables:  p_dirowner	Directory Owner
--**			 p_dirname	Directory Name
--**			 p_dirpath	Directory Path
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_dircnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION directory_exists
(
 p_dirowner			IN		VARCHAR2, 
 p_dirname			IN		VARCHAR2, 
 p_dirpath			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_dircnt 			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_dircnt 
	FROM sys.dba_directories
	WHERE owner = UPPER(p_dirowner)
	AND directory_name = UPPER(p_dirname)
	AND directory_path = p_dirpath;
	--
	IF l_dircnt  > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END directory_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	grantee_rolepriv_exists
--**           Purpose:	This function returns true or false based on existence of a grantee role privilege combination.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_role_privs
--**   Tables Modified:	--
--**  Passed Variables: p_grantee	Passed Grantee of Privielge
--**			p_rolepriv	Passed Role Privielge
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_roleprivcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION grantee_rolepriv_exists
(
 p_grantee			IN		VARCHAR2,
 p_rolepriv			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_roleprivcnt			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_roleprivcnt
	FROM sys.dba_role_privs
	WHERE grantee = UPPER(p_grantee)
	AND granted_role = UPPER(p_rolepriv);
	--
	IF l_roleprivcnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END grantee_rolepriv_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	grantee_syspriv_exists
--**           Purpose:	This function returns true or false based on existence of a grantee system privilege combination.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_sys_privs
--**   Tables Modified:	--
--**  Passed Variables:  p_grantee	Passed Grantee of Privielge
--**			 p_syspriv	Passed System Privilege
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_sysprivcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION grantee_syspriv_exists
(
 p_grantee			IN		VARCHAR2,
 p_syspriv			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_sysprivcnt			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_sysprivcnt
	FROM sys.dba_sys_privs
	WHERE privilege = UPPER(p_syspriv)
	AND grantee = UPPER(p_grantee);
	--
	IF l_sysprivcnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END grantee_syspriv_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	init_param_value_mem_exists
--**           Purpose:	This function returns true or false based on existence of a passed initparam and initvalue.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: v$parameter
--**   Tables Modified:	--
--**  Passed Variables:  p_objowner	Object Owner
--**			 p_objname	Object Name
--**			 p_objtype	Object Type
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_objcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION init_param_value_mem_exists
(
 p_initparam			IN		VARCHAR2,
 p_initvalue			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_initparamcnt			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_initparamcnt
	FROM v$parameter
	WHERE name = LOWER(p_initparam)
	AND value = p_initvalue;
	--
	IF l_initparamcnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END init_param_value_mem_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	init_param_value_spfile_exists
--**           Purpose:	This function returns true or false based on existence of a passed initparam and initvalue.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: v$spparameter
--**   Tables Modified:	--
--**  Passed Variables:  p_objowner	Object Owner
--**			 p_objname	Object Name
--**			 p_objtype	Object Type
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_objcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION init_param_value_spfile_exists
(
 p_initparam			IN		VARCHAR2,
 p_initvalue			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_initparamcnt			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_initparamcnt
	FROM v$spparameter
	WHERE name = LOWER(p_initparam)
	AND value = p_initvalue;
	--
	IF l_initparamcnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END init_param_value_spfile_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	object_exists
--**           Purpose:	This function returns true or false based on existence of a passed object name.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_objects
--**   Tables Modified:	--
--**  Passed Variables:  p_objowner	Object Owner
--**			 p_objname	Object Name
--**			 p_objtype	Object Type
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_objcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION object_exists
(
 p_objowner			IN		VARCHAR2, 
 p_objname			IN		VARCHAR2, 
 p_objtype			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_objcnt 			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_objcnt 
	FROM sys.dba_objects
	WHERE owner = UPPER(p_objowner)
	AND object_name = UPPER(p_objname)
	AND object_type = UPPER(p_objtype);
	--
	IF l_objcnt  > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END object_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	profile_exists
--**           Purpose:	This function returns true or false based on existence of a passed profile.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_profiles
--**   Tables Modified:	--
--**  Passed Variables: p_profilename	Profile Name
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_profilecnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION profile_exists
(
 p_profilename			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_profilecnt			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_profilecnt
	FROM sys.dba_profiles
	WHERE profile = UPPER(p_profilename);
	--
	IF l_profilecnt > 0 THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
	--
END profile_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	profile_limit_exists
--**           Purpose:	This function returns true or false based on existence of a role system privilege combination.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: role_sys_privs
--**   Tables Modified:	--
--**  Passed Variables: p_role		Passed Role
--**			p_syspriv	Passed System Privielge
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_roleprivcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION profile_limit_exists
(
 p_profile			IN		VARCHAR2,
 p_resourcename			IN		VARCHAR2,
 p_limit			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_profreslimcnt		NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_profreslimcnt
	FROM sys.dba_profiles
	WHERE profile = UPPER(p_profile)
	AND resource_name = UPPER(p_resourcename)
	AND limit = UPPER(p_limit);
	--
	IF l_profreslimcnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END profile_limit_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	pwfile_user_exists
--**           Purpose:	This function returns true or false based on existence of a user in v$pwfile.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: v$pwfile_users
--**   Tables Modified:	--
--**  Passed Variables: p_username	Passed Username With Special Privielges
--**			p_privlege	Passed Special Privielge
--**			p_booleanchar	Characters TRUE or FALSE
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_pwfilecnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION pwfile_user_exists
(
 p_username			IN		VARCHAR2,
 p_privlege			IN		VARCHAR2,
 p_booleanchar			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_pwfilecnt			NUMBER		:= 0;
BEGIN
	--
	IF p_privlege = 'SYSDBA' THEN
		SELECT COUNT(*) INTO l_pwfilecnt
		FROM v$pwfile_users
		WHERE username = UPPER(p_username)
		AND sysdba = UPPER(p_booleanchar);
	ELSIF p_privlege = 'SYSOPER' THEN
		SELECT COUNT(*) INTO l_pwfilecnt
		FROM v$pwfile_users
		WHERE username = UPPER(p_username)
		AND sysoper = UPPER(p_booleanchar);
	ELSIF p_privlege = 'SYSASM' THEN
		SELECT COUNT(*) INTO l_pwfilecnt
		FROM v$pwfile_users
		WHERE username = UPPER(p_username)
		AND sysasm = UPPER(p_booleanchar);
	ELSIF p_privlege = 'SYSBACKUP' THEN
		SELECT COUNT(*) INTO l_pwfilecnt
		FROM v$pwfile_users
		WHERE username = UPPER(p_username)
		AND sysbackup = UPPER(p_booleanchar);
	ELSIF p_privlege = 'SYSDG' THEN
		SELECT COUNT(*) INTO l_pwfilecnt
		FROM v$pwfile_users
		WHERE username = UPPER(p_username)
		AND sysdg = UPPER(p_booleanchar);
	ELSIF p_privlege = 'SYSKM' THEN
		SELECT COUNT(*) INTO l_pwfilecnt
		FROM v$pwfile_users
		WHERE username = UPPER(p_username)
		AND syskm = UPPER(p_booleanchar);
	ELSE
		RETURN false;
	END IF;
	--
	IF l_pwfilecnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END pwfile_user_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	role_exists
--**           Purpose:	This function returns true or false based on existence of a passed role.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_roles
--**   Tables Modified:	--
--**  Passed Variables:  p_rolename	Passed Role Name
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_rolecnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION role_exists
(
 p_rolename			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_rolecnt			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_rolecnt
	FROM sys.dba_roles
	WHERE role = UPPER(p_rolename);
	--
	IF l_rolecnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END role_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	role_rolepriv_exists
--**           Purpose:	This function returns true or false based on existence of a role role privilege combination.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: role_role_privs
--**   Tables Modified:	--
--**  Passed Variables: p_role		Passed Role
--**			p_rolepriv	Passed Role Privielge
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables:  l_roleprivcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION role_rolepriv_exists
(
 p_role				IN		VARCHAR2,
 p_rolepriv			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_roleprivcnt			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_roleprivcnt
	FROM sys.role_role_privs
	WHERE role = UPPER(p_role)
	AND granted_role = UPPER(p_rolepriv);
	--
	IF l_roleprivcnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END role_rolepriv_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	role_syspriv_exists
--**           Purpose:	This function returns true or false based on existence of a role system privilege combination.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: role_sys_privs
--**   Tables Modified:	--
--**  Passed Variables: p_role		Passed Role
--**			p_syspriv	Passed System Privielge
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_roleprivcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION role_syspriv_exists
(
 p_role				IN		VARCHAR2,
 p_syspriv			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_roleprivcnt			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_roleprivcnt
	FROM sys.role_sys_privs
	WHERE role = UPPER(p_role)
	AND privilege = UPPER(p_syspriv);
	--
	IF l_roleprivcnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END role_syspriv_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	synonym_exists
--**           Purpose:	This function returns true or false based on existence of a passed synonym name.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_synonyms
--**   Tables Modified:	--
--**  Passed Variables:  p_synowner	Passed Synonym Owner
--**			 p_synname	Passed Synonym Name
--**			 p_tabowner	Passed Table Owner
--**			 p_tabname	Passed Table Name
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_syncnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION synonym_exists
(
 p_synowner			IN		VARCHAR2, 
 p_synname			IN		VARCHAR2,
 p_tabowner			IN		VARCHAR2,
 p_tabname			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_syncnt 			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_syncnt 
	FROM sys.dba_synonyms
	WHERE owner = upper(p_synowner)
	AND synonym_name = upper(p_synname)
	AND table_owner = upper(p_tabowner)
	AND table_name = upper(p_tabname);
	--
	IF l_syncnt  > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END synonym_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	tabcom_exists
--**           Purpose:	This function returns true or false based on existence of a passed Table Comment.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_tab_comments
--**   Tables Modified:	--
--**  Passed Variables:  p_tabcom	Passed Table Comment
--**			 p_tabowner	Passed Table Owner
--**			 p_tabname	Passed Table Name
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_tabcomcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION tabcom_exists
(
 p_tabcom			IN		VARCHAR2,
 p_tabowner			IN		VARCHAR2,
 p_tabname			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_tabcomcnt 			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_tabcomcnt 
	FROM sys.dba_tab_comments
	WHERE owner = upper(p_tabowner)
	AND table_name = upper(p_tabname)
	AND comments = p_tabcom;
	--
	IF l_tabcomcnt  > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END tabcom_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	tablespace_exists
--**           Purpose:	This function returns true or false based on existence of a tablespace.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_tablespaces
--**   Tables Modified:	--
--**  Passed Variables: p_tablespace	Passed Tablespace Name
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_tablespacecnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION tablespace_exists
(
 p_tablespace			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_tablespacecnt		NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_tablespacecnt
	FROM sys.dba_tablespaces
	WHERE tablespace_name = UPPER(p_tablespace);
	--
	IF l_tablespacecnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END tablespace_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	tabprivs_exists
--**           Purpose:	This function returns true or false based on existence of a passed Table Privelege Combination.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_tab_privs
--**   Tables Modified:	--
--**  Passed Variables: --
--** Passed Global Var:	 p_tabowner	Passed Table Owner
--**			 p_tabname	Passed Table Name
--**			 p_grantee	Passed Grantee
--**			 p_privilege	Passed Privlege
--**   Global Var Mods:	--
--**   Local Variables: l_tabprivcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION tabprivs_exists
(
 p_tabowner			IN		VARCHAR2, 
 p_tabname			IN		VARCHAR2,
 p_grantee			IN		VARCHAR2,
 p_privilege			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_tabprivcnt 			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_tabprivcnt 
	FROM sys.dba_tab_privs
	WHERE owner = upper(p_tabowner)
	AND table_name = upper(p_tabname)
	AND grantee = upper(p_grantee)
	AND privilege = upper(p_privilege);
	--
	IF l_tabprivcnt  > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END tabprivs_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	trigger_exists
--**           Purpose:	This function returns true or false based on existence of a passed trigger.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_triggers
--**   Tables Modified:	--
--**  Passed Variables: p_trigowner	Trigger Owner
--**			p_trigname	Trigger Name
--**			p_tabowner	Table Owner That Trigger Is On
--**			p_tabname	Table Name That Trigger Is On
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_trigcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION trigger_exists
(
 p_trigowner			IN		VARCHAR2,
 p_trigname			IN		VARCHAR2,
 p_tabowner			IN		VARCHAR2,
 p_tabname			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_trigcnt 			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_trigcnt
	FROM sys.dba_triggers
	WHERE owner = upper(p_trigowner)
	AND trigger_name = upper(p_trigname)
	AND table_owner = upper(p_tabowner)
	AND table_name = upper(p_tabname);
	--
	IF l_trigcnt  > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END trigger_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	tsquota_exists
--**           Purpose:	This function returns true or false based on existence of a tablespace.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_tablespaces
--**   Tables Modified:	--
--**  Passed Variables: p_tablespace	Passed Tablespace Name
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_tablespacecnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION tsquota_exists
(
 p_username			IN		VARCHAR2,
 p_tablespace			IN		VARCHAR2,
 p_tsquota			IN		NUMBER,
 p_uom				IN		VARCHAR2,
 p_unlimited			IN		BOOLEAN
)
RETURN BOOLEAN
IS
 l_tsquotacnt			NUMBER		:= 0;
 l_tsquota			NUMBER;
BEGIN
	IF p_unlimited = true THEN
		l_tsquota := -1;
	ELSE
		IF UPPER(p_uom) IN ('K', 'KB') THEN
			l_tsquota := 1024 * p_tsquota;
		ELSIF UPPER(p_uom) IN ('M', 'MB') THEN
			l_tsquota := 1024 * 1024 * p_tsquota;
		ELSIF UPPER(p_uom) IN ('G', 'GB') THEN
			l_tsquota := 1024 * 1024 * 1024 * p_tsquota;
		ELSE
			l_tsquota := 1024 * 1024 * p_tsquota;
		END IF;
	END IF;
	--
	SELECT COUNT(*) INTO l_tsquotacnt
	FROM sys.dba_ts_quotas
	WHERE tablespace_name = UPPER(p_tablespace)
	AND max_bytes = l_tsquota;
	--
	IF l_tsquotacnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END tsquota_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	user_exists
--**           Purpose:	This function returns true or false based on existence of a user.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_role_privs
--**   Tables Modified:	--
--**  Passed Variables: p_grantee	Passed Grantee of Privielge
--**			p_rolepriv	Passed Role Privielge
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_roleprivcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION user_exists
(
 p_username			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_usercnt			NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_usercnt
	FROM sys.dba_users
	WHERE username = UPPER(p_username);
	--
	IF l_usercnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END user_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	user_assigned_profile_exists
--**           Purpose:	This function returns true or false based on existence of a profile assigned to a user.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_users
--**   Tables Modified:	--
--**  Passed Variables: p_username	Passed Username
--**			p_profile	Passed Profile Name
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_roleprivcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION user_assigned_profile_exists
(
 p_username			IN		VARCHAR2,
 p_profile			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_userassignprofilecnt		NUMBER		:= 0;
BEGIN
	--
	SELECT COUNT(*) INTO l_userassignprofilecnt
	FROM sys.dba_users
	WHERE username = UPPER(p_username)
	AND profile = UPPER(p_profile);
	--
	IF l_userassignprofilecnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END user_assigned_profile_exists;
--
--
--**************************************************************************************************************************
--**         Procedure:	user_objects_exists
--**           Purpose:	This function returns true or false based on existence of objects owned by a user.
--**  Calling Programs:	--
--**   Programs Called: --
--**   Tables Accessed: dba_objects
--**   Tables Modified:	--
--**  Passed Variables: p_username	Passed Username
--** Passed Global Var:	--
--**   Global Var Mods:	--
--**   Local Variables: l_userobjcnt	Count Variable
--**           Cursors:	--
--**           pragmas: --
--**         Exception: --
--**************************************************************************************************************************
--**        Psudo code: 
--**			Function specific Query
--**			IF count > 0 THEN Return true
--**			ELSE Return False
--**************************************************************************************************************************
--
--
FUNCTION user_objects_exists
(
 p_username			IN		VARCHAR2
)
RETURN BOOLEAN
IS
 l_userobjcnt			NUMBER		:= 0;
BEGIN
	--
	SELECT count(*) INTO l_userobjcnt
	FROM sys.dba_objects
	WHERE owner = UPPER(p_username);
	--
	IF l_userobjcnt > 0 THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
	--
END user_objects_exists;
--
--
END fs_exists_functions;
--
--
--**************************************************************************************************************************
--End Package Body.
--**************************************************************************************************************************
--
--
/


exit;

