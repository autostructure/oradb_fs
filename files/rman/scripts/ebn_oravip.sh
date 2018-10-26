#!/usr/bin/env ksh
#
# File: ebn_oravip.sh
#
# Purpose: Configure Oracle VIPs for the EBN network in NITC
#

[[ $(id) == "uid=1002(grid)"* ]] || { echo "Run as grid"; exit 1; }
[[ -d /var/tmp/rman ]] || sudo -u oracle mkdir /var/tmp/rman || exit 1
sudo -u oracle chmod 777 /var/tmp/rman || exit 2
sudo -u oracle chown oracle.oinstall /var/tmp/rman || exit 3
if [[ $? != 0 ]]; then
   echo "Error: couldn't do: chmod 777 /var/tmp/rman"; exit 1;
fi
export NOW=$(date +"%Y-%m-%d:%H:%M:%S")
export LOG=/var/tmp/rman/ebn_oravip.sh.$NOW.log
export LOG=/var/tmp/rman/ebn_oravip.sh.log  #TODO
if ! touch $LOG; then echo "ERROR: couldn't touch $LOG"; exit 1; fi
while getopts b option; do
   case "$option" in
      b) export BACK_OUT="YES";;
     \?) eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         echo "Usage: $0 [-b]";;
   esac
done

function error_exit {
   echo "  ERROR $2"
   exit $1
}
#This code doesn't properly set the colums more than 80 when it is in the {} block of code.
stty_columns=$(stty -a | tr ';' '\n' | grep 'columns')
stty columns 65535; sudo -l > $LOG.sudo-l || error_exit 1 "couldn't do 'sudo -l'"
stty $stty_columns

