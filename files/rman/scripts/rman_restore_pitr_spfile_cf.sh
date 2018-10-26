#!/usr/bin/env ksh
#
#  %Z%%W%,%I%:%G%:%U%
#  VERSION:  %I%   #05/01/2013   v1.5
#  DATE:  %G%:%U%
#
#  (C) COPYRIGHT International Business Machines Corp. 2002-2007, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Restore the control file from the current incarnation to /tmp/cf.tmp.

export NLS_LANG=american
export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'

#############################################################################
echo "Step 32.1.1 - Verify user ID is oracle"
#############################################################################
export ID=$(id -u -n)
if [[ $ID != oracle ]]; then
   echo "Please log in as user oracle"
   exit 1
fi


export TMP=/tmp/rman
mkdir $TMP 2> /dev/null
chown oracle:dba $TMP
chmod 750 $TMP

export LOG_DIR=/opt/oracle/diag/bkp/rman/log
mkdir $LOG_DIR 2> /dev/null
chown oracle:dba $LOG_DIR
chmod 700 $LOG_DIR

export LOG_DIR_GRID=/opt/oracle/diag/bkp/rman/vote_disk
mkdir $LOG_DIR_GRID 2> /dev/null
chown oracle:dba $LOG_DIR_GRID
chmod 775 $LOG_DIR_GRID

program="rman_restore_spfile_cf.sh"
export RAO1=$TMP/$program.1.sh
export RAO1_1=$TMP/$program.1_1.sh
export RAO2=$TMP/$program.2.sh
export RAO3=$TMP/$program.3.sh
export RAO3a=$TMP/$program.3a.sh
export RAO3b=$TMP/$program.3b.sh
export RAO4=$TMP/$program.4.sh
export RAO4_1=$TMP/$program.4_1.sh
export LOG1=$LOG_DIR/$program.1.$$.log
export LOG1_3=$LOG_DIR/$program.1_3.$$.log
export LOG2=$LOG_DIR_GRID/$program.2.$$.log
export LOG3=$LOG_DIR_GRID/$program.3.$$.log
export LOG3_1=$LOG_DIR_GRID/$program.3_1.$$.log
export LOG3a=$LOG_DIR/$program.3a.$$.log
export LOG3a_1=$LOG_DIR/$program.3a_1.$$.log
export LOG3b=$LOG_DIR/$program.3b.$$.log
export LOG3b_1=$LOG_DIR/$program.3b_1.$$.log
export LOG4=$LOG_DIR/$program.4.$$.log
export LOG4_3=$LOG_DIR/$program.4_3.$$.log
export SQL3b=$TMP/$program.3b.sql
>$LOG1
chown oracle:dba $LOG1

function usage_exit
{
   echo "Usage:  rman_restore_spfile.sh {-o[ORACLE_SID]} {-r} {-i[DBID]}"
   echo "          Restores the last backed up controlfile to /tmp/cf.tmp"
   echo "          -o, Values for ORACLE_SID i.e. [a|ddb|rdb|tdb|admin]"
   echo "          -i, specifies DBID to remove ambiguity."
   echo "          -t, time to restore to.  Note that HH is 24 hour time."
   echo "          -s N, restore until scn value of N."
   echo "          -d, read from disk instead of tape device"
   echo "          -g, generate init.ora file out of restored spfile for Stand-Alone"
   exit 1
}

unset DISK_OPT
unset DB_ID
while getopts ho:i:t:s:dg option
do
   case "$option"
   in
      h) usage_exit;;
      o) export FS615_ORACLE_SID="$OPTARG";;
      i) export DBID_CMD="set DBID=$OPTARG";;
      t) export rec_time="$OPTARG";;
      s) export scn="$OPTARG";;
      d) export DISK_OPT='YES';;
      g) export GENERATE_INIT_ORA__OTP='YES';;
     \?)
         eval echo -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done

alias shopt=': '; UID=$(id | sed 's|(.*||;s|.*=||'); . /home/oracle/.bash_profile
export ORACLE_SID=$FS615_ORACLE_SID

if [[ -z "$ORACLE_SID" ]]; then
   . /home/oracle/system/rman/choose_a_sid.sh
fi
if [[ "$rec_time" != [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]:[0-9][0-9]:[0-9][0-9]:[0-9][0-9] ]]; then
   if [[ $scn != [0-9][0-9]* ]]; then
      #usage_exit
      :
   else
      set_until="set until scn = $scn;"
   fi
