#!/bin/bash
################################################################################
# File   : /usr/local/bin/puppet_oraverify.sh
# Author : matthewparker
# Date   : October 31, 2017
# Version: 2.0
# Purpose: This is the verification utility for the Oracle Platform
#          puppet module. This is used by the OPS/eDBA team to
#          verify that the puppet actions are performed as exepected.
# Command:
#          These are the commands for the Database and OEM Platform.
#
#          /usr/local/bin/puppet_oraverify.sh platform sum
#          /usr/local/bin/puppet_oraverify.sh platform detail
#          /usr/local/bin/puppet_oraverify.sh bootstrap sum
#          /usr/local/bin/puppet_oraverify.sh bootstrap detail
#          /usr/local/bin/puppet_oraverify.sh prereqs sum
#          /usr/local/bin/puppet_oraverify.sh prereqs detail
#          /usr/local/bin/puppet_oraverify.sh postreqs sum
#          /usr/local/bin/puppet_oraverify.sh postreqs detail
#          /usr/local/bin/puppet_oraverify.sh oem sum
#          /usr/local/bin/puppet_oraverify.sh oem detail
#          /usr/local/bin/puppet_oraverify.sh orahome sum
#          /usr/local/bin/puppet_oraverify.sh orahome detail
#          /usr/local/bin/puppet_oraverify.sh oradb sum
#          /usr/local/bin/puppet_oraverify.sh oradb detail
#          /usr/local/bin/puppet_oraverify.sh orabasic sum
#          /usr/local/bin/puppet_oraverify.sh orabasic detail
#          /usr/local/bin/puppet_oraverify.sh oraall sum
#          /usr/local/bin/puppet_oraverify.sh oraall detail
#          /usr/local/bin/puppet_oraverify.sh extfact sum
#          /usr/local/bin/puppet_oraverify.sh extfact detail
#          /usr/local/bin/puppet_oraverify.sh intfact sum
#          /usr/local/bin/puppet_oraverify.sh intfact detail
#          /usr/local/bin/puppet_oraverify.sh puppet
#          /usr/local/bin/puppet_oraverify.sh help
#          /usr/local/bin/puppet_oraverify.sh
#
#Column Display Width For Reports Are 140 characters.
#Line Display Buffer Length For Reports Are 5000 lines.
#
################################################################################


########################################
# VERIFY RUNNING AS ROOT
########################################
if [[ $EUID -ne 0 ]] ; then
 echo "This script must be run with root permissions" 1>&2
 exit 1
fi


############################################################
# Color Initialization
############################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

############################################################
# GLOBAL VARIABLES
############################################################

ORA_PLATFORM=`/bin/cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep 'ora_platform' | awk -F ' ' '{print $2}' | sed "s/'//g" | sed "s/\r//"`

########################################
# PUPPET
########################################

puppet_verification_total=0
puppet_verification_pass=0
puppet_verification_fail=0


########################################
# BOOTSTRAP
########################################

ora_bootstrap_verification_total=0
ora_bootstrap_verification_pass=0
ora_bootstrap_verification_fail=0


########################################
# PREREQS
########################################

linux_ora_os_file_verification_total=0
linux_ora_os_file_verification_pass=0
linux_ora_os_file_verification_fail=0

linux_ora_pkg_verification_total=0
linux_ora_pkg_verification_pass=0
linux_ora_pkg_verification_fail=0

linux_ora_os_groups_verification_total=0
linux_ora_os_groups_verification_pass=0
linux_ora_os_groups_verification_fail=0

linux_ora_os_users_verification_total=0
linux_ora_os_users_verification_pass=0
linux_ora_os_users_verification_fail=0

linux_ora_os_verification_total=0
linux_ora_os_verification_pass=0
linux_ora_os_verification_fail=0

ora_setup_verification_total=0
ora_setup_verification_pass=0
ora_setup_verification_fail=0


########################################
# POSTREQS
########################################

full_export_scripts_verification_total=0
full_export_scripts_verification_pass=0
full_export_scripts_verification_fail=0

bash_profile_verification_total=0
bash_profile_verification_pass=0
bash_profile_verification_fail=0

db_maintenance_scripts_verification_total=0
db_maintenance_scripts_verification_pass=0
db_maintenance_scripts_verification_fail=0


########################################
# ORAHOME
########################################

sw_verification_total=0
sw_verification_pass=0
sw_verification_fail=0

home_patch_verification_total=0
home_patch_verification_pass=0
home_patch_verification_fail=0

listener_verification_total=0
listener_verification_pass=0
listener_verification_fail=0


########################################
# ORADB
########################################

db_verification_total=0
db_verification_pass=0
db_verification_fail=0

dbint_verification_total=0
dbint_verification_pass=0
dbint_verification_fail=0


########################################
# EXTFACT
########################################

extfact_verification_total=0
extfact_verification_pass=0
extfact_verification_fail=0

########################################
# INTFACT
########################################

intfact_verification_total=0
intfact_verification_pass=0
intfact_verification_fail=0

############################################################
# PLATFORM
############################################################

########################################
# oraverify
########################################

oraverify () {

########################################
# VERIFY TWO INPUT PARAMETERS
########################################
if [[ $1 == 'help' ]] || [[ $# -ne 2 ]] ; then
 help_display
 exit 1
fi

if [[ $1 = 'platform' ]] || [[ $1 = 'bootstrap' ]] ; then

 ora_bootstrap_verification "$@"

fi

if [[ $1 = 'platform' ]] || [[ $1 = 'prereqs' ]] || [[ $1 = 'oem' ]] ; then

 linux_ora_os_file_verification "$@"
 linux_ora_os_groups_verification "$@"
 linux_ora_os_users_verification "$@"
 linux_ora_os_verification "$@"
 linux_ora_pkg_verification "$@"
 ora_setup_verification "$@"

fi

if [[ $1 = 'platform' ]] || [[ $1 = 'postreqs' ]] ; then

 full_export_scripts_verification "$@"
 bash_profile_verification "$@"
 db_maintenance_scripts_verification "$@"

fi

if [[ $1 = 'platform' ]] || [[ $1 = 'orahome' ]] ; then

 sw_verification "$@"
 home_patch_verification "$@"
 listener_verification "$@"

fi

if [[ $1 = 'platform' ]] || [[ $1 = 'oradb' ]] ; then

 dbint_verification "$@"
 db_verification "$@"

fi

if [[ $1 = 'orabasic' ]] ; then

 sw_verification "$@"
 home_patch_verification "$@"
 db_verification "$@"

fi

if [[ $1 = 'oraall' ]] ; then

 sw_verification "$@"
 home_patch_verification "$@"
 listener_verification "$@"
 dbint_verification "$@"
 db_verification "$@"

fi

if [[ $1 = 'oem' ]] ; then

 bash_profile_verification "$@"

fi

if [[ $1 = 'platform' ]] || [[ $1 = 'puppet' ]] ; then

 puppet_verification "$@"

fi


if [[ $1 = 'platform' ]] || [[ $1 = 'extfact' ]] ; then

 extfact_verification "$@"

fi

if [[ $1 = 'platform' ]] || [[ $1 = 'intfact' ]] ; then

 intfact_verification "$@"

fi

# END main
}


############################################################
# INTERNAL FUNCTIONS
############################################################

printf_repeat () {
 str5=$1
 num5=$2
 v=$(printf "%-${num5}s" "$str5")
 echo "${v// /$str5}"
}

printf_cjust () {
 str=$1
 num=$2
 str2="#"
 size=${#str}
 if (( size % 2 )); then
  addsize=1
 else
  addsize=0
 fi
 s=`printf "%*s\n" $((((size+($num-2))/2)+1)) "$str"`
 t=`printf "%*s\n" $((((($num-2)-size)/2)+addsize)) "$str2"`
echo -e "#$s$t"
}

printf_cjust_color () {
 str=$1
 num=$2
 if [ "$3" = "RED" ] ; then
  color=${RED}
 elif [ "$3" = "YELLOW" ] ; then
  color=${YELLOW}
 elif [ "$3" = "GREEN" ] ; then
  color=${GREEN}
 else
  color=${NC}
 fi
 str2="#"
 size=${#str}
 if (( size % 2 )); then
  addsize=1
 else
  addsize=0
 fi
 s=`printf "%*s\n" $((((size+($num-2))/2)+1)) "$str"`
 t=`printf "%*s\n" $((((($num-2)-size)/2)+addsize)) "$str2"`
echo -e "#$color$s${NC}$t"
}

printf_header1 () {
 str10=$1
 str11=$2
 printf_repeat "#" 140
 printf_cjust "DETAIL" 140
 printf_cjust "${str10}" 140
 printf_repeat "#" 140
 echo -e "#`printf " %-54s" "VERIFY ACTION"`#`printf " %-72s" "${str11}"`# STATUS #"
 printf_repeat "#" 140
}

printf_header2 () {
 str12=$1
 printf_repeat "#" 140
 printf_cjust "DETAIL" 140
 printf_cjust "${str12}" 140
 printf_repeat "#" 140
 echo -e "#`printf " %-128s" "VERIFY ACTION"`# STATUS #"
 printf_repeat "#" 140
}

printf_header3 () {
 str13=$1
 printf_repeat "#" 140
 printf_cjust "${str13}" 140
}

printf_summary () {
str1=$1
num1=$2
num2=$3
printf_repeat "#" 60
printf_cjust "SUMMARY" 60
printf_cjust "${str1}" 60
printf_repeat "#" 60
echo -e "${GREEN}#`printf " %-57s" "TOTAL SPECS PASSED                     : ${num1-0}"`#${NC}"
if [[ "$(($num2))" = "0" ]] ; then
 echo -e "${GREEN}#`printf " %-57s" "TOTAL SPECS FAILED                     : ${num2-0}"`#${NC}"
else
 echo -e "${RED}#`printf " %-57s" "TOTAL SPECS FAILED                     : ${num2-0}"`#${NC}"
fi
echo -e "#`printf " %-57s" "TOTAL SPECS TO ENFORCE                 : $((${num1-0}+${num2-0}))"`#"
if [[ "$((${num1-0}+${num2-0}))" = "0" ]] ; then
 echo -e "${NC}#`printf " %-57s" "PERCENTAGE OF SPECS ENFORCED           : 0.00%"`#${NC}"
elif [[ "`echo "scale=2;(${num1-0}/(${num1-0}+${num2-0}))*100" | bc -l`" = 100.00 ]] ; then
 num9=`echo "scale=2;(${num1-0}/(${num1-0}+${num2-0}))*100" | bc -l`
 echo -e "${GREEN}#`printf " %-57s" "PERCENTAGE OF SPECS ENFORCED           : ${num9}%"`#${NC}"
else
  num9=`printf %.2f $(echo "((${num1-0})/(${num1-0}+${num2-0}))*100" | bc -l)`
# num9=`echo "scale=2;(${num1-0}/(${num1-0}+${num2-0}))*100" | bc -l`
 echo -e "${RED}#`printf " %-57s" "PERCENTAGE OF SPECS ENFORCED           : ${num9}%"`#${NC}"
fi
printf_repeat "#" 60
}

############################################################
# BOOTSTRAP
############################################################

########################################
# ora_bootstrap_verification
########################################

ora_bootstrap_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
 printf_header1 "BOOTSTRAP FILES TO VERIFY" "FILE TO VERIFY"
fi

if [ -f /usr/local/bin/puppet_admin.sh ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/usr/local/bin/puppet_admin.sh"`# PASS   #${NC}"

 fi
 ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+1))
 if [ $(sha256sum /usr/local/bin/puppet_admin.sh | awk '{print $1}') = 'facfc3a89f0b7b6bc1d505da3f08d9aabb9cdafa51a2596bb217eee3e027fbf1' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/usr/local/bin/puppet_admin.sh"`# PASS   #${NC}"
  fi
  ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/usr/local/bin/puppet_admin.sh"`# FAIL   #${NC}"
  fi
  ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+1))
 fi
 #
 if [ ! $(stat -c %a:%U:%G /usr/local/bin/puppet_admin.sh) = '754:root:root' ] ; then
  if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/usr/local/bin/puppet_admin.sh"`# FAIL   #${NC}"
  fi
  ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+5))
 else
  if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/usr/local/bin/puppet_admin.sh"`# PASS   #${NC}"
  fi
  ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+5))
 fi
else
 if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/usr/local/bin/puppet_admin.sh"`# FAIL   #${NC}"
 fi
 ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+7))
fi


if [ -f /usr/local/bin/puppet_oraverify.sh ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/usr/local/bin/puppet_oraverify.sh"`# PASS   #${NC}"
 fi
 ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+1))
 if [ $(/bin/cat /usr/local/bin/puppet_oraverify.sh | grep -v '##~DO NOT REMOVE THIS~##' | sha256sum | awk '{print $1}') = 'dd37a6a0b53acb5414cfd8243bd67e2eb0c5ddc3f295a5382ba61850fe6da17c' ] ; then ##~DO NOT REMOVE THIS~##
  if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/usr/local/bin/puppet_oraverify.sh"`# PASS   #${NC}"
  fi
  ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /usr/local/bin/puppet_oraverify.sh) = '754:root:root' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/usr/local/bin/puppet_oraverify.sh"`# FAIL   #${NC}"
   fi
   ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/usr/local/bin/puppet_oraverify.sh"`# PASS   #${NC}"
   fi
   ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/usr/local/bin/puppet_oraverify.sh"`# FAIL   #${NC}"
  fi
  ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/usr/local/bin/puppet_oraverify.sh"`# FAIL   #${NC}"
 fi
 ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+7))
fi
#
#
if [ -f /usr/local/bin/sql/dbint_verification.sql ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/usr/local/bin/sql/dbint_verification.sql"`# PASS   #${NC}"
 fi
 ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+1))
 if [ $(sha256sum /usr/local/bin/sql/dbint_verification.sql | awk '{print $1}') = 'afdeeda444c9b56c8ea9f8871abd0681e2eb969e711eb40e9b9cf36934456292' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/usr/local/bin/sql/dbint_verification.sql"`# PASS   #${NC}"
  fi
  ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /usr/local/bin/sql/dbint_verification.sql) = '754:root:root' ] ; then
   if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/usr/local/bin/sql/dbint_verification.sql"`# FAIL   #${NC}"
   fi
   ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+3))
  else
   if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/usr/local/bin/sql/dbint_verification.sql"`# PASS   #${NC}"
   fi
   ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+3))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/usr/local/bin/sql/dbint_verification.sql"`# FAIL   #${NC}"
  fi
  ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/usr/local/bin/sql/dbint_verification.sql"`# FAIL   #${NC}"
 fi
 ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+5))
fi
#
#
if [ -f /etc/sudoers.d/ora_puppet_perm ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/sudoers.d/ora_puppet_perm"`# PASS   #${NC}"
 fi
 ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+1))
 if [ $(sha256sum /etc/sudoers.d/ora_puppet_perm | awk '{print $1}') = '9158a55721c088bf8b92caca0449944f9ae9a3173d1fcd1d8809a48d7a729e68' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/sudoers.d/ora_puppet_perm"`# PASS   #${NC}"
  fi
  ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /etc/sudoers.d/ora_puppet_perm) = '644:root:root' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/sudoers.d/ora_puppet_perm"`# FAIL   #${NC}"
   fi
   ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/sudoers.d/ora_puppet_perm"`# PASS   #${NC}"
   fi
   ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/sudoers.d/ora_puppet_perm"`# FAIL   #${NC}"
  fi
  ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/sudoers.d/ora_puppet_perm"`# FAIL   #${NC}"
 fi
 ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+7))
fi

YAML_FILE="/opt/puppetlabs/facter/facts.d/"$(hostname -f)".yaml"

if [ -f $YAML_FILE ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" $YAML_FILE`# PASS   #${NC}"
 fi
 ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+1))
 if [ ! $(stat -c %a:%U:%G $YAML_FILE) = '644:root:root' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" $YAML_FILE`# FAIL   #${NC}"
  fi
  ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" $YAML_FILE`# PASS   #${NC}"
  fi
  ora_bootstrap_verification_pass=$((ora_bootstrap_verification_pass+5))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" $YAML_FILE`# FAIL   #${NC}"
 fi
 ora_bootstrap_verification_fail=$((ora_bootstrap_verification_fail+6))
fi

if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "BOOTSTRAP FILES TO VERIFY" $ora_bootstrap_verification_pass $ora_bootstrap_verification_fail

# END ora_bootstrap_verification
}


############################################################
# PREREQS
############################################################

########################################
# linux_ora_os_file_verification
########################################
linux_ora_os_file_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 "KERNEL FILES TO VERIFY" "FILE/VALUE TO VERIFY"
fi

