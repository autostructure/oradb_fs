#!/usr/bin/env ksh
alias shopt=': '; UID=$(id | sed 's|(.*||;s|.*=||'); . /home/grid/.bash_profile
function usage_exit {
   echo "Usage: $0 -d <db_name> [ -r ]
   where -r specifies to delete subdirectories: ONLINELOG, ARCHIVELOG, BACKUPSET"
   exit 1
}
while getopts hd:r option
do
   case "$option"
   in
      h) usage_exit;;
      d) export db_name="$OPTARG";;
      r) export RM_ARCH_DIRS="YES";;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done

export ID=$(id -u -n)
if [[ $ID != grid ]]; then
   echo "ERROR: run as user grid"
   usage_exit
fi
if [[ -z $db_name ]]; then
   echo "ERROR: please set environment variable db_name"
   usage_exit
fi
#crs_stat ora.$db_name.db;
#export rc=$?
#if ((rc!=0)); then
#   echo "ERROR: $db_name doesn't appeart to ba a registered database"
#   exit $rc
#fi
export ORACLE_SID=$(ps -ef | grep [p]mon_+ASM | sed 's|.*asm_pmon_||')
(sleep 1;echo "find * *") | asmcmd -p > /tmp/find_asm.txt
cnt=$(grep '^+[A-Z][^/]*/' /tmp/find_asm.txt | wc -l)
echo "cnt=$cnt"
if ((cnt<6)); then
   echo "ERROR: couldn't find sufficient ASM directories"
   exit
fi
tr ' ' '\n' < /tmp/find_asm.txt |  tr -d '\r' | sort -r | egrep -v '/ONLINELOG|/ARCHIVELOG|/BACKUPSET' | grep -i /$db_name/ | sed '/\/$/!d;s|^|rm |;s|$|*\&~|' | tr '&~' '\ny' > /tmp/find_asm.rm.sh
wc /tmp/find_asm.rm.sh

if [[ $RM_ARCH_DIRS == "YES" ]]; then
   echo "Adding removal for Archive related directories"
   # Note that the only difference from the above is that the below read "egrep -v"
   tr ' ' '\n' < /tmp/find_asm.txt |  tr -d '\r' | sort -r | egrep '/ONLINELOG|/ARCHIVELOG|/BACKUPSET' | grep -i /$db_name/ | sed '/\/$/!d;s|^|rm |;s|$|*\&~|' | tr '&~' '\ny' >> /tmp/find_asm.rm.sh
fi
wc /tmp/find_asm.rm.sh
echo "Output file is:  /tmp/find_asm.rm.sh"
echo "SCRIPT SUCCESSFULLY COMPLETED"