else
   set_until="set until time = '$rec_time';"
fi

# Set  $NB_ORA_CLIENT  $NB_ORA_SERV  $NB_ORA_POLICY  and  $send_cmd,  log /opt/oracle/diag/bkp/rman/log/build_SEND_cmd.sh.log
. /home/oracle/system/rman/build_SEND_cmd.sh
export ALLOCATE_SBT_CHANNELS="
        allocate channel t1 type 'sbt_tape';
        $send_cmd
        "
echo "ALLOCATE_SBT_CHANNELS=$ALLOCATE_SBT_CHANNELS"
RELEASE_CHANNEL="release channel t1;"

if [[ -z $DISK_OPT ]]; then
   ALLOCATE_SBT_CHANNELS="$ALLOCATE_SBT_CHANNELS
             allocate channel d1 type disk;"
   
   RELEASE_CHANNEL="$RELEASE_CHANNEL  release channel d1;"
fi

export FS615_ORATAB=/etc/oratab
[[ $(uname) == "SunOS" ]] && export FS615_ORATAB=/var/opt/oracle/oratab

if grep -q '^+ASM[0-9]' $FS615_ORATAB; then
   # Set the DB_NAME for RAC
   export DB_NAME=${ORACLE_SID%[0-9]}; 
else 
   # Set the DB_NAME for Stand Alone servers
   export DB_NAME=$ORACLE_SID; 
fi
echo "DB_NAME=$DB_NAME" | tee -a $LOG1

unset PFILE
if [[ -n "$GENERATE_INIT_ORA__OTP" ]]; then
   export PFILE=$ORACLE_HOME/dbs/init$ORACLE_SID.ora
fi