if [ -f /etc/inittab ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/inittab"`# PASS   #${NC}"
 fi
 linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 if [ ! $(stat -c %a:%U:%G /etc/inittab) = '644:root:root' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/inittab"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/inittab"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
 fi
else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/inittab"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+6))
fi


if [ -f /etc/sudoers.d/oracle_perm_temp ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Non Existence"`#`printf " %-72s" "/etc/sudoers.d/oracle_perm_temp"`# FAIL   #${NC}"
 fi
 linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Non Existence"`#`printf " %-72s" "/etc/sudoers.d/oracle_perm_temp"`# PASS   #${NC}"
 fi
 linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
fi


if [ $ORA_PLATFORM = 'oem' ] ; then
 if [ -f /etc/sudoers.d/oracle_oms ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/sudoers.d/oracle_oms"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
  if [ $(sha256sum /etc/sudoers.d/oracle_oms | awk '{print $1}') = '60980cc9b6f8ffd929968a57fc481473b6ea7be76c37c0aea6b1a9c5c3eb096b' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/sudoers.d/oracle_oms"`# PASS   #${NC}"
   fi
   linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
   if [ ! $(stat -c %a:%U:%G /etc/sudoers.d/oracle_oms) = '644:root:root' ] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/sudoers.d/oracle_oms"`# FAIL   #${NC}"
    fi
    linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
   else
    if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/sudoers.d/oracle_oms"`# PASS   #${NC}"
    fi
    linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
   fi
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/sudoers.d/oracle_oms"`# FAIL   #${NC}"
   fi
   linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/sudoers.d/oracle_oms"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+7))
 fi

 if [ -f /home/oracle/cleanup/scripts/cleanup.sh ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/home/oracle/cleanup/scripts/cleanup.sh"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
  if [ $(sha256sum /home/oracle/cleanup/scripts/cleanup.sh | awk '{print $1}') = 'da018cff14ff8b639daf932bc944bb8a3ee0f0d1ff3b2f1086b90ee45a1dc747' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/home/oracle/cleanup/scripts/cleanup.sh"`# PASS   #${NC}"
   fi
   linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
   if [ ! $(stat -c %a:%U:%G /home/oracle/cleanup/scripts/cleanup.sh) = '755:oracle:oinstall' ] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/home/oracle/cleanup/scripts/cleanup.sh"`# FAIL   #${NC}"
    fi
    linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
   else
    if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/home/oracle/cleanup/scripts/cleanup.sh"`# PASS   #${NC}"
    fi
    linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
   fi
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/home/oracle/cleanup/scripts/cleanup.sh"`# FAIL   #${NC}"
   fi
   linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/home/oracle/cleanup/scripts/cleanup.sh"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+7))
 fi

 if [[ $(crontab -u oracle -l | grep "0 5 \* \* \* /home/oracle/cleanup/scripts/cleanup.sh > /home/oracle/cleanup/logs/cleanup.log 2>&1") = "0 5 * * * /home/oracle/cleanup/scripts/cleanup.sh > /home/oracle/cleanup/logs/cleanup.log 2>&1" ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Cron Entry Existence"`#`printf " %-72s" "/home/oracle/cleanup/scripts/cleanup.sh"`# PASS   #${NC}"
  fi
  full_export_scripts_verification_pass=$((full_export_scripts_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Cron Entry Existence"`#`printf " %-72s" "/home/oracle/cleanup/scripts/cleanup.sh"`# FAIL   #${NC}"
  fi
  full_export_scripts_verification_fail=$((full_export_scripts_verification_fail+5))
 fi

fi


if [ -f /etc/postfix/main.cf ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/postfix/main.cf"`# PASS   #${NC}"
 fi
 linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 if [ ! $(stat -c %a:%U:%G /etc/postfix/main.cf) = '644:root:root' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/postfix/main.cf"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/postfix/main.cf"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5 ))
 fi
 #
 if [ `/bin/cat /etc/postfix/main.cf | grep inet_protocols | awk -F= '{print $2}' | awk '{$1=$1;print}' | sed "s/\r//"` = 'ipv4' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "/etc/postfix/main.cf Value inet_protocols"`#`printf " %-72s" "ipv4"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1 ))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "/etc/postfix/main.cf Value inet_protocols"`#`printf " %-72s" "ipv4"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 #
 if [ `/bin/cat /etc/postfix/main.cf | grep relayhost | grep smtp | awk -F= '{print $2}' | awk '{$1=$1;print}' | sed "s/\r//"` = '[smtp.fs.usda.gov]' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "/etc/postfix/main.cf Value relayhost"`#`printf " %-72s" "[smtp.fs.usda.gov]"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1 ))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "/etc/postfix/main.cf Value relayhost"`#`printf " %-72s" "[smtp.fs.usda.gov]"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/postfix/main.cf"`# FAIL   #${NC}"
 fi
 linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+8))
fi

if [ -f /etc/profile.d/oracle.sh ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/profile.d/oracle.sh"`# PASS   #${NC}"
 fi
 linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 if [ $(sha256sum /etc/profile.d/oracle.sh | awk '{print $1}') = '6d30236380d93753e025d8adf5245e3e135aa5c3c109c08d6292d82bdfa39a80' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/profile.d/oracle.sh"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /etc/profile.d/oracle.sh) = '755:root:root' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/profile.d/oracle.sh"`# FAIL   #${NC}"
   fi
   linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/profile.d/oracle.sh"`# PASS   #${NC}"
   fi
   linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/profile.d/oracle.sh"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/profile.d/oracle.sh"`# FAIL   #${NC}"
 fi
 linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+7))
fi


if [ -f /etc/init.d/dbora ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/init.d/dbora"`# PASS   #${NC}"
 fi
 linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 if [ $(sha256sum /etc/init.d/dbora | awk '{print $1}') = 'a0b24820a1f5521c08f403e09307e1d69a6243f0c78e88ef1085e277c5271bac' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/init.d/dbora"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /etc/init.d/dbora) = '750:root:root' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/init.d/dbora"`# FAIL   #${NC}"
   fi
   linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/init.d/dbora"`# PASS   #${NC}"
   fi
   linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/init.d/dbora"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/init.d/dbora"`# FAIL   #${NC}"
 fi
 linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+7))
fi


if [ ! $(chkconfig 2>/dev/null | grep dbora | awk '{print $1}') = 'dbora' ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Service Enabled"`#`printf " %-72s" "/etc/init.d/dbora"`# FAIL   #${NC}"
 fi
 linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Service Enabled"`#`printf " %-72s" "/etc/init.d/dbora"`# PASS   #${NC}"
 fi
 linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
fi


if [ -f /etc/oraInst.loc ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/oraInst.loc"`# PASS   #${NC}"
 fi
 linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 if [ $(sha256sum /etc/oraInst.loc | awk '{print $1}') = 'd060afba1643993b0b0170e30821c9e4c19d79fe82450f1cdc1bba0b141e734f' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/oraInst.loc"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /etc/oraInst.loc) = '664:oracle:oinstall' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/oraInst.loc"`# FAIL   #${NC}"
   fi
   linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/oraInst.loc"`# PASS   #${NC}"
   fi
   linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/oraInst.loc"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/oraInst.loc"`# FAIL   #${NC}"
 fi
 linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+7))
fi


if [ -f /etc/pam.d/emagent ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/pam.d/emagent"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 if [ $(sha256sum /etc/pam.d/emagent | awk '{print $1}') = '9348223a025b703db2efc46b1ea60e08e8d1073a569ae3e3cde7cd7f8f1b924a' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/pam.d/emagent"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /etc/pam.d/emagent) = '644:root:root' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/pam.d/emagent"`# FAIL   #${NC}"
   fi
   linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/pam.d/emagent"`# PASS   #${NC}"
   fi
   linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/pam.d/emagent"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/pam.d/emagent"`# FAIL   #${NC}"
 fi
 linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+7))
fi

##############################################
# /etc/sudoers.d/S_OEM-Deploy_perm
##############################################

if [ -f /etc/sudoers.d/S_OEM-Deploy_perm ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/sudoers.d/S_OEM-Deploy_perm"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 if [ $(sha256sum /etc/sudoers.d/S_OEM-Deploy_perm | awk '{print $1}') = 'e1b71a4de5f767badd92ec15b23155f767ff31cc3bae6d3b72e3c8ee674777e3' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/sudoers.d/S_OEM-Deploy_perm"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /etc/sudoers.d/S_OEM-Deploy_perm) = '644:root:root' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/sudoers.d/S_OEM-Deploy_perm"`# FAIL   #${NC}"
   fi
   linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/sudoers.d/S_OEM-Deploy_perm"`# PASS   #${NC}"
   fi
   linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/sudoers.d/S_OEM-Deploy_perm"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/sudoers.d/S_OEM-Deploy_perm"`# FAIL   #${NC}"
 fi
 linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+7))
fi

##############################################
# /etc/pam.d/su
##############################################
#
#if [ $(uname -r | awk -F '.' '{print $1"."$2}') = '2.6' -o $(uname -r | awk -F '.' '{print $1"."$2}') = '3.08' ] ; then
# SHA_SUM_SU='4b3453fc7cf569a05276218d72752cbfab77a57edb19fe9e8bbebc5e02f3e084'
# SHA_SUM_LOGIN='f051c61887dc68e205ada063e12df4c66f7f8e7c71abf39d8b5d370c1651765a'
#elif [ $(uname -r | awk -F '.' '{print $1"."$2}') = '3.10' -o $(uname -r | awk -F '.' '{print $1"."$2}') = '4.1' ] ; then
# SHA_SUM_SU='e046027ddc74dd6299188dc8c11a3a1d8f567e277abb4192e3ce86d142bb4e42'
# SHA_SUM_LOGIN='8472dd6eb0c199108a0dfb8cf099b90d73e2abc824b636fbe38f5c00f78509ca'
#fi
#
#if [ -f /etc/pam.d/su ] ; then
# if [[ "$2" = "detail" ]] ; then
#  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/pam.d/su"`# PASS   #${NC}"
# fi
# linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
# if [ $(sha256sum /etc/pam.d/su | awk '{print $1}') = $SHA_SUM_SU ] ; then
#  if [[ "$2" = "detail" ]] ; then
#   echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/pam.d/su"`# PASS   #${NC}"
#  fi
#  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
#  if [ ! $(stat -c %a:%U:%G /etc/pam.d/su) = '644:root:root' ] ; then
#   if [[ "$2" = "detail" ]] ; then
#    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/pam.d/su"`# FAIL   #${NC}"
#   fi
#   linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
#  else
#   if [[ "$2" = "detail" ]] ; then
#    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/pam.d/su"`# PASS   #${NC}"
#   fi
#   linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
#  fi
# else
#  if [[ "$2" = "detail" ]] ; then
#   echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/pam.d/su"`# FAIL   #${NC}"
#  fi
#  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
# fi
#else
# if [[ "$2" = "detail" ]] ; then
#  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/pam.d/su"`# FAIL   #${NC}"
# fi
# linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+7))
#fi

##############################################
# /etc/pam.d/login
##############################################

#if [ -f /etc/pam.d/login ] ; then
# if [[ "$2" = "detail" ]] ; then
#  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/pam.d/login"`# PASS   #${NC}"
# fi
# linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
# if [ $(sha256sum /etc/pam.d/login | awk '{print $1}') = $SHA_SUM_LOGIN ] ; then
#  if [[ "$2" = "detail" ]] ; then
#   echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/pam.d/login"`# PASS   #${NC}"
#  fi
#  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
#  if [ ! $(stat -c %a:%U:%G /etc/pam.d/login) = '644:root:root' ] ; then
#   if [[ "$2" = "detail" ]] ; then
#    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/pam.d/login"`# FAIL   #${NC}"
#   fi
#   linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
#  else
#   if [[ "$2" = "detail" ]] ; then
#    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/pam.d/login"`# PASS   #${NC}"
#   fi
#   linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
#  fi
# else
#  if [[ "$2" = "detail" ]] ; then
#   echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/etc/pam.d/login"`# FAIL   #${NC}"
#  fi
#  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
# fi
#else
#  if [[ "$2" = "detail" ]] ; then
#   echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/pam.d/login"`# FAIL   #${NC}"
#  fi
#  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+7))
#fi

##############################################
# /etc/security/limits.d/oracle.conf 
##############################################

if [ -f /etc/security/limits.d/oracle.conf ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/security/limits.d/oracle.conf"`# PASS   #${NC}"
 fi
 linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 #
 if [ ! $(stat -c %a:%U:%G /etc/security/limits.conf) = '644:root:root' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/security/limits.d/oracle.conf"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/etc/security/limits.d/oracle.conf"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
 fi
 #
 if [ `/bin/cat /etc/security/limits.d/oracle.conf | grep "oracle soft nproc" | awk '{print $4}'` = '2047' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "oracle.conf Value oracle soft nproc"`#`printf " %-72s" "2047"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "oracle.conf Value oracle soft nproc"`#`printf " %-72s" "2047"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
 fi
 #
 if [ `/bin/cat /etc/security/limits.d/oracle.conf | grep "oracle hard nproc" | awk '{print $4}'` = '16384' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "oracle.conf Value oracle hard nproc"`#`printf " %-72s" "16384"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "oracle.conf Value oracle hard nproc"`#`printf " %-72s" "16384"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
 fi
 #
 if [ `/bin/cat /etc/security/limits.d/oracle.conf | grep "oracle soft nofile" | awk '{print $4}'` = '1024' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "oracle.conf Value oracle soft nofile"`#`printf " %-72s" "1024"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "oracle.conf Value oracle soft nofile"`#`printf " %-72s" "1024"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
 fi
 #
 if [ `/bin/cat /etc/security/limits.d/oracle.conf | grep "oracle hard nofile" | awk '{print $4}'` = '65536' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "oracle.conf Value oracle hard nofile"`#`printf " %-72s" "65536"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "oracle.conf Value oracle hard nofile"`#`printf " %-72s" "65536"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
 fi
 #
 if [ `/bin/cat /etc/security/limits.d/oracle.conf | grep "oracle soft stack" | awk '{print $4}'` = '10240' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "oracle.conf Value oracle soft stack"`#`printf " %-72s" "10240"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "oracle.conf Value oracle soft stack"`#`printf " %-72s" "10240"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
 fi
 #
 if [ `/bin/cat /etc/security/limits.d/oracle.conf | grep "oracle hard stack" | awk '{print $4}'` = '32768' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "oracle.conf Value oracle hard stack"`#`printf " %-72s" "32768"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "oracle.conf Value oracle hard stack"`#`printf " %-72s" "32768"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
 fi
 #
 if [ `/bin/cat /etc/security/limits.d/oracle.conf | grep "oracle soft memlock" | awk '{print $4}'` = '3145728' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "oracle.conf Value oracle soft memlock"`#`printf " %-72s" "3145728"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "oracle.conf Value oracle soft memlock"`#`printf " %-72s" "3145728"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
 fi
 #
 if [ `/bin/cat /etc/security/limits.d/oracle.conf | grep "oracle hard memlock" | awk '{print $4}'` = '3145728' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "oracle.conf Value oracle hard memlock"`#`printf " %-72s" "3145728"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "oracle.conf Value oracle hard memlock"`#`printf " %-72s" "3145728"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+5))
 fi
 #
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/security/limits.d/oracle.conf"`# FAIL   #${NC}"
 fi
 linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+15))
fi

##############################################
# /etc/sysctl.d/99-z-oracle.conf
##############################################
if [ -f /etc/sysctl.d/99-z-oracle.conf ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Exists"`#`printf " %-72s" "/etc/sysctl.d/99-z-oracle.conf"`# PASS   #${NC}"
 fi
 linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 ###
 shmmni=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep kernel.shmmni | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 shmmni_mem=`/bin/cat /proc/sys/kernel/shmmni | awk '{$1=$1;print}'`
 if [[ '4096' = $shmmni ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value shmmni"`#`printf " %-72s" "${shmmni}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value shmmni"`#`printf " %-72s" "cur:${shmmni} tar:4096"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ '4096' = $shmmni_mem ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value shmmni"`#`printf " %-72s" "${shmmni_mem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value shmmni"`#`printf " %-72s" "cur:${shmmni_mem} tar:4096"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
 sem=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep kernel.sem | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 sem_mem=`/bin/cat /proc/sys/kernel/sem  | awk '{$1=$1;print}'`
 if [[ '250 32000 100 128' = $sem ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value sem"`#`printf " %-72s" "${sem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1)) 
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value sem"`#`printf " %-72s" "cur:${sem} tar:250 32000 100 128"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ '250 32000 100 128' = $sem_mem ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value sem"`#`printf " %-72s" "${sem_mem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value sem"`#`printf " %-72s" "cur:${sem_mem} tar:250 32000 100 128"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
 shmmax=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep kernel.shmmax | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 shmmaxcalc1=`/usr/local/bin/facter -p memory.system.total_bytes`
 shmmaxcalc2=`echo ${shmmaxcalc1}*3/4 | bc`
 shmmax_mem=`/bin/cat /proc/sys/kernel/shmmax | awk '{$1=$1;print}'`
 if [[ $shmmaxcalc2 = $shmmax ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value shmmax"`#`printf " %-72s" "${shmmax}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1)) 
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value shmmax"`#`printf " %-72s" "cur:${shmmax} tar:$shmmaxcalc2"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ $shmmaxcalc2 = $shmmax_mem ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value shmmax"`#`printf " %-72s" "${shmmax_mem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value shmmax"`#`printf " %-72s" "cur:${shmmax_mem} tar:$shmmaxcalc2"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
 shmall=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep kernel.shmall | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 shmallcalc1=`/usr/local/bin/facter -p memory.system.total_bytes`
 shmallcalc2=`echo ${shmallcalc1}/4096*3/4 | bc`
 shmall_mem=`/bin/cat /proc/sys/kernel/shmall | awk '{$1=$1;print}'`
 if [[ $shmallcalc2 = $shmall ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value shmall"`#`printf " %-72s" "${shmall}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1)) 
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value shmall"`#`printf " %-72s" "cur:${shmall} tar:$shmallcalc2"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ $shmallcalc2 = $shmall_mem ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value shmall"`#`printf " %-72s" "${shmall_mem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value shmall"`#`printf " %-72s" "cur:${shmall_mem} tar:$shmallcalc2"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
 file_max=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep fs.file-max | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 file_max_mem=`/bin/cat /proc/sys/fs/file-max  | awk '{$1=$1;print}'`
 if [[ '6815744' = ${file_max} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value file-max"`#`printf " %-72s" "${file_max}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1)) 
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value file-max"`#`printf " %-72s" "cur:${file_max} tar:6815744"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ '6815744' = ${file_max_mem} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value file-max"`#`printf " %-72s" "${file_max_mem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value file-max"`#`printf " %-72s" "cur:${file_max_mem} tar:6815744"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
 net_ipv4_ip_local_port_range=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep net.ipv4.ip_local_port_range | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 net_ipv4_ip_local_port_range_mem=`/bin/cat /proc/sys/net/ipv4/ip_local_port_range | awk '{$1=$1;print}'`
 if [[ '9000 65500' = ${net_ipv4_ip_local_port_range} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value net.ipv4.ip_local_port_range"`#`printf " %-72s" "${net_ipv4_ip_local_port_range}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1)) 
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value net.ipv4.ip_local_port_range"`#`printf " %-72s" "cur:${net_ipv4_ip_local_port_range} tar:9000 65500"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ '9000 65500' = ${net_ipv4_ip_local_port_range_mem} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value net.ipv4.ip_local_port_range"`#`printf " %-72s" "${net_ipv4_ip_local_port_range_mem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value net.ipv4.ip_local_port_range"`#`printf " %-72s" "cur:${net_ipv4_ip_local_port_range_mem} tar:9000 65500"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
 net_core_rmem_default=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep net.core.rmem_default | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 net_core_rmem_default_mem=`/bin/cat /proc/sys/net/core/rmem_default | awk '{$1=$1;print}'`
 if [[ '262144' = ${net_core_rmem_default} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value net.core.rmem_default"`#`printf " %-72s" "${net_core_rmem_default}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1)) 
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value net.core.rmem_default"`#`printf " %-72s" "cur:${net_core_rmem_default} tar:262144"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ '262144' = ${net_core_rmem_default_mem} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value net.core.rmem_default"`#`printf " %-72s" "${net_core_rmem_default_mem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value net.core.rmem_default"`#`printf " %-72s" "cur:${net_core_rmem_default_mem} tar:262144"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
 net_core_rmem_max=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep net.core.rmem_max | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 net_core_rmem_max_mem=`/bin/cat /proc/sys/net/core/rmem_max | awk '{$1=$1;print}'`
 if [[ '4194304' = ${net_core_rmem_max} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value net.core.rmem_max"`#`printf " %-72s" "${net_core_rmem_max}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1)) 
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value net.core.rmem_max"`#`printf " %-72s" "cur:${net_core_rmem_max} tar:4194304"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ '4194304' = ${net_core_rmem_max_mem} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value net.core.rmem_max"`#`printf " %-72s" "${net_core_rmem_max_mem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value net.core.rmem_max"`#`printf " %-72s" "cur:${net_core_rmem_max_mem} tar:4194304"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
 net_core_wmem_default=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep net.core.wmem_default | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 net_core_wmem_default_mem=`/bin/cat /proc/sys/net/core/wmem_default | awk '{$1=$1;print}'`
 if [[ '262144' = ${net_core_wmem_default} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value net.core.wmem_default"`#`printf " %-72s" "${net_core_wmem_default}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1)) 
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value net.core.wmem_default"`#`printf " %-72s" "cur:${net_core_wmem_default} tar:4194304"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ '262144' = ${net_core_wmem_default_mem} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value net.core.wmem_default"`#`printf " %-72s" "${net_core_wmem_default}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value net.core.wmem_default"`#`printf " %-72s" "cur:${net_core_wmem_default_mem} tar:4194304"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
 net_core_wmem_max=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep net.core.wmem_max | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 net_core_wmem_max_mem=`/bin/cat /proc/sys/net/core/wmem_max | awk '{$1=$1;print}'`
 if [[ '1048576' = ${net_core_wmem_max} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value net.core.wmem_max"`#`printf " %-72s" "${net_core_wmem_max}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1)) 
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value net.core.wmem_max"`#`printf " %-72s" "cur:${net_core_wmem_max} tar:1048576"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ '1048576' = ${net_core_wmem_max} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value net.core.wmem_max"`#`printf " %-72s" "${net_core_wmem_max_mem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value net.core.wmem_max"`#`printf " %-72s" "cur:${net_core_wmem_max_mem} tar:1048576"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
 fs_aio_max_nr=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep fs.aio-max-nr | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 fs_aio_max_nr_mem=`/bin/cat /proc/sys/fs/aio-max-nr | awk '{$1=$1;print}'`
 if [[ '1048576' = ${fs_aio_max_nr} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value fs.aio-max-nr"`#`printf " %-72s" "${fs_aio_max_nr}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1)) 
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value fs.aio-max-nr"`#`printf " %-72s" "cur:${fs_aio_max_nr} tar:1048576"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ '1048576' = ${fs_aio_max_nr_mem} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value fs.aio-max-nr"`#`printf " %-72s" "${fs_aio_max_nr_mem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value fs.aio-max-nr"`#`printf " %-72s" "cur:${fs_aio_max_nr_mem} tar:1048576"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
 kernel_panic_on_oops=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep kernel.panic_on_oops | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 kernel_panic_on_oops_mem=`/bin/cat /proc/sys/kernel/panic_on_oops | awk '{$1=$1;print}'`
 if [[ '1' = ${kernel_panic_on_oops} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value kernel.panic_on_oops"`#`printf " %-72s" "${kernel_panic_on_oops}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1)) 
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value kernel.panic_on_oops"`#`printf " %-72s" "${kernel_panic_on_oops} tar:1"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ '1' = ${kernel_panic_on_oops_mem} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value kernel.panic_on_oops"`#`printf " %-72s" "${kernel_panic_on_oops_mem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value kernel.panic_on_oops"`#`printf " %-72s" "cur:${kernel_panic_on_oops_mem} tar:1"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
 kernel_keys_maxbytes=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep kernel.keys.maxbytes | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 kernel_keys_maxbytes_mem=`/bin/cat /proc/sys/kernel/keys/maxbytes | awk '{$1=$1;print}'`
 if [[ '60000' = ${kernel_keys_maxbytes} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value kernel.keys.maxbytes"`#`printf " %-72s" "${kernel_keys_maxbytes}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1)) 
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value kernel.keys.maxbytes"`#`printf " %-72s" "cur:${kernel_keys_maxbytes} tar:60000"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ '60000' = ${kernel_keys_maxbytes_mem} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value kernel.keys.maxbytes"`#`printf " %-72s" "${kernel_keys_maxbytes_mem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value kernel.keys.maxbytes"`#`printf " %-72s" "cur:${kernel_keys_maxbytes_mem} tar:60000"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
 kernel_keys_maxkeys=`/bin/cat /etc/sysctl.d/99-z-oracle.conf | grep kernel.keys.maxkeys | awk -F= '{print $2}' | awk '{$1=$1;print}'`
 kernel_keys_maxkeys_mem=`/bin/cat /proc/sys/kernel/keys/maxkeys | awk '{$1=$1;print}'`
 if [[ '600' = ${kernel_keys_maxkeys} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "99-z-oracle.conf Value kernel.keys.maxkeys"`#`printf " %-72s" "${kernel_keys_maxkeys}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1)) 
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value kernel.keys.maxkeys"`#`printf " %-72s" "cur:${kernel_keys_maxkeys} tar:600"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 if [[ '600' = ${kernel_keys_maxkeys_mem} ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Memory Value kernel.keys.maxkeys"`#`printf " %-72s" "${kernel_keys_maxkeys_mem}"`# PASS   #${NC}"
  fi
  linux_ora_os_file_verification_pass=$((linux_ora_os_file_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Memory Value kernel.keys.maxkeys"`#`printf " %-72s" "cur:${kernel_keys_maxkeys_mem} tar:600"`# FAIL   #${NC}"
  fi
  linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+1))
 fi
 ###
else
  if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Exists"`#`printf " %-72s" "/etc/sysctl.d/99-z-oracle.conf"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value shmmni"`#`printf " %-72s" "cur:${shmmni} tar:4096"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value shmmni"`#`printf " %-72s" "cur:${shmmni} tar:4096"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value sem"`#`printf " %-72s" "cur:${sem} tar:250 32000 100 128"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value sem"`#`printf " %-72s" "cur:${sem} tar:250 32000 100 128"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value shmmax"`#`printf " %-72s" "cur:${shmmax} tar:$shmmaxcalc2"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value shmmax"`#`printf " %-72s" "cur:${shmmax} tar:$shmmaxcalc2"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value shmall"`#`printf " %-72s" "cur:${shmall} tar:$shmallcalc2"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value shmall"`#`printf " %-72s" "cur:${shmall} tar:$shmallcalc2"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value file-max"`#`printf " %-72s" "cur:${file_max} tar:6815744"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value file-max"`#`printf " %-72s" "cur:${file_max} tar:6815744"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value net.ipv4.ip_local_port_range"`#`printf " %-72s" "cur:${net_ipv4_ip_local_port_range} tar:9000 65500"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value net.ipv4.ip_local_port_range"`#`printf " %-72s" "cur:${net_ipv4_ip_local_port_range} tar:9000 65500"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value net.core.rmem_default"`#`printf " %-72s" "cur:${net_core_rmem_default} tar:262144"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value net.core.rmem_default"`#`printf " %-72s" "cur:${net_core_rmem_default} tar:262144"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value net.core.rmem_max"`#`printf " %-72s" "cur:${net_core_rmem_max} tar:4194304"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value net.core.rmem_max"`#`printf " %-72s" "cur:${net_core_rmem_max} tar:4194304"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value net.core.wmem_default"`#`printf " %-72s" "cur:${net_core_wmem_default} tar:n4194304"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value net.core.wmem_default"`#`printf " %-72s" "cur:${net_core_wmem_default} tar:n4194304"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value net.core.wmem_max"`#`printf " %-72s" "cur:${net_core_wmem_max} tar:1048576"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value net.core.wmem_max"`#`printf " %-72s" "cur:${net_core_wmem_max} tar:1048576"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value fs.aio-max-nr"`#`printf " %-72s" "cur:${fs_aio_max_nr} tar:1048576"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value fs.aio-max-nr"`#`printf " %-72s" "cur:${fs_aio_max_nr} tar:1048576"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value kernel.panic_on_oops"`#`printf " %-72s" "cur:${kernel_panic_on_oops} tar:1"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value kernel.panic_on_oops"`#`printf " %-72s" "cur:${kernel_panic_on_oops} tar:1"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value kernel.keys.maxbytes"`#`printf " %-72s" "cur:${kernel_keys_maxbytes} tar:60000"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value kernel.keys.maxbytes"`#`printf " %-72s" "cur:${kernel_keys_maxbytes} tar:60000"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "99-z-oracle.conf Value kernel.keys.maxkeys"`#`printf " %-72s" "cur:${kernel_keys_maxkeys} tar:600"`# FAIL   #${NC}"
    echo -e "${RED}#`printf " %-54s" "Memory Value kernel.keys.maxkeys"`#`printf " %-72s" "cur:${kernel_keys_maxkeys} tar:600"`# FAIL   #${NC}"
    linux_ora_os_file_verification_fail=$((linux_ora_os_file_verification_fail+29))
  fi
fi

if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "KERNEL FILES TO VERIFY" $linux_ora_os_file_verification_pass $linux_ora_os_file_verification_fail


# END linux_ora_os_file_verification
}


########################################
# linux_ora_pkg_verification
########################################

linux_ora_pkg_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 "KERNEL PACKAGES TO VERIFY" "PACKAGES TO VERIFY"
fi

HUMAN=`/usr/bin/who am i | awk '{print $1}' | sed 's/\n//'`

yum list installed  > /tmp/${HUMAN}rpms.list

VERSION=$(uname -r | awk -F . '{print $1"."$2 }')
if [ $VERSION = '2.6' -o $VERSION = '3.08' -o $VERSION = '3.10' -o $VERSION = '4.1' ] ; then
 RPM_LIST=(	bc.x86_64
                binutils.x86_64
                compat-libcap1.x86_64
                compat-libstdc++-33.i686
                compat-libstdc++-33.x86_64
                expect.x86_64
                gcc.x86_64
                gcc-c++.x86_64
                glibc.i686
                glibc.x86_64
                glibc-devel.i686
                glibc-devel.x86_64
                ksh.x86_64
                libaio.i686
                libaio.x86_64
                libaio-devel.i686
                libaio-devel.x86_64
                libgcc.i686
                libgcc.x86_64
                libstdc++.i686
                libstdc++.x86_64
                libstdc++-devel.i686
                libstdc++-devel.x86_64
                libvncserver.x86_64
                libXi.i686
                libXi.x86_64
                libXtst.i686
                libXtst.x86_64
                make.x86_64
                motif.x86_64
                motif-devel.x86_64
                pam_krb5.x86_64
                psmisc.x86_64
                redhat-lsb-core.x86_64
                sysstat.x86_64
                tigervnc.x86_64
                tigervnc-server.x86_64
                xorg-x11-apps.x86_64
                xorg-x11-utils.x86_64
                xterm.x86_64
		)
 for i in ${RPM_LIST[*]}
 do
  EXISTS=$(grep ^$i /tmp/${HUMAN}rpms.list | awk '{print $2 }' || echo '')
  rpmcurrent=`/bin/cat /tmp/${HUMAN}rpms.list | grep "^$i" | awk '{print $2 }'`
  rpmlatest=`yum list available $i --showduplicates | grep $i | awk END{print} | awk '{print $2 }'`
  if [ ! -z $EXISTS ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Package Installed"`#`printf " %-72s" "$i"`# PASS   #${NC}"
   fi
   linux_ora_pkg_verification_pass=$((linux_ora_pkg_verification_pass+1))
   if [[ $rpmcurrent = $rpmlatest ]] ; then
    if [[ "$2" = "detail" ]] ; then
      echo -e "${GREEN}#`printf " %-54s" "Package At Latest Version"`#`printf " %-72s" "$i: $rpmcurrent"`# PASS   #${NC}"
    fi
    linux_ora_pkg_verification_pass=$((linux_ora_pkg_verification_pass+1))
   else
    if [[ "$2" = "detail" ]] ; then
      echo -e "${RED}#`printf " %-54s" "Package At Latest Version"`#`printf " %-72s" "$i: cur:$rpmcurrent lat:$rpmlatest"`# FAIL   #${NC}"
    fi
    linux_ora_pkg_verification_fail=$((linux_ora_pkg_verification_fail+1))
   fi
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Package Installed"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
   fi
   linux_ora_pkg_verification_fail=$((linux_ora_pkg_verification_fail+1))
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Package At Latest Version"`#`printf " %-72s" "$i: $rpmcurrent"`# FAIL   #${NC}"
   fi
   linux_ora_pkg_verification_fail=$((linux_ora_pkg_verification_fail+1))
  fi
 done
fi

if [ $ORA_PLATFORM = 'oem' ] ; then
 RPM_LIST=( pam.x86_64
            glibc-common.x86_64
          )
 for i in ${RPM_LIST[*]}
 do
  EXISTS=$(grep ^$i /tmp/${HUMAN}rpms.list | awk '{print $2 }' || echo '')
  rpmcurrent=`/bin/cat /tmp/${HUMAN}rpms.list | grep "^$i" | awk '{print $2 }'`
  rpmlatest=`yum list available $i --showduplicates | grep $i | awk END{print} | awk '{print $2 }'`
  if [ ! -z $EXISTS ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Package Installed"`#`printf " %-72s" "$i"`# PASS   #${NC}"
   fi
   linux_ora_pkg_verification_pass=$((linux_ora_pkg_verification_pass+1))
   if [[ $rpmcurrent = $rpmlatest ]] ; then
    if [[ "$2" = "detail" ]] ; then
      echo -e "${GREEN}#`printf " %-54s" "Package At Latest Version"`#`printf " %-72s" "$i: $rpmcurrent"`# PASS   #${NC}"
    fi
    linux_ora_pkg_verification_pass=$((linux_ora_pkg_verification_pass+1))
   else
    if [[ "$2" = "detail" ]] ; then
      echo -e "${RED}#`printf " %-54s" "Package At Latest Version"`#`printf " %-72s" "$i: cur:$rpmcurrent lat:$rpmlatest"`# FAIL   #${NC}"
    fi
    linux_ora_pkg_verification_fail=$((linux_ora_pkg_verification_fail+1))
   fi
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Package Installed"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
   fi
   linux_ora_pkg_verification_fail=$((linux_ora_pkg_verification_fail+1))
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Package At Latest Version"`#`printf " %-72s" "$i: $rpmcurrent"`# FAIL   #${NC}"
   fi
   linux_ora_pkg_verification_fail=$((linux_ora_pkg_verification_fail+1))
  fi
 done
fi
###
if [ $ORA_PLATFORM = 'db' ] ; then
 RPM_LIST=(	libX11.i686
		libX11.x86_64
		libXau.i686
		libXau.x86_64
		libxcb.i686
		libxcb.x86_64
		net-tools.x86_64
		smartmontools.x86_64
		tigervnc-server-applet
		tigervnc-server-module
		)
 
for i in ${RPM_LIST[*]}
 do
  EXISTS=$(grep ^$i /tmp/${HUMAN}rpms.list | awk '{print $2 }' || echo '')
  rpmcurrent=`/bin/cat /tmp/${HUMAN}rpms.list | grep "^$i" | awk '{print $2 }'`
  rpmlatest=`yum list available $i --showduplicates | grep $i | awk END{print} | awk '{print $2 }'`
  if [ ! -z $EXISTS ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Package Installed"`#`printf " %-72s" "$i"`# PASS   #${NC}"
   fi
   linux_ora_pkg_verification_pass=$((linux_ora_pkg_verification_pass+1))
   if [[ $rpmcurrent = $rpmlatest ]] ; then
    if [[ "$2" = "detail" ]] ; then
      echo -e "${GREEN}#`printf " %-54s" "Package At Latest Version"`#`printf " %-72s" "$i: $rpmcurrent"`# PASS   #${NC}"
    fi
    linux_ora_pkg_verification_pass=$((linux_ora_pkg_verification_pass+1))
   else
    if [[ "$2" = "detail" ]] ; then
      echo -e "${RED}#`printf " %-54s" "Package At Latest Version"`#`printf " %-72s" "$i: cur:$rpmcurrent lat:$rpmlatest"`# FAIL   #${NC}"
    fi
    linux_ora_pkg_verification_fail=$((linux_ora_pkg_verification_fail+1))
   fi
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Package Installed"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
   fi
   linux_ora_pkg_verification_fail=$((linux_ora_pkg_verification_fail+1))
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Package At Latest Version"`#`printf " %-72s" "$i: $rpmcurrent"`# FAIL   #${NC}"
   fi
   linux_ora_pkg_verification_fail=$((linux_ora_pkg_verification_fail+1))
  fi
 done
fi
###
if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "KERNEL PKGS TO VERIFY" $linux_ora_pkg_verification_pass $linux_ora_pkg_verification_fail

# END linux_ora_pkg_verification
}


########################################
# linux_ora_os_groups_verification
########################################

linux_ora_os_groups_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 "OS GROUPS TO VERIFY" "GROUPS TO VERIFY"
fi

GROUP=$(cat /etc/group | grep -E '^oinstall:')
if [ $GROUP ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Group Existence"`#`printf " %-72s" "$(echo $GROUP | awk -F ':' '{print $1}')"`# PASS   #${NC}"
 fi
 linux_ora_os_groups_verification_pass=$((linux_ora_os_groups_verification_pass+1))
 if [ $(echo $GROUP | awk -F ':' '{print $3}') = '501' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Group GUID"`#`printf " %-72s" "$(echo $GROUP | awk -F ':' '{print $3}')"`# PASS   #${NC}"
  fi
  linux_ora_os_groups_verification_pass=$((linux_ora_os_groups_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Group GUID"`#`printf " %-72s" "$(echo $GROUP | awk -F ':' '{print $3}')"`# FAIL   #${NC}"
  fi
  linux_ora_os_groups_verification_fail=$((linux_ora_os_groups_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Group Existence"`#`printf " %-72s" "$(echo $GROUP | awk -F ':' '{print $1}')"`# FAIL   #${NC}"
 fi
 linux_ora_os_groups_verification_fail=$((linux_ora_os_groups_verification_fail+1))
fi

GROUP=$(cat /etc/group | grep -E '^dba:')
if [ $GROUP ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Group Existence"`#`printf " %-72s" "$(echo $GROUP | awk -F ':' '{print $1}')"`# PASS   #${NC}"
 fi
 linux_ora_os_groups_verification_pass=$((linux_ora_os_groups_verification_pass+1))
 if [ $(echo $GROUP | awk -F ':' '{print $3}') = '502' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Group GUID"`#`printf " %-72s" "$(echo $GROUP | awk -F ':' '{print $3}')"`# PASS   #${NC}"
  fi
  linux_ora_os_groups_verification_pass=$((linux_ora_os_groups_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Group GUID"`#`printf " %-72s" "$(echo $GROUP | awk -F ':' '{print $3}')"`# FAIL   #${NC}"
  fi
  linux_ora_os_groups_verification_fail=$((linux_ora_os_groups_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Group Existence"`#`printf " %-72s" "$(echo $GROUP | awk -F ':' '{print $1}')"`# FAIL   #${NC}"
 fi
 linux_ora_os_groups_verification_fail=$((linux_ora_os_groups_verification_fail+1))
fi

GROUP=$(cat /etc/group | grep -E '^oper:')
if [ $GROUP ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Group Existence"`#`printf " %-72s" "$(echo $GROUP | awk -F ':' '{print $1}')"`# PASS   #${NC}"
 fi
 linux_ora_os_groups_verification_pass=$((linux_ora_os_groups_verification_pass+1))
 if [ $(echo $GROUP | awk -F ':' '{print $3}') = '503' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Group GUID"`#`printf " %-72s" "$(echo $GROUP | awk -F ':' '{print $3}')"`# PASS   #${NC}"
  fi
  linux_ora_os_groups_verification_pass=$((linux_ora_os_groups_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Group GUID"`#`printf " %-72s" "$(echo $GROUP | awk -F ':' '{print $3}')"`# FAIL   #${NC}"
  fi
  linux_ora_os_groups_verification_fail=$((linux_ora_os_groups_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Group Existence"`#`printf " %-72s" "$(echo $GROUP | awk -F ':' '{print $1}')"`# FAIL   #${NC}"
 fi
 linux_ora_os_groups_verification_fail=$((linux_ora_os_groups_verification_fail+1))
fi

if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "OS GROUPS TO VERIFY" $linux_ora_os_groups_verification_pass $linux_ora_os_groups_verification_fail


# END linux_ora_os_groups_verification
}


########################################
# linux_ora_os_users_verification
########################################

linux_ora_os_users_verification () {


echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 "OS USERS TO VERIFY" "USERS/ATTRIBUTES TO VERIFY"
fi

USER=`id -Gn oracle 2>/dev/null`
if [ "$USER" ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "USER Existence"`#`printf " %-72s" "oracle"`# PASS   #${NC}"
 fi
 linux_ora_os_users_verification_pass=$((linux_ora_os_users_verification_pass+1))

 oralinuxhome=`getent passwd oracle | awk -F: '{print $6}'`
 if [[ $oralinuxhome = '/home/oracle' ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Oracle User's Home"`#`printf " %-72s" "${oralinuxhome}"`# PASS   #${NC}"
  fi
  linux_ora_os_users_verification_pass=$((linux_ora_os_users_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Oracle User's Home"`#`printf " %-72s" "$i: cur:$oralinuxhome req:/home/oracle"`# FAIL   #${NC}"
  fi
  linux_ora_os_users_verification_fail=$((linux_ora_os_users_verification_fail+1))
 fi
 orashell=`getent passwd oracle | awk -F: '{print $7}'`
 if [[ $orashell = '/bin/bash' ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Oracle User's Shell"`#`printf " %-72s" "${orashell}"`# PASS   #${NC}"
  fi
  linux_ora_os_users_verification_pass=$((linux_ora_os_users_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Oracle User's Shell"`#`printf " %-72s" "$i: cur:$orashell req:/bin/bash"`# FAIL   #${NC}"
  fi
  linux_ora_os_users_verification_fail=$((linux_ora_os_users_verification_fail+1))
 fi

 if [ "$(echo $USER | grep oinstall)" ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "USER oracle Part of Group"`#`printf " %-72s" "$(id -Gn oracle 2>/dev/null | egrep -wio oinstall)"`# PASS   #${NC}"
  fi
  linux_ora_os_users_verification_pass=$((linux_ora_os_users_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "USER oracle Part of Group"`#`printf " %-72s" "$(id -Gn oracle 2>/dev/null | egrep -wio oinstall)"`# FAIL   #${NC}"
  fi
  linux_ora_os_users_verification_fail=$((linux_ora_os_users_verification_fail+1))
 fi
 if [ "$(echo $USER | grep oper)" ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "USER oracle Part of Group"`#`printf " %-72s" "$(id -Gn oracle 2>/dev/null | egrep -wio oper)"`# PASS   #${NC}"
  fi
  linux_ora_os_users_verification_pass=$((linux_ora_os_users_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "USER oracle Part of Group"`#`printf " %-72s" "$(id -Gn oracle 2>/dev/null | egrep -wio oper)"`# FAIL   #${NC}"
  fi
  linux_ora_os_users_verification_fail=$((linux_ora_os_users_verification_fail+1))
 fi
 if [ "$(echo $USER | grep dba)" ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "USER oracle Part of Group"`#`printf " %-72s" "$(id -Gn oracle 2>/dev/null | egrep -wio dba)"`# PASS   #${NC}"
  fi
  linux_ora_os_users_verification_pass=$((linux_ora_os_users_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "USER oracle Part of Group"`#`printf " %-72s" "$(id -Gn oracle 2>/dev/null | egrep -wio dba)"`# FAIL   #${NC}"
  fi
  linux_ora_os_users_verification_fail=$((linux_ora_os_users_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "USER Existence"`#`printf " %-72s" "oracle"`# FAIL   #${NC}"
 fi
 linux_ora_os_users_verification_fail=$((linux_ora_os_users_verification_fail+4))
fi


if [ -f /etc/cron.allow ] ;  then
 if [ $(grep -E '^oracle$' /etc/cron.allow) ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "USER oracle In File"`#`printf " %-72s" "/etc/cron.allow"`# PASS   #${NC}"
  fi
  linux_ora_os_users_verification_pass=$((linux_ora_os_users_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "USER oracle Not In File"`#`printf " %-72s" "/etc/cron.allow"`# FAIL   #${NC}"
  fi
  linux_ora_os_users_verification_fail=$((linux_ora_os_users_verification_fail+1))
 fi
elif [ -f /etc/cron.deny ] ; then
 if [ $(grep -E '^oracle$' /etc/cron.deny) ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "USER oracle In File"`#`printf " %-72s" "/etc/cron.deny"`# FAIL   #${NC}"
  fi
  linux_ora_os_users_verification_fail=$((linux_ora_os_users_verification_fail+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "USER oracle NOT In File"`#`printf " %-72s" "/etc/cron.deny"`# PASS   #${NC}"
  fi
  linux_ora_os_users_verification_pass=$((linux_ora_os_users_verification_pass+1))
 fi
else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/etc/cron.deny and /etc/cron.allow"`# FAIL   #${NC}"
  fi
  linux_ora_os_users_verification_fail=$((linux_ora_os_users_verification_fail+1))
fi

USER=`id -Gn S_OEM-Deploy 2>/dev/null`
if [ "$USER" ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "USER Existence"`#`printf " %-72s" "S_OEM-Deploy"`# PASS   #${NC}"
 fi
 linux_ora_os_users_verification_pass=$((linux_ora_os_users_verification_pass+1))
 if [ "$(echo $USER | grep oinstall)" ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "USER S_OEM-Deploy Part of Group"`#`printf " %-72s" "$(id -Gn S_OEM-Deploy 2>/dev/null | egrep -wio oinstall)"`# PASS   #${NC}"
  fi
  linux_ora_os_users_verification_pass=$((linux_ora_os_users_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "USER S_OEM-Deploy Part of Group"`#`printf " %-72s" "$(id -Gn S_OEM-Deploy 2>/dev/null | egrep -wio oinstall)"`# FAIL   #${NC}"
  fi
  linux_ora_os_users_verification_fail=$((linux_ora_os_users_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "USER Existence"`#`printf " %-72s" "S_OEM-Deploy"`# FAIL   #${NC}"
  echo -e "${RED}#`printf " %-54s" "USER S_OEM-Deploy Part of Group"`#`printf " %-72s" "$(id -Gn S_OEM-Deploy 2>/dev/null | egrep -wio oinstall)"`# FAIL   #${NC}"
 fi
 linux_ora_os_users_verification_fail=$((linux_ora_os_users_verification_fail+2))
fi

if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "OS USERS TO VERIFY" $linux_ora_os_users_verification_pass $linux_ora_os_users_verification_fail


# END linux_ora_os_users_verification
}


########################################
# linux_ora_os_verification
########################################

linux_ora_os_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 "ORAPRIV/SOFTLINKS TO VERIFY" "ORAPRIV/SOFTLINKS TO VERIFY"
fi

TEST_VAR=`dnsdomainname`

if [[ $TEST_VAR = 'wrk.fs.usda.gov' ]] ; then
 AREA_DOMAIN='work'
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Domain Existence"`#`printf " %-72s" "work"`# PASS   #${NC}"
 fi
 linux_ora_os_verification_pass=$((linux_ora_os_verification_pass+1))
elif [[ $TEST_VAR = 'fdc.fs.usda.gov' ]] ; then
 AREA_DOMAIN='prod'
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Domain Existence"`#`printf " %-72s" "prod"`# PASS   #${NC}"
 fi
 linux_ora_os_verification_pass=$((linux_ora_os_verification_pass+1))
else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Domain Existence"`#`printf " %-72s" "Unknown"`# FAIL   #${NC}"
  fi
  linux_ora_os_verification_fail=$((linux_ora_os_verification_fail+1))
fi


if [ -L /fslink/orapriv ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Link Existence"`#`printf " %-72s" "/fslink/orapriv"`# PASS   #${NC}"
 fi
 linux_ora_os_verification_pass=$((linux_ora_os_verification_pass+1))
 if [ $(readlink /fslink/orapriv) = "/nfsroot/$AREA_DOMAIN/orapriv/$(hostname)" ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Link Existence Correct Config"`#`printf " %-72s" "/nfsroot/$AREA_DOMAIN/orapriv/$(hostname)"`# PASS   #${NC}"
  fi
  linux_ora_os_verification_pass=$((linux_ora_os_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Link Existence Correct Config"`#`printf " %-72s" "/nfsroot/$AREA_DOMAIN/orapriv/$(hostname)"`# FAIL   #${NC}"
  fi
  linux_ora_os_verification_fail=$((linux_ora_os_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Link Existence"`#`printf " %-72s" "/fslink/orapriv"`# FAIL   #${NC}"
 fi
 linux_ora_os_verification_fail=$((linux_ora_os_verification_fail+2))
fi


if [ -L /fslink/ops ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Link Existence"`#`printf " %-72s" "/fslink/ops"`# PASS   #${NC}"
 fi
 linux_ora_os_verification_pass=$((linux_ora_os_verification_pass+1))
 if [ $(readlink /fslink/ops) = "/nfsroot/$AREA_DOMAIN/ops" ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Link Existence Correct Config"`#`printf " %-72s" "/nfsroot/$AREA_DOMAIN/ops"`# PASS   #${NC}"
  fi
  linux_ora_os_verification_pass=$((linux_ora_os_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Link Existence Correct Config"`#`printf " %-72s" "/nfsroot/$AREA_DOMAIN/ops"`# FAIL   #${NC}"
  fi
  linux_ora_os_verification_fail=$((linux_ora_os_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Link Existence"`#`printf " %-72s" "/fslink/ops"`# FAIL   #${NC}"
 fi
 linux_ora_os_verification_fail=$((linux_ora_os_verification_fail+2))
fi


if [ -L /fslink/sysinfra ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Link Existence"`#`printf " %-72s" "/fslink/sysinfra"`# PASS   #${NC}"
 fi
 linux_ora_os_verification_pass=$((linux_ora_os_verification_pass+1))
 if [ $(readlink /fslink/sysinfra) = "/nfsroot/$AREA_DOMAIN/sysinfra" ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Link Existence Correct Config"`#`printf " %-72s" "/nfsroot/$AREA_DOMAIN/sysinfra"`# PASS   #${NC}"
  fi
  linux_ora_os_verification_pass=$((linux_ora_os_verification_pass+1))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Link Existence Correct Config"`#`printf " %-72s" "/nfsroot/$AREA_DOMAIN/sysinfra"`# FAIL   #${NC}"
  fi
  linux_ora_os_verification_fail=$((linux_ora_os_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Link Existence"`#`printf " %-72s" "/fslink/sysinfra"`# FAIL   #${NC}"
 fi
 linux_ora_os_verification_fail=$((linux_ora_os_verification_fail+2))
fi


if [ -d /tmp ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Mount Existence"`#`printf " %-72s" "/tmp"`# PASS   #${NC}"
 fi
 linux_ora_os_verification_pass=$((linux_ora_os_verification_pass+1))
 if [ $(find /tmp -maxdepth 0 -perm 1777) = '/tmp' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Mount Permissions:Owner:Group:World"`#`printf " %-72s" "/tmp"`# PASS   #${NC}"
  fi
  linux_ora_os_verification_pass=$((linux_ora_os_verification_pass+4))
 else
  REALPERM=`ls -l / | awk '$9 == "tmp" {print $1}'`
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Mount Permissions:Owner:Group:World"`#`printf " %-72s" "/tmp: $REALPERM instead of drwxrwxrwt"`# FAIL   #${NC}"
  fi
  linux_ora_os_verification_fail=$((linux_ora_os_verification_fail+4))
  echo "/tmp has the incorrect permissions. $(ls -l | awk '$9 == "tmp" {print $1}') instead of drwxrwxrwt."
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Mount Existence"`#`printf " %-72s" "/tmp"`# FAIL   #${NC}"
 fi
 linux_ora_os_verification_fail=$((linux_ora_os_verification_fail+5))
fi

if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "ORAPRIV/SOFTLINKS TO VERIFY" $linux_ora_os_verification_pass $linux_ora_os_verification_fail


# END linux_ora_os_verification
}


########################################
# ora_setup_verification
########################################

ora_setup_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 "ORACLE FILES/DIRECTORIES TO VERIFY" "FILES/DIRECTORIES TO VERIFY"
fi

if [ -d /opt/oracle ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/opt/oracle"`# PASS   #${NC}"
 fi
 ora_setup_verification_pass=$((ora_setup_verification_pass+1))
 if [ ! $(stat -c %a:%U:%G /opt/oracle) = '775:oracle:oinstall' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/opt/oracle"`# FAIL   #${NC}"
  fi
  ora_setup_verification_fail=$((ora_setup_verification_fail+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/opt/oracle"`# PASS   #${NC}"
  fi
  ora_setup_verification_pass=$((ora_setup_verification_pass+5))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/opt/oracle"`# FAIL   #${NC}"
 fi
 ora_setup_verification_fail=$((ora_setup_verification_fail+6))
fi


if [ -d /home/oracle ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/home/oracle"`# PASS   #${NC}"
 fi
 ora_setup_verification_pass=$((ora_setup_verification_pass+1))
 if [ ! $(stat -c %a:%U:%G /home/oracle) = '750:oracle:oinstall' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/home/oracle"`# FAIL   #${NC}"
  fi
  ora_setup_verification_fail=$((ora_setup_verification_fail+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/home/oracle"`# PASS   #${NC}"
  fi
  ora_setup_verification_pass=$((ora_setup_verification_pass+5))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/home/oracle"`# FAIL   #${NC}"
 fi
 ora_setup_verification_fail=$((ora_setup_verification_fail+6))
fi


if [ -d /opt/oraInventory ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/opt/oraInventory"`# PASS   #${NC}"
 fi
 ora_setup_verification_pass=$((ora_setup_verification_pass+1))
 if [ ! $(stat -c %a:%U:%G /opt/oraInventory) = '775:oracle:oinstall' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/opt/oraInventory"`# FAIL   #${NC}"
  fi
  ora_setup_verification_fail=$((ora_setup_verification_fail+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/opt/oraInventory"`# PASS   #${NC}"
  fi
  ora_setup_verification_pass=$((ora_setup_verification_pass+5))
fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/home/oracle"`# FAIL   #${NC}"
 fi
 ora_setup_verification_fail=$((ora_setup_verification_fail+6))
 echo "/opt/oraInventory directory does not exist."
fi


if [ $ORA_PLATFORM='db' ] ; then
 DIRECTORY_LIST=(/opt/oracle/sw
                 /opt/oracle/sw/home_files_copy
                 /opt/oracle/sw/working_dir
                 /opt/oracle/cfgtoollogs
                 /opt/oracle/product
                 /opt/oracle/oradata
                 /opt/oracle/oradata/data01
                 /opt/oracle/oradata/data02
                 /opt/oracle/oradata/data03
                 /opt/oracle/oradata/data04
                 /opt/oracle/oradata/data05
                 /opt/oracle/oradata/data06
                 /opt/oracle/oradata/fra01
                 /opt/oracle/oradata/fra02
                 /opt/oracle/oradata/fra03
                 /opt/oracle/oradata/fra04
                 /opt/oracle/oradata/fra05
                 /opt/oracle/oradata/fra06
                 /fslink/orapriv/ora_exports
                 /fslink/orapriv/db
                 /fslink/orapriv/db/diag
                )

 for i in ${DIRECTORY_LIST[*]}
 do
  if [ -d $i ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "$i"`# PASS   #${NC}"
   fi
   ora_setup_verification_pass=$((ora_setup_verification_pass+1))
   if [ ! $(stat -c %a:%U:%G $i) = '775:oracle:oinstall' ] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
    fi
    ora_setup_verification_fail=$((ora_setup_verification_fail+5))
   else
    if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "$i"`# PASS   #${NC}"
    fi
    ora_setup_verification_pass=$((ora_setup_verification_pass+5))
   fi
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
   fi
   ora_setup_verification_fail=$((ora_setup_verification_fail+1))
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
   fi
   ora_setup_verification_fail=$((ora_setup_verification_fail+5))
  fi
 done
##
 if [ -L /opt/oracle/diag ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Link Existence"`#`printf " %-72s" "/fslink/ops"`# PASS   #${NC}"
  fi
  ora_setup_verification_pass=$((ora_setup_verification_pass+1))
  if [ $(readlink /opt/oracle/diag) = '/fslink/orapriv/db/diag' ] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "Link Existence Correct Config"`#`printf " %-72s" "/fslink/orapriv/db/diag"`# PASS   #${NC}"
    fi
    ora_setup_verification_pass=$((ora_setup_verification_pass+1))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Link Existence Correct Config"`#`printf " %-72s" "/nfsroot/$AREA_DOMAIN/ops"`# FAIL   #${NC}"
   fi
   ora_setup_verification_fail=$((ora_setup_verification_fail+1))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Link Existence"`#`printf " %-72s" "/fslink/ops"`# FAIL   #${NC}"
  fi
  ora_setup_verification_fail=$((ora_setup_verification_fail+2))
 fi
##
 DIR_NAME="/fslink/sysinfra/signatures/oracle/"$(hostname)

 if [ -d $DIR_NAME ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "$DIR_NAME"`# PASS   #${NC}"
  fi
  ora_setup_verification_pass=$((ora_setup_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G $DIR_NAME) = '775:oracle:oinstall' ] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "$DIR_NAME"`# FAIL   #${NC}"
    fi
    ora_setup_verification_fail=$((ora_setup_verification_fail+5))
  else
    if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "$DIR_NAME"`# PASS   #${NC}"
    fi
    ora_setup_verification_pass=$((ora_setup_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "$DIR"`# FAIL   #${NC}"
  fi
  ora_setup_verification_fail=$((ora_setup_verification_fail+6))
 fi
##
 if [ -d /opt/oracle/signatures ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/opt/oracle/signatures"`# PASS   #${NC}"
  fi
  ora_setup_verification_pass=$((ora_setup_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /opt/oracle/signatures) = '775:oracle:oinstall' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/opt/oracle/signatures"`# FAIL   #${NC}"
   fi
   ora_setup_verification_fail=$((ora_setup_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/opt/oracle/signatures"`# PASS   #${NC}"
   fi
   ora_setup_verification_pass=$((ora_setup_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/opt/oracle/signatures"`# FAIL   #${NC}"
  fi
  ora_setup_verification_fail=$((ora_setup_verification_fail+6))
 fi
##
elif [ $ORA_PLATFORM='oem' ] ; then
 if [ -d /opt/oracle/em13.2.0/middleware ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/opt/oracle/em13.2.0/middleware"`# PASS   #${NC}"
  fi
  ora_setup_verification_pass=$((ora_setup_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /opt/oraInventory) = '775:oracle:oinstall' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/opt/oracle/em13.2.0/middleware"`# FAIL   #${NC}"
   fi
   ora_setup_verification_fail=$((ora_setup_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/opt/oracle/em13.2.0/middleware"`# PASS   #${NC}"
   fi
   ora_setup_verification_pass=$((ora_setup_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/opt/oracle/em13.2.0/middleware"`# FAIL   #${NC}"
  fi
  ora_setup_verification_fail=$((ora_setup_verification_fail+6))
 fi
##
 if [ -d /opt/oracle/emagent ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/opt/oracle/emagent"`# PASS   #${NC}"
  fi
  ora_setup_verification_pass=$((ora_setup_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /opt/oracle/emagent) = '775:oracle:oinstall' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/opt/oracle/emagent"`# FAIL   #${NC}"
   fi
   ora_setup_verification_fail=$((ora_setup_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/opt/oracle/emagent"`# PASS   #${NC}"
   fi
   ora_setup_verification_pass=$((ora_setup_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/opt/oracle/emagent"`# FAIL   #${NC}"
  fi
  ora_setup_verification_fail=$((ora_setup_verification_fail+6))
 fi
##
 DIRECTORY_LIST=(/fslink/orapriv/BIP
                 /fslink/orapriv/BIP/cluster
                 /fslink/orapriv/BIP/config
                 /fslink/orapriv/emconfig_bkp
                 /fslink/orapriv/swlib_1
                )
 for i in ${DIRECTORY_LIST[*]}
 do
  if [ -d $i ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "$i"`# PASS   #${NC}"
   fi
   ora_setup_verification_pass=$((ora_setup_verification_pass+1))
   if [ ! $(stat -c %a:%U:%G $i) = '755:oracle:oinstall' ] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
    fi
    ora_setup_verification_fail=$((ora_setup_verification_fail+5))
   else
    if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "$i"`# PASS   #${NC}"
    fi
    ora_setup_verification_pass=$((ora_setup_verification_pass+5))
   fi
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
   fi
   ora_setup_verification_fail=$((ora_setup_verification_fail+6))
  fi
 done
##
##
 DIRECTORY_LIST=(/home/oracle/cleanup
                 /home/oracle/cleanup/logs
                 /home/oracle/cleanup/scripts
                )
 for i in ${DIRECTORY_LIST[*]}
 do
  if [ -d $i ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "$i"`# PASS   #${NC}"
   fi
   ora_setup_verification_pass=$((ora_setup_verification_pass+1))
   if [ ! $(stat -c %a:%U:%G $i) = '775:oracle:oinstall' ] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
    fi
    ora_setup_verification_fail=$((ora_setup_verification_fail+5))
   else
    if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "$i"`# PASS   #${NC}"
    fi
    ora_setup_verification_pass=$((ora_setup_verification_pass+5))
   fi
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
   fi
   ora_setup_verification_fail=$((ora_setup_verification_fail+6))
  fi
 done
##


fi

if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "ORACLE SPECIFIC FILES TO VERIFY" $ora_setup_verification_pass $ora_setup_verification_fail


# END ora_setup_verification
}


############################################################
# POSTREQS
############################################################

########################################
# full_export_scripts_verification
########################################

full_export_scripts_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 "FULL EXPORT FILES TO VERIFY" "FILE TO VERIFY"
fi


if [ -d /home/oracle/system ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/home/oracle/system"`# PASS   #${NC}"
   fi
   full_export_scripts_verification_pass=$((full_export_scripts_verification_pass+1))
 if [ ! $(stat -c %a:%U:%G /home/oracle/system) = '775:oracle:oinstall' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/home/oracle/system"`# FAIL   #${NC}"
  fi
  full_export_scripts_verification_fail=$((full_export_scripts_verification_fail+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/home/oracle/system"`# PASS   #${NC}"
  fi
  full_export_scripts_verification_pass=$((full_export_scripts_verification_pass+5))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/home/oracle/system"`# FAIL   #${NC}"
 fi
 full_export_scripts_verification_fail=$((full_export_scripts_verification_fail+6))
fi


if [ -d /home/oracle/system/oraexport ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/home/oracle/system/oraexport"`# PASS   #${NC}"
 fi
 full_export_scripts_verification_pass=$((full_export_scripts_verification_pass+1))
 if [ ! $(stat -c %a:%U:%G /home/oracle/system/oraexport) = '775:oracle:oinstall' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/home/oracle/system/oraexport"`# FAIL   #${NC}"
  fi
  full_export_scripts_verification_fail=$((full_export_scripts_verification_fail+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "/home/oracle/system/oraexport"`# PASS   #${NC}"
  fi
  full_export_scripts_verification_pass=$((full_export_scripts_verification_pass+5))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/home/oracle/system/oraexport"`# FAIL   #${NC}"
 fi
 full_export_scripts_verification_fail=$((full_export_scripts_verification_fail+6))
fi


if [ -f /home/oracle/system/oraexport/full_export_nocomp.sh ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/home/oracle/system/oraexport/full_export_nocomp.sh"`# PASS   #${NC}"
 fi
 full_export_scripts_verification_pass=$((full_export_scripts_verification_pass+1))
 if [ $(sha256sum /home/oracle/system/oraexport/full_export_nocomp.sh | awk '{print $1}') = '40a35d69f08bf75f1bcc7196d56ee42601e89ae53dd1c1a1e411881bc9b645f0' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/home/oracle/system/oraexport/full_export_nocomp.sh"`# PASS   #${NC}"
  fi
  full_export_scripts_verification_pass=$((full_export_scripts_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /home/oracle/system/oraexport/full_export_nocomp.sh) = '774:oracle:oinstall' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/home/oracle/system/oraexport/full_export_nocomp.sh"`# FAIL   #${NC}"
   fi
   full_export_scripts_verification_fail=$((full_export_scripts_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/home/oracle/system/oraexport/full_export_nocomp.sh"`# PASS   #${NC}"
   fi
   full_export_scripts_verification_pass=$((full_export_scripts_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/home/oracle/system/oraexport/full_export_nocomp.sh"`# FAIL   #${NC}"
  fi
  full_export_scripts_verification_fail=$((full_export_scripts_verification_fail+1))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/home/oracle/system/oraexport/full_export_nocomp.sh"`# FAIL   #${NC}"
 fi
 full_export_scripts_verification_fail=$((full_export_scripts_verification_fail+7))
fi


if [ -f /home/oracle/system/oraexport/get_sid.ksh ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/home/oracle/system/oraexport/get_sid.ksh"`# PASS   #${NC}"
 fi
 full_export_scripts_verification_pass=$((full_export_scripts_verification_pass+1))
 if [ $(sha256sum /home/oracle/system/oraexport/get_sid.ksh | awk '{print $1}') = '0c2e0c01205f56b0cc7e92cf7fd142f451d840cf24e46f481a88ce91bc4e28d8' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/home/oracle/system/oraexport/get_sid.ksh"`# PASS   #${NC}"
  fi
  full_export_scripts_verification_pass=$((full_export_scripts_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /home/oracle/system/oraexport/get_sid.ksh) = '774:oracle:oinstall' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/home/oracle/system/oraexport/get_sid.ksh"`# FAIL   #${NC}"
   fi
   full_export_scripts_verification_fail=$((full_export_scripts_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/home/oracle/system/oraexport/get_sid.ksh"`# PASS   #${NC}"
   fi
   full_export_scripts_verification_pass=$((full_export_scripts_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/home/oracle/system/oraexport/get_sid.ksh"`# FAIL   #${NC}"
  fi
  full_export_scripts_verification_fail=$((full_export_scripts_verification_fail+3))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/home/oracle/system/oraexport/get_sid.ksh"`# FAIL   #${NC}"
 fi
 full_export_scripts_verification_fail=$((full_export_scripts_verification_fail+7))
fi


if [[ $(crontab -u oracle -l | grep "30 22 \* \* 1,2,3,4,5,6 /home/oracle/system/oraexport/full_export_nocomp.sh -o ALL > /fslink/orapriv/ora_exports/full_export.sh.log 2>&1") = "30 22 * * 1,2,3,4,5,6 /home/oracle/system/oraexport/full_export_nocomp.sh -o ALL > /fslink/orapriv/ora_exports/full_export.sh.log 2>&1" ]] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Cron Entry Existence"`#`printf " %-72s" "/home/oracle/system/oraexport/full_export_nocomp.sh"`# PASS   #${NC}"
 fi
 full_export_scripts_verification_pass=$((full_export_scripts_verification_pass+1))
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Cron Entry Existence"`#`printf " %-72s" "/home/oracle/system/oraexport/full_export_nocomp.sh"`# FAIL   #${NC}"
 fi
 full_export_scripts_verification_fail=$((full_export_scripts_verification_fail+5))
fi

if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "FULL EXPORT FILES TO VERIFY" $full_export_scripts_verification_pass $full_export_scripts_verification_fail


# END full_export_scripts_verification
}


########################################
# bash_profile_verification
########################################

bash_profile_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 ".BASH_PROFILE TO VERIFY" "FILE/VALUES TO VERIFY"
fi
if [[ $ORA_PLATFORM = 'db' ]] ; then
 if [ -f /home/oracle/.bash_profile ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/home/oracle/.bash_profile"`# PASS   #${NC}"
  fi
  bash_profile_verification_pass=$((bash_profile_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G /home/oracle/.bash_profile) = '755:oracle:oinstall' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/home/oracle/.bash_profile"`# FAIL   #${NC}"
   fi
   bash_profile_verification_fail=$((bash_profile_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/home/oracle/.bash_profile"`# PASS   #${NC}"
   fi
   bash_profile_verification_pass=$((bash_profile_verification_pass+5))
  fi
##
  ORACLE_SID=`/bin/cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep 'ora_bash_db_name' | awk -F ' ' '{print $2}' | sed "s/.*'\(.*\)'.*/\1/g"`
  ORACLE_HOME=`/bin/cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep 'ora_bash_home' | awk -F ' ' '{print $2}' | sed "s/.*'\(.*\)'.*/\1/g"`
  AGENT_CORE=`/bin/cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep 'agent_core' | awk -F ' ' '{print $2}' | sed "s/.*'\(.*\)'.*/\1/g"`
  AGENT_HOME=`/bin/cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep 'agent_home' | awk -F ' ' '{print $2}' | sed "s/.*'\(.*\)'.*/\1/g"`

  ORACLE_SID_REAL=`/bin/cat /home/oracle/.bash_profile | grep '^ORACLE_SID' | awk -F '[=;]' '{print $2}'`
  ORACLE_HOME_REAL=`/bin/cat /home/oracle/.bash_profile | grep '^ORACLE_HOME' | awk -F '[=;]' '{print $2}'`
  AGENT_CORE_REAL=`/bin/cat /home/oracle/.bash_profile | grep '^AGENT_CORE' | awk -F '[=;]' '{print $2}'`
  AGENT_HOME_REAL=`/bin/cat /home/oracle/.bash_profile | grep '^AGENT_HOME' | awk -F '[=;]' '{print $2}'`

  if [ $(cat /home/oracle/.bash_profile | grep -v ^AGENT_HOME | grep -v ^AGENT_CORE | grep -v ^ORACLE_SID | grep -v ^ORACLE_HOME | grep -v ^ORACLE_UNQNAME | sed '/^$/d' | sha256sum | awk '{print $1}') = '9ec4d449c5ca13d8c0fe6fcd0246bf4f4f7c12ebefa7a4936a1a655c3c15f4a4' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Static Checksum"`#`printf " %-72s" "/home/oracle/.bash_profile"`# PASS   #${NC}"
   fi
   bash_profile_verification_pass=$((bash_profile_verification_pass+1))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Static Checksum"`#`printf " %-72s" "/home/oracle/.bash_profile"`# FAIL   #${NC}"
   fi
   bash_profile_verification_fail=$((bash_profile_verification_fail+1))
  fi
##
  if [[ $ORACLE_SID_REAL != '' || $ORACLE_SID != '' && $ORACLE_SID_REAL = $ORACLE_SID ]] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Variable Check to External Fact"`#`printf " %-72s" "ORACLE_SID"`# PASS   #${NC}"
   fi
   bash_profile_verification_pass=$((bash_profile_verification_pass+1))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Variable Check to External Fact"`#`printf " %-72s" "ORACLE_SID"`# FAIL   #${NC}"
   fi
   bash_profile_verification_fail=$((bash_profile_verification_fail+1))
  fi
##
  if [[ $ORACLE_HOME_REAL != '' || $ORACLE_HOME != '' && $ORACLE_HOME_REAL = $ORACLE_HOME ]] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Variable Check to External Fact"`#`printf " %-72s" "ORACLE_HOME"`# PASS   #${NC}"
   fi
   bash_profile_verification_pass=$((bash_profile_verification_pass+1))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Variable Check to External Fact"`#`printf " %-72s" "ORACLE_HOME"`# FAIL   #${NC}"
   fi
   bash_profile_verification_fail=$((bash_profile_verification_fail+1))
  fi
##
  if [ ! $AGENT_CORE = '' ] ; then
   if [[ $AGENT_CORE_REAL != '' && $AGENT_CORE_REAL = $AGENT_CORE ]] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "Variable Check to External Fact"`#`printf " %-72s" "AGENT_CORE"`# PASS   #${NC}"
    fi
    bash_profile_verification_pass=$((bash_profile_verification_pass+1))
   else
    if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "Variable Check to External Fact"`#`printf " %-72s" "AGENT_CORE"`# FAIL   #${NC}"
    fi
    bash_profile_verification_fail=$((bash_profile_verification_fail+1))
   fi
  fi
##
  if [[ $AGENT_HOME_REAL != '' || $AGENT_HOME != '' && $AGENT_HOME_REAL = $AGENT_HOME ]] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Variable Check to External Fact"`#`printf " %-72s" "AGENT_HOME"`# PASS   #${NC}"
   fi
   bash_profile_verification_pass=$((bash_profile_verification_pass+1))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Variable Check to External Fact"`#`printf " %-72s" "AGENT_HOME"`# FAIL   #${NC}"
   fi
   bash_profile_verification_fail=$((bash_profile_verification_fail+1))
  fi
##
 else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/home/oracle/.bash_profile"`# FAIL   #${NC}"
   fi
   bash_profile_verification_fail=$((bash_profile_verification_fail+11))
 fi
elif [[ $ORA_PLATFORM = 'oem' ]] ; then
 if [ -f /home/oracle/.bash_profile ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/home/oracle/.bash_profile"`# PASS   #${NC}"
  fi
  bash_profile_verification_pass=$((bash_profile_verification_pass+1))
  if [ $(sha256sum /home/oracle/.bash_profile | awk '{print $1}') = '617177b2f5dc91a44db9cda2cdc663fa881b067831ef5c8d50c7d97084538340' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/home/oracle/.bash_profile"`# PASS   #${NC}"
   fi
   bash_profile_verification_pass=$((bash_profile_verification_pass+1))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "/home/oracle/.bash_profile"`# FAIL   #${NC}"
   fi
   bash_profile_verification_fail=$((bash_profile_verification_fail+1))
  fi
  if [ ! $(stat -c %a:%U:%G /home/oracle/.bash_profile) = '755:oracle:oinstall' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/home/oracle/.bash_profile"`# FAIL   #${NC}"
   fi
   bash_profile_verification_fail=$((bash_profile_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "/home/oracle/.bash_profile"`# PASS   #${NC}"
   fi
   bash_profile_verification_pass=$((bash_profile_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "/home/oracle/.bash_profile"`# FAIL   #${NC}"
  fi
  bash_profile_verification_fail=$((bash_profile_verification_fail+7))
 fi
fi

if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary ".BASH_PROFILE TO VERIFY" $bash_profile_verification_pass $bash_profile_verification_fail


# END bash_profile_verification
}


########################################
# db_maintenance_scripts_verification
########################################

db_maintenance_scripts_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 "DBMAINT FILES TO VERIFY" "FILE/DIRECTORES TO VERIFY"
fi

DIRECTORY_LIST=(/home/oracle/dbcheck
                /home/oracle/dbcheck/scripts
                /home/oracle/dbcheck/logs
                /opt/oracle/diag/bkp
                /opt/oracle/diag/bkp/alertlogs
                /opt/oracle/diag/bkp/rman
                /opt/oracle/diag/bkp/rman/log)

for i in ${DIRECTORY_LIST[*]}
do
 if [ -d $i ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "$i"`# PASS   #${NC}"
  fi
  db_maintenance_scripts_verification_pass=$((db_maintenance_scripts_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G $i) = '775:oracle:oinstall' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
   fi
   db_maintenance_scripts_verification_fail=$((db_maintenance_scripts_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" "$i"`# PASS   #${NC}"
   fi
   db_maintenance_scripts_verification_pass=$((db_maintenance_scripts_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" "/home/oracle/.bash_profile"`# FAIL   #${NC}"
  fi
  db_maintenance_scripts_verification_fail=$((db_maintenance_scripts_verification_fail+6))
 fi
done

FILE_LIST=(8a1828c17727124a3d134facb581fc183d0a41efaf65603d911c3dbb33607e8b:archloglist.sql
           32cb68d9d489db11e9faacbf3754b52063ab06f5539349edf74346f9e63714f0:chained_rows.sql
           bcc7960170ecb1655d66761427371740e6a21af9355fc0db0f7f7d412c42dcbc:check_for_extents.sql
           f4755811cc5d9e8baffafd20cdebe6d62cfe5e7eca217fa93e562afd29ec7210:ckalertlog.sh
           bf373285c477707d6d7e8c9e2ba35dc094aaf7118fafae8de52b378fb2e7bb6a:ckexplogs.sh
           806d7def701ca396ea2d53c70fd9013378dcda7e2590703a215cc7362d25a49e:ckrmanlogs.sh
           1f3e0b4d2232e381d24eba099fc0ee273d1c953b27ffb3e2a68f0b44897963c6:cleanup.sh
           ab05ec20f31e8b7f91c07d7b313e1ffb2466642c6a53a46bd9e0efe5cd1afdf4:count_fsdba_privs.sql
           7aec360f3e57c05928584763f2a3c07c8a9e9f9fc61a99f17b71b5b6dbd885c1:cr_reset_fsschemas.sql
           1949a6488333c7af5d1d53fef903274cb6caf227e8825ae8d1ba8f5de5615ba6:cr_rpwd_lock_procedure.sql
           f4bf1ac73503567a844d26a24e1561bde518b7760880b5ef477ac2b5d6073e94:cr_rpwd_procedure.sql
           0dc960be92b03994ea6baef7621289708561ddea79fefde612d29c21af5dc1bb:data_pump_dir.sql
           e81dc90eb927891131d0b2e32ebbd47fb29ea40fbc2c76884bfb931b87b62a90:dbmaint_daily.sh
           edaa05b366a74db5fab5406aecc3bfbaee4f7e1aadf282464dd524498a88d4a3:dbmaint.sh
           e94a45b5072b1b5d17994ea0bd18ab3f72d458f7ed96040304a342ab9e910549:dbmaint_start.job
           61319f285a7ec9045a50ca2377c41fc65c369e4d66bb42d70ca97c8a49e92520:dbsize.sql
           dbd9af0e4f773a6a0713218cbfd6b4f54144f1984c41eb43607468d1a8f895c5:db_start.sql
           b5e6f9c5d9d161969d48828b0e7a9cac98416705ab8f1541226a1af2fa352fdb:FSoptions.sql
           f23b96c8e68cdf460dbef822248e6f5512cb3bf39782227b9e7b77e239ea1241:FSutlrp.sql
           0c2e0c01205f56b0cc7e92cf7fd142f451d840cf24e46f481a88ce91bc4e28d8:get_sid.ksh
           83846d36ed1437dfa6c46cfda4f5662ee07f558f0799b3dc7abb9dca18cdfeaa:global_name.sql
           13dc5686b6e98c4a3c0bf21b8362b13e19df0daedb76f0100bb667acc823a478:list_user_privs.sql
           f0690fdcd42231530bdf363b03c626a88d95d04d7ac5c204ba9a60dc11902728:logswitch.sql
           a3a0e24620e91b2c21df4f0052f0f8d69d4b8fa1adbb231d4583ac8df2a11fd7:options_packs_usage_statistics.sql
           9020a96f684e62ee283f72ebde025f906e27dd514ae6c3f4ad78dbc26155f608:parms.sql
           c67d81691455423049cecabcdeb80e7e77340c9601f2827e1bee0ce43197cf5b:reset_fsschemas.sh
           88d803bc619bcef81aa10efbb5af97548634643c4c9d2a368e4cd8e6bf00394d:rotate_alertlogs.sh
           bdabbf24ab1eb58caee80ac67720c8811b59595529a9b622b6a25f2c78c668c6:rundbsql.sh
           e3ba217ca552941e8b8138426f9ab9ce109ef7910f6af9e52e0003f494932136:set_16k_dfile_ext.sql
           c5c44475ae3153951cda92dd722e6019e75ded5f4739602d6b8326790551e3c6:set_8k_dfile_ext.sql
           a695eed14d211c7ba26634db946d765bd94db2ead4de29b8e8e5203bfff799f2:tbs.sql
           01b309b168c12048ba7dbbdd7f56df675e2ab6232d4d2a5949a203cbbd3aa9f4:trim_logs.sh

           )

for i in ${FILE_LIST[*]}
do
 SHA_SUM=`echo $i | awk -F ':' '{print $1}'`
 FILE_NAME=`echo $i | awk -F ':' '{print $2}'`
 if [ -f /home/oracle/dbcheck/scripts/$FILE_NAME ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "$FILE_NAME"`# PASS   #${NC}"
  fi
  db_maintenance_scripts_verification_pass=$((db_maintenance_scripts_verification_pass+1))
  if [ $(sha256sum /home/oracle/dbcheck/scripts/$FILE_NAME | awk '{print $1}') = $SHA_SUM ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "$FILE_NAME"`# PASS   #${NC}"
   fi
   db_maintenance_scripts_verification_pass=$((db_maintenance_scripts_verification_pass+1))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "$FILE_NAME"`# FAIL   #${NC}"
   fi
   db_maintenance_scripts_verification_fail=$((db_maintenance_scripts_verification_fail+1))
  fi
  if [ ! $(stat -c %a:%U:%G /home/oracle/dbcheck/scripts/$FILE_NAME) = '774:oracle:oinstall' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "$FILE_NAME"`# FAIL   #${NC}"
   fi
   db_maintenance_scripts_verification_fail=$((db_maintenance_scripts_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "$FILE_NAME"`# PASS   #${NC}"
   fi
   db_maintenance_scripts_verification_pass=$((db_maintenance_scripts_verification_pass+5))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "$FILE_NAME"`# FAIL   #${NC}"
  fi
  db_maintenance_scripts_verification_fail=$((db_maintenance_scripts_verification_fail+7))
 fi
done

if [ -f /home/oracle/dbcheck/scripts/emailto ] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "emailto"`# PASS   #${NC}"
 fi
 db_maintenance_scripts_verification_pass=$((db_maintenance_scripts_verification_pass+1))
 MAIL_LIST=`/bin/cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml  | grep 'optional_mail_list' | sed "/^#.*/d" | sed  "s/^oradb_fs::optional_mail_list: '\(.*\)'.*/\1/" | sed "s/\r//"`
 if [[ $MAIL_LIST != '' && $MAIL_LIST = 'null' ]] ; then
  if [ $(sha256sum /home/oracle/dbcheck/scripts/emailto | awk '{print $1}') = '216b4287dcb15e920cd0fba749f9c0e127a722530371a7b96e803a634bef2960' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "emailto"`# PASS   #${NC}"
   fi
   db_maintenance_scripts_verification_pass=$((db_maintenance_scripts_verification_pass+1))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Checksum"`#`printf " %-72s" "emailto"`# FAIL   #${NC}"
   fi
   db_maintenance_scripts_verification_fail=$((db_maintenance_scripts_verification_fail+1))
  fi
 else
  MAIL_LIST_REAL=`/bin/cat /home/oracle/dbcheck/scripts/emailto`
  if [[ $MAIL_LIST_REAL != '' || $MAIL_LIST != '' && $MAIL_LIST_REAL = $MAIL_LIST ]] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Content Match"`#`printf " %-72s" "emailto"`# PASS   #${NC}"
   fi
   db_maintenance_scripts_verification_pass=$((db_maintenance_scripts_verification_pass+1))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Content Match"`#`printf " %-72s" "emailto"`# FAIL   #${NC}"
   fi
   db_maintenance_scripts_verification_fail=$((db_maintenance_scripts_verification_fail+1))
  fi
 fi
 if [ ! $(stat -c %a:%U:%G /home/oracle/dbcheck/scripts/emailto) = '774:oracle:oinstall' ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "emailto"`# FAIL   #${NC}"
  fi
  db_maintenance_scripts_verification_fail=$((db_maintenance_scripts_verification_fail+5))
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" "emailto"`# PASS   #${NC}"
  fi
  db_maintenance_scripts_verification_pass=$((db_maintenance_scripts_verification_pass+5))
 fi
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "$FILE_NAME"`# FAIL   #${NC}"
 fi
 db_maintenance_scripts_verification_fail=$((db_maintenance_scripts_verification_fail+7))
fi


if [[ $(crontab -u oracle -l | grep "0 0 1 \* \* /home/oracle/dbcheck/scripts/rotate_alertlogs.sh > /home/oracle/dbcheck/logs/alert.log 2>&1") = "0 0 1 * * /home/oracle/dbcheck/scripts/rotate_alertlogs.sh > /home/oracle/dbcheck/logs/alert.log 2>&1" ]] ; then
 if [[ "$2" = "detail" ]] ; then
  echo -e "${GREEN}#`printf " %-54s" "Cron Entry"`#`printf " %-72s" "/home/oracle/dbcheck/scripts/rotate_alertlogs.sh"`# PASS   #${NC}"
 fi
 db_maintenance_scripts_verification_pass=$((db_maintenance_scripts_verification_pass+3))
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Cron Entry"`#`printf " %-72s" "/home/oracle/dbcheck/scripts/rotate_alertlogs.sh"`# FAIL   #${NC}"
 fi
 db_maintenance_scripts_verification_fail=$((db_maintenance_scripts_verification_fail+3))
fi


if [[ $(crontab -u oracle -l | grep "0 5 \* \* \* /home/oracle/dbcheck/scripts/dbmaint_start.job all > /tmp/dbmaint_daily.log 2>&1") = "0 5 * * * /home/oracle/dbcheck/scripts/dbmaint_start.job all > /tmp/dbmaint_daily.log 2>&1" ]] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Cron Entry"`#`printf " %-72s" "/home/oracle/dbcheck/scripts/dbmaint_start.job"`# PASS   #${NC}"
  fi
  db_maintenance_scripts_verification_pass=$((db_maintenance_scripts_verification_pass+3))
else
 if [[ "$2" = "detail" ]] ; then
  echo -e "${RED}#`printf " %-54s" "Cron Entry"`#`printf " %-72s" "/home/oracle/dbcheck/scripts/dbmaint_start.job"`# FAIL   #${NC}"
 fi
 db_maintenance_scripts_verification_fail=$((db_maintenance_scripts_verification_fail+3))
fi

if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "DBMAINT FILES TO VERIFY" $db_maintenance_scripts_verification_pass $db_maintenance_scripts_verification_fail


# END db_maintenance_scripts_verification
}


############################################################
# ORAHOME
############################################################

########################################
# sw_verification
########################################

sw_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 "ORACLE SW TO VERIFY" "FILE TO VERIFY"
fi

#mapfile -t FACT_HOMES < <(cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep 'oradb::ora_home_db_' | awk -F ' ' '{print $2}' | sed "s/'//g")
mapfile -t FACT_HOMES < <(cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep 'oradb::ora_home_db_' | awk -F\' '{print $2}')

for i in ${FACT_HOMES[*]}
do
 if [ ! `echo $i|awk '{print substr($0,length($0),1)}'` = 'x' ]; then
 if [ -d $i ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" $i`# PASS   #${NC}"
  fi
  sw_verification_pass=$((sw_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G $i) = '775:oracle:oinstall' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" $i`# FAIL   #${NC}"
   fi
   sw_verification_fail=$((ora_bootstrap_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Directory Permissions: Owner:Group:World"`#`printf " %-72s" $i`# PASS   #${NC}"
   fi
   sw_verification_pass=$((sw_verification_pass+5))
  fi
  if [ -f $i/bin/oracle ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Existence"`#`printf " %-72s" "$i/bin/oracle"`# PASS   #${NC}"
   fi
   sw_verification_pass=$((sw_verification_pass+1))

   su -c "$i/OPatch/opatch lsinventory -patch_id -oh $i -invPtrLoc /etc/oraInst.loc" - oracle >/dev/null 2>&1
   EXIT_CODE=$?

   if [ $EXIT_CODE == 0 ] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "lsinventory Successful"`#`printf " %-72s" "$i"`# PASS   #${NC}"
    fi
    sw_verification_pass=$((sw_verification_pass+1))
   else
    if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "lsinventory Successful"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
    fi
    sw_verification_fail=$((sw_verification_fail+1))
   fi

   CHOPT=`ar -tv $i/rdbms/lib/libknlopt.a | awk '/ksnkkpo.o/ {print $8}'`

   if [[ ! -z $CHOPT && $CHOPT = 'ksnkkpo.o' ]] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "Partitioning Disabled"`#`printf " %-72s" "$i"`# PASS   #${NC}"
    fi
    sw_verification_pass=$((sw_verification_pass+1))
   else
    if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "Partitioning Disabled"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
    fi
    sw_verification_fail=$((sw_verification_fail+1))
   fi
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "$i/bin/oracle"`# FAIL   #${NC}"
   fi
   sw_verification_fail=$((sw_verification_fail+1))
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "lsinventory Successful"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
   fi
    sw_verification_fail=$((sw_verification_fail+1))
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Partitioning Disabled"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
   fi
   sw_verification_fail=$((sw_verification_fail+1))
  fi
 else
  if [[ "$2" = "detail" ]] ; then
   echo -e "${RED}#`printf " %-54s" "Directory Existence"`#`printf " %-72s" $i`# FAIL   #${NC}"
   echo -e "${RED}# Directory Permissions: Owner:Group:World #`printf " %-72s" $i`# FAIL   #${NC}"
   echo -e "${RED}#`printf " %-54s" "File Existence"`#`printf " %-72s" "$i/bin/oracle"`# FAIL   #${NC}"
   echo -e "${RED}#`printf " %-54s" "lsinventory Successful"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
   echo -e "${RED}#`printf " %-54s" "Partitioning Disabled"`#`printf " %-72s" "$i"`# FAIL   #${NC}"
  fi
  sw_verification_fail=$((sw_verification_fail+9))
 fi
 else
    echo -e "${YELLOW}#`printf " %-54s" "DEFAULT ORACLE HOME"`#`printf " %-72s" "$i"`# WARN   #${NC}"
 fi
done

if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "ORACLE SW VERIFY" $sw_verification_pass $sw_verification_fail


# END sw_verification
}


########################################
# home_patch_verification
########################################

home_patch_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header2 "ORACLE SW HOME PATCH TO VERIFY" 
fi


mapfile -t FACT_HOMES < <(cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep 'oradb::ora_home_db_' | sed  "s/^oradb::ora_home_db_\(.*:\) '\(.*\)'.*/\1\2/")
FACTER=`/usr/local/bin/facter -p`
mapfile -t HOME_PATCHES < <(echo "$FACTER" | sed -n '/home_patch_list => \[/,/]/p' | sed -n 's/.*"\(.*\)"/\1/p' | sed 's/,$//')
for (( i=1; i<=${#FACT_HOMES[@]}; i++ ))
do
 mapfile -t HOME_INFO_I < <(echo ${FACT_HOMES[$i-1]} | sed 's/:/\n/')
 for (( j=1; j<=${#HOME_PATCHES[@]}; j++ ))
 do
  mapfile -t HOME_INFO_J < <(echo ${HOME_PATCHES[$j-1]} | sed 's/:/\n/')
  if [ ! `echo ${HOME_INFO_I[1]}|awk '{print substr($0,length($0),1)}'` = 'x' ] ; then
  if [[ ${HOME_INFO_J[0]} = ${HOME_INFO_I[1]} ]] ; then
   PATCH_PATH=`/bin/cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep "oradb::ora_patch_path_db_${HOME_INFO_I[0]}" | awk -F\' '{print $2}' `
   PATCH_PATH_ZERO_REGEX='.*\.0\.0'
   if [[ $PATCH_PATH =~ $PATCH_PATH_ZERO_REGEX && ${HOME_INFO_J[1]} = '_' ]] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-128s" "${FACT_HOMES[$i-1]} ora_patch_path_db_x: $PATCH_PATH , Lsinventory patch: base install only"`# PASS   #${NC}"
    fi
    home_patch_verification_pass=$((home_patch_verification_pass+1))
   elif [[ $PATCH_PATH =~ $PATCH_PATH_ZERO_REGEX && ! ${HOME_INFO_J[1]}  = '_' ]] || [[ ! $PATCH_DATE = 'none' && ! ${HOME_INFO_J[1]}  = '_' ]] ; then
    mapfile -t PATCHES < <(echo ${HOME_PATCHES[$j-1]} | awk -F ':' '{print $2}' | awk -F '_' '{print $2"\n"$3}')
    mapfile -t PATCH_1 < <(echo "$FACTER" | grep "p${PATCHES[0]}_" | sed 's/[ ]*=>.*//' | awk -F '::' '{print $3":"$2}' | sed -r 's/(.*)_([1-9]?[0-9])_([0-2])/\1.\2.\3/')
    mapfile -t PATCH_2 < <(echo "$FACTER" | grep "p${PATCHES[1]}_" | sed 's/[ ]*=>.*//' | awk -F '::' '{print $3":"$2}' | sed -r 's/(.*)_([1-9]?[0-9])_([0-2])/\1.\2.\3/')
    if [ $PATCH_PATH = 'xx.xx.x' ] ; then
     PATCH_PATH='the default value (xx.xx.x)'
    fi
    if [[ ${PATCH_1[0]} =~ '^:' ]] ; then
     HOLDING_PATH=' '
     HOLDING_TYPE="mismatch"
    elif [[ ${#PATCH_1[@]} > 1 ]] ; then
     HOLDING_PATH=' '
     HOLDING_TYPE=' '
     for (( k=1; k<=${#PATCH_1[@]}; k++ ))
     do
      PATCH_TYPE_1=`echo ${PATCH_1[$k-1]} | awk -F ':' '{print $1}'`
      PATCH_PATH_1=`echo ${PATCH_1[$k-1]} | awk -F ':' '{print $2}'`
      if [ $k == 1 ] ; then
       HOLDING_PATH=$PATCH_PATH_1
      else
       HOLDING_PATH=$HOLDING_PATH"/"$PATCH_PATH_1
      fi
      if [ $k == 1 ] ; then
       HOLDING_TYPE=$PATCH_TYPE_1
      elif [ $HOLDING_TYPE = $PATCH_TYPE_1 ] ; then
       HOLDING_TYPE=$PATCH_TYPE_1
      else
       HOLDING_TYPE="mismatch"
      fi
     done
    elif [[ ${#PATCH_1[@]} = 1 ]] ; then
     HOLDING_TYPE=`echo ${PATCH_1[0]} | awk -F ':' '{print $1}'`
     HOLDING_PATH=`echo ${PATCH_1[0]} | awk -F ':' '{print $2}'`
    fi
    PATCH_PATH_1=$HOLDING_PATH
    PATCH_TYPE_1=$HOLDING_TYPE
    if [[ ${PATCH_2[0]} == ':' ]] ; then
     HOLDING_PATH=' '
     HOLDING_TYPE="mismatch"
    elif [[ ${#PATCH_2[*]} > 1 ]] ; then
     HOLDING_PATH=' '
     HOLDING_TYPE=' '
     for (( h=1; h<=${#PATCH_2[@]}; h++ ))
     do
      PATCH_TYPE_2=`echo ${PATCH_2[$h-1]} | awk -F ':' '{print $1}'`
      PATCH_PATH_2=`echo ${PATCH_2[$h-1]} | awk -F ':' '{print $2}'`
      if [ $h == 1 ]; then
       HOLDING_PATH=$PATCH_PATH_2
      else
       HOLDING_PATH=$HOLDING_PATH"/"$PATCH_PATH_2
      fi
      if [ $h == 1 ] ; then
       HOLDING_TYPE=$PATCH_TYPE_2
      elif [ $HOLDING_TYPE = $PATCH_TYPE_2 ] ; then
       HOLDING_TYPE=$PATCH_TYPE_2
      else
       HOLDING_TYPE="mismatch"
      fi
     done
    elif [[ ${#PATCH_2[@]} = 1 ]] ; then
     HOLDING_TYPE=`echo ${PATCH_2[0]} | awk -F ':' '{print $1}'`
     HOLDING_PATH=`echo ${PATCH_2[0]} | awk -F ':' '{print $2}'`
    fi
    PATCH_PATH_2=$HOLDING_PATH
    PATCH_TYPE_2=$HOLDING_TYPE
## CODE MOD
    if [[ "$PATCH_PATH_1" = "$PATCH_PATH_2" && "$PATCH_PATH_1" = "$PATCH_PATH" && "$PATCH_TYPE_1" != 'mismatch' && "$PATCH_TYPE_2" != 'mismatch' ]] ; then
     PATCH_PATH_FINAL=$PATCH_PATH_1
     if [[ "$2" = "detail" ]] ; then
      echo -e "${GREEN}#`printf " %-128s" "${FACT_HOMES[$i-1]} ora_patch_path_db_x: $PATCH_PATH , Lsinventory patch: $PATCH_PATH_FINAL"`# PASS   #${NC}"
     fi
     home_patch_verification_pass=$((home_patch_verification_pass+1))
    elif [[ "$PATCH_PATH_1" = "$PATCH_PATH_2" && "$PATCH_PATH_1" != "$PATCH_PATH" && "$PATCH_TYPE_1" != 'mismatch' && "$PATCH_TYPE_2" != 'mismatch' && "$PATCH_PATH" = '12_2.0.0'  ]] ; then
     PATCH_PATH_FINAL=$PATCH_PATH_1
     if [[ "$2" = "detail" ]] ; then
      echo -e "${YELLOW}#`printf " %-128s" "${FACT_HOMES[$i-1]} ora_patch_path_db_x: $PATCH_PATH , Lsinventory patch: $PATCH_PATH_FINAL"`# WARN   #${NC}"
     fi
     home_patch_verification_pass=$((home_patch_verification_pass+1))
    elif [[ "$PATCH_PATH_1" = "$PATCH_PATH_2" && "$PATCH_PATH_1" != "$PATCH_PATH" && "$PATCH_TYPE_1" != 'mismatch' && "$PATCH_TYPE_2" != 'mismatch' ]] ; then
     PATCH_PATH_FINAL=$PATCH_PATH_1
     if [[ "$2" = "detail" ]] ; then
      echo -e "${RED}#`printf " %-128s" "${FACT_HOMES[$i-1]} ora_patch_path_db_x: $PATCH_PATH , Lsinventory patch: $PATCH_PATH_FINAL"`# FAIL   #${NC}"
     fi
     home_patch_verification_fail=$((home_patch_verification_fail+1))
    elif [[ $PATCH_TYPE_1 = "mismatch" ]] || [[ $PATCH_TYPE_2 = "mismatch" ]] ; then
     if [[ "$2" = "detail" ]] ; then
      echo -e "${RED}#`printf " %-128s" "${FACT_HOMES[$i-1]}"`# FAIL   #${NC}"
      echo -e "${RED}#`printf "    %-125s" "Dbeng.yaml contains conflicting information or Home unstable. Manual verification of home required."`# FAIL   #${NC}"
      echo -e "${RED}#`printf "    %-125s" "Lsinventory patch number: ${PATCHES[0]}"`# FAIL   #${NC}"
      echo -e "${RED}#`printf "    %-125s" "Dbeng.yaml contents matching patch number: ${PATCH_1[*]}"`# FAIL   #${NC}"
      echo -e "${RED}#`printf "    %-125s" "Lsinventory patch number: ${PATCHES[1]}"`# FAIL   #${NC}"
      echo -e "${RED}#`printf "    %-125s" "Dbeng.yaml contents matching patch number: ${PATCH_2[*]}"`# FAIL   #${NC}"
     fi
     home_patch_verification_fail=$((home_patch_verification_fail+1))
    else
     mapfile -t HOLDING_PATCH_PATH_1 < <( echo $PATCH_PATH_1 | sed 's/\//\n/g' )
     mapfile -t HOLDING_PATCH_PATH_2 < <( echo $PATCH_PATH_2 | sed 's/\//\n/g' )
     PATCH_PATH_SUM_1=( )
     PATCH_PATH_SUM_2=( )
     PATCH_PATH_INDEX_M=' '
     PATCH_PATH_INDEX_N=' '
     for (( m=1; m<=${#HOLDING_PATCH_PATH_1[@]}; m++ ))
     do
      mapfile -t PATCH_PATH_EXPANDED_1 < <( echo ${HOLDING_PATCH_PATH_1[$m-1]} | sed 's/\./\n/g' )
      (( PATCH_PATH_SUM_1[$m-1]= ${PATCH_PATH_EXPANDED_1[1]} + ${PATCH_PATH_EXPANDED_1[2]} ))
     done
     for (( n=1; n<=${#HOLDING_PATCH_PATH_2[@]}; n++ ))
     do
      mapfile -t PATCH_PATH_EXPANDED_2 < <( echo ${HOLDING_PATCH_PATH_2[$n-1]} | sed 's/\./\n/g' )
      (( PATCH_PATH_SUM_2[$n-1]= ${PATCH_PATH_EXPANDED_2[1]} + ${PATCH_PATH_EXPANDED_2[2]} ))
     done
     for (( m=1; m<=${#PATCH_PATH_SUM_1[@]}; m++ ))
     do
      for (( n=1; n<=${#PATCH_PATH_SUM_1[@]}; n++ ))
      do
       if [[ ${PATCH_PATH_SUM_1[$m-1]} = ${PATCH_PATH_SUM_2[$n-1]} ]] ; then
        PATCH_PATH_INDEX_M=$m-1
        PATCH_PATH_INDEX_N=$n-1
       fi
      done
     done
     if [[ $PATCH_PATH_INDEX_M = ' ' && PATCH_PATH_INDEX_N = ' ' ]] ; then
      if [[ "$2" = "detail" ]] ; then
       echo -e "${RED}#`printf " %-128s" "${FACT_HOMES[$i-1]}"`# FAIL   #${NC}"
       echo -e "${RED}#`printf "    %-125s" "Dbeng.yaml contains conflicting information or Home unstable. Manual verification of home required."`# FAIL   #${NC}"
       echo -e "${RED}#`printf "    %-125s" "opatch_inst_patch patch number: ${PATCHES[0]}"`# FAIL   #${NC}"
       echo -e "${RED}#`printf "    %-125s" "Dbeng.yaml matching patch path: ${PATCH_1[*]}"`# FAIL   #${NC}"
       echo -e "${RED}#`printf "    %-125s" "opatch_inst_patch patch number: ${PATCHES[1]}"`# FAIL   #${NC}"
       echo -e "${RED}#`printf "    %-125s" "Dbeng.yaml matching patch path: ${PATCH_2[*]}"`# FAIL   #${NC}"
      fi
      home_patch_verification_fail=$((home_patch_verification_fail+1))
     else
      mapfile -t PATCH_PATH_EXPANDED_1 < <( echo ${HOLDING_PATCH_PATH_1[$PATCH_PATH_INDEX_M]} | sed 's/\./\n/g' )
      mapfile -t PATCH_PATH_EXPANDED_2 < <( echo ${HOLDING_PATCH_PATH_2[$PATCH_PATH_INDEX_N]} | sed 's/\./\n/g' )
      if [[ ${PATCH_PATH_EXPANDED_1[1]} > ${PATCH_PATH_EXPANDED_2[1]} ]] ; then
       PATCH_PATH_FINAL=${HOLDING_PATCH_PATH_2[$PATCH_PATH_INDEX_N]}
      else
       PATCH_PATH_FINAL=${HOLDING_PATCH_PATH_1[$PATCH_PATH_INDEX_M]}
      fi
     fi
     if [[ $PATCH_PATH_FINAL = $PATCH_PATH ]] ; then
      if [[ "$2" = "detail" ]] ; then
       echo -e "${GREEN}#`printf " %-128s" "${FACT_HOMES[$i-1]} ora_patch_path_db_x: $PATCH_PATH , Lsinventory patch: $PATCH_PATH_FINAL"`# PASS   #${NC}"
      fi
      home_patch_verification_pass=$((home_patch_verification_pass+1))
     else
      if [[ "$2" = "detail" ]] ; then
       echo -e "${RED}#`printf " %-128s" "${FACT_HOMES[$i-1]} ora_patch_path_db_x: $PATCH_PATH , Lsinventory patch: $PATCH_PATH_FINAL"`# FAIL   #${NC}"
      fi
      home_patch_verification_fail=$((home_patch_verification_fail+1))
     fi
    fi
   elif [[ ! $PATCH_PATH = 'xx.xx.x' && ${HOME_INFO_J[1]} = '_' ]] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-128s" "${FACT_HOMES[$i-1]} ora_patch_path_db_x: $PATCH_PATH , Lsinventory patch: base install only"`# FAIL   #${NC}"
    fi
    home_patch_verification_fail=$((home_patch_verification_fail+1))
   else
    if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-128s" "${FACT_HOMES[$i-1]} Unknown Error"`# FAIL   #${NC}"
    fi
    home_patch_verification_fail=$((home_patch_verification_fail+1))
   fi
  fi
  else
    echo -e "${YELLOW}#`printf " %-128s" "DEFAULT HOME ${FACT_HOMES[$i-1]}"`# WARN   #${NC}"
  fi
 done
done

if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "ORACLE SW HOME PATCH VERIFY" $home_patch_verification_pass $home_patch_verification_fail

# END home_patch_verification
}



########################################
# listener_verification
########################################

listener_verification () {


echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 "LISTENER TO VERIFY" "FILE/PROCESS TO VERIFY"
fi

mapfile -t FACT_HOMES < <(cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep 'oradb::ora_home_db_' | sed  "s/^oradb::ora_home_db_\(.*:\) '\(.*\).*'/\1\2/" | sed 's/\r//')

for i in ${FACT_HOMES[*]}
do
 if [ ! `echo $i|awk '{print substr($0,length($0),1)}'` = 'x' ]; then
 mapfile -t HOME_INFO < <(echo $i | sed 's/:/\n/g' | sed 's/\r//')
 RUNNING=`ps -ef | grep ${HOME_INFO[1]}/bin/tnslsnr | grep -v grep | awk '{print $8}'`
 if [ ! -z $RUNNING ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Listener Running"`#`printf " %-72s" "Listener for Home ${HOME_INFO[1]}"`# PASS   #${NC}"
   fi
   listener_verification_pass=$((listener_verification_pass+1))
 else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Listener Running"`#`printf " %-72s" "Listener for Home ${HOME_INFO[1]}"`# FAIL   #${NC}"
   fi
   listener_verification_fail=$((listener_verification_fail+1))
 fi

 if [ -f ${HOME_INFO[1]}/network/admin/listener.ora ] ; then
  if [[ "$2" = "detail" ]] ; then
   echo -e "${GREEN}#`printf " %-54s" "Listener.ora Existence"`#`printf " %-72s" "${HOME_INFO[1]}/network/admin/listener.ora"`# PASS   #${NC}"
  fi
  listener_verification_pass=$((listener_verification_pass+1))
  if [ ! $(stat -c %a:%U:%G ${HOME_INFO[1]}/network/admin/listener.ora) = '644:oracle:oinstall' ] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" ${HOME_INFO[1]}"/network/admin/listener.ora"`# FAIL   #${NC}"
   fi
   listener_verification_fail=$((listener_verification_fail+5))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" ${HOME_INFO[1]}"/network/admin/listener.ora"`# PASS   #${NC}"
   fi
   listener_verification_pass=$((listener_verification_pass+5))
  fi
  VALID_NODE=`su -c "export ORACLE_HOME=${HOME_INFO[1]}; export LD_LIBRARY_PATH=${HOME_INFO[1]}/lib; export TNS_ADMIN=${HOME_INFO[1]}/network/admin; ${HOME_INFO[1]}/bin/lsnrctl show valid_node_checking_registration" - oracle 2>/dev/null | grep 'valid_node_checking_registration' | awk '{print $6}'`
  if [[ ! -z $VALID_NODE && $VALID_NODE = 'LOCAL' ]] ; then
   if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "valid_node_checking_registration"`#`printf " %-72s" "set to local for Home ${HOME_INFO[1]}"`# PASS   #${NC}"
   fi
   listener_verification_pass=$((listener_verification_pass+1))
  else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "valid_node_checking_registration"`#`printf " %-72s" "set to local for Home ${HOME_INFO[1]}"`# FAIL   #${NC}"
   fi
   listener_verification_fail=$((listener_verification_fail+1))
  fi
 else
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Listener.ora Existence"`#`printf " %-72s" "${HOME_INFO[1]}/network/admin/listener.ora"`# FAIL   #${NC}"
   fi
   listener_verification_fail=$((listener_verification_fail+1))
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "File Permissions:Owner:Group:World"`#`printf " %-72s" ${HOME_INFO[1]}"/network/admin/listener.ora"`# FAIL   #${NC}"
   fi
   listener_verification_fail=$((listener_verification_fail+5))
   if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "valid_node_checking_registration"`#`printf " %-72s" "set to local for Home ${HOME_INFO[1]}"`# FAIL   #${NC}"
   fi
   listener_verification_fail=$((listener_verification_fail+1))
 fi

 PORT_YAML=`/bin/cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep "oradb::db_port_db_${HOME_INFO[0]}" | awk '{print \$2}' | sed 's/\r//'`
 PORT_LSNR=`su -c "export ORACLE_HOME=${HOME_INFO[1]}; export LD_LIBRARY_PATH=${HOME_INFO[1]}/lib; export TNS_ADMIN=${HOME_INFO[1]}/network/admin; ${HOME_INFO[1]}/bin/lsnrctl status" - oracle 2>/dev/null | grep 'Connecting to' | sed "s/.*(PORT=\([0-9]*\)).*/\1/"`

 if [[ ! -z $PORT_YAML && ! -z $PORT_LSNR ]] ; then
  if [[ $PORT_YAML = $PORT_LSNR ]] ; then
   if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "Listener port number"`#`printf " %-72s" "port numbers match. File:$PORT_YAML , Actual:$PORT_LSNR" `# PASS   #${NC}"
   fi
   listener_verification_pass=$((listener_verification_pass+1))
  else
   if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "Listener port number"`#`printf " %-72s" "port numbers do not match. File:$PORT_YAML , Actual:$PORT_LSNR"`# FAIL   #${NC}"
   fi
   listener_verification_fail=$((listener_verification_fail+1))
  fi
 elif [[ -z $PORT_YAML && -z $PORT_LSNR ]] ; then
   if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "Listener port number"`#`printf " %-72s" "not found in External Fact .yaml or Listener.ora. Manual verification needed."`# FAIL   #${NC}"
     echo -e "${RED}#`printf " %-54s" ""`#`printf " %-72s" "File:$PORT_YAML , Actual:$PORT_LSNR"`# FAIL   #${NC}"
   fi
   listener_verification_fail=$((listener_verification_fail+1))
 elif [[ ! -z $PORT_YAML && -z $PORT_LSNR ]] ; then
   if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "Listener port number"`#`printf " %-72s" "can not verify port number. Listener.ora may not exist."`# FAIL   #${NC}"
     echo -e "${RED}#`printf " %-54s" ""`#`printf " %-72s" "File:$PORT_YAML , Actual:$PORT_LSNR"`# FAIL   #${NC}"
   fi
   listener_verification_fail=$((listener_verification_fail+1))
 elif [[ -z $PORT_YAML && ! -z $PORT_LSNR ]] ; then
   if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "Listener port number"`#`printf " %-72s" "not found in External Fact .yaml. Update artifactory file."`# FAIL   #${NC}"
     echo -e "${RED}#`printf " %-54s" ""`#`printf " %-72s" "File:$PORT_YAML , Actual:$PORT_LSNR"`# FAIL   #${NC}"
   fi
   listener_verification_fail=$((listener_verification_fail+1))
 fi
 else
  echo -e "${YELLOW}#`printf " %-54s" "DEFAULT ORACLE HOME"`#`printf " %-72s" " $i"`# FAIL   #${NC}"
 fi
done

if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "LISTENER VERIFY" $listener_verification_pass $listener_verification_fail


# END listener_verification
}


############################################################
# ORADB
############################################################

########################################
# dbint_verification
########################################

dbint_verification () {


mapfile -t FACT_HOMES < <(cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep -v "^#" | grep 'oradb::ora_home_db_' | sed  "s/^oradb::ora_home_db_\(.*:\) '\(.*\)'/\1\2/" | sed 's/\r//')

mapfile -t FACT_DBS < <(cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep -v "^#" | grep 'oradb_fs::ora_db_info_list_db_' | sed  "s/^oradb_fs::ora_db_info_list_db_\([0-9]*:\) \[ \('.*'\) \]/\1\2/" | sed "s/'\s*,\s*'/:/g;s/'//g;" | awk -F ':' '{ for (i=2;i<=NF;i+=5) print $1":"$i":"$(i+1)":"$(i+2)":"$(i+3)":"$(i+4) }' | sed 's/\r//')

PS=`ps -efwwl | grep -v grep | grep pmon`
HUMAN=`/usr/bin/who am i | awk '{print $1}' | sed 's/\n//'`
rm -rf /tmp/*dbint_verification.txt
#DB_INSTANCES=`/bin/cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep -v "^#" | grep 'oradb_fs::db_instances' | sed "s/.*'\(.*\)'.*/\1/"`

for (( i=0; i<=${#FACT_HOMES[@]}-1; i++ ))
do
  mapfile -t HOME_INFO < <(echo ${FACT_HOMES[$i]} | sed 's/:/\n/g')
  for (( j=0; j<=${#FACT_DBS[@]}-1; j++ ))
  do
    mapfile -t DB_INFO < <(echo ${FACT_DBS[$j]} | sed 's/:/\n/g')
    if [[ ${DB_INFO[0]} = ${HOME_INFO[0]} ]] ; then
     if [[ ${DB_INFO[1]} = 'yzzzzzzz' ]] ; then
       :
     else
      if [[ ! -z ${DB_INFO[1]} ]] ; then
        RUNNING=`echo $PS | grep -v grep | grep -i pmon_${DB_INFO[1]}`
        if [[ ${#RUNNING} > 0 ]] ; then
          mapfile -t SEC_INFO < <(echo ${DB_INFO[4]} | sed 's/~/\n/g')
          HOSTNAME_D=`hostname -d`
          su -c "
            export ORACLE_HOME=${HOME_INFO[1]}
            export TNS_ADMIN=\$ORACLE_HOME/network/admin
            export LD_LIBRARY_PATH=\$ORACLE_HOME/lib
            export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin:/root/bin:\$ORACLE_HOME/bin
            export ORACLE_SID=${DB_INFO[1]}
            sqlplus -S /nolog @/usr/local/bin/sql/dbint_verification.sql ${DB_INFO[2]} ${DB_INFO[1]} $HOSTNAME_D /opt/oracle/oradata/data${DB_INFO[3]} /opt/oracle/oradata/fra${DB_INFO[3]} /opt/oracle ${SEC_INFO[0]} ${SEC_INFO[1]} /tmp/${HUMAN}_${DB_INFO[1]}_dbint_verification.txt " - oracle 2>/dev/null
   
          mapfile -t DBINT_VERIFICATION_OUTPUT < <( cat /tmp/${HUMAN}_${DB_INFO[1]}_dbint_verification.txt | sed "/^$/d;s/:/\n/" ) 
          (( dbint_verification_pass = dbint_verification_pass + ${DBINT_VERIFICATION_OUTPUT[0]} ))
          (( dbint_verification_fail = dbint_verification_fail + ${DBINT_VERIFICATION_OUTPUT[1]} ))
        else
          if [[ "$2" = "detail" ]] ; then
            printf_repeat "#" 140
          fi
          printf_cjust_color "${HOME_INFO[1]} - ${DB_INFO[1]} is down - Unable to verify internal structures" 140 "YELLOW"
          if [[ "$2" = "detail" ]] ; then
            printf_repeat "#" 140
            echo -e ""
          fi
        fi 
      fi
     fi
    fi
  done
done


# END dbint_verification
}


########################################
# db_verification
########################################

db_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
printf_repeat "#" 140
printf_cjust "DETAIL" 140
printf_cjust "ORACLE DB TO ORACLE SW HOME VERIFY" 140
printf_repeat "#" 140
echo -e "#`printf " %-54s" "VERIFY ACTION"`#`printf " %-72s" "DB TO VERIFY"`# STATUS #"
printf_repeat "#" 140
fi


# mapfile -t FACT_DBS < <(cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep -v "^\#" | grep 'oradb_fs::ora_db_info_list_db' | awk -F '::' '{print " "$2}' | awk -F '[\\[\\]]' '{print ""$1","$2}' | sed "s/,/\n /g; s/'//g" | awk -F '[ :]' '{print $2}' | grep -v "^$")

mapfile -t FACT_DBS < <(cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep -v "^\#" | grep 'oradb_fs::ora_db_info_list_db' | awk -F ':' '{print $3}')

HUMAN=`/usr/bin/who am i | awk '{print $1}'`
FACTER=`/usr/local/bin/facter -p`

for j in ${FACT_DBS[*]}
do
 if [[ $j =~ 'ora_db_info_list_db' ]] ; then
  HOME_NUM=`echo $j | sed 's/ora_db_info_list_db_//'`
  HOME=`/bin/cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep -v "^\#" | grep "oradb::ora_home_db_$HOME_NUM" | awk -F\' '{print $2}'`
  PATCH_PATH=`/bin/cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep "oradb::ora_patch_path_db_$HOME_NUM" | awk -F\' '{print $2}' `

  if [[ "$2" = "detail" ]] ; then
   printf_repeat "#" 140
   echo -e "#`printf " %-54s" "ORACLE SW HOME"`#`printf " %-72s" "$HOME"`#        #"
   printf_repeat "#" 140
  fi

  HOMEDBLIST=`/bin/cat /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml | grep -v "^\#" | grep "oradb_fs::ora_db_info_list_db_$HOME_NUM" | sed 's/#.*//' | awk -F ': ' '{print $2}' | sed "s/'//g" | sed "s/\[//g" | sed "s/\]//g"| sed "s/\s*,\s*/:/g" | sed 's/ //g' | grep -v "^$" `
  num1=1
  num0=$(echo "${HOMEDBLIST}" | awk -F":" '{print NF}')
  num2=$((num0/5))
  num3=1
  while [ $num1 -le $num2 ]
  do
   db=`echo "${HOMEDBLIST}" | awk -v colvar=$num3 'BEGIN {OFS=FS=":"} {print $colvar}'`
  if [[ ${db} = 'yzzzzzzz' ]]; then
    echo -e "${YELLOW}#`printf " %-54s" "Database SID Set To DEFAULT Name"`#`printf " %-72s" "yzzzzzzz"`# WARN   #${NC}"
  else
   RUNNING=`ps -ef | grep pmon | grep $db | awk '{print $8}'`
   PROCID=`ps -ef | grep pmon | grep $db | awk '{print $2}'`
   if [[ ! -z $PROCID ]] ; then
    RUNNINGOH=`lsof -p $PROCID | grep -G "/opt/.*/bin/oracle" | sed 's/\/bin\/.*//' | awk '{print $9}'`
   fi
   if [[ ! -z $RUNNING && $RUNNING = "ora_pmon_${db}" && $RUNNINGOH = $HOME ]] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "Database Built and Running"`#`printf " %-72s" "$db"`# PASS   #${NC}"
    fi
    db_verification_pass=$((db_verification_pass+2))
    su -c "
          export ORACLE_HOME=$HOME
          export TNS_ADMIN=\$ORACLE_HOME/network/admin
          export LD_LIBRARY_PATH=\$ORACLE_HOME/lib
          export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/bin:/root/bin:\$ORACLE_HOME/bin
          export ORACLE_SID=$db
          sqlplus -S /nolog @/usr/local/bin/sql/db_patch_verification.sql /tmp/${HUMAN}_${db}_patch_info.txt" - oracle 2>/dev/null
    if [ -f "/tmp/${HUMAN}_${db}_patch_info.txt" ] ; then
     mapfile -t PATCHES < <(cat /tmp/${HUMAN}_${db}_patch_info.txt | grep ':' | sed 's/:/\n/; s/\r//g')
     PATCH_PATH_ZERO_REGEX='.*\.0\.0'
     if [[ $PATCH_PATH =~ $PATCH_PATH_ZERO_REGEX && -z ${PATCHES[0]} && -z ${PATCHES[1]} ]] ; then
      if [[ "$2" = "detail" ]] ; then
       echo -e "${GREEN}#`printf " %-54s" "Patch path"`#`printf " %-72s" "ora_patch_path_db_x: $PATCH_PATH , opatch_inst_patch: base install only"`# PASS   #${NC}"
      fi
      db_verification_pass=$((db_verification_pass+1))
     elif [[ ! $PATCH_PATH =~ $PATCH_PATH_ZERO_REGEX && $PATCH_PATH != 'xx.xx.x' && -z ${PATCHES[0]} && -z ${PATCHES[1]} ]] ; then
      if [[ "$2" = "detail" ]] ; then
       echo -e "${RED}#`printf " %-54s" "Patch path"`#`printf " %-72s" "ora_patch_path_db_x: $PATCH_PATH , opatch_inst_patch: base install only"`# FAIL   #${NC}"
      fi
      db_verification_fail=$((db_verification_fail+1))
     else
      mapfile -t PATCH_1 < <(echo "$FACTER" | grep "p${PATCHES[0]}_" | sed 's/[ ]*=>.*//' | awk -F '::' '{print $3":"$2}' | sed -r 's/(.*)_([1-9]?[0-9])_([0-2])/\1.\2.\3/')
      mapfile -t PATCH_2 < <(echo "$FACTER" | grep "p${PATCHES[1]}_" | sed 's/[ ]*=>.*//' | awk -F '::' '{print $3":"$2}' | sed -r 's/(.*)_([1-9]?[0-9])_([0-2])/\1.\2.\3/')
      if [ $PATCH_PATH = 'xx.xx.x' ] ; then
       PATCH_PATH='the default value (xx.xx.x)'
      fi
      if [[ ${PATCH_1[0]} =~ '^:' ]] ; then
       HOLDING_PATH=' '
       HOLDING_TYPE="mismatch"
      elif [[ ${#PATCH_1[@]} > 1 ]] ; then
       HOLDING_PATH=' '
       HOLDING_TYPE=' '
       for (( k=1; k<=${#PATCH_1[@]}; k++ ))
       do
        PATCH_TYPE_1=`echo ${PATCH_1[$k-1]} | awk -F ':' '{print $1}'`
        PATCH_PATH_1=`echo ${PATCH_1[$k-1]} | awk -F ':' '{print $2}'`
        if [ $k == 1 ] ; then
         HOLDING_PATH=$PATCH_PATH_1
        else
         HOLDING_PATH=$HOLDING_PATH"/"$PATCH_PATH_1
        fi
        if [ $k == 1 ] ; then
         HOLDING_TYPE=$PATCH_TYPE_1
        elif [ $HOLDING_TYPE = $PATCH_TYPE_1 ] ; then
         HOLDING_TYPE=$PATCH_TYPE_1
        else
         HOLDING_TYPE="mismatch"
        fi
       done
      elif [[ ${#PATCH_1[@]} = 1 ]] ; then
       HOLDING_TYPE=`echo ${PATCH_1[0]} | awk -F ':' '{print $1}'`
       HOLDING_PATH=`echo ${PATCH_1[0]} | awk -F ':' '{print $2}'`
      fi
      PATCH_PATH_1=$HOLDING_PATH
      PATCH_TYPE_1=$HOLDING_TYPE
      if [[ ${PATCH_2[0]} == '^:' ]] ; then
       HOLDING_PATH=' '
       HOLDING_TYPE="mismatch"
      elif [[ ${#PATCH_2[*]} > 1 ]] ; then
       HOLDING_TYPE=' '
       HOLDING_PATH=' '
       for (( h=1; h<=${#PATCH_2[@]}; h++ ))
       do
        PATCH_TYPE_2=`echo ${PATCH_2[$h-1]} | awk -F ':' '{print $1}'`
        PATCH_PATH_2=`echo ${PATCH_2[$h-1]} | awk -F ':' '{print $2}'`
        if [ $h == 1 ]; then
         HOLDING_PATH=$PATCH_PATH_2
        else
         HOLDING_PATH=$HOLDING_PATH"/"$PATCH_PATH_2
        fi
        if [ $h == 1 ] ; then
         HOLDING_TYPE=$PATCH_TYPE_2
        elif [ $HOLDING_TYPE = $PATCH_TYPE_2 ] ; then
         HOLDING_TYPE=$PATCH_TYPE_2
        else
         HOLDING_TYPE="mismatch"
        fi
       done
      elif [[ ${#PATCH_2[@]} = 1 ]] ; then
       HOLDING_TYPE=`echo ${PATCH_2[0]} | awk -F ':' '{print $1}'`
       HOLDING_PATH=`echo ${PATCH_2[0]} | awk -F ':' '{print $2}'`
      fi
      PATCH_PATH_2=$HOLDING_PATH
      PATCH_TYPE_2=$HOLDING_TYPE
## CODE MOD
      if [[ "$PATCH_PATH_1" = "$PATCH_PATH_2" && "$PATCH_PATH_1" = "$PATCH_PATH" && "$PATCH_TYPE_1" != 'mismatch' && "$PATCH_TYPE_2" != 'mismatch' ]] ; then
       PATCH_PATH_FINAL=$PATCH_PATH_1
       if [[ "$2" = "detail" ]] ; then
        echo -e "${GREEN}#`printf " %-54s" "Patch path"`#`printf " %-72s" "ora_patch_path_db_x: $PATCH_PATH , opatch_inst_patch: $PATCH_PATH_FINAL"`# PASS   #${NC}"
       fi
       db_verification_pass=$((db_verification_pass+1))
      elif [[ "$PATCH_PATH_1" = "$PATCH_PATH_2" && "$PATCH_PATH_1" != "$PATCH_PATH" && "$PATCH_TYPE_1" != 'mismatch' && "$PATCH_TYPE_2" != 'mismatch' && "$PATCH_PATH" = '12_2.0.0' ]] ; then
       PATCH_PATH_FINAL=$PATCH_PATH_1
        if [[ "$2" = "detail" ]] ; then
         echo -e "${YELLOW}#`printf " %-54s" "Patch path"`#`printf " %-72s" "ora_patch_path_db_x: $PATCH_PATH , opatch_inst_patch: $PATCH_PATH_FINAL"`# WARN   #${NC}"
        fi
        db_verification_pass=$((db_verification_pass+1))
      elif [[ "$PATCH_PATH_1" = "$PATCH_PATH_2" && "$PATCH_PATH_1" != "$PATCH_PATH" && "$PATCH_TYPE_1" != 'mismatch' && "$PATCH_TYPE_2" != 'mismatch' ]] ; then
       PATCH_PATH_FINAL=$PATCH_PATH_1
        if [[ "$2" = "detail" ]] ; then
         echo -e "${RED}#`printf " %-54s" "Patch path"`#`printf " %-72s" "ora_patch_path_db_x: $PATCH_PATH , opatch_inst_patch: $PATCH_PATH_FINAL"`# FAIL   #${NC}"
        fi
        db_verification_fail=$((db_verification_fail+1))
      elif [[ $PATCH_TYPE_1 = "mismatch" ]] || [[ $PATCH_TYPE_2 = "mismatch" ]] ; then
       if [[ "$2" = "detail" ]] ; then
        echo -e "${RED}#`printf " %-128s" "$db"`# FAIL   #${NC}"
        echo -e "${RED}#`printf "    %-125s" "Dbeng.yaml contains conflicting information or Home unstable. Manual verification of home required."`# FAIL   #${NC}"
        echo -e "${RED}#`printf "    %-125s" "opatch_inst_patch patch number: ${PATCHES[0]}"`# FAIL   #${NC}"
        echo -e "${RED}#`printf "    %-125s" "Dbeng.yaml matching patch number: ${PATCH_1[*]}"`# FAIL   #${NC}"
        echo -e "${RED}#`printf "    %-125s" "opatch_inst_patch patch number: ${PATCHES[1]}"`# FAIL   #${NC}"
        echo -e "${RED}#`printf "    %-125s" "Dbeng.yaml matching patch number: ${PATCH_2[*]}"`# FAIL   #${NC}"
       fi
       db_verification_fail=$((db_verification_fail+1))
      else
       mapfile -t HOLDING_PATCH_PATH_1 < <( echo $PATCH_PATH_1 | sed 's/\//\n/g' )
       mapfile -t HOLDING_PATCH_PATH_2 < <( echo $PATCH_PATH_2 | sed 's/\//\n/g' )
       PATCH_PATH_SUM_1=( )
       PATCH_PATH_SUM_2=( )
       PATCH_PATH_INDEX_I=' '
       PATCH_PATH_INDEX_J=' '
       for (( i=1; i<=${#HOLDING_PATCH_PATH_1[@]}; i++ ))
       do
        mapfile -t PATCH_PATH_EXPANDED_1 < <( echo ${HOLDING_PATCH_PATH_1[$i-1]} | sed 's/\./\n/g' )
        (( PATCH_PATH_SUM_1[$i-1]= ${PATCH_PATH_EXPANDED_1[1]} + ${PATCH_PATH_EXPANDED_1[2]} ))
       done
       for (( j=1; j<=${#HOLDING_PATCH_PATH_2[@]}; j++ ))
       do
        mapfile -t PATCH_PATH_EXPANDED_2 < <( echo ${HOLDING_PATCH_PATH_2[$j-1]} | sed 's/\./\n/g' )
        (( PATCH_PATH_SUM_2[$j-1]= ${PATCH_PATH_EXPANDED_2[1]} + ${PATCH_PATH_EXPANDED_2[2]} ))
       done
       for (( i=1; i<=${#PATCH_PATH_SUM_1[@]}; i++ ))
       do
        for (( j=1; j<=${#PATCH_PATH_SUM_1[@]}; j++ ))
        do
         if [[ ${PATCH_PATH_SUM_1[$i-1]} = ${PATCH_PATH_SUM_2[$j-1]} ]] ; then
          PATCH_PATH_INDEX_I=$i-1
          PATCH_PATH_INDEX_J=$j-1
         fi
        done
      done
       if [[ $PATCH_PATH_INDEX_I = ' ' && PATCH_PATH_INDEX_J = ' ' ]] ; then
        if [[ "$2" = "detail" ]] ; then
         echo -e "${RED}#`printf " %-128s" "$db"`# FAIL   #${NC}"
         echo -e "${RED}#`printf "    %-125s" "Dbeng.yaml contains conflicting information or Home unstable. Manual verification of home required."`# FAIL   #${NC}"
         echo -e "${RED}#`printf "    %-125s" "opatch_inst_patch patch number: ${PATCHES[0]}"`# FAIL   #${NC}"
         echo -e "${RED}#`printf "    %-125s" "Dbeng.yaml matching patch path: ${PATCH_1[*]}"`# FAIL   #${NC}"
         echo -e "${RED}#`printf "    %-125s" "opatch_inst_patch patch number: ${PATCHES[1]}"`# FAIL   #${NC}"
         echo -e "${RED}#`printf "    %-125s" "Dbeng.yaml matching patch path: ${PATCH_2[*]}"`# FAIL   #${NC}"
        fi
        db_verification_fail=$((db_verification_fail+1))
       else
        mapfile -t PATCH_PATH_EXPANDED_1 < <( echo ${HOLDING_PATCH_PATH_1[$PATCH_PATH_INDEX_I]} | sed 's/\./\n/g' )
        mapfile -t PATCH_PATH_EXPANDED_2 < <( echo ${HOLDING_PATCH_PATH_2[$PATCH_PATH_INDEX_J]} | sed 's/\./\n/g' )
        if [[ ${PATCH_PATH_EXPANDED_1[1]} > ${PATCH_PATH_EXPANDED_2[1]} ]] ; then
         PATCH_PATH_FINAL=${HOLDING_PATCH_PATH_2[$PATCH_PATH_INDEX_J]}
        else
         PATCH_PATH_FINAL=${HOLDING_PATCH_PATH_1[$PATCH_PATH_INDEX_i]}
        fi
       fi
## CODE MOD
       if [[ $PATCH_PATH_FINAL = $PATCH_PATH ]] ; then
        if [[ "$2" = "detail" ]] ; then
         echo -e "${GREEN}#`printf " %-54s" "Patch path"`#`printf " %-72s" "ora_patch_path_db_x: $PATCH_PATH , opatch_inst_patch: $PATCH_PATH_FINAL"`# PASS   #${NC}"
        fi
        db_verification_pass=$((db_verification_pass+1))
       elif [[ $PATCH_PATH = '12_2.0.0' &&  $PATCH_PATH_FINAL != $PATCH_PATH ]] ; then
        if [[ "$2" = "detail" ]] ; then
         echo -e "${YELLOW}#`printf " %-54s" "Patch path"`#`printf " %-72s" "ora_patch_path_db_x: $PATCH_PATH , opatch_inst_patch: $PATCH_PATH_FINAL"`# WARN   #${NC}"
        fi
        db_verification_pass=$((db_verification_pass+1))
       else
        if [[ "$2" = "detail" ]] ; then
         echo -e "${RED}#`printf " %-54s" "Patch path"`#`printf " %-72s" "ora_patch_path_db_x: $PATCH_PATH , opatch_inst_patch: $PATCH_PATH_FINAL"`# FAIL   #${NC}"
        fi
        db_verification_fail=$((db_verification_fail+1))
       fi
      fi
     fi
    else
     if [[ "$2" = "detail" ]] ; then
      echo -e "${GREEN}#`printf " %-54s" "Database Built and Running"`#`printf " %-72s" "$db"`# PASS   #${NC}"
      echo -e "${RED}#`printf " %-54s" "Patch path"`#`printf " %-72s" "DB script was not run. Db down."`# FAIL   #${NC}"
     fi
     db_verification_pass=$((db_verification_pass+2))
     db_verification_fail=$((db_verification_fail+1))
    fi
   else
    if [[ "$2" = "detail" ]] ; then
     echo -e "${RED}#`printf " %-54s" "Database Built and Running"`#`printf " %-72s" "$db"`# FAIL   #${NC}"
     echo -e "${RED}#`printf " %-54s" "Patch path"`#`printf " %-72s" "DB script was not run. Db down."`# FAIL   #${NC}"
    fi
    db_verification_fail=$((db_verification_fail+3))
   fi
   ORATAB=`/bin/cat /etc/oratab 2>/dev/null | grep $db:$HOME`
   if [ ! -z $ORATAB ] ; then
    if [[ "$2" = "detail" ]] ; then
     echo -e "${GREEN}#`printf " %-54s" "Database Has /etc/oratab Entry"`#`printf " %-72s" "$db"`# PASS   #${NC}"
    fi
    db_verification_pass=$((db_verification_pass+1))
    if [[ $ORATAB =~ "$db:$HOME:Y" ]] ; then
     if [[ "$2" = "detail" ]] ; then
      echo -e "${GREEN}#`printf " %-54s" "/etc/oratab Autorestart Entry Set"`#`printf " %-72s" "$db"`# PASS   #${NC}"
     fi
     db_verification_pass=$((db_verification_pass+1))
    else
     if [[ "$2" = "detail" ]] ; then
      echo -e "${RED}#`printf " %-54s" "/etc/oratab Autorestart Entry Set"`#`printf " %-72s" "$db"`# FAIL   #${NC}"
     fi
      db_verification_fail=$((db_verification_fail+1))
    fi
   else
    ORATAB=`/bin/cat /etc/oratab 2>/dev/null | grep -e "^$db:"`
    if [ ! -z $ORATAB ] ; then
     ORATAB_HOME=` echo $ORATAB | awk -F ':' '{print $2}'`
     if [[ "$2" = "detail" ]] ; then
      echo -e "${RED}#`printf " %-54s" "Database Has /etc/oratab Entry"`#`printf " %-72s" "External fact .yaml does not allign with /etc/oratab."`# FAIL   #${NC}"
      echo -e "${RED}#`printf " %-54s" ""`#`printf " %-72s" "expected home: $HOME"`# FAIL   #${NC}"
      echo -e "${RED}#`printf " %-54s" ""`#`printf " %-72s" "actual home: $ORATAB_HOME"`# FAIL   #${NC}"
     fi
     db_verification_fail=$((db_verification_fail+1))
     ORATAB_RESTART=` echo $ORATAB | awk -F ':' '{print $3}'`
     if [ $ORATAB_RESTART = 'Y' ] ; then
      if [[ "$2" = "detail" ]] ; then
       echo -e "${GREEN}#`printf " %-54s" "/etc/oratab Autorestart Entry Set"`#`printf " %-72s" "$db"`# PASS   #${NC}"
      fi
      db_verification_pass=$((db_verification_pass+1))
     else
      if [[ "$2" = "detail" ]] ; then
       echo -e "${RED}#`printf " %-54s" "/etc/oratab Autorestart Entry Set"`#`printf " %-72s" "$db"`# FAIL   #${NC}"
      fi
      db_verification_fail=$((db_verification_fail+1))
     fi
    else
      if [[ "$2" = "detail" ]] ; then
       echo -e "${RED}#`printf " %-54s" "Database Has /etc/oratab Entry"`#`printf " %-72s" "$db"`# FAIL   #${NC}"
      fi
     db_verification_fail=$((db_verification_fail+1))
      if [[ "$2" = "detail" ]] ; then
       echo -e "${RED}#`printf " %-54s" "/etc/oratab Autorestart Entry Set"`#`printf " %-72s" "$db"`# FAIL   #${NC}"
      fi
     db_verification_fail=$((db_verification_fail+1))
    fi
   fi
  fi
  num1=$((num1+1))
  num3=$((num3+5))
  done
 fi
done

if [[ "$2" = "detail" ]] ; then
printf_repeat "#" 140
echo -e ""
fi

printf_summary "ORACLE DB TO ORACLE SW HOME VERIFY" $db_verification_pass $db_verification_fail

# END db_verification
}

############################################################
# PUPPET
############################################################

########################################
# puppet_verification
########################################

puppet_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 "PUPPET SERVICE TO VERIFY" "FILE TO VERIFY"
fi

if [ -f /opt/puppetlabs/puppet/cache/state/agent_disabled.lock ]; then
  if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Agent"`#`printf " %-72s" "Enabled"`# PASS   #${NC}"
    DISABLED=`/bin/cat /opt/puppetlabs/puppet/cache/state/agent_disabled.lock | awk -F\" '{print $4}'`
    echo -e "${RED}#`printf " %-54s" "Agent"`#`printf " %-72s" "$DISABLED"`# PASS   #${NC}"
  fi
  puppet_verification_fail=$((puppet_verification_fail+1))
else
  if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Agent"`#`printf " %-72s" "Enabled"`# PASS   #${NC}"
  fi
  puppet_verification_pass=$((puppet_verification_pass+1))
fi
#
#
status=`/usr/bin/systemctl status puppet | grep "Active: active (running)" | awk -F\( '{print $2}' | awk -F\) '{print $1}'`
if [[ ! -z ${status} && "${status}" == "running" ]] ; then
  if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "Service"`#`printf " %-72s" "Running"`# PASS   #${NC}"
  fi
  puppet_verification_pass=$((puppet_verification_pass+1))
else
  if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "Service"`#`printf " %-72s" "Running"`# FAIL   #${NC}"
  fi
  puppet_verification_fail=$((puppet_verification_fail+1))
fi
#
#
if [ -f /opt/puppetlabs/facter/facts.d/$(hostname -f).yaml ]; then
  if [[ "$2" = "detail" ]] ; then
    echo -e "${GREEN}#`printf " %-54s" "External FACT yaml File"`#`printf " %-72s" "Deployed"`# PASS   #${NC}"
  fi
  puppet_verification_pass=$((puppet_verification_pass+1))
else
  if [[ "$2" = "detail" ]] ; then
    echo -e "${RED}#`printf " %-54s" "External FACT yaml File"`#`printf " %-72s" "Deployed"`# PASS   #${NC}"
  fi
  puppet_verification_fail=$((puppet_verification_fail+1))
fi
#
#
if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "PUPPET SERVICE VERIFY" $puppet_verification_pass $puppet_verification_fail

# END puppet_verify
}


############################################################
# EXTFACT
############################################################

extfact_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 "ORACLE PLATFORM EXTERNAL FACT TO VERIFY" "VARIABLE TO VERIFY"
fi

if [[ "$2" = "detail" ]] ; then
  echo -e "#`printf " %-54s" "Puppet Oracle Platform"`#`printf " %-72s" "Version 3.0 Feature"`# PASS   #${NC}"
fi

if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "ORACLE PLATFORM EXTERNAL FACT" $extfact_verification_pass $extfact_verification_fail


# END extfact_verification
}

############################################################
# INTFACT
############################################################

intfact_verification () {

echo -e ""
if [[ "$2" = "detail" ]] ; then
  printf_header1 "ORACLE PLATFORM INTERNAL FACT TO VERIFY" "VARIABLE TO VERIFY"
fi

if [[ "$2" = "detail" ]] ; then
  echo -e "#`printf " %-54s" "Puppet Oracle Platform"`#`printf " %-72s" "Version 3.0 Feature"`# PASS   #${NC}"
fi


if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 echo -e ""
fi

printf_summary "ORACLE PLATFORM INTERNAL FACT" $intfact_verification_pass $intfact_verification_fail


# END intfact_verification
}

############################################################
# HELP
############################################################
help_display () {

the_help_display="
These are the commands for the Database and OEM Platform.

          /usr/local/bin/puppet_oraverify.sh platform sum
          /usr/local/bin/puppet_oraverify.sh platform detail
          /usr/local/bin/puppet_oraverify.sh bootstrap sum
          /usr/local/bin/puppet_oraverify.sh bootstrap detail
          /usr/local/bin/puppet_oraverify.sh prereqs sum
          /usr/local/bin/puppet_oraverify.sh prereqs detail
          /usr/local/bin/puppet_oraverify.sh postreqs sum
          /usr/local/bin/puppet_oraverify.sh postreqs detail
          /usr/local/bin/puppet_oraverify.sh oem sum
          /usr/local/bin/puppet_oraverify.sh oem detail
          /usr/local/bin/puppet_oraverify.sh orahome sum
          /usr/local/bin/puppet_oraverify.sh orahome detail
          /usr/local/bin/puppet_oraverify.sh oradb sum
          /usr/local/bin/puppet_oraverify.sh oradb detail
          /usr/local/bin/puppet_oraverify.sh orabasic sum
          /usr/local/bin/puppet_oraverify.sh orabasic detail
          /usr/local/bin/puppet_oraverify.sh oraall sum
          /usr/local/bin/puppet_oraverify.sh oraall detail
          /usr/local/bin/puppet_oraverify.sh extfact sum
          /usr/local/bin/puppet_oraverify.sh extfact detail
          /usr/local/bin/puppet_oraverify.sh intfact sum
          /usr/local/bin/puppet_oraverify.sh intfact detail
          /usr/local/bin/puppet_oraverify.sh puppet
          /usr/local/bin/puppet_oraverify.sh help
          /usr/local/bin/puppet_oraverify.sh

 Column display width for commands are 140 characters.
 Number of lines for the display buffer scrollback for commands are 5000 lines.
"

echo "$the_help_display"
exit 1

}


############################################################
# EXECUTE CODE
############################################################

oraverify "$@"

ora_platform_pass=$((puppet_verification_pass+
ora_bootstrap_verification_pass+
linux_ora_os_file_verification_pass+
linux_ora_pkg_verification_pass+
linux_ora_os_groups_verification_pass+
linux_ora_os_users_verification_pass+
linux_ora_os_verification_pass+
ora_setup_verification_pass+
full_export_scripts_verification_pass+
bash_profile_verification_pass+
db_maintenance_scripts_verification_pass+
sw_verification_pass+
home_patch_verification_pass+
listener_verification_pass+
db_verification_pass+
dbint_verification_pass))



ora_platform_fail=$((puppet_verification_fail+
ora_bootstrap_verification_fail+
linux_ora_os_file_verification_fail+
linux_ora_pkg_verification_fail+
linux_ora_os_groups_verification_fail+
linux_ora_os_users_verification_fail+
linux_ora_os_verification_fail+
ora_setup_verification_fail+
full_export_scripts_verification_fail+
bash_profile_verification_fail+
db_maintenance_scripts_verification_fail+
sw_verification_fail+
home_patch_verification_fail+
listener_verification_fail+
db_verification_fail+
dbint_verification_fail))

ora_platform_total=$((ora_platform_pass+ora_platform_fail))

echo -e ""
if [[ "$2" = "detail" ]] ; then
 printf_repeat "#" 140
 printf_cjust "END OF DETAIL" 140
 printf_repeat "#" 140
fi


echo -e ""
printf_repeat "#" 80
printf_repeat "#" 80
printf_cjust "SUMMARY TOTAL" 80
printf_cjust "ORACLE PLATFORM" 80
printf_repeat "#" 80
echo -e "${GREEN}#`printf " %-77s" "TOTAL SPECS PASSED                     : ${ora_platform_pass-0}"`#${NC}"
if [[ "$(($ora_platform_fail))" = "0" ]] ; then
 echo -e "${GREEN}#`printf " %-77s" "TOTAL SPECS FAILED                     : ${ora_platform_fail-0}"`#${NC}"
else
 echo -e "${RED}#`printf " %-77s" "TOTAL SPECS FAILED                     : ${ora_platform_fail-0}"`#${NC}"
fi
echo -e "#`printf " %-77s" "TOTAL SPECS TO ENFORCE                 : $((${ora_platform_total}))"`#"
if [[ "$((${ora_platform_pass-0}+${ora_platform_fail-0}))" = "0" ]] ; then
 echo -e "${NC}#`printf " %-77s" "PERCENTAGE OF SPECS ENFORCED           : 0.00%"`#${NC}"
elif [[ "`echo "scale=2;(${ora_platform_pass-0}/(${ora_platform_total-0}))*100" | bc -l`" = 100.00 ]] ; then
 num1=`echo "scale=2;(${ora_platform_pass-0}/(${ora_platform_total-0}))*100" | bc -l`
 echo -e "${GREEN}#`printf " %-77s" "PERCENTAGE OF SPECS ENFORCED           : ${num1}%"`#${NC}"
else
  num1=`printf %.2f $(echo "((${ora_platform_pass-0})/(${ora_platform_total-0}))*100" | bc -l)`
  echo -e "${RED}#`printf " %-77s" "PERCENTAGE OF SPECS ENFORCED           : ${num1}%"`#${NC}"
fi
printf_repeat "#" 80

################################################################################
# END
################################################################################



