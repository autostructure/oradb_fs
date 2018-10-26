function error_exit {
  echo "  ERROR $2" | tee -a $LOG
  exit $1
}

if [[ -e /usr/openv/netbackup/bp.conf ]]; then
   hosts1="fsxcfox0160
fsxcfox9996
fsxcfox9997
fsxnfsx9987
fsxnfsx9988
fsxnfsx9989
fsxnfsx9990
fsxnfsx9993
fsxnfsx9994
fsxnfsx9999
fsxopsx1470
fsxopsx1471
fsxopsx1472
fsxopsx1477
fsxopsx1478
fsxopsx1479
fsxopsx1481
fsxopsx1483
fsxopsx1484
fsxopsx1485
fsxopsx1486
fsxopsx1487
fsxopsx1488
fsxopsx1489
fsxopsx1490
fsxopsx1491
fsxopsx1492
fsxopsx1493
fsxopsx1494
fsxopsx1505
fsxopsx1508
fsxopsx1509
fsxopsx1510
fsxopsx1511
fsxopsx1512
fsxopsx1513
fsxopsx1515
fsxopsx1516
fsxopsx9895
fsxopsx9897
fsxopsx9898
fsxopsx9930
fsxopsx9931
fsxopsx9942
fsxopsx9944
fsxopsx9945
fsxopsx9947
fsxopsx9948
fsxopsx9949
fsxopsx9950
fsxopsx9957
fsxopsx9962
fsxopsx9963
fsxopsx9964
fsxopsx9965
fsxrndx9995
fsxrndx9996
fsxrndx9998
fsxrndx9999
fsxrnsx9994
fsxrnsx9995
fsxrnsx9997
fsxrnsx9998
fsxrnsx9999
fsxsnpf9994
fsxsnpf9995
fsxsnpf9998"

   hosts2="fsxcfox0156
fsxcfox0161
fsxcfox0162
fsxcfox0163
fsxcfox0164
fsxcfox0165
fsxcfox0166
fsxcfox9998
fsxnfsx0139
fsxnfsx0149
fsxnfsx0158
fsxnfsx0204
fsxnfsx0205
fsxnfsx0206
fsxnfsx0207
fsxnfsx0208
fsxnfsx0209
fsxnfsx0210
fsxnfsx0211
fsxnfsx0212
fsxnfsx9991
fsxopsx0548
fsxopsx0568
fsxopsx0651
fsxopsx0652
fsxopsx0660
fsxopsx0661
fsxopsx0699
fsxopsx0701
fsxopsx0716
fsxopsx0766
fsxopsx0774
fsxopsx0901
fsxopsx0935
fsxopsx0942
fsxopsx0944
fsxopsx0945
fsxopsx9881
fsxopsx9882
fsxopsx9896
fsxopsx9909
fsxopsx9910
fsxopsx9915
fsxopsx9923
fsxopsx9929
fsxopsx9942
fsxopsx9958
fsxopsx9959
fsxrndx0162
fsxrnsx0144
fsxrnsx0145
fsxrnsx0146
fsxrnsx9992
fsxrnsx9993
fsxsnpf9996
fsxsnpf9997
fsxsnpf9999"

   hosts3="fsxcfox9995