umask 077
cat > $RAO1 <<EOF2
  export ORACLE_SID=$ORACLE_SID
  echo "ORACLE_SID=\$ORACLE_SID"
  export GENERATE_INIT_ORA__OTP=$GENERATE_INIT_ORA__OTP
  echo "GENERATE_INIT_ORA__OTP=\$GENERATE_INIT_ORA__OTP"
  export PFILE=$PFILE
  echo "PFILE=\$PFILE"

  export NLS_LANG=american
  export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'
  # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
  . /home/oracle/system/oraenv.usfs
  PATH=\$ORACLE_HOME/bin:\$PATH
  export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
  if [[ \$ORACLE_HOME == */11.* ]]; then 
     # Here, the database is 11g
     if grep -v '^[ 	]*#' $FS615_ORATAB | grep -q "ASM[1-9]:"; then
        # Here, the DB is 11g RAC, make the ADR home.
        mkdir -p /opt/oracle/admin/${ORACLE_SID%[0-9]}/arch
        mkdir -p /opt/oracle/admin/${ORACLE_SID%[0-9]}/adump
        mkdir -p /opt/oracle/admin/${ORACLE_SID%[0-9]}/create
        mkdir -p /opt/oracle/admin/${ORACLE_SID%[0-9]}/exp
        mkdir -p /opt/oracle/admin/${ORACLE_SID%[0-9]}/dpdump
        mkdir -p /opt/oracle/admin/${ORACLE_SID%[0-9]}/logbook
        mkdir -p /opt/oracle/admin/${ORACLE_SID%[0-9]}/pfile
        mkdir -p /opt/oracle/admin/${ORACLE_SID%[0-9]}/scripts
        chmod 750 /opt/oracle/admin/${ORACLE_SID%[0-9]}
        chmod 750 /opt/oracle/admin/${ORACLE_SID%[0-9]}/*
     else
        # Here, the DB is 11g Stand Alone.  Make the ADMIN_HOME dirs
        mkdir -p /opt/oracle/admin/${ORACLE_SID}/arch
        mkdir -p /opt/oracle/admin/${ORACLE_SID}/adump
        mkdir -p /opt/oracle/admin/${ORACLE_SID}/create
        mkdir -p /opt/oracle/admin/${ORACLE_SID}/exp
        mkdir -p /opt/oracle/admin/${ORACLE_SID}/dpdump
        mkdir -p /opt/oracle/admin/${ORACLE_SID}/logbook
        mkdir -p /opt/oracle/admin/${ORACLE_SID}/pfile
        mkdir -p /opt/oracle/admin/${ORACLE_SID}/scripts
        chmod 750 /opt/oracle/admin/${ORACLE_SID}
        chmod 750 /opt/oracle/admin/${ORACLE_SID}/*
     fi
  else
     # For 10g, create dump dest directories
     ADMIN=$(ls -d /opt/oracle/admin /opt/oracle/db/admin 2> \
             /dev/null)
     # Make subdirectories under OH/admin
     for subdir in adump  bdump  cdump  dpdump  hdump  pfile  udump \
           arch_\${ORACLE_SID%[0-9]};do
        mkdir -p \$ADMIN/\${ORACLE_SID%[0-9]}/\$subdir
     done
  fi

  echo "*.db_name='$DB_NAME'" > $TMP/init$DB_NAME.ora
  #echo "startup nomount pfile=$TMP/init$DB_NAME.ora;" | sqlplus "/ as sysdba"
  echo "
     $DBID_CMD
     connect target /
     shutdown immediate
     startup nomount pfile=$TMP/init$DB_NAME.ora;
     run {
        $ALLOCATE_SBT_CHANNELS

        #Another useful command:  restore spfile from autobackup;

        $set_until

        restore  spfile;
        restore  spfile to '/tmp/rman/spfile.ora';

        $RELEASE_CHANNEL
     }
     " > $RAO1_1
 . /home/oracle/system/oraenv.usfs
  export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
  echo "== Restore spfile TNS_ADMIN=\$TNS_ADMIN"
  rman catalog /@\$RMAN_CATALOG cmdfile=$RAO1_1 2>&1 | tee -a $LOG1
  spfile=\$(sed '/output filename=/!d;s|output filename=||' $LOG1 | head -1)
  echo spfile=\$spfile
  if [[ -z "\$GENERATE_INIT_ORA__OTP" ]]; then
     cp /tmp/rman/spfile.ora \$ORACLE_HOME/dbs/spfile$DB_NAME.ora # For RAC
     #echo -e "startup force nomount;\nalter system set control_files='\${ORACLE_HOME}/dbs/cntrl${ORACLE_SID}.dbf' scope=spfile;" | sqlplus "/ as sysdba"
     echo "startup force nomount;" | sqlplus "/ as sysdba"
     echo -e "show parameter spfile\nshow parameter control_f" | sqlplus "/ as sysdba" | tee $LOG1_3
  else
     if [[ \$spfile -nt $RAO1 ]]; then
        echo "Here, the spfile is newer than its restore command"
        echo "Therefore, create an init.ora file out of the spfile"
        mv \$ORACLE_HOME/dbs/spfile$ORACLE_SID.ora \$ORACLE_HOME/dbs/spfile$ORACLE_SID.ora.$(date "+%Y-%m-%d:%H:%M:%S")
        cp \$spfile \$ORACLE_HOME/dbs/spfile$ORACLE_SID.ora # For Stand Alone
        spfile=/tmp/rman/spfile.ora
        echo spfile=\$spfile
        mv \$PFILE \$PFILE.$(date "+%Y-%m-%d:%H:%M:%S")

        # Generate init.ora from spfile.  Remove the dikgroup paths though.
        strings \$spfile | \
           sed "s|+.*'|\$ADMIN'|;
             s|*.control_files=.*|*.control_files='\$ADMIN/control_file.dbf'|;
             s|*.log_archive_dest_1=.*|*.log_archive_dest_1='LOCATION=\$ADMIN/\${ORACLE_SID%[0-9]}/arch_${ORACLE_SID%[0-9]}'|;
             /cluster_database/d" \
           > \$PFILE
        echo "USFS Successfully generated '\$PFILE' file from spfile" | tee -a $LOG1
     else
        echo "ERROR: couldn't identify the restored spfile: '$spfile'"
     fi
  fi
EOF2

chmod 700 $RAO1
chown oracle.dba $RAO1
ksh $RAO1

# Handle RAC environment (instead of Stand-Alone)
if [[ -z "$GENERATE_INIT_ORA__OTP" ]]; then
   if grep "ORA-1750[32]" $LOG1; then
      echo "Couldn't make the path for the spfile in ASM.  Making that path." \
        | tee $LOG2

      cat > $RAO2 <<EOF
         # Get the ASM SID on this node
         echo "whoami=$(whoami)"
         export ORACLE_SID=+$(ps -ef | sed '/pmon_+AS[M]/!d;s|.*pmon_+||')
         echo \
         "mkdir $(grep "ORA-1750[32]" $LOG1|tail -1|sed "s|.*+||;s|/[^/]*$||")" |\
            asmcmd -p
EOF
      chmod 700 $RAO2
      if id grid > /dev/null 2>&1; then
         rm -f $LOG2
         chmod a+rwx $RAO2 $LOG2
         echo \" . ~/.bash_profile; $RAO2 | tee -a $LOG2\" | (cd /tmp; sudo -u grid ksh)
         #while true; do
         #   echo "Do this as your admin user in another window:" | tee -a $LOG2
         #   echo "    echo \" . ~/.bash_profile; $RAO2 | tee -a $LOG2\" | (cd /tmp; sudo -u grid ksh)"
         #   echo "Press enter in this window once it is complete."
         #   chmod 775 $LOG2 >> $LOG2
         #   read pause
         #   [[ -f $LOG2 ]] && break
         #   echo "Could not file $LOG2  Please retry."
         #done
         chmod 700 $RAO2
      else
         chown oracle:dba $RAO2 $LOG2
         chmod u+x $RAO2 $LOG2
         ksh $RAO2 | tee -a $LOG2
      fi
      cat $LOG2
      cp $LOG2 $LOG_DIR
   
      mv $LOG1 $LOG1.first_pass
      echo "With the path to the spfile now created in ASM, try to restore spfile"
      chmod 700 $RAO1
      chown oracle:dba $RAO1
      ksh $RAO1
   fi
   
   if grep "ORA-1750[32]" $LOG1; then
      echo "ERROR: couldn't make a path in ASM for the spfile"
      exit 1
   fi

   rm -f /tmp/rman_restore_pitr_spfile_cf.tmp
   control_files=$(
      # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
      . /home/oracle/system/oraenv.usfs >/dev/null 2>&1
      PATH=$ORACLE_HOME/bin:$PATH
      export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
      cat <<\EOF2 | sqlplus "/nolog" | sed '/val=/!d;s|[+,]| |g;s|val=||'
         connect / as sysdba
         set lines 1000
         set head off
         ! echo SID=$ORACLE_SID > /tmp/rman_restore_pitr_spfile_cf.tmp
         select 'val' || '='||value from v$parameter where name='control_files';
EOF2
   )
   echo -e "SID:\c"
   cat /tmp/rman_restore_pitr_spfile_cf.tmp
   echo control_files=$control_files
   
   if [[ -z $control_files ]]; then echo "ERROR couldn't parse controlfiles"; exit; fi
   echo "Note that some errors are ignored in the below ASM commands."
   echo "Signficant errors, if any, will be caught if RMAN fails later."
   echo RAO3=$RAO3
   cat <<EOF > $RAO3
      export ORACLE_SID=$(ps -ef|grep [p]mon_+ASM | sed 's|.*+|+|')
      echo ORACLE_SID for ASM=\$ORACLE_SID
      echo "$control_files" | tr ' ' '\n' | \
          sed '/^$/d; s|/[^/]*\..*||;
               h
               s|/[^/]*$||;
               s|^|mkdir |;
               p
               g
               s|^|mkdir |' | sort -u > $LOG3_1
      cat $LOG3_1 | asmcmd -p 2>&1 | tee $LOG3
EOF

   touch $RAO3 $LOG3_1 $LOG3
   chmod 775 $RAO3 $LOG3_1 $LOG3
   echo \" . ~/.bash_profile; $RAO3\" | (cd /tmp; sudo -u grid ksh)
   #echo "Do this as your admin user in another window:"
   #echo "    echo \" . ~/.bash_profile; $RAO3\" | (cd /tmp; sudo -u grid ksh)"
   #echo "Press enter in this window once it is complete."
   #read pause

   echo cat $LOG3_1
   cat $LOG3_1
   cp $LOG3_1 $LOG_DIR

   # HACK, test this in 11g
   if grep "asmcmd: diskgroup '.*' does not exist or is not mounted" $LOG3; then
      missingdiskgroup=$(
         sed "/asmcmd: diskgroup '.*' does not exist or is not mounted/!d
            s|.* '||;s|'.*||" $LOG3 | sort -u)
      echo missingdiskgroup=$missingdiskgroup
      if [[ $missingdiskgroup == *\ * ]]; then
         echo "ERROR: only one missing diskgroup can be handled by this script"
         echo "       Please manually set the diskgroups for the controlfiles"
         echo "       by modifying the spfile in ASM.  Use these command:"
         echo "          alter system set controlfile='<+newdiskgroup>/<path>/<confttrolfile1>,<+newdiskgroup>/<path>/<confttrolfile2>,<+newdiskgroup>/<path>/<confttrolfile3';"
         echo "       where <controlfileX> is seen with this command:"
         echo "       strings /tmp/rman/spfile.ora | grep -i controlfiles"
         exit 1
      fi
      
      echo RAO3a=$RAO3a
      cat <<EOF > $RAO3a
         export ORACLE_SID=$(ps -ef|grep [p]mon_+ASM | sed 's|.*+|+|')
         echo ORACLE_SID for ASM=\$ORACLE_SID
         # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
         . /home/oracle/system/oraenv.usfs >/dev/null 2>&1
         PATH=\$ORACLE_HOME/bin:\$PATH
         export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
         echo 'select NAME, FREE_MB, TOTAL_MB from V\$ASM_DISKGROUP;' > $LOG3a_1
         cat $LOG3a_1 | sqlplus -s / as sysdba 2>&1 | tee $LOG3a
EOF
   
      chmod 700 $RAO3a
      ksh $RAO3a
   
      echo
      echo
      echo "The above are the Diskgroups in this RAC cluster"
      echo "The '$missingdiskgroup' diskgroup is missing"
      echo "Enter the name of a substitute disk group: "
      read newdiskgroup
   
      #set -x
      export cnt=1
      # grep -v 'alter system set control_files' | \
      echo RAO3b=$RAO3b
      cat <<EOF > $RAO3b
         # Note ORACLE_SID is inherited
         echo ORACLE_SID=\$ORACLE_SID
         # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
         . /home/oracle/system/oraenv.usfs
         PATH=\$ORACLE_HOME/bin:\$PATH
         export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
         echo "set echo on" > $LOG3b_1
         strings $TMP/spfile$DB_NAME.ora | grep + | \
            sed "s|+$missingdiskgroup|+$newdiskgroup|;s|^\*\.||;s|^|alter system set |;
                 s|$| scope=spfile;|;s|/.*'|'|" >> $LOG3b_1
         # echo "alter system set control_files='+RACDB_DATAGRP/labdb/controlfile/current.256.651443005' scope=spfile;
         echo "shutdown abort
         quit" >> $LOG3b_1
         sqlplus "/ as sysdba"  @$LOG3b_1 2>&1 | tee $LOG3b
EOF
   
      chmod 700 $RAO3b
      ksh $RAO3b
   fi
fi # End of RAC (as opposed to Stand-Alone) spfile restore


# Restore the controlfiles
umask 077
cat > $RAO4 <<EOF2
#set -x
  export ORACLE_SID=$ORACLE_SID
  echo "ORACLE_SID=\$ORACLE_SID"
  export PFILE=$PFILE
  echo "PFILE=\$PFILE"

  export NLS_LANG=american
  export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'
  # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
  . /home/oracle/system/oraenv.usfs
  PATH=\$ORACLE_HOME/bin:\$PATH
  export TNS_ADMIN=/home/oracle/system/rman/admin.wallet


  if [[ -n "\$PFILE" ]]; then
    pfilecmd="pfile=$PFILE"
  fi

  echo "
     $DBID_CMD
     connect target /
     shutdown immediate
     startup nomount \$pfilecmd
     run {
        $ALLOCATE_SBT_CHANNELS

        $set_until

        restore controlfile;

        $RELEASE_CHANNEL
     }
     " > $RAO4_1
     echo "== Restore controlfile"
     rman catalog /@\$RMAN_CATALOG cmdfile=$RAO4_1 2>&1 | tee -a $LOG4
     #echo -e "startup force nomount;\nalter system set control_files='${ORACLE_HOME}/dbs/cntrl${ORACLE_SID}.dbf' scope=spfile;" | sqlplus "/ as sysdba"
     echo "startup force nomount;" | sqlplus "/ as sysdba"
     echo -e "show parameter spfile\nshow parameter control_f" | sqlplus "/ as sysdba" | tee $LOG4_3
EOF2

chmod 700 $RAO4
chown oracle:dba $RAO4
ksh $RAO4

echo LOG1=$LOG1
if ! egrep "ORA-|STACK" $LOG1 $LOG4 $LOG1_3 $LOG4_3 > /dev/null; then
   echo "SCRIPT SUCCESSFULLY COMPLETED."
   exit 0
else
   echo "Errors encountered."
   exit 1
fi