{
   function error_exit {
     echo "  ERROR $2"
     exit $1
   }
   function set_envars {
      bin_dir=/opt/grid/12.1.0/grid_1/bin
      [[ -f $bin_dir/appvipcfg ]] || error_exit 1 "couldn't validate executable diectory (1)"
      [[ -f $bin_dir/srvctl ]] || error_exit 1 "couldn't validate executable diectory (2)"
   }
   function check_whoami {
      echo "==Check grid user"
      [[ $(whoami) != "grid" ]] && error_exit 1 "run as user grid"
   }
   function check_sudo {
      echo "==Check sudo priviledges"
      unset msg
      grep -q '(root) SETENV: NOPASSWD: .*/opt/oracle/product/11.2.0/db_?/bin/srvctl' $LOG.sudo-l || msg="$msg 'sudo -l' for user $(whoami) missing 'SETENV: NOPASSWD: .*/opt/oracle/product/11.2.0/db_?/bin/srvctl'          "
      grep -q '(root) .*NOPASSWD: .*/opt/grid/12.1.0/grid_?/bin/appvipcfg' $LOG.sudo-l || msg="$msg 'sudo -l' for user $(whoami) missing '(root) NOPASSWD: .*/opt/grid/12.1.0/grid_?/bin/appvipcfg'         "
      grep -q '(root) .*NOPASSWD: .*/opt/grid/12.1.0/grid_?/bin/srvctl' $LOG.sudo-l || msg="$msg '(root) NOPASSWD: .*/opt/grid/12.1.0/grid_?/bin/srvctl'        "
      grep -q '(root) .*NOPASSWD: .*/sbin/ifconfig' $LOG.sudo-l || msg="$msg sudo for user $(whoami) missing '(root) .*NOPASSWD: .*/sbin/ifconfig'          "
      grep -q '(root) .*NOPASSWD: .*/usr/openv/netbackup/bin/goodies/netbackup' $LOG.sudo-l || msg="$msg sudo for user $(whoami) missing '(root) .*NOPASSWD: .*/usr/openv/netbackup/bin/goodies/netbackup'          "
      [[ -z $msg ]] || error_exit 4 "sudo missing priviledges:  $msg"
   }
   function prompt_IP {
      echo "== Prompt for Oracle VIP IP address on the EBN network"
      if [[ -z $IP ]]; then
         while true; do
            host $(hostname)-oravip-ebn
            default=$(host $(hostname)-oravip-ebn | sed 's|.* ||')
            echo "Enter Oracle VIP IP address on the EBN network [$default]:"
            read IP; export IP
            if [[ -z $IP ]]; then
               IP=$default
            fi
            if ((  $( echo $IP | tr '[0-9]' '\n'  | grep -c '\.' )   != 3 )); then
               echo "IP missing 3 periods.  Please reenter."
            else
               break
            fi
         done
      fi
   }
   function prompt_NM {
      echo "== Prompt for EBN netmask"
      if [[ -z $NM ]]; then
         while true; do
            echo "Enter EBN net mask [255.255.252.0]: "
            read NM; export NM
            if [[ -z $NM ]]; then 
               export NM="255.255.252.0"
            fi
            if ((  $( echo $NM | tr '[0-9]' '\n'  | grep -c '\.' )   != 3 )); then
               echo "Netmask missing 3 periods.  Please reenter."
            else
               break
            fi
         done
      fi
   }
   function compute_subnet {
      echo "== Comput Sub net"
      IPs=( $(echo $IP | tr '.' ' ') )
      echo IPs=${IPs[*]}  >> $LOG
      NMs=( $(echo $NM | tr '.' ' ') )
      echo NMs=${NMs[*]} >> $LOG

      subnet=$( cnt=0; unset delm; while ((cnt<4)); do echo -e "$delm$(( ${IPs[cnt]}  &  ${NMs[cnt]} ))\c"; ((cnt=cnt+1)); delm=.; done; echo)
      echo ".. Subnet: $subnet"
      echo "subnet=$subnet" >> $LOG
   }
   function compute_BCAST {
      echo "== Compute the broadcast map"
      cnt=0
      while ((cnt<4)); do
         ((BCASTs[cnt]=(~${NMs[cnt]} & 255 ) | ${IPs[cnt]} ))
         ((cnt=cnt+1))
      done
      BCAST=$(echo "${BCASTs[0]}.${BCASTs[1]}.${BCASTs[2]}.${BCASTs[3]}")
      echo "Boradcast map: $BCAST"
      # For example:  10.202.51.255
   }
   function get_node_number {
      echo "== Get node number"
      NODE_NUM=$($bin_dir/olsnodes -n | grep $(hostname) | awk '{print $2}')
      echo "NODE_NUM=$NODE_NUM"
   }
   function unconfigure_previous_ebn_oravip {
      echo "== Unconfig previous EBN Oracle VIP"
      [[ -z $bin_dir ]] && error_exit 1 '$bin_dir is null'
      [[ -z $NODE_NUM ]] && error_exit 1 '$NODE_NUM is null'
      if $bin_dir/crs_stat | grep net.ebn${NODE_NUM}.vip; then 
         echo ".. Removing"
         sudo $bin_dir/appvipcfg delete -vipname=net.ebn${NODE_NUM}.vip -force || error_exit 1 "couldn't remove Oracle EBN VIP ($)"
      else
         echo ".. Oracle EBN VIP (net.ebn${NODE_NUM}.vip) already missing.  Skipping."
      fi
   }
   function unconfigure_all_ebn_oravip {
      echo "== Unconfigure all EBN Oracle VIPs"
      max_node=$($bin_dir/olsnodes -n | sort -k2 -n | awk '{print $2}' | tail -1)
      NODE_NUM_BU=$NODE_NUM
      NODE_NUM=1
      while ((NODE_NUM<=max_node)); do
         export NODE_NUM
         echo ".. NODE_NUM=$NODE_NUM"
         unconfigure_previous_ebn_oravip
         ((NODE_NUM=NODE_NUM+1))
      done
   }
   function old_match_subnet_to_NIC {
      echo "== Match subnet to NIC"
      bonded_ifs=$( (ifconfig | sed '/^[a-zA-Z]/!d; {s| .*||; /:/!d; s|:.*|| }' | sort -u | tr '\n' '|'; echo ) | sed 's/|$//' ); 
      echo bonded_ifs=$bonded_ifs >> $LOG
      #For example:  eth0|eth2

      ebn_candidates=$(ifconfig | sed '/^[a-zA-Z]/!d; {s| .*||; }' | grep -Ev $bonded_ifs | grep -v ^lo)
      echo ebn_candidates=$ebn_candidates >> $LOG
      #For example:  eth1 eth3

      ebn_if=$(
         for if in $ebn_candidates; do 
            if_IPs=( $(ifconfig $if | sed '/inet addr:/!d; s|.*inet addr:||; s|[^0-9.].*$||; s|\.| |g') ); 
            echo ${if_IPs[0]} ${if_IPs[1]} ${if_IPs[2]} ${if_IPs[3]} > /dev/null;        
            if_subnet=$(cnt=0; unset delm; while ((cnt<4)); do 
               echo -e "$delm$(( ${if_IPs[cnt]}  &  ${NMs[cnt]} ))\c"; ((cnt=cnt+1)); delm=.; done; echo); 
               if [[ $if_subnet == $subnet ]]; then echo $if; fi; 
            done); 
      echo ebn_if=$ebn_if >> $LOG
      cnt=$(echo "$ebn_if" | wc -w)
      echo "cnt=$cnt" >> $LOG
      ((cnt==1)) || error_exit 3 "couldn't find a single NIC on the EBN subnet"
   }
   function match_BCAST_to_NIC {
      echo "== Match BCAST to a NIC"
      [[ -z $BCAST ]] && error_exit 1 "\$BCAT is null"
      physical_nics=$(ifconfig | sed '/^[a-zA-Z]/!d; s| .*||; /:/d; /^lo$/d')
      echo "physical_nics=$physical_nics" >> $LOG
      for nic in $physical_nics; do 
         if ifconfig $nic | grep $BCAST; then
            ebn_if=$nic
            break
         fi
      done
      echo ebn_if=$ebn_if >> $LOG
      cnt=$(echo "$ebn_if" | wc -w)
      echo "cnt=$cnt" >> $LOG
      ((cnt==1)) || error_exit 3 "couldn't find a single NIC on the EBN subnet"
   }
   function ifconfig_down_running_ora_vip {
      echo "== Stop the Oracle VIP if it is running"
      nics=$(ifconfig | grep ^$ebn_if: | sed 's| .*||')
      echo "nics=$nics" >> $LOG
      for nic in $nics; do 
         sudo /sbin/ifconfig $nic down || error_exit 1 "couldn't stop VIP: $nic"
      done
   }
   function set_VIPNAME {
      echo "== Set VIP name"
      VIPNAME=net.ebn${NODE_NUM}.vip
      echo "VIPNAME=$VIPNAME" >> $LOG
   }
   function add_oracle_network {
      echo "== Create Oracle Network"
      NETNUM=1
      while ((NETNUM<4)); do
         $bin_dir/srvctl config network  -netnum $NETNUM > /tmp/ebn_oravip.sh.$NETNUM.set_NETNUM  2>&1
         rc=$?
         if [[ $rc != 0 ]]; then
            # TODO, test this path
            echo ".. create the network since we didn't find one with the Netmask and subnet"
            echo "sudo $bin_dir/srvctl add network -netnum $NETNUM -subnet $subnet/$NM/$ebn_if" >> $LOG
            sudo $bin_dir/srvctl add network -netnum $NETNUM -subnet $subnet/$NM/$ebn_if
            break
         fi
         if grep -q $subnet/$NM /tmp/ebn_oravip.sh.$NETNUM.set_NETNUM; then
            echo ".. The network is already created, so don't create it"
            break
         fi
         ((NETNUM=NETNUM+1))
      done
      echo "NETNUM=$NETNUM"
   }
   function create_vip {
      echo "== Create VIP"
      if ! $bin_dir/crs_stat | grep $VIPNAME; then
         echo ".. VIP missing, now creating it"
         sudo $bin_dir/appvipcfg create -network=$NETNUM -ip=$IP -vipname=$VIPNAME -user=root | tee /tmp/ebn_oravip.sh.appvipcfg.log 
         grep CRS-[0-9] /tmp/ebn_oravip.sh.appvipcfg.log 
         # rc=$?  doesn't work
         [[ $? == 0 ]] && error_exit 1 "couldn't create VIP"

         # http://oracle.su/docs/11g/rac.112/e10717/crschp.htm#BGBGJIHB
         # favored: If values are assigned to either the SERVER_POOLS or HOSTING_MEMBERS resource attribute, then Oracle Clusterware considers servers belonging to the member list in either attribute first. If no servers are available, then Oracle Clusterware places the resource on any other available server. If there are values for both theSERVER_POOLS and HOSTING_MEMBERS attributes, then SERVER_POOLS indicates preference and HOSTING_MEMBERS restricts the choices to the servers within that preference.
         sudo $bin_dir/crsctl modify resource $VIPNAME -attr "PLACEMENT=favored, HOSTING_MEMBERS=$(hostname)"
         [[ $? == 0 ]] || error_exit 1 "couldn't set PLACEMENT and HOSTING_MEMBER attriutes for the VIP"
         #bin_dir/crsctl status res net.ebn2.vip -p  | grep -Ei 'placement|hosting_members'
      else
         echo ".. VIP already exists, so skipping create..."
      fi
   }
   function start_vip {
      echo "== Add new VIP to cluster resources for auto atarting"
      sudo $bin_dir/crsctl start resource $VIPNAME >> $LOG 2>&1
      rc=$?  # rc works for crsctl

      #sudo $bin_dir/srvctl add vip -n $(hostname) -k $NETNUM -A $IP/$NM >> $LOG 2>&1
      #rc=$?
      #
      #sudo srvctl start vip -n $(hostname) -i  >> $LOG 2>&1
   }
   function create_netbackup_log_dir {
      echo "== Create Netbackup client's log directory"
      if [[ ! -d /usr/openv/netbackup/bin/dbclient ]]; then
         echo ".. missing, so creating it"
         mkdir /usr/openv/netbackup/bin/dbclient
         chmod 755 /usr/openv/netbackup/bin/dbclient
      else
         echo ".. exists already, so skipping..."
      fi
   }
   function extrapolate_NM_and_subnet {
      echo "== Extrapolate NM from the log"
      eval $(grep ^NETNUM= $LOG | tail -1)  #Output: $NETNUM
      eval $(grep ^subnet= $LOG | tail -1)  #Output: $subnet
      eval $(grep ^ebn_if= $LOG | tail -1)  #Output: $ebn_if
      echo ".. NETNUM: $NETNUM"
      echo ".. Subnet: $subnet"
      echo ".. ebn_if: $ebn_if"
   }
   function srvctl_remove_network {
      echo "== Remove Oracle network object"
      [[ -z $NETNUM ]] && error_exit 1 "null Network number"
      export TMP_MAX_SRVCTL=$(ls /opt/oracle/product/11.2.0/db_*/bin/srvctl | sort | tail -1)
      [[ -z $TMP_MAX_SRVCTL ]] && error_exit 1 "couldn't find max ORACLE_HOME for srvctl"
      cnt=$( (export ORACLE_HOME=/opt/oracle/product/11.2.0/db_1/; sudo -E $ORACLE_HOME/bin/srvctl config network)  | grep $NETNUM/$subnet/[^/]*/$ebn_if | wc -l)
      if ((cnt<1)); then
         echo ".. network already gone, nothing to do"
      else
         cnt2=$( (export ORACLE_HOME=/opt/oracle/product/11.2.0/db_1/; sudo -E $ORACLE_HOME/bin/srvctl config network)  | grep -v $NETNUM/$subnet/[^/]*/$ebn_if | wc -l)
         if ((cnt2<1)); then
            echo ".. This Oracle network object is the last.  Delete it anyway? (n/[y]): "
            read resp
            if [[ $resp != [yY]* ]]; then
               echo ".. exiting on user's request."
               exit 1
            fi
         else
            echo ".. found n=$cnt other networks, continuing..."
         fi
         echo ".. Dropping Oracle Network object ($NETNUM):  $NETNUM/$subnet/[^/]*/$ebn_if"
         (export ORACLE_HOME=${TMP_MAX_SRVCTL%/bin/srvctl}; sudo -E $ORACLE_HOME/bin/srvctl remove network  -k $NETNUM -f)
         #TODO, need some error handling here.
      fi
   }
   ### MAIN ###
   set_envars
   check_whoami
   check_sudo
   if [[ $BACK_OUT == "YES" ]]; then
      extrapolate_NM_and_subnet
      get_node_number
      unconfigure_all_ebn_oravip
      srvctl_remove_network
   else
      prompt_IP
      prompt_NM
      compute_subnet
      compute_BCAST
      get_node_number
      unconfigure_previous_ebn_oravip
      #old_match_subnet_to_NIC
      match_BCAST_to_NIC
      ifconfig_down_running_ora_vip
      set_VIPNAME
      add_oracle_network
      create_vip
      start_vip  
      create_netbackup_log_dir
   fi

   echo "SCRIPT COMPLETED SUCCESSFULLY $(date)"
} 2>&1 | tee -a $LOG
echo "Log file for this script is $LOG"
tail $LOG | grep -q "^SCRIPT COMPLETED SUCCESSFULLY" || exit 1
exit 0

