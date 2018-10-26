#!/usr/bin/env ksh
#
#  %Z%%W%,%I%:%G%:%U%
#  VERSION:  %I%   #03/30/2018   v2.0
#  DATE:  %G%:%U%
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract 
#
#  Purpose:
#    Configure private RMAN repositories
#
#
[[ $(id) == "uid=1001(oracle)"* ]] || { echo "Run as oracle"; exit 1; }
export NOW=$(date +"%Y-%m-%d:%H:%M:%S")
export LOG=/var/tmp/rman/private_rcat.log
mkdir /var/tmp/rman 2> /dev/null
chmod 777 /var/tmp/rman 
if ! touch $LOG; then echo "ERROR: couldn't touch $LOG"; exit 1; fi
while getopts bf option; do
   case "$option" in
      b) export BACK_OUT="YES";;
      f) export AUTO_SHUTDOWN="-f";;
     \?) eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         echo "Usage: $0 [-b]";;
   esac
done

{
   #================================================================
   # Set envars
   #================================================================
   function set_envars
   {
      if [[ -f /home/oracle/system/rman/rman_parameters.sh ]]; then
         . /home/oracle/system/rman/rman_parameters.sh  # $SYSINFRA
      else
         . /tmp/rcat_12.2.0/rman_parameters.sh  # $SYSINFRA
      fi
      # Pick an 12.2 ORACLE_HOME
      mkdir /home/oracle/system/ 2> /dev/null
      chown oracle:dba /home/oracle/system/
      mkdir /home/oracle/system/rman/ 2> /dev/null
      chown oracle:dba /home/oracle/system/rman/
   
   }
   #================================================================
   # Issue an error message and exit with the specified return code
   #================================================================
   function error_exit
   {
     echo "  ERROR $2"
     exit $1
   }
   #================================================================
   # Explain how to use script
   #================================================================
   function script_usage
   {
     echo "rcat_12.2.0.sh [-b]"
     echo "   -b  backout the changes made during install"
   }
   #================================================================
   # Check required free space in K bytes
   #================================================================
   function check_freespace
   {
     REQSP=$1
     FS=$2
     FREE=$(df -Pk $FS | tail -1 | awk '{print $4}')
     (( $FREE < $REQSP )) && error_exit 1 "Insufficient free space in $FS"
   }
   #================================================================
   # Check if any backup process are currently running
   # For Oracle servers, the database must be up
   #================================================================
   function check_running_processes
   {
      echo "== Precheck for running processes "
      XX=$(ps -ef | grep "[r]man_backup" | wc -l)
      (( $XX > 0 )) && error_exit 2 "RMAN backups are currently active"
   
      XX=$(ps -ef | grep "[o]ra_pmon" | wc -l)
      (( $XX < 1 )) && error_exit 4 "Oracle must be running for this update"
      echo ".. no running processes precheck passed"
   }
   #================================================================
   # Check that all of the files for this package are present
   #================================================================
   function check_required_files
   {
      REQUIRED="/home/oracle/system/rman/oraenv.usfs"
      REQUIRED="/tmp/rcat_12.2.0/oraenv.usfs"
   
      echo "== Checking for required installation files"
      for FILE in $REQUIRED
      do
         [[ ! -f $FILE ]] && error_exit 5 "Required file $FILE not found. Verify untar."
      done
      [[ -d /tmp/rcat_12.2.0 ]] || error_exit 5 "Expected /tmp/rcat_12.2.0 to exist"
      echo ".. All required files found"
   }
   #================================================================
   # Check the Oracle configuration
   #================================================================
   function check_oracle_software
   {
      echo "== Checking Oracle software"
      [[ -f $FS615_ORATAB ]] || error_exit 32 "expected \$FS615_ORATAB ($FS615_ORATAB) to exist"
      echo "..  \$FS615_ORATAB ($FS615_ORATAB) file found"
   }
   #================================================================
   # Check the Oracle configuration
   #================================================================
   function check_sysinfra_symlink
   {
      echo "== Check for symlink $SYSINFRA"
      if [[ -z "$IGNORE_NFS_CLIENT_TEST" ]]; then
         [[ -L $SYSINFRA ]] || error_exit 37 "missing symbolic link for $SYSINFRA"
         ls $SYSINFRA/oracle/* > /dev/null || error_exit 38 "ls $SYSINFRA/oracle/* failed"
         echo ".. NFS mount found"
      else
         echo "IGNORE_GPFS_CLIENT_TEST is set, ignoring thist test."
      fi
   }
   function chmod_775_opt_oracle_diag {
      echo "== Set permissions on /opt/oracle/diag/"
      owner=$(ls -ld /opt/oracle/diag/ | awk '{print $3}')
      [[ $owner != oracle && $owner != grid ]] && error_exit 1 "neither oracle nor grid own /opt/oracle/diag/"
      if [[ $owner == grid ]]; then
         results=$(echo "chmod 775 /opt/oracle/diag/; ls -ld /opt/oracle/diag/ | awk '{print \$1}'" | sudo -iu grid)
         [[ $results == *drwxrwxr-x* ]] || error_exit 1 "couldn't set permissions on /opt/oracle/diag/ to 775"
      fi
   }
   #================================================================
   # Find all the ORACLE_HOME valuse
   #================================================================
   function find_all_OH {
      # INPUT:  /tmp/rcat_12.2.0/usfs_local_sids
      #         /tmp/rcat_12.2.0/oraenv.usfs
      # OUTPUT: $ALL_OH
      echo "== Find all values for ORACLE_HOME"
      SIDS=$(/tmp/rcat_12.2.0/usfs_local_sids)
      echo SIDS=$SIDS >> $LOG
      export ALL_OH=$(for ORACLE_SID in $SIDS; do
         # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH, etc
         . /tmp/rcat_12.2.0/oraenv.usfs > /dev/null
         echo $ORACLE_HOME
      done | sort -u)
      echo ALL_OH=$ALL_OH
      if [[ ${#ALL_OH} == 0 ]]; then
         error_exit 39 "could not determine all of the ORACLE_HOME values"
      fi
   }
   #================================================================
   # Find the maximum version from an Oracle Home
   #================================================================
   function find_max_oracle_SW_version {
      # INPUT:  $ALL_OH
      # OUTPUT:  Envars of   MAX_OH and MAX_VER
      echo "== Find Maximum Oracle Software version"
      MAX_COMPVER=0.0
      for ORACLE_HOME in $ALL_OH; do
         VER=$( 
            export ORACLE_HOME=$ORACLE_HOME
            export PATH=$ORACLE_HOME/bin:$PATH
            export LD_LIBRARY_PATH=$ORACLE_HOME/lib
            echo | sqlplus /nolog 2>&1 | tee /var/tmp/rman/rcat.sqlplus.version.$$.log | sed '/ Release /!d;s|.*Release.\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*|\1|' | tail -1 )
         echo VER=$VER >> $LOG
         # Remove all but the left most decimal point, i.e. change 10.2.0.2 to 10.202
         COMPVER=$( echo $VER | sed 'h;s|^[0-9][0-9]*\.\(.*\)|\1|;s|\.||g;x;s|^\([0-9][0-9]*\.\).*|\1|;G;s|\.[^[0-9]|.|g' )
         echo COMPVER=$COMPVER >> $LOG
         if (( $(expr $MAX_COMPVER '<' $COMPVER) == 1 )); then # was bc
            MAX_OH=$ORACLE_HOME
            MAX_VER=$VER 
            MAX_COMPVER=$COMPVER
         fi
         echo MAX_VER=$MAX_VER >> $LOG
         echo MAX_OH=$MAX_OH >> $LOG
      done 
      export MAX_OH=$(sed '/MAX_OH=/!d;s|.*=||' $LOG | tail -1)
      export MAX_VER=$(sed '/MAX_VER=/!d;s|.*=||' $LOG | tail -1)
      echo MAX_OH=$MAX_OH
      echo MAX_VER=$MAX_VER
      if [[ ! -d $MAX_OH ]]; then
         error_exit 40 "ORACLE_HOME with max version is not a real directory"
      fi
   }
   #================================================================
   # Copy scripts
   #================================================================
   function cp_scripts {
      echo "== Copy scripts"
      if [[ ! -d /home/oracle/system/ ]]; then
         mkdir /home/oracle/system/ 2>&1
      fi
      ( cd /tmp/rcat_12.2.0/ || error_exit 1 "couldn't cd to /tmp/rcat_12.2.0/";
         for file in *; do
            if [[ ! -f /home/oracle/system/rman/$file ]]; then 
               cp /tmp/rcat_12.2.0/$file /home/oracle/system/rman/ 
            elif [[ $file -nt /home/oracle/system/rman/$file ]]; then
               cp /tmp/rcat_12.2.0/$file /home/oracle/system/rman/
            fi
         done
      )
   }
   #================================================================
   # Create the RMAN directory for TNS files
   #================================================================
   function conditionally_create_rman_admin_directory
   {
      # Requires: $MAX_OH
      #           
      echo "== Create the RMAN directory for TNS files"
      export ORACLE_HOME=$MAX_OH
      export TNS_ADMIN=$ORACLE_HOME/network/admin
      [[ ! -d $TNS_ADMIN ]] && error_exit 7 "'\$TNS_ADMIN' ($TNS_ADMIN) is not a directory"
      if [[ ! -d /home/oracle/system/rman/admin ]]; then
         mkdir /home/oracle/system/rman/admin.pre_private_rcat_12g
         touch /home/oracle/system/rman/admin.pre_private_rcat_12g/.previously_empty
      fi
      if [[ ! -d /home/oracle/system/rman/admin.pre_private_rcat_12g ]]; then
         cp -rp /home/oracle/system/rman/admin /home/oracle/system/rman/admin.pre_private_rcat_12g
      fi
      if [[ ! -d /home/oracle/system/rman/admin ]]; then
         mkdir /home/oracle/system/rman/admin
         cd /home/oracle/system/rman/admin
         ln -sf $TNS_ADMIN/tnsnames.ora /home/oracle/system/rman/admin
         touch /home/oracle/system/rman/admin/sqlnet.ora
   
         chown -R oracle:dba /home/oracle/system/rman/admin
      fi
   }
   #================================================================
   # Determine list of TNS aliases comprising the pool of remote servers
   #================================================================
   function remove_rman_cron
   {
      echo "== Disable catalog sync in cron"
      if crontab -l | grep -q 'rman_cron_resync.sh'; then
         if [[ ! -f /var/tmp/rman/crontab.rcat.before.tmp ]]; then
            crontab -l > /var/tmp/rman/crontab.rcat.before.tmp
         fi
         > /tmp/crontab.rcat.no_sync.tmp
         crontab /tmp/crontab.rcat.no_sync.tmp
         echo ".. Disabled the catalog sync in cron"
      else
         echo ".. Disabling the catalog sync in cron not needed"
      fi
   }
   #================================================================
   # Determine list of TNS aliases comprising the pool of remote servers
   #================================================================
   function restore_cron
   {
      echo "== Restore catalog sync in cron"
      if [[ -f /var/tmp/rman/crontab.rcat.before.tmp ]]; then
         crontab /var/tmp/rman/crontab.rcat.before.tmp
         echo "== Restored the catalog sync in cron"
      else
         echo ".. catalog restore not needed."
      fi
   }
   
   #================================================================
   # Determine list of TNS aliases comprising the pool of remote servers
   #================================================================
   function set_pool_envar_and_ALIAS_array
   {
      # Requires: $DOMAIN
      echo "== Set catalog pool based on domain"
      echo "$(date) DOMAIN=$DOMAIN" >> $LOG
      if [[ $DOMAIN == fdc ]]; then
         ALIAS[1]="RCAT01P =
           (DESCRIPTION =
             (ADDRESS = (PROTOCOL = TCP)(HOST = fsxopsx1470.fdc.fs.usda.gov)(PORT = 1521))
             (CONNECT_DATA =
               (SERVER = DEDICATED)
               (SERVICE_NAME = rcat01p.fdc.fs.usda.gov)
             )
           )"
         ALIAS[2]="RCAT02P =
           (DESCRIPTION =
             (ADDRESS = (PROTOCOL = TCP)(HOST = fsxopsx1471.fdc.fs.usda.gov)(PORT = 1521))
             (CONNECT_DATA =
               (SERVER = DEDICATED)
               (SERVICE_NAME = rcat02p.fdc.fs.usda.gov)
             )
           )"
         if ((MAX_TNS>2)); then MAX_TNS=2; fi
      else
         ALIAS[1]="RCAT01P =
           (DESCRIPTION =
             (ADDRESS = (PROTOCOL = TCP)(HOST = fsxopsx1470.fdc.fs.usda.gov)(PORT = 1521))
             (CONNECT_DATA =
               (SERVER = DEDICATED)
               (SERVICE_NAME = rcat01p.fdc.fs.usda.gov)
             )
           )"
         ALIAS[2]="RCAT02P =
           (DESCRIPTION =
             (ADDRESS = (PROTOCOL = TCP)(HOST = fsxopsx1471.fdc.fs.usda.gov)(PORT = 1521))
             (CONNECT_DATA =
               (SERVER = DEDICATED)
               (SERVICE_NAME = rcat02p.fdc.fs.usda.gov)
             )
           )"
         if ((MAX_TNS>2)); then MAX_TNS=2; fi
      fi
      if [[ $HOSTNAME == cant_match_me.fsxopsx0974 ]]; then
         #ALIAS[1]="D9964A =
         ALIAS[1]="RCAT01P =
            (DESCRIPTION =
              (ADDRESS = (PROTOCOL = TCP)(HOST = opsrac012.wrk.fs.usda.gov)(PORT = 1521))
              (CONNECT_DATA =
                (SERVER = DEDICATED)
                (SERVICE_NAME = d9964a.wrk.fs.usda.gov)
              )
            )"
         #ALIAS[1]="D9964B =
         ALIAS[2]="RCAT02P =
            (DESCRIPTION =
              (ADDRESS = (PROTOCOL = TCP)(HOST = opsrac012)(PORT = 1521))
              (CONNECT_DATA =
                (SERVER = DEDICATED)
                (SERVICE_NAME = d9964b)
              )
            )"
      fi
   
      echo "ALIAS[1]"    >> $LOG
      echo "${ALIAS[1]}" >> $LOG
      echo "ALIAS[2]"    >> $LOG
      echo "${ALIAS[2]}" >> $LOG
      echo "ALIAS[3]"    >> $LOG
      echo "${ALIAS[3]}" >> $LOG
   
      cnt=1; tns_patern[$cnt]=$(echo "${ALIAS[$cnt]}" | sed 's|\.|\\\.|g;s| *= *||' | head -1)
                    tns[$cnt]=$(echo "${ALIAS[$cnt]}" | sed 's|=||;s| *||g'   | head -1)
                    echo ${tns_patern[$cnt]}: >> $LOG
                    echo ${tns[$cnt]}:        >> $LOG
      cnt=2; tns_patern[$cnt]=$(echo "${ALIAS[$cnt]}" | sed 's|\.|\\\.|g;s| *= *||' | head -1)
                    tns[$cnt]=$(echo "${ALIAS[$cnt]}" | sed 's|=||;s| *||g'   | head -1)
                    echo ${tns_patern[$cnt]}: >> $LOG
                    echo ${tns[$cnt]}:        >> $LOG
      cnt=3; tns_patern[$cnt]=$(echo "${ALIAS[$cnt]}" | sed 's|\.|\\\.|g;s| *= *||' | head -1)
                    tns[$cnt]=$(echo "${ALIAS[$cnt]}" | sed 's|=||;s| *||g'   | head -1)
                    echo ${tns_patern[$cnt]}: >> $LOG
                    echo ${tns[$cnt]}:        >> $LOG
   }
   #================================================================
   # Add aliases in tnsnames.ora, if needed
   #================================================================
   function populate_tnsnames_file
   {
      # Requires:
      #           ${ALIAS[1]} through 3   the full tns alias
      #           ${tns_patern[1]} through 3     just the name
      echo "== Populate tnsnames.ora for each ORACLE_HOME"
      # Take advantage of the for loop creating a subshell so that the
      # envar modifications are discarded
      for ORACLE_HOME in $ALL_OH; do
         export TNS_ADMIN=$ORACLE_HOME/network/admin
         echo ".. TNS_ADMIN=$TNS_ADMIN"
         if [[ ! -d $TNS_ADMIN ]]; then
           error_exit 12 " could not find $TNS_ADMIN"
         fi
         tnsnames=$TNS_ADMIN/tnsnames.ora
         # Follow the link if it is a link
         if [[ -L $tnsnames ]]; then
            tnsnames=$(/bin/ls -ld $tnsnames | sed 's|.*-> ||' )
         fi
         if [[ -L $tnsnames ]]; then
            exit_error 99 " tnsnames.ora linked to a link not supported."
         fi
         if [[ ! -f $tnsnames ]]; then
            touch $tnsnames
            chown oracle:dba $tnsnames
         fi
         if [[ ! -f $tnsnames.pre_private_rcat_12g ]]; then
            cp -p $tnsnames $tnsnames.pre_private_rcat_12g
         fi
         cnt=1
         # I had $MAX_TNS but PRP wasn't setting asdb.mci  
         # while ((cnt<=$MAX_TNS)); do
         while ((cnt<=${#tns[*]})); do
            if grep -q "^ *${tns_patern[$cnt]} *=" $tnsnames; then
               echo "..    found ${tns[$cnt]}, not adding"
            else
               echo "..    adding ${tns[$cnt]} since it is not there already"
               echo "${ALIAS[$cnt]}" >> $tnsnames
            fi
            ((cnt=cnt+1))
         done
      done
   }
   #================================================================
   # Test the tns aliases used to connect to the RMAN repositories
   #================================================================
   function test_tns_aliases {
      # Requires:
      #           $TNS_ADMIN/tnsnames.ora
      #           ${ALIAS[1]} through 3     just the name
      #           $BACKOUT_RMAN_RN
      # Try to contact the RMAN repositories
      echo "== Trying to contact the RMAN repositories with tnsping"
      if [[ -n "$BACKOUT_RMAN_RN" ]]; then
         export Q_MSG=" check the log for backout being executed already. $LOG"
      fi
      for ORACLE_HOME in $ALL_OH; do
         cnt=1
         while ((cnt<=$MAX_TNS)); do
            echo -e "\n\n\n\n\ntnsping ${tns[$cnt]}" >> $LOG
            (  export ORACLE_HOME=$ORACLE_HOME;PATH=$ORACLE_HOME/bin:$PATH;
               tnsping ${tns[$cnt]} ) >> $LOG 2>&1
            (($?>0)) && error_exit 15 "As user oracle (ORACLE_HOME=$ORACLE_HOME), this command failed:  tnsping ${tns[$cnt]} $Q_MSG"
            ((cnt=cnt+1))
         done
      done
      echo ".. all tnsping commands succeeded"
   }
   #================================================================
   # Determine name of the user name of remote catalogs
   #================================================================
   function set_envar_NEW_RMAN_SCHEMA
   {
      echo "== Set schema envars"
      if [[ -z $CEMUTLO ]]; then
         unset CLUSTER_NAME
      else
         export CLUSTER_NAME=$(ksh "$CEMUTLO -n" | tr '-' '_')
      fi
      cnt=$(echo $CLUSTER_NAME | wc -w)
      echo "CLUSTER_NAME=$CLUSTER_NAME" >> $LOG
      echo "cnt=$cnt" >> $LOG
      if (( $cnt == 0 )); then
         if ps -ef | grep -q "[p]mon_+ASM"; then
            error_exit 31 "ASM 10g is running, yet can't determine the cluster name"
         fi
         export NEW_RMAN_SCHEMA="rcat_${DOMAIN}_$(hostname)"
      elif (( $cnt == 1 )); then
         export NEW_RMAN_SCHEMA="rcat_${DOMAIN}_$CLUSTER_NAME"
      else
         echo "ERROR: could not determine the clustername"
      fi
      echo ".. NEW_RMAN_SCHEMA=$NEW_RMAN_SCHEMA"
   }
   #================================================================
   # Populate oracle's .bash_profile with catalog envars
   #================================================================
   function set_evars_in_profile
   {
      # Requires:  $tns[1..3]
      echo "== Setting envars in oracle's .bash_profile"
      echo "$(date) DOMAIN=$DOMAIN" >> $LOG
      if [[ -f ~oracle/.bash_profile ]]; then echo "FYI:  ~oracle/.bash_profile exists" >> $LOG;
                                         else echo "FYI:  ~oracle/.bash_profile missing" >> $LOG; fi
      if [[ -f ~oracle/.profile      ]]; then echo "FYI:  ~oracle/.profile exists" >> $LOG;
                                         else echo "FYI:  ~oracle/.profile missing" >> $LOG; fi
      if [[ -s /etc/redhat-release ]]; then
         if [[ ! -s ~oracle/.bash_profile ]]; then
            touch ~oracle/.bash_profile
            chown oracle:dba ~oracle/.bash_profile
         fi
      fi
      for file in $(ls ~oracle/.bash_profile ~oracle/.profile 2>/dev/null); do
         echo "file=$file" >> $LOG
         export RMAN_CATALOG=${tns[1]}
         export RMAN_CATALOG_POOL=$(
            cnt=1
            while ((cnt<=MAX_TNS)); do
               echo -e "$delim${tns[$cnt]}\c"
               delim=':'
               ((cnt=cnt+1))
            done)
         echo "export RMAN_CATALOG=$RMAN_CATALOG"           >> $LOG
         echo "export RMAN_CATALOG_POOL=$RMAN_CATALOG_POOL" >> $LOG
   
         if [[ ! -f $file.pre_private_rcat_12g ]]; then
            echo "cp $file $file.pre_private_rcat_12g" >> $LOG
            cp $file $file.pre_private_rcat_12g 2>> $LOG
         fi
         grep -v RMAN_ $file                                 > $file.new
         echo "export RMAN_SCHEMA=$NEW_RMAN_SCHEMA"         >> $file.new
         echo "export RMAN_CATALOG=$RMAN_CATALOG"           >> $file.new
         echo "export RMAN_CATALOG_POOL=$RMAN_CATALOG_POOL" >> $file.new
         mv $file $file.$(date +"%Y-%m-%d:%H:%M:%S")
         cp $file.new $file
         chown oracle:dba $file 2>> $LOG
      done
      # Source these now since they're all changed.
      . ./.profile 2> /dev/null
      . ./.bash_profile 2> /dev/null
   }
   #================================================================
   # Prompt user for remote SYS passwords
   #================================================================
   function read_user_SYS_passwords
   {
      # Requires:
      #           $TNS_ADMIN/tnsnames.ora
      #           ${ALIAS[1]} through 3     just the name
      echo "== Fetch user SYS passwords"
      SYSpwd[1]=$SYSpwd_rcat01p
      SYSpwd[2]=$SYSpwd_rcat02p
      export cnt=1
      all_passwords_good=1
      while ((cnt<=$MAX_TNS)); do
         echo ".. Trying SYS password for '${tns[$cnt]}'"
         (  export TNS_ADMIN=/home/oracle/system/rman/admin; \
            export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH; \
            (sleep 1; echo "${SYSpwd[$cnt]}"; sleep 1; echo exit) | \
               sqlplus -L SYS@${tns[$cnt]} as sysdba) 2>&1 | tee -a $LOG | grep -- -[0-9]
         if [[ $? == 0 ]]; then
            echo "SYS password for ${tns[$cnt]} fails to connect to database."
            all_passwords_good=0
         else
            echo "SYS password for ${tns[$cnt]} is correct"
            echo ""
            echo ""
         fi
         if ((cnt==$MAX_TNS)); then
            (( all_passwords_good == 1 )) || error_exit 1 'not all SYS passwords worded on remote catalog servers.  Double check values for envars $SYSpwd_rcat01p and $SYSpwd_rcat02p'
         fi
         ((cnt=cnt+1))
      done
   }
   #================================================================
   # Prompt user for RMAN catalog password
   #================================================================
   function read_rcat_password {
      echo "== Fetch catalog password"
      while true; do
         if [[ -z "$RMAN_PWD" ]]; then
            echo "Enter the case-sensitive password for the RMAN catalog: "
            stty -echo
            read RMAN_PWD
            stty echo
         fi
         crypt_pwd=$(echo "$RMAN_PWD" | openssl dgst -sha384)
         if [[ $crypt_pwd != "(stdin)= 51a38bd378f833ae6785a05b7b91b6cc2086b7f750afa1d3a8ea8929ec267970fd940169fe3fb1e73da408bad31e8ebb" ]]; then
            echo "catalog password is incorrect"
            unset RMAN_PWD
         else
            echo "catalog password correct"
            echo ""
            echo ""
            break;
         fi
      done
   }
   #================================================================
   # See if the remote catalog users (schemas) exist
   #================================================================
   function query_rman_schema_existence {
      # Requires:
      #           $TNS_ADMIN/tnsnames.ora
      #           ${tns[1]} through 3     just the name
      # Output: SCHEMA_EXISTS[1..3] equals 'TRUE' or 'FALSE'
      echo "== Query for remote RMAN catalog schemas"
      printthem=$1
      export cnt=1
      while ((cnt<=$MAX_TNS)); do
         echo ".. looking for schema '$NEW_RMAN_SCHEMA' in ${tns[$cnt]}"
         output=$(echo "starting output" | tee -a $LOG; 
            export TNS_ADMIN=/home/oracle/system/rman/admin;
            export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH; 
            echo "sqlplus -L SYS@${tns[$cnt]} as sysdba" >> $LOG
            (  sleep 1; echo "${SYSpwd[$cnt]}"; sleep 1; 
               echo -e "alter session set NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';\n select 'created='||created from all_users 
                  where username=upper('$NEW_RMAN_SCHEMA')"; 
               echo; echo l; echo r; echo exit ) \
            | sqlplus -L SYS@${tns[$cnt]} as sysdba 2>&1 | tee -a $LOG; echo "ending output" | tee -a $LOG       )
         if echo "$output" | grep -v ^created | grep -q -- [A-Z][A-Z][A-Z0-9]-[0-9]; then
            error_exit 16 "could not query schema's existence"
         elif echo "$output" | grep -q ^created=; then
            echo "schema '$NEW_RMAN_SCHEMA'@'${tns[$cnt]}' exists"
            SCHEMA_EXISTS[$cnt]=$(echo "$output" | grep ^created=)
         else
            echo "schema '$NEW_RMAN_SCHEMA'@'${tns[$cnt]}' does not exist"
            SCHEMA_EXISTS[$cnt]='FALSE'
         fi
         ((cnt=cnt+1))
      done
      if [[ $printthem == "printthem" ]]; then
         cnt=1
         while ((cnt<=$MAX_TNS)); do
            echo "SCHEMA_EXISTS[$cnt]=${SCHEMA_EXISTS[$cnt]}:"
            ((cnt=cnt+1))
         done
      fi
   }
   #================================================================
   # Remove remote catalog users
   #================================================================
   function drop_rman_remote_schemas {
      # Requires:
      #           $TNS_ADMIN/tnsnames.ora
      #           ${tns[1]} through 3     just the name
      #           $NEW_RMAN_SCHEMA
      #           ${SYSpwd[$cnt]}
      echo "== Drop remote catalog schemas"
      if [[ -z $SKIP_DROP ]]; then
         export cnt=1
         while ((cnt<=$MAX_TNS)); do
            echo ".. drop schema '$NEW_RMAN_SCHEMA' in ${tns[$cnt]}"
            (  export TNS_ADMIN=/home/oracle/system/rman/admin; \
               export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH; \
               (sleep 1; echo "${SYSpwd[$cnt]}"; sleep 1; \
               echo "drop user $NEW_RMAN_SCHEMA cascade"; echo; echo l; echo r; echo exit ) \
               | sqlplus -L SYS@${tns[$cnt]} as sysdba
            ) 2>&1 | tee -a $LOG | grep -v ORA-01918 | grep -- -[0-9]
            if [[ $? == 0 ]]; then
               echo "drop schema '$NEW_RMAN_SCHEMA' from '${tns[$cnt]}' failed."
            else
               echo "drop schema '$NEW_RMAN_SCHEMA' from '${tns[$cnt]}' succeeded"
            fi
            ((cnt=cnt+1))
         done
      else
         echo ".. envar SKIP_DROP is set, so skipping this step..."
      fi
   }
   #================================================================
   #  Create remote RMAN catalog users
   #================================================================
   function create_rman_remote_schemas {
      # Requires:
      #           $TNS_ADMIN/tnsnames.ora
      #           ${tns[1]} through 3     just the name
      echo "== Create remote RMAN catalog schemas"
      export cnt=1
      while ((cnt<=$MAX_TNS)); do
         echo ".. creating schema '$NEW_RMAN_SCHEMA' in ${tns[$cnt]}"
         (   export TNS_ADMIN=/home/oracle/system/rman/admin;
             export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH;
             (  sleep 1; echo "${SYSpwd[$cnt]}"; 
                sleep 1; echo $NEW_RMAN_SCHEMA; echo $RMAN_PWD; echo exit ) \
             | sqlplus -L SYS@${tns[$cnt]} as sysdba @/home/oracle/system/rman/create_rcat.sql 
         ) 2>&1 | sed 's|identified by.*|identified by ****|' | tee -a $LOG | grep -- -[0-9] | grep -vE 'ORA-01920|ORA-02379|ORA-02248'
         [[ $? == 0 ]] && error_exit 35 "schema creation for '${tns[$cnt]}' failed."
         echo "schema creation for '${tns[$cnt]}' succeeded"
         ((cnt=cnt+1))
      done
   }
   #================================================================
   function call_rpm_post_install_sh {
      echo "starting rpm_post_install.sh"
      # 10/16/13 Run the RPM post install to do things like create ~oracle/.bash_profile
      unset FS615_BACKUP_SCRIPT_BACKOUT_OR_JUST_SCRIPTS
      export IGNORE_TDPOCONF_ENV=yes
      export RMAN_SCHEMA=$NEW_RMAN_SCHEMA
      (  (  echo "Here2 RMAN_SCHEMA=$RMAN_SCHEMA  #RMAN_PWD=${#RMAN_PWD} SKIP_NFS_MOUNT_CHECK=$SKIP_NFS_MOUNT_CHECK";
            export RMAN_SCHEMA; export RMAN_PWD; export SKIP_NFS_MOUNT_CHECK;
            . /home/oracle/system/rman/rpm_post_install.sh;)
         echo $? > /var/tmp/rman/rcat.semiphore3)
      rc=$(cat /var/tmp/rman/rcat.semiphore3)
      rm -f /var/tmp/rman/rcat.semiphore3
      [[ $rc == "0" ]] || error_exit 30 "failed /home/oracle/system/rman/rpm_post_install.sh"
   }
   function call_archivelog_mode_sh {
      # $1 - commandline options
      CMD_OPTS=$1
      /home/oracle/system/rman/archivelog_mode.sh $CMD_OPTS || error_exit 1 "couldn't call archivelog_mode.sh successfully"
   }
   #================================================================
   # Create catalog objects
   #================================================================
   function create_catalog_objects {
      # Requires:
      #           $TNS_ADMIN/tnsnames.ora
      #           ${tns[1]} through 3     just the name
      #           $NEW_RMAN_SCHEMA
      echo "== Create remote catalog schemas"
      echo "create catalog tablespace users;" > /tmp/rcat_12.2.0/create_catalog.rmn
      chown oracle:dba /tmp/rcat_12.2.0/create_catalog.rmn
      chmod 700 /tmp/rcat_12.2.0/create_catalog.rmn
      export cnt=1
      while ((cnt<=$MAX_TNS)); do
         echo ".. Create catalog objects in schema '$NEW_RMAN_SCHEMA' in ${tns[$cnt]}"
         (  export TNS_ADMIN=/home/oracle/system/rman/admin; 
            export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH;
            echo $RMAN_PWD | $ORACLE_HOME/bin/rman catalog $NEW_RMAN_SCHEMA@${tns[$cnt]} cmdfile=/tmp/rcat_12.2.0/create_catalog.rmn
         ) 2>&1 | tee -a $LOG | grep RMAN-
         [[ $? != 0 ]] || error_exit 34 "create schema objects in '$NEW_RMAN_SCHEMA' at '${tns[$cnt]}' failed."
         echo "create schema objects in '$NEW_RMAN_SCHEMA' at '${tns[$cnt]}' succeeded." 
         ((cnt=cnt+1))
      done
   }
   
   
   #================================================================
   # Register databases in RMAN repositories
   #================================================================
   function reregister_dbs {
      echo "== Registering databases in RMAN repositories"
      touch /tmp/rman_reregister.semiphore.txt
      chown oracle:dba /tmp/rman_reregister.semiphore.txt
      # Getting library errors, therefore trying to unset some envars
      # rman: symbol lookup error: rman: undefined symbol: kgxgnWFinit_
      unset ORACLE_HOME_SOURCE
      unset ORACLE_BASE
      unset ORACLE_HOME
      unset ORACLE_SID
      unset ORA_CRS_HOME
      (
         > /tmp/rman_reregister.semiphore.txt
         /home/oracle/system/rman/reregister_dbs.sh || \
            echo nonzero_exit > /tmp/rman_reregister.semiphore.txt
      ) | tee -a $LOG \
        | egrep 'ORACLE_SID=|Trying repository |starting full resync of recovery catalog'
      if grep -q nonzero_exit /tmp/rman_reregister.semiphore.txt; then
         error_exit 24 "Registering databases failed."
      else
         echo ".. successfully registerd databases"
      fi
      rm /tmp/rman_reregister.semiphore.txt
   }
   #================================================================
   # Install the Inventory signature file
   #================================================================
   function install_signature_file
   {
      echo "== Installing signature file"
      SIGDIR="/home/oracle/system/signatures"
      SIGFILE="private_rman_catalog_12.2.0.sig"
   
      mkdir -p $SIGDIR
      [[ $? != 0 ]] && error_exit 25 "Unable to create signature directory"
   
      echo "private_rman_catalog_12.2.0.sig,129,RMAN Private Catalog 12.2.0,/home/oracle/system/signatures/private_rman_catalog_12.2.0.sig,Solaris" > $SIGDIR/$SIGFILE
   
      [[ $? != 0 ]] && error_exit 26 "Unable to create signature file"
      chmod 755 $SIGDIR/$SIGFILE
      echo ".. done"
   }
   #================================================================
   # Remove the Inventory signature file
   #================================================================
   function remove_signature_file
   {
      echo "== Removing signature file"
      SIGDIR="/home/oracle/system/signatures"
      SIGFILE="private_rman_catalog_12.2.0.sig"
   
      if [[ -f $SIGDIR/$SIGFILE ]]; then
         rm $SIGDIR/$SIGFILE
         [[ $? != 0 ]] && error_exit 27 "Unable to remove signature file"
         echo ".. Removed signature file"
      fi
      echo ".. done"
   }
   function call_rpm_post_uninstall_sh {
      ksh /tmp/rcat_12.2.0/rpm_post_uninstall.sh || error_exit 41 'rpm_post_uninstall.sh failed'
   }
   #================================================================
   # Backout the changes, if any
   #================================================================
   function backout_files_and_dirs
   {
      echo "== Backout files and directories"
      echo ".. find /opt/oracle/.../network/admin"
      for dir in $(find $(find /opt/oracle/product -type d -name network 2>/dev/null) -name admin); do
         if [[ -f $dir/tnsnames.ora.pre_private_rcat_12g ]]; then
            cp -p $dir/tnsnames.ora.pre_private_rcat_12g $dir/tnsnames.ora
         fi
      done
      if [[ -f ~oracle/.profile.pre_private_rcat_12g ]]; then
         cp ~oracle/.profile.pre_private_rcat_12g ~oracle/.profile
      fi
      if [[ -f ~oracle/.bash_profile.pre_private_rcat_12g ]]; then
         cp ~oracle/.bash_profile.pre_private_rcat_12g ~oracle/.bash_profile
      fi
      if [[ -f /home/oracle/system/rman/admin.pre_private_rcat_12g/.previously_empty ]]; then
        rm -rf /home/oracle/system/rman/admin.pre_private_rcat_12g/
        rm -rf /home/oracle/system/rman/admin/
      fi
      if [[ -d /home/oracle/system/rman/admin.pre_private_rcat_12g ]]; then
        rm -rf /home/oracle/system/rman/admin
        mv /home/oracle/system/rman/admin.pre_private_rcat_12g /home/oracle/system/rman/admin
      fi
      ( cd /home/oracle/system/rman
           rm -f cf_snapshot_in_recovery.sh
           rm -f choose_a_sid.sh
           rm -f choose_OH.sh
           rm -f cold.sh
           rm -f desc_all_catalogs.sh
           rm -f extrapolate_dbid.sh
           rm -f find_asm.sh
           rm -f insert_row1.sh
           rm -f insert_wrong_val.sh
           rm -f install_shield_cron.sh
           rm -f local_sids.sh
           rm -f nid.sh
           rm -f oracle_cron_conditional_arch_backup.sh
           rm -f rcat_12.2.0.sh
           rm -f rcat_wallet.sh
           rm -f report_obsolete.sh
           rm -f repository_vote.sh
           rm -f reregister_dbs.sh
           rm -f rman_backup.sh
           rm -f rman_cf_scn.sh
           rm -f rman_change_archivelog_all_crosscheck.sh
           rm -f rman_change_crosscheck.sh
           rm -f rman_change_del.sh
           rm -f rman_cron_resync.sh
           rm -f rman_delete.days.sh
           rm -f rman_delete.DISK.krb.sh
           rm -f rman_delete.sh
           rm -f rman_recover.sh
           rm -f rman_report_need_backup.sh
           rm -f rman_restore_cf.sh
           rm -f rman_restore_df.sh
           rm -f rman_restore_pitr_spfile_cf.sh
           rm -f rman_restore_pitr.preview.3.sh
           rm -f rman_restore_pitr.preview.sh
           rm -f rman_restore_pitr.sh
           rm -f rman_restore_tbs.sh
           rm -f rman_restore.sh
           rm -f rpm_post_install.sh
           rm -f rpm_post_uninstall.sh
           rm -f rpm_prereq.sh
           rm -f select_tsm_test.sh
           rm -f set_profile_rman_envars.sh
           rm -f show_max_archived_log_scn.sh
           rm -f tnsping_catalogs.sh
           rm -f voting_disk.sh 
   
           rm -f fs615_allocate_disk.ora.*
           rm -f fs615_allocate_sbt.ora.*
           rm -f rc_grant_all.sql
           rm -f restore_arch.rmn
           rm -f restore_redo_2_local_disk_after_ckpt.rmn
           rm -f restore_redo_2_local_disk_after_ckpt.sql
           rm -f rman_parameters.sh
           rm -f usfs_local_sids)
        echo ".. Done"
   }
   
   
   ################################################################
   # MAIN
   ################################################################
   set_envars
   echo "$(date) Begin $0 'RMAN priviate catalog'" >> $LOG
   MYID=$(id -u -n)
   [[ $MYID != "oracle" ]] && error_exit 29 "This script must be executed as oracle"
   
   # Check available free space in Kbytes
   check_freespace  5000 /tmp
   echo ".. free space prerequisite passed"
   
   # Check to make sure no backups are currently running
   check_oracle_software
   check_running_processes
   check_sysinfra_symlink
   
   # Verify required files are present
   check_required_files
   set_pool_envar_and_ALIAS_array
   set_envar_NEW_RMAN_SCHEMA
   set_evars_in_profile
   cp_scripts
   find_all_OH
   find_max_oracle_SW_version
   
   remove_rman_cron
   conditionally_create_rman_admin_directory
   if [[ "$BACK_OUT" == "YES" ]]; then
      # Backout the Release Notice
      echo "== Begining backout"
      export BACKOUT_RMAN_RN=YES
      test_tns_aliases
      read_user_SYS_passwords
      #HACK OLD read_rcat_password
      call_archivelog_mode_sh -y -b $AUTO_SHUTDOWN
      query_rman_schema_existence
      drop_rman_remote_schemas
      query_rman_schema_existence
      call_rpm_post_uninstall_sh
      backout_files_and_dirs
      remove_signature_file
      echo "$(date) SUCCESSFULLY COMPLETED BACKOUT PROCEDURE"
   else
      chmod_775_opt_oracle_diag
      populate_tnsnames_file
      test_tns_aliases
      read_user_SYS_passwords
      read_rcat_password

      query_rman_schema_existence printthem
      drop_rman_remote_schemas
      create_rman_remote_schemas
      query_rman_schema_existence # This really isn't necessary.

      call_rpm_post_install_sh
      call_archivelog_mode_sh -y $AUTO_SHUTDOWN

      create_catalog_objects
      reregister_dbs

      restore_cron
      install_signature_file
   fi
   echo "SCRIPT COMPLETED SUCCESSFULLY $(date)" >> $LOG
} 2>&1 | tee -a $LOG
echo "Log file for this script is $LOG"
tail $LOG | grep "^SCRIPT COMPLETED SUCCESSFULLY" || exit 1
exit 0
