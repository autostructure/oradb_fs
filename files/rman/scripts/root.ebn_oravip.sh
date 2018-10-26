#!/usr/bin/env ksh
#
# File: ebn_oravip.sh
#
# Purpose: Configure Oracle VIPs for the EBN network in NITC
#

mkdir /var/tmp/rman 2> /dev/null
chmod 777 /var/tmp/rman
chown oracle.oinstall /var/tmp/rman
if [[ $? != 0 ]]; then
   echo "Error: couldn't do: chmod 777 /var/tmp/rman"; exit 1;
fi
export NOW=$(date +"%Y-%m-%d:%H:%M:%S")
export LOG=/var/tmp/rman/ebn_oravip.sh.$NOW.log
export LOG=/var/tmp/rman/ebn_oravip.sh.log  #TODO

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
   function check_root_user {
      echo "==Check root user"
      [[ $(whoami) != "root" ]] && error_exit 1 "run as user root"
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
      echo ".. subnet=$subnet"
   }
   function compute_BCAST {
      echo "== Compute the broadcast map"
      cnt=0
      while ((cnt<4)); do
         ((BCASTs[cnt]=(~${NMs[cnt]} & 255 ) | ${IPs[cnt]} ))
         ((cnt=cnt+1))
      done
      BCAST=$(echo "${BCASTs[0]}.${BCASTs[1]}.${BCASTs[2]}.${BCASTs[3]}")
      # For example:  10.202.51.255
   }
   function get_node_number {
      echo "== Get node number"
      NODE_NUM=$($bin_dir/olsnodes -n | grep $(hostname) | awk '{print $2}')
      echo "NODE_NUM=$NODE_NUM"
   }
   function unconfigure_previous_ebn_oravip {
      echo "== Unconfig previous EBN Oracle VIP"
      if $bin_dir/crs_stat | grep net.ebn${NODE_NUM}.vip; then 
         echo ".. Removing"
         $bin_dir/appvipcfg delete -vipname=net.ebn${NODE_NUM}.vip -force || error_exit 1 "couldn't remove Oracle EBN VIP ($)"
      else
         echo ".. Oracle EBN VIP (net.ebn${NODE_NUM}.vip) already missing.  Skipping."
      fi
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
      physical_nics=$(ifconfig | sed '/^[a-zA-Z]/!d; s| .*||; /:/d; /^lo$/d')
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
         ifconfig $nic down || error_exit 1 "couldn't stop VIP: $nic"
      done
   }
   function set_VIPNAME {
      echo "== Set VIP name"
      VIPNAME=net.ebn${NODE_NUM}.vip
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
            $bin_dir/srvctl add network -netnum $NETNUM -subnet $subnet/$NM/$ebn_if
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
         $bin_dir/appvipcfg create -network=$NETNUM -ip=$IP -vipname=$VIPNAME -user=root | tee /tmp/ebn_oravip.sh.appvipcfg.log 
         grep CRS-[0-9] /tmp/ebn_oravip.sh.appvipcfg.log 
         # rc=$?  doesn't work
         [[ $? == 0 ]] && error_exit 1 "couldn't create VIP"

         # http://oracle.su/docs/11g/rac.112/e10717/crschp.htm#BGBGJIHB
         # favored: If values are assigned to either the SERVER_POOLS or HOSTING_MEMBERS resource attribute, then Oracle Clusterware considers servers belonging to the member list in either attribute first. If no servers are available, then Oracle Clusterware places the resource on any other available server. If there are values for both theSERVER_POOLS and HOSTING_MEMBERS attributes, then SERVER_POOLS indicates preference and HOSTING_MEMBERS restricts the choices to the servers within that preference.
         $bin_dir/crsctl modify resource $VIPNAME -attr "PLACEMENT=favored, HOSTING_MEMBERS=$(hostname)"
         [[ $? == 0 ]] || error_exit 1 "couldn't set PLACEMENT and HOSTING_MEMBER attriutes for the VIP"
         #bin_dir/crsctl status res net.ebn2.vip -p  | grep -Ei 'placement|hosting_members'
      else
         echo ".. VIP already exists, so skipping create..."
      fi
   }
   function start_vip {
      echo "== Add new VIP to cluster resources for auto atarting"
      $bin_dir/crsctl start resource $VIPNAME >> $LOG 2>&1
      rc=$?  # rc works for crsctl

      #$bin_dir/srvctl add vip -n $(hostname) -k $NETNUM -A $IP/$NM >> $LOG 2>&1
      #rc=$?
      #
      #srvctl start vip -n $(hostname) -i  >> $LOG 2>&1
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
   ### MAIN ###
   set_envars
   check_root_user
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

   echo "SCRIPT COMPLETED SUCCESSFULLY $(date)"
} 2>&1 | tee -a $LOG
echo "Log file for this script is $LOG"
tail $LOG | grep -q "^SCRIPT COMPLETED SUCCESSFULLY" || exit 1
exit 0