fsxnfsx0135
fsxopsx0106
fsxopsx0630
fsxopsx0631
fsxopsx0648
fsxopsx0649
fsxopsx0688
fsxopsx0765
fsxopsx0766
fsxopsx0774
fsxopsx0946
fsxopsx0947
fsxopsx0963
fsxopsx0964
fsxopsx0967
fsxopsx0968
fsxopsx0969
fsxopsx0970
fsxopsx0971
fsxopsx0972
fsxopsx0974
fsxopsx0999
fsxopsx1031
fsxopsx1037
fsxopsx1038
fsxopsx1039
fsxopsx1061
fsxopsx1080
fsxopsx1084
fsxopsx1085
fsxopsx1347
fsxopsx1352
fsxopsx1442
fsxopsx9944
fsxopsx9945
fsxrndx0164
fsxrndx0165
fsxrndx0166
fsxrndx0167
fsxrndx0168
fsxrndx0170
fsxrndx0171
fsxrndx0174
fsxrndx0175
fsxrndx0177
fsxrndx0178
fsxrndx0179
fsxrndx0180
fsxsnpf0141
fsxsnpf0142
fsxsnpf0143"
   export NB_ORA_SERV=$(grep '^SERVER[ ]*=' /usr/openv/netbackup/bp.conf | head -1 | sed 's|SERVER[ ]*=[ ]*||;')
   export NB_ORA_CLIENT=$(grep '^CLIENT_NAME[ ]*=' /usr/openv/netbackup/bp.conf | sed 's|CLIENT_NAME[ ]*=[ ]*||')
   ping -c1 $NB_ORA_SERV > /opt/oracle/diag/bkp/rman/log/build_SEND_cmd.sh.log 2>&1 || error_exit 1 "in /home/oracle/system/rman/build_SEND_cmd.sh, couldn't ping (NB_ORA_SERV) $NB_ORA_SERV" 
   ping -c1 $NB_ORA_CLIENT > /opt/oracle/diag/bkp/rman/log/build_SEND_cmd.sh.log 2>&1 
   if [[ $? != 0 ]]; then
      echo ".. FYI, in /home/oracle/system/rman/build_SEND_cmd.sh, couldn't ping (NB_ORA_CLIENT) $NB_ORA_CLIENT"
      echo ".. FYI, inspecting EBN Oracle VIP for node1 actually being on node1"
      TAB=$(echo -e "\t")
      NODE1=$(olsnodes -n | grep "[ $TAB]1$" | awk '{print $1}')
      echo "NODE1=$NODE1"
      [[ -z $NODE1 ]] && error_exit 1 "couldn't find node1"
      /opt/grid/12.1.0/grid_1/bin/crs_stat | sed 's/^$/~/; /~/! {s/\(.\)$/\1|/ }' | head -30 | sed ':join; {N; s/|\n/|/g; bjoin}' | grep vip | grep "^NAME=net.ebn1.vip|TYPE=app.appvipx.type|TARGET=ONLINE|STATE=ONLINE on $NODE1"
      [[ $? == 0 ]] && error_exit 1 "net.ebn1.vip already on NODE1 ($NODE1) but pinging it failed."
      echo ".. moving net.ebn1.vip to NODE1 ($NODE1)"
      sudo -u grid sudo /opt/grid/12.1.0/grid_1/bin/crsctl relocate resource net.ebn1.vip -n $NODE1
      ping -c1 $NB_ORA_CLIENT > /opt/oracle/diag/bkp/rman/log/build_SEND_cmd.sh.log 2>&1  || error_exit 1 "in /home/oracle/system/rman/build_SEND_cmd.sh, couldn't ping (NB_ORA_CLIENT) $NB_ORA_CLIENT"
   fi
   myhost=$(hostname)
   if [[ "$hosts1" == *$myhost* ]]; then
      export NB_ORA_POLICY="FSX_Oracle"
   elif [[ "$hosts2" == *$myhost* ]]; then
      export NB_ORA_POLICY="FSX_Oracle_2"
   elif [[ "$hosts3" == *$myhost* ]]; then
      export NB_ORA_POLICY="FSX_Oracle_3"
   else
      export NB_ORA_POLICY="FSX_Oracle_3"
   fi
   export send_cmd="send 'NB_ORA_CLIENT=$NB_ORA_CLIENT, NB_ORA_SERV=$NB_ORA_SERV, NB_ORA_POLICY=$NB_ORA_POLICY';" #Pre NBU aliasing
   export send_cmd="send '                              NB_ORA_SERV=$NB_ORA_SERV, NB_ORA_POLICY=$NB_ORA_POLICY';"  
fi
