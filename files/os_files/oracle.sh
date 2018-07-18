# /etc/profile.d/oracle.sh
#
# THIS FILE IS CONTROLLED BY PUPPET
# DO NOT EDIT
#
##############################
# Oracle Database requirements
##############################

if [ $USER = "oracle" ] ; then
  if [ $SHELL = "/bin/ksh" ]; then
    ulimit -u 16384
    ulimit -n 65536
  else
    ulimit -u 16384 -n 65536
  fi
fi

