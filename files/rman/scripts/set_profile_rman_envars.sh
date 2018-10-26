#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/set_profile_rman_envars.sh, ora, build6_1, build6_1a,1.2:9/6/11:13:27:05
#  VERSION:  1.2
#  DATE:  9/6/11:13:27:05
#
#  (C) COPYRIGHT International Business Machines Corp. 2003
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose: 
#    Move RMAN_CATALOG envar from /home/root/.bash_profile to /home/oracle/.bash_profile
#    Appends "RMAN_SCHEMA=rcat<version>" to /home/oracle/.bash_profile
#

TAB=$(echo -e "\t")
parm='RMAN_CATALOG'

o_file=/home/oracle/.bash_profile
o_cnt=$(grep "^[ $TAB]*export[ $TAB]*${parm}=[^ $TAB]*" $o_file | wc -l)

if (( $o_cnt == 0 )); then
   echo "ERROR: expecting RMAN_CATALOG to be in $o_file"
   exit 1
fi


file=/home/oracle/.bash_profile
export FS615_ORATAB=/etc/oratab
[[ $(uname) == "SunOS" ]] && export FS615_ORATAB=/var/opt/oracle/oratab

# First, define the function modify_ora_parameter_file that will be used
# to modify the Oracle initialization file.
# Suggestion: Two lines down, shouldn't this just be file=$INIT_FILE7
# since $INIT_FILE7 has
# already been defined?  Also, can't dest_dir simply be dirname of $INIT_FILE7?
export file=/home/oracle/.bash_profile
export dest_dir=/home/oracle
# Requires: dest_dir, file, parm, parm_value, step_num, sub_step
function modify_ora_parameter_file
{
   cd $dest_dir || exit 1
   export unfinished_file=$file.unfinished
   save_sub_step=$sub_step
   if [[ -f $file ]]; then
      touch $unfinished_file || exit 1
      (( sub_step = sub_step + 1 ))
      print "Step $step_num.$sub_step - Removing old  $parm"
      TAB=$(echo -e "\t")
      cnt=$(grep "^[ $TAB]*${parm}[ $TAB]*=[ $TAB]*" $file | wc -l )
      if ((cnt>0)); then
         (( sub_step = sub_step + 1 ))
         print "Step $step_num.$sub_step - replacing existing $parm"
         sed \
           "s|\(^[ $TAB]*${parm}[ $TAB]*=[ $TAB]*\).*|\1${parm_value}|" \
           $file > $unfinished_file || exit 1
         (( sub_step = sub_step + 1 ))
         print "Step $step_num.$sub_step - unused step"
      else
         (( sub_step = sub_step + 1 ))
         print "Step $step_num.$sub_step - unused step"
         (( sub_step = sub_step + 1 ))
         print "Step $step_num.$sub_step - appending new $parm"
         echo "${parm}=${parm_value}" | cat $file - > $unfinished_file \
            || exit 1
      fi
      cp $unfinished_file $file || exit 1
      rm $unfinished_file || exit 1
   fi
   sub_step=$save_sub_step
}

#================================================================
# Issue an error message and exit with the specified return code
#================================================================
function error_exit
{
  echo "  ERROR $2" | tee -a $LOG
  exit $1
}

DOMAIN=$( host $(hostname) | sed 's|[^\.]*\.||;s|\..*||')

function set_envar_NEW_RMAN_SCHEMA
{
   export CEMUTLO=$(find $(find /opt/grid -type d -name bin 2> /dev/null) -name cemutlo 2> /dev/null | head -1)
   export CLUSTER_NAME=$(ksh "$CEMUTLO -n" | tr '-' '_')
   cnt=$(echo $CLUSTER_NAME | wc -w)
   if ((cnt==0)); then
      export NEW_RMAN_SCHEMA="rcat_${DOMAIN}_$(hostname)"
   elif ((cnt==1)); then
      export NEW_RMAN_SCHEMA="rcat_${DOMAIN}_$CLUSTER_NAME"
   else
      echo "ERROR: could not determine the clustername" | tee -a $LOG
   fi
   echo ".. NEW_RMAN_SCHEMA=$NEW_RMAN_SCHEMA" | tee -a $LOG
}


set_envar_NEW_RMAN_SCHEMA

# Now, execute the function defined above to modify the initialization file
export step_num=50.1.0.0
export parm="export RMAN_SCHEMA"
export parm_value=$NEW_RMAN_SCHEMA
print "Step $step_num   - Changing compatible $parm_value"
print "Step $step_num.1 - Backing up $file"
export sub_step=1
modify_ora_parameter_file  # function


